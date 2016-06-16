prefix = 'prefix'
_ = require 'lodash'


class Branch
  constructor: (@parent_branch, @is_new_scope)->
    @calls = {}
    parent_calls =  @parent_branch?.calls or {}

    _.each parent_calls, (parent_call_obj, prefixed_func_name)=>

      @initBlankFunc(parent_call_obj.func_name)

      # inherited
      @calls[prefixed_func_name].min_hits = parent_call_obj.min_hits
      @calls[prefixed_func_name].max_hits = parent_call_obj.max_hits
      @calls[prefixed_func_name].is_defined_in_this_scope = parent_call_obj.is_defined_in_this_scope
      @calls[prefixed_func_name].might_not_be_func = parent_call_obj.might_not_be_func
      @calls[prefixed_func_name].is_defined_in_this_file = parent_call_obj.is_defined_in_this_file

      # inherited pass by ref!!!
      @calls[prefixed_func_name].called_at_nodes = _.clone parent_call_obj.called_at_nodes # array is cloned. nodes are not. major speed boost
      @calls[prefixed_func_name].triggered_errors = parent_call_obj.triggered_errors

      # emptied values:
      @calls[prefixed_func_name].min_hits_this_branch = 0
      @calls[prefixed_func_name].max_hits_this_branch = 0
      @calls[prefixed_func_name].called_at_nodes_this_branch = []
      @calls[prefixed_func_name].is_defined_in_this_branch = false
      @calls[prefixed_func_name].is_modified_in_branch = false

      if @is_new_scope
        @calls[prefixed_func_name].is_defined_in_this_scope = false

      return

    _.each @calls, (call_obj)=>
      call_obj.min_hits_this_branch = 0
      call_obj.max_hits_this_branch = 0
      call_obj.called_at_nodes_this_branch = []
      call_obj.is_defined_in_this_branch = false

      if @is_new_scope
        call_obj.is_defined_in_this_scope = false
      return
    return

  isDeadBranch: ()=>
    out = @is_dead_branch
    if @is_new_scope
      out = false
    return out

  getBranchDepth: ()=>
    branch_count = 0
    next_branch_up = @
    while branch_count < 99 and not _.isNull next_branch_up
      next_branch_up = next_branch_up.getParentBranch()
      branch_count += 1

    return branch_count

  isEndOfFuncExistence: (call_obj)=>
    if @is_end_of_branch and call_obj.is_defined_in_this_branch
      return true

    return false

  isRootBranch: ()=>
    if _.isNull @parent_branch
      return true
    return false

  getParentBranch: ()=>
    return @parent_branch

  initBlankFunc: (func_name)=>
    if "#{prefix}-#{func_name}" is 'prefix-undefined' or "#{prefix}-#{func_name}" is 'prefix-null'
      throw new Error "undefined/null func_name passed to initBlankFunc()"
      return

    @calls["#{prefix}-#{func_name}"] ?=
      min_hits: 0
      max_hits: 0
      min_hits_this_branch: 0
      max_hits_this_branch: 0
      is_defined_in_this_scope: false
      is_defined_in_this_branch: false
      called_at_nodes: []
      called_at_nodes_this_branch: []
      func_name: func_name
      might_not_be_func: true
      triggered_errors:
        no_hits: false
        multiple_hits: false
      is_defined_in_this_file: false
      is_modified_in_branch: false
    return

  addFuncCall: (func_name, node)=>

    @initBlankFunc func_name

    call_obj = @calls["#{prefix}-#{func_name}"]
    call_obj.min_hits += 1
    call_obj.max_hits += 1
    call_obj.min_hits_this_branch += 1
    call_obj.max_hits_this_branch += 1

    call_obj.called_at_nodes.push node
    call_obj.called_at_nodes_this_branch.push node

    # if it's being called, we have no doubt that its a function
    call_obj.might_not_be_func = false
    call_obj.is_modified_in_branch = true

#    console.log "Calling #{func_name}: [#{call_obj.min_hits}, #{call_obj.max_hits}]"
    return

  # when a func is defined through assignment or as a param, trigger this
  addFuncDef: (func_name, node, might_not_be_func = true)=>

    @initBlankFunc func_name

    @calls["#{prefix}-#{func_name}"].is_defined_in_this_scope = true
    @calls["#{prefix}-#{func_name}"].is_defined_in_this_branch = true
    @calls["#{prefix}-#{func_name}"].def_node = node
    @calls["#{prefix}-#{func_name}"].might_not_be_func &= might_not_be_func
    @calls["#{prefix}-#{func_name}"].is_defined_in_this_file = true
    @calls["#{prefix}-#{func_name}"].is_modified_in_branch = true
    return

  mergeChildCalls: (child_branch)=>

    # FIXME: child_branch.is_dead_branch????
#    if child_branch.is_dead_branch
#      console.log "Hit Return, skipping merge"
#      return

    child_calls = child_branch.getCalls()
    out_calls = @calls

    _.each child_calls, (call_obj, prefixed_func_name)=>

      # skip over variables defined deeper in the chain or variables that havent been touched
      if ( not call_obj.is_modified_in_branch ) or call_obj.is_defined_in_this_branch
        return

      @initBlankFunc call_obj.func_name
      out_calls[prefixed_func_name].triggered_errors.no_hits |= call_obj.no_hits
      out_calls[prefixed_func_name].triggered_errors.multiple_hits |= call_obj.multiple_hits

#      out_calls[prefixed_func_name].min_hits = call_obj.min_hits
#      out_calls[prefixed_func_name].max_hits = call_obj.max_hits

      # if its a dead branch, we don't need max_hits added up the chain
      if not child_branch.isDeadBranch()
        out_calls[prefixed_func_name].def_node ?= call_obj.def_node
        out_calls[prefixed_func_name].called_at_nodes_this_branch = out_calls[prefixed_func_name].called_at_nodes_this_branch.concat call_obj.called_at_nodes_this_branch
        out_calls[prefixed_func_name].called_at_nodes = out_calls[prefixed_func_name].called_at_nodes.concat call_obj.called_at_nodes_this_branch
#        out_calls[prefixed_func_name].max_hits = _.max [out_calls[prefixed_func_name].max_hits, call_obj.max_hits]
        out_calls[prefixed_func_name].max_hits += call_obj.max_hits_this_branch
        out_calls[prefixed_func_name].max_hits_this_branch += call_obj.max_hits_this_branch

      out_calls[prefixed_func_name].min_hits += call_obj.min_hits_this_branch
      out_calls[prefixed_func_name].min_hits_this_branch += call_obj.min_hits_this_branch
#      out_calls[prefixed_func_name].min_hits = _.min [out_calls[prefixed_func_name].min_hits, call_obj.min_hits]

      # out_calls[prefixed_func_name].is_defined_in_this_scope |= call_obj.is_defined_in_this_scope
      out_calls[prefixed_func_name].might_not_be_func &= call_obj.might_not_be_func


      return

    child_branch.is_end_of_branch = true
#    child_branch.is_dead_branch = true

    return

  getCalls: ()=>
    return @calls

module.exports = Branch