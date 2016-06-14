
# var defs to prevent undefined errors
stuff = {}

async = require 'async'


badAsync = (callback)-> # HIT
  steps = []

  steps.push ()->
    callback()
    return

  steps.push ()->
    err = new Error 'yo'
    callback err # HIT
    return

  async.parallel steps
  return
#

badAsync2 = (case_data, unhandled_callback)-> # HIT
  steps = []

  _.each case_data, (val, key) ->
    steps.push (cb) ->
      email_payload =
        body: "some email"

      _.each val.things, (thing) ->
        prop = thing.prop
        return

      stuff.emailNotification email_payload, (mail_err, mail_result) ->
        if mail_err
          stuff.error "Failed to send email: #{mail_err.message}"
          cb mail_err
          return

        cb null, mail_result
        return
      return
    return
  return

badAsync2()