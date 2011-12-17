express = require("express")
cwm = require("./cwm")

kublai = module.exports = express.createServer()
kublai.configure ->
  kublai.use express.bodyParser()
  kublai.use express.methodOverride()
  kublai.use kublai.router
  kublai.use express.errorHandler()

kublai.get "/:scheme(xyz|tms)/:tileset/:z/:x/:y.:format(png|jpg|jpeg)", cwm.xyz.getTile, (req, res) ->

kublai.error (err, req, res, next) ->
  res.send err.message, 500
      
kublai.listen 7027
console.log "Kublai is listening on port %d", kublai.address().port
