
# var defs to prevent undefined errors
stuff = {}

_ = require 'lodash'

badEach = (steps, callback)->
  _.each steps, ()->
    callback
    return
  return

goodEach = (data, callback)->
  steps = []
  _.each data, (val, key) ->
    steps.push (cb) ->
      email_payload =
        body: "some email"

      _.each val.assets, (asset) ->
        eitms_code = asset.eitms_code
        device_name = asset.device_name
        from = asset.lender
        to = asset.borrower
        email_payload.body += "#{device_name} (#{eitms_code}): loaned to (#{to}) by (#{from}).\n"
        return

      stuff.emailNotification email_payload, (mail_err, mail_result) ->
        if mail_err
          stuff.error 'Failed to send loan warning: ' + mail_err.message
          cb mail_err
          return

        cb null, mail_result
        return
      return
    return
  return