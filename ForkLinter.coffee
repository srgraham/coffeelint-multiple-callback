_ = require 'lodash'

Branch = require './Branch'

prefix = 'prefix'

getNodeType = (node)->
  return node.constructor.name

# Given a var_name, dumps the var name we will consider as being incremented
# or null if we don't think its a callback variable
getCallbackVarName = (var_name)->
  express_regex = ///
    ^res\.          # var name matches res.[blah]
      (
        _end
        | end
        | json
        | redirect
        | render
        | send
      )$
    | ^next$        # var name is "next"

  ///i

  promise_regex = ///
    ^(resolve|reject)$
  ///

  # if it matches an express callback, return "express variable"
  if express_regex.test var_name
    return 'express variable'

  # if it matches an promise callback, return "promise variable"
  if promise_regex.test var_name
    return 'promise variable'

  regex = ///
      (^(cb|callback|fn|cbb)\d*$)               # var name exact matches
    | (^(cb|callback|fn)_)                      # var name that starts with "cb_"
    | (_(cb|callback|fn)\d*$)                   # var name that ends with "_cb"
    | (^(express|promise)\svariable$)           # one of our special variables
  ///i

  # if it looks like a cb variable, return the var name
  if regex.test var_name
    return var_name
  return null

variableObjToStr = (variable_obj)->
  var_name = variable_obj.base.value

  accessors = _.filter variable_obj.properties, (prop)->
    out = getNodeType(prop) is 'Access'
    return out

  if not _.isEmpty accessors
    var_name_pieces = []
    var_name_pieces.push var_name

    _.each accessors, (prop)->
      var_name_pieces.push prop.name.value
      return

    var_name = var_name_pieces.join '.'

  return var_name

isExempt = (func_name)->

  exempt_regex = ///
      ^(module\.)?exports(\.|$)    # module =
                                   # module.exports =
                                   # module.exports.blah.... =
    | ^constructor$                # class constructors
  ///

  if exempt_regex.test func_name
    return true

  return false

