thing = 1

hasValueCheck = (callback)->
  if callback
    callback()

  a = 9
  return

existanceCheck = (callback)->
  if callback?
    callback()

  a = 8
  return

existanceCheckInverse = (callback)->
  if not callback
    thing()
  else
    callback()
  return

uglyIfCheck = (callback)->
  callback() if callback
  return

multiConditionCheck = (callback)-> # HIT
  if thing and callback
    callback()
  else
    a = 7
  return

ifCheckMultiCall = (callback)->
  if callback
    callback()
    callback() # HIT
  else
    a = 7
  return


unlessCheck = (callback)->
  unless callback
    thing()
  else
    callback()

  a = 9
  return

ifCheck = (callback)->
  unless callback
    thing()
  else
    callback()

  a = 9
  return

errCheck = ()->
  thing.stuff (err, cb)->
    if err
      console.log err

    cb err
    return
  return