express = require("express")
cwm = require("./cwm")

kublai = module.exports = express.createServer()
kublai.configure ->
  kublai.use express.bodyParser()
  kublai.use express.methodOverride()
  kublai.use kublai.router
  kublai.use express.errorHandler()

kublai.get "/:scheme(xyz|tms)/:tileset/:z/:x/:y.:format(png|jpg|jpeg)", cwm.xyz.getTile, (req, res) ->
  console.log "serving you"
  if req.params.format = "jpg"
    format = "jpeg"
  else
    format = req.params.format
  res.send req.data,
    "Content-Type": "image/" + format
  , 200
kublai.get "/:scheme(xyz|tms)/:tileset/:z/:x/:y.:format(json|grid.json)", cwm.xyz.getGrid, (req, res) ->
  console.log "serving you"
  res.send req.data,
    "Content-Type": "application/json"
  , 200
kublai.get "/:tileset/:z/:x/:y.:format(png|jpg|jpeg)", cwm.mbtiles.getTile, (req, res) ->
  console.log "serving you"
  res.send req.data,
    "Content-Type": "image/png"
  , 200
###
kublai.get "/:tileset1/:tileset2/:z/:x/:y.:format(png|jpg|jpeg)", cwm.mbtiles.blendTile, (req, res) ->
  console.log "serving you"
  res.send req.data1,
    "Content-Type": "image/png"
  , 200
###
kublai.get "/:scheme(xyz|tms)/:tileset1/:tileset2/:z/:x/:y.:format(png|jpg|jpeg)", cwm.xyz.blendTile, (req, res) ->
  console.log "serving you"
  res.send req.data,
    "Content-Type": "image/png"
  , 200
###
kublai.get "/:tileset/:z/:x/:y.:format(json|grid.json)", cwm.mbtiles.getGrid, (req, res) ->
###
kublai.error (err, req, res, next) ->
  res.send err.message, 500
      
kublai.listen 7027
console.log "Kublai is listening on port %d", kublai.address().port
