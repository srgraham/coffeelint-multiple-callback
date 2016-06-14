
# var defs to prevent undefined errors
stuff = {}

_ = require 'lodash'

badEach = (steps, callback)-> # HIT
  _.each steps, ()->
    callback
    return
  return

goodEach = (data, bad_callback)-> # HIT
  steps = []
  _.each data, (val, key) ->
    steps.push (cb) ->
      email_payload =
        body: "some email"

      _.each val.assets, (asset) ->
        thing = asset.thing
        email_payload.body += "#{thing}\n"
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

goodEach()