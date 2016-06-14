

caller2 = (cb)-> # HIT
  return

caller2()

caller = ()-> # HIT
  return

  
# var defs to prevent undefined errors
stuff = {}

async = require 'async'

exports.getPoolConnection = (good_callback) ->
  # min=0 max=0
  stuff.asdf.getConnection (err, connection) ->
    # min=0 max=0
    if err
      # min=0 max=0
      good_callback err
      # min=1 max=1, okay
      return

    # min=1 max=0
    good_callback null, connection
    # min=2 max=1, okay
    return
  # min=2 max=1, okay
  return

exports.getBadPoolConnection = (bad_callback) ->
  # min=0 max=0
  stuff.getConnection (err, connection) ->
    # min=0 max=0
    if err
      # min=0 max=0
      bad_callback err
      # min=1 max=1

    # min=1 max=1
    bad_callback null, connection # HIT
    # min=2 max=2 BAD
    return
  # min=2 max=1, BAD
  return



badFunc = (err, a_cb)->
  a_cb err
  a_cb err # HIT
  return


badFunc2 = (err, a_cb)-> # HIT
  a_cb err
  a_cb err # HIT
  return


badFunc()

badFunc3 = (cb)-> # HIT
  return

badFunc3()


goodIf = (err, cb)->
  if err
    cb err
  else
    cb null
  return

goodIf()

bad = (cb)->
  cb()
  cb() # HIT
  cb()
  cb()
  cb()
  return

bad()

badIf = (err, cb)->
  if err
    cb err

  cb null # HIT
  return

badIf()

#      when 'CodeFragment', 'Base', 'Block', 'Literal', 'Undefined', 'Null', 'Bool', 'Return', 'Value', 'Comment', 'Call', 'Extends', 'Access' ,'Index', 'Range', 'Slice', 'Obj', 'Arr', 'Class', 'Assign', 'Code', 'Param', 'Splat', 'Expansion', 'While', 'Op', 'In', 'Try', 'Throw' ,'Existence', 'Parens', 'For', 'Switch', 'If'

goodSwitch = (thing, cb)->
  switch thing
    when 1
      cb 1
    when 2
      cb 2
    when 3
      cb 3
    when 4
      cb 4
    when 5,6
      cb 5
    else
      cb 9
  return

goodSwitch()

badSwitch = (thing, cb)->

  switch thing
    when 1
      cb 1
    when 2
      cb 2 # HIT
    when 3
      cb 3
    when 4
      cb 4
    when 5,6
      cb 5
    else
      cb 9

  cb 8
  return

badSwitch()