class ForkLinter
  constructor: ()->
    @current_branch = null
    @root_branch = null
    @stack = []
    return

  lint: (root, @options)=>
    @errors = []
    @current_branch = new Branch(null, true)
    @root_branch = @current_branch
    @visit root
    @root_branch.is_end_of_branch = true
    @root_branch.is_dead_branch = true
    @root_branch.is_new_scope = false
    @checkBranchForBadCalls @root_branch

    return

  checkBranchForBadCalls: (branch)=>
    calls = branch.getCalls()
    _.each calls, (call_obj)=>
      @checkForBadCall call_obj, branch
      return
    return

  checkForBadCall: (call_obj, branch)=>

    if isExempt call_obj.func_name
      return

    if call_obj.might_not_be_func
      # see if the name of the variable is callback-esque. if not, we'll skip over it
      if not getCallbackVarName call_obj.func_name
        return

    # check if this func might never be called :0!!
    if call_obj.min_hits is 0

      # only trigger if this is the end of a branch and the var was defined in this branch
      if branch.isEndOfFuncExistence(call_obj) # branch.isDeadBranch()
        if not call_obj.triggered_errors.no_hits
          call_obj.triggered_errors.no_hits = true
          err_msg = "Callback '#{call_obj.func_name}' has the chance of never being called."
          @throwError call_obj.def_node, err_msg, call_obj.func_name, call_obj.min_hits, call_obj

    # check if this func has been called multiple times :0!!
    if call_obj.max_hits > 1
      if not call_obj.triggered_errors.multiple_hits
        if call_obj.is_defined_in_this_file
          call_obj.triggered_errors.multiple_hits = true

          # guarenteed to be length - max_hits_this_branch
          first_bad_node = call_obj.called_at_nodes[1]

          err_msg = "Callback '#{call_obj.func_name}' has the chance of being called multiple times (#{call_obj.max_hits})."
          @throwError first_bad_node, err_msg, call_obj.func_name, call_obj.max_hits, call_obj
    return

  addBranch: (is_new_scope, cb)=>
    parent_branch = @current_branch
    child_branch = new Branch parent_branch, is_new_scope
    @current_branch = child_branch

    cb()

    # @current_branch.is_dead_branch = not is_new_scope
    @current_branch.is_end_of_branch = true

    @checkBranchForBadCalls @current_branch

    @current_branch = parent_branch
    return child_branch

  mergeForkBranches: (fork_branches...)=>
    out_calls = {}
    first_branch = _.first fork_branches
    parent_branch = first_branch.getParentBranch()
    
    _.each fork_branches, (fork_branch)=>

      _.each fork_branch.getCalls(), (call_obj, prefixed_func_name)=>
        # skip if it was defined in the fork
        if call_obj.is_defined_in_this_branch
          return

        # if not already in out, just add it and return to the loop
        if not out_calls[prefixed_func_name]
          out_calls[prefixed_func_name] = call_obj
          if fork_branch.isDeadBranch()
            out_calls[prefixed_func_name].max_hits_this_branch = 0
            out_calls[prefixed_func_name].called_at_nodes = []
            out_calls[prefixed_func_name].called_at_nodes_this_branch = []

          # then resume _.each loop
          return

        out_calls[prefixed_func_name].triggered_errors.no_hits |= call_obj.no_hits
        out_calls[prefixed_func_name].triggered_errors.multiple_hits |= call_obj.multiple_hits

        if not fork_branch.isDeadBranch()
          out_calls[prefixed_func_name].def_node ?= call_obj.def_node
          out_calls[prefixed_func_name].called_at_nodes_this_branch = out_calls[prefixed_func_name].called_at_nodes_this_branch.concat call_obj.called_at_nodes_this_branch
          out_calls[prefixed_func_name].max_hits_this_branch = _.max [out_calls[prefixed_func_name].max_hits_this_branch, call_obj.max_hits_this_branch]

        out_calls[prefixed_func_name].min_hits_this_branch = _.min [out_calls[prefixed_func_name].min_hits_this_branch, call_obj.min_hits_this_branch]

        # out_calls[prefixed_func_name].is_defined_in_this_scope |= call_obj.is_defined_in_this_scope
        out_calls[prefixed_func_name].might_not_be_func &= call_obj.might_not_be_func

        return
      return

    parent_calls = parent_branch.getCalls()

    _.each out_calls, (call_obj, prefixed_func_name)->
      if not parent_calls[prefixed_func_name]
        parent_branch.initBlankFunc call_obj.func_name

      call_obj.min_hits = parent_calls[prefixed_func_name].min_hits + out_calls[prefixed_func_name].min_hits_this_branch
      call_obj.max_hits = parent_calls[prefixed_func_name].max_hits + out_calls[prefixed_func_name].max_hits_this_branch
      call_obj.called_at_nodes_this_branch = parent_calls[prefixed_func_name].called_at_nodes_this_branch.concat out_calls[prefixed_func_name].called_at_nodes_this_branch
      call_obj.called_at_nodes = parent_calls[prefixed_func_name].called_at_nodes.concat out_calls[prefixed_func_name].called_at_nodes_this_branch
      return

#    # merge in current branch's calls, overwriting values that it has priority over
#    _.each @current_branch.getCalls(), (call_obj, prefixed_func_name)=>
#      if not out_calls[prefixed_func_name]
#        out_calls[prefixed_func_name] = call_obj
#        return
#
##      out_calls[prefixed_func_name].def_node ?= call_obj.def_node
##      out_calls[prefixed_func_name].called_at_nodes = out_calls[prefixed_func_name].called_at_nodes.concat call_obj.called_at_nodes
#      out_calls[prefixed_func_name].min_hits = _.min [out_calls[prefixed_func_name].min_hits, call_obj.min_hits]
#      out_calls[prefixed_func_name].max_hits = _.max [out_calls[prefixed_func_name].max_hits, call_obj.max_hits]
#
#      out_calls[prefixed_func_name].is_defined_in_this_scope = call_obj.is_defined_in_this_scope
#      out_calls[prefixed_func_name].might_not_be_func &= call_obj.might_not_be_func
#
#
#      return

    combined_branch = new Branch parent_branch, false
