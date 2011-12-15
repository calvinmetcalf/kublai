express = require("express")
routes = require("./routes")
sqlite3 = require("sqlite3")

kublai = module.exports = express.createServer()
kublai.configure ->
  kublai.set "views", __dirname + "/views"
  kublai.set "view engine", "jade"
  kublai.use express.bodyParser()
  kublai.use express.methodOverride()
  kublai.use kublai.router
  kublai.use express.static(__dirname + "/public")
  kublai.use express.favicon(__dirname + "/public/images/favicon.ico")

kublai.configure "development", ->
  kublai.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

kublai.configure "production", ->
  kublai.use express.errorHandler()

kublai.get "/", routes.index 
kublai.get "/:tileset/:z/:x/:y.*", (req, res)->
  res.render "tile",
    title: req.params.tileset
    zoom: req.params.z
    y: req.params.y
    x: req.params.x
    format: req.params[0]
kublai.listen 3000
console.log "Express server listening on port %d in %s mode", kublai.address().port, kublai.settings.env
