express = require("express")
fs = require("fs")
kublai = module.exports = express.createServer()
kublai.configure ->
  kublai.use express.bodyParser()
  kublai.use express.methodOverride()
  kublai.use kublai.router
  kublai.use express.errorHandler()

kublai.get "/:scheme(xyz|tms)/:tileset/:z/:x/:y.:format(png|jpg|jpeg)", (req, res) ->
  if req.params.scheme is "tms"
    fs.readFile __dirname + "/tiles/" + req.params.tileset + "/1.0.0/" + req.params.tileset + "/" + req.params.z + "/" + req.params.x + "/" + req.params.y + "." + req.params.format, (err, data) ->
      if err
        res.json "oh noes!", 500
      else
        res.send data,
          "Content-Type": "image/png"
        , 200
  else
    y = Math.pow(2, req.params.z) - 1 - req.params.y
    fs.readFile __dirname + "/tiles/" + req.params.tileset + "/1.0.0/" + req.params.tileset + "/" + req.params.z + "/" + req.params.x + "/" + y + "." + req.params.format, (err, data) ->
      if err
        res.json "oh noes!", 500
      else
        res.send data,
          "Content-Type": "image/png"
        , 200

kublai.get "/:tileset/:z/:x/:y.:format(png|jpg|jpeg)", (req, res) ->
  y = Math.pow(2, req.params.z) - 1 - req.params.y
  fs.readFile __dirname + "/tiles/" + req.params.tileset + "/1.0.0/" + req.params.tileset + "/" + req.params.z + "/" + req.params.x + "/" + y + "." + req.params.format, (err, data) ->
    if err
      res.json "oh noes!", 500
    else
      res.send data,
        "Content-Type": "image/png"
      , 200

kublai.error (err, req, res, next) ->
  res.send err.message, 500

kublai.listen 7027
console.log "Kublai is listening on port %d", kublai.address().port