#    combined_branch = new Branch parent_branch, first_branch.is_new_scope
    combined_branch.calls = out_calls
    return combined_branch

  visit: (node)=>
    node_type = getNodeType(node)
    handler = @["visit#{node_type}"]
#    console.log "Visiting #{node_type}"

    if handler?
      handler node
    else
#      console.log "No handler for #{node_type}"
      node.eachChild @visit
    return
    
  visitReturn: (node)=>
#    console.log node
    @current_branch.is_dead_branch = true
    @current_branch.is_end_of_branch = true
#    @checkForBadCall @current_branch.calls
#    @current_branch.calls = {}

    return false

  visitDef: (node, func_name, might_not_be_func = true)=>

    converted_func_name = getCallbackVarName(func_name) or func_name

    if not converted_func_name
      throw new Error "no converted_func_name passed to visitDef()"
#    converted_func_name = variableObjToStr node.variable

    @current_branch.addFuncDef converted_func_name, node, might_not_be_func
    return
    
  visitCall: (node)=>
    # FIXME: handle do

    variable = node.variable

    # trigger a call on each param
    # This happens before the main Call handling because coffeescript doesn't have a node for a super() call
    if node.args
      _.each node.args, (child_node)=>
        child_node_type = getNodeType child_node
        switch child_node_type
          when 'Value'
            # we only care about variables. don't care about strings, numbers, etc
            if child_node.isAssignable()
              called_func_name = variableObjToStr child_node
              converted_called_func_name = getCallbackVarName(called_func_name) or called_func_name
              @current_branch.addFuncCall converted_called_func_name, node, false
          # end when Value
        return

    # Now handle the Call node

    # super() has a null variable or something
    if not variable
      node.eachChild @visit
      return

    switch getNodeType variable
      # if a call calls a call, it needs to be handled special
      when 'Call'
        @visitCall variable
        return

    func_name = variableObjToStr variable

    converted_func_name = getCallbackVarName(func_name) or func_name

    @current_branch.addFuncCall converted_func_name, node

    node.eachChild @visit

    return

      #      when 'CodeFragment', 'Base', 'Block', 'Literal', 'Undefined', 'Null', 'Bool', 'Return', 'Value', 'Comment', 'Call', 'Extends', 'Access' ,'Index', 'Range', 'Slice', 'Obj', 'Arr', 'Class', 'Assign', 'Code', 'Param', 'Splat', 'Expansion', 'While', 'Op', 'In', 'Try', 'Throw' ,'Existence', 'Parens', 'For', 'Switch', 'If'

  visitAssign: (node)=>
    # TODO: bring this back and check for whether or not a func is module.exported to flag it as used
#    node_type = getNodeType node.value
#    if node_type is 'Code'
#      func_name = variableObjToStr node.variable
#      if func_name
#        @visitDef node, func_name, false

    node.eachChild @visit
    return

  visitIf: (node)=>
    block1 = node.body
    block2 = node.elseBody

    condition = node.condition

    # check for these:
    # if callback
    # if callback?
    # if not callback
    # if not callback?

    invert_checking_existence_varname = false

    while condition.first and condition.operator is '!'
      invert_checking_existence_varname ^= true
      condition = condition.first

    if condition.expression
      condition = condition.expression

    checking_existence_varname = condition.base?.value
    if checking_existence_varname
      existence_func_name = variableObjToStr condition
      existence_converted_func_name = getCallbackVarName(existence_func_name) or existence_func_name

    block1_branch = @addBranch false, ()=>
      # if the if's condition is checking for the existence of a variable and it has a "not" operator,
      # trigger this condition as a call, because missing a call in this branch is considered okay
      if existence_converted_func_name and invert_checking_existence_varname
        @current_branch.addFuncCall existence_converted_func_name, condition, false

      block1.eachChild @visit
      return

    block2_branch = @addBranch false, ()=>
      # if the if's condition is checking for the existence of a variable and it doesn't have a "not" operator,
      # trigger this condition as a call, because missing a call in this branch is considered okay
      if existence_converted_func_name and not invert_checking_existence_varname
        @current_branch.addFuncCall existence_converted_func_name, condition, false

      if block2
        block2.eachChild @visit
      return

