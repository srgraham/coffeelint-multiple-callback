
_ = require 'lodash'
ForkLinter = require './ForkLinter'

module.exports = class MultipleCallback
  rule:
    name: 'multiple_callback'
    level: 'error'
    message: 'asdf'
    description: '''
    '''

  lintAST: (root_node, @astApi) ->
    fork_linter = new ForkLinter()
    fork_linter.lint root_node
#    fork_linter.getRootSumScopeCalls()

#    console.log 123, fork_linter.errors

    for err in fork_linter.errors
      @errors.push @astApi.createError(err)

    return