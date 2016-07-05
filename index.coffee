
_ = require 'lodash'
ForkLinter = require './ForkLinter'

module.exports = class MultipleCallback
  rule:
    name: 'multiple_callback'
    level: 'error'
    message: 'Callback has the potential of being called multiple times'
    description: '''
      CoffeeLint rule that finds instances where callbacks might be called more than once or not at all.

      These functions have the potential of calling cb() multiple times, and is likely an error:

        # cb() is called twice

        badFunc = (err, cb)->
          cb err
          cb err # BAD
          return


        # cb() could be called multiple times

        badIf = (err, cb)->
          if err
            cb err

          cb null # BAD
          return


        # cb() might never be called

        badIf2 = (err, cb)-> # BAD
          if err
            cb err
          return


      These functions are okay, since they only call the callback once no matter how the logic runs:

        goodIf = (err, cb)->
          if err
            cb err
          else
            cb null
          return


        goodIf2 = (err, cb)->
          if err
            cb err
            return

          cb null
          return


        goodIf3 = (err, cb)->
          if cb
            cb()
          return

    '''

  lintAST: (root_node, @astApi) ->
    fork_linter = new ForkLinter()
    fork_linter.lint root_node
#    console.log 123, fork_linter.errors

    for err in fork_linter.errors
      @errors.push @astApi.createError(err)

    return