#    @checkBranchForBadCalls block1_branch
#    @checkBranchForBadCalls block2_branch

    # AFTER processing all the branches, merge the calls back in
    # if child hit a Return, then all its calls have already been emptied out
    fork_branch = @mergeForkBranches block1_branch, block2_branch
    @current_branch.mergeChildCalls fork_branch

#    @current_branch.calls = fork_calls

    @checkBranchForBadCalls @current_branch

    return

  visitSwitch: (node)=>
    branches = []

    block_else = node.otherwise

    _.each node.cases, (block_obj)=>
      # the second arg to the block obj is always the actual Block
      block = block_obj[1]
      block_branch = @addBranch false, ()=>
        block.eachChild @visit
        return
        
      branches.push block_branch
      return

    else_branch = @addBranch false, ()=>
      if block_else
        block_else.eachChild @visit
      return

    # AFTER processing all the branches, merge the calls back in
    fork_branch = @mergeForkBranches branches..., else_branch
    @current_branch.mergeChildCalls fork_branch

    @checkBranchForBadCalls @current_branch

    return

  visitParam: (node)=>
    func_name = node.name.value
#    func_name = getCallbackVarName node.variable
#
#    if func_name
#      @current_branch.addFuncDef func_name, node

    if func_name
      @visitDef node, func_name, true
      return
    return

  visitCode: (node)=>
    child_branch = @addBranch true, ()=>
      node.eachChild @visit
      return


    # IDK!:
#    @checkBranchForBadCalls child_branch
    @current_branch.mergeChildCalls child_branch
    @checkBranchForBadCalls @current_branch
    return

#  visitdBlock: (node)=>
#    @visitCode node
##    child_branch = @addBranch true, ()=>
##      node.eachChild @visit
##      return
##
##    # IDK!:
##    @checkBranchForBadCalls child_branch
##    @current_branch.mergeChildCalls child_branch
##    @checkBranchForBadCalls @current_branch
#    return

#  visitLiteral: ()=>
#    return
  
  visitClass: (node)=>
    node.body.eachChild (child_node)=>
      node_type = getNodeType child_node
      switch node_type
        when 'Value'
          # if a body node of a Class is a Value, that means it's a method or variable applied directly to the class
          child_node.base.eachChild (method_node)=>
            method_body_node = method_node.value
            @visit method_body_node
            return
        else
          # otherwise, it behaves as normal code
          child_node.eachChild @visit
      return
    return

  visitTry: (node)=>
    try_block = node.attempt
    catch_block = node.recovery
    finally_block = node.ensure

    # possible routes
    # (try -> catch) -> finally
    # (try) -> finally

    # we have two branches we're forking into: either both try and catch are hit, or only try
    # we have to group in the try block on both because there's a chance it returns and we have to handle that properly
    catch_branch_hit = @addBranch false, ()=>
      try_block.eachChild @visit
      if catch_block
        catch_block.eachChild @visit
      return

    catch_branch_skipped = @addBranch false, ()=>
      try_block.eachChild @visit
      return

    # FIXME: we might also need a branch to account for Try being hit, but not hitting an inner Return?

    # AFTER processing all the branches, merge the calls back in
    catch_fork_branch = @mergeForkBranches catch_branch_hit, catch_branch_skipped
    @current_branch.mergeChildCalls catch_fork_branch


    # then hit finally
    if finally_block
      finally_block.eachChild @visit

    @checkBranchForBadCalls @current_branch
    return

  throwError: (node, err_msg, func_name, hits, call_obj)=>
    if not node or not node.locationData
      throw new Error "Missing node.locationData for throwError()"
      return

    err_obj =
      lineNumber: node.locationData.first_line + 1
      func_name: func_name
      hits: hits
      call_obj: call_obj

    if err_msg
      err_obj.message = err_msg

    if not _.isEmpty call_obj.called_at_nodes
      called_at_lines = _.map call_obj.called_at_nodes, (called_at_node)->
        out = called_at_node.locationData.first_line + 1
        return out
      err_obj.message += " - Called at #{called_at_lines.join(', ')}"

    @errors.push err_obj
    return


module.exports = ForkLinter

