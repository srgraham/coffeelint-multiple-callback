
app = express()
app.use '/test-multiple-res-error', (req,res,next)->
  options = {}
  res.send(123)
  res.render 'path/to/template.ejs', options
  return

app.use '/test-multiple-res-okay', (req,res,next)->
  options = {}
  res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate")
  res.render 'path/to/template.ejs', options
  return

app.use '/test-res-not-sent-error', (req,res,next)->
  return

app.use '/test-next-and-res-error', (req,res,next)->
  res.send(123)
  next()
  return

