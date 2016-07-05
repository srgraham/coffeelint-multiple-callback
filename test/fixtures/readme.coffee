
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

badIf = (err, cb)-> # BAD
  if err
    cb err
  return


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
