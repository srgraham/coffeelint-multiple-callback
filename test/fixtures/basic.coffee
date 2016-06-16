
some_require = require('./thing')()

caller = ()->
  return

caller2 = (cb)-> # HIT
  return

caller2()
  
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


badFunc2 = (err, a_cb)->
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

goodIf2 = (err, cb)->
  if err
    cb err
    return

  cb null
  return

goodIf2()

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

# TODO: this fails. put effort into fixing it....
#factorial = (n) ->
#  if n < 0
#    return 0
#
#  if n is 0 or n is 1
#    return 1
#
#  return n * factorial(n - 1)

six = 6

class A
  one: 1
  @two: 2
  three = 3
  @four = 4
  five()
  six
  9

  constructor: (bad_cb)-> # HIT
    return

  methodOne: (bad_cb2)-> # HIT
    return 1

  @methodTwo: (bad_cb3)-> # HIT
    return 2

  methodThree = (bad_cb4)-> # HIT
    return 3

  @methodFour = (bad_cb5)-> # HIT
    return 4

class B extends A
  constructor: () ->
    super 'B'
    return

goodTry = (cb)->
  a = 0

  try
    a = 1 # all of this

  catch e
    a = 2 # all of this
    cb()
    return

  finally
    a = 3 # all of this

  a = 4
  cb()
  return
  
goodTry()

badTry = (bad_cb)->
  try
    bad_cb()
  catch e
    stuff()
    return

  bad_cb() # HIT
  return

badTry()

goodFunc = (cb)->
  someFunc cb, 123
  return
