express = require("express")
routes = require("./routes")
mbtiles = require("mbtiles")
sqlite3 = require("sqlite3")

app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")
  app.use express.favicon(__dirname + "/public/images/favicon.ico")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.index 
app.get "/:tileset/:z/:x/:y.*", (req, res)->
  res.render "tile",
    title: req.params.tileset
    zoom: req.params.z
    y: req.params.y
    x: req.params.x
    format: req.params[0]
app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
