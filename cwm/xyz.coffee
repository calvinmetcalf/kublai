express = require("express")
fs = require("fs")
blend = require("blend")
Buffer = require("buffer").Buffer

getTile = (req, res, next) ->
  console.log "looking up"
  tileset = req.params.tileset
  scheme = req.params.scheme
  x = req.params.x
  z = req.params.z
  format = req.params.format
  if scheme is "tms"
    y = req.params.y
  else if scheme is "xyz"
    y = Math.pow(2, z) - 1 - req.params.y
    console.log "fliped your y from " + req.params.y + " to " + y
  else
    err
  console.log "reading " + tileset + "/1.0.0/" + tileset + "/" + z + "/" + x + "/" + y + "." + format
  fs.readFile "tiles/" + tileset + "/1.0.0/" + tileset + "/" + z + "/" + x + "/" + y + "." + format, (err, data) ->
    if err
      res.json "oh noes!", 500
      console.log "couldnt find it"
    else
      console.log "found it"
      req.data = data
      next()
      
blendTile = (req, res, next) ->
  console.log "looking up"
  tileset1 = req.params.tileset1
  tileset2 = req.params.tileset2
  scheme = req.params.scheme
  x = req.params.x
  z = req.params.z
  format = req.params.format
  if scheme is "tms"
    y = req.params.y
  else if scheme is "xyz"
    y = Math.pow(2, z) - 1 - req.params.y
    console.log "fliped your y from " + req.params.y + " to " + y
  else
    err
  console.log "about to blend"
  blend [fs.readFileSync("tiles/" + tileset1 + "/1.0.0/" + tileset1 + "/" + z + "/" + x + "/" + y + "." + format), fs.readFileSync("tiles/" + tileset2 + "/1.0.0/" + tileset2 + "/" + z + "/" + x + "/" + y + "." + format)], (err, result) ->
    if err
      res.json "oh noes!", 500
      console.log "couldnt find it"
    else
      console.log "found it"
      req.data = result
      next()
getGrid = (req, res, next) ->
  console.log "looking up"
  tileset = req.params.tileset
  scheme = req.params.scheme
  x = req.params.x
  z = req.params.z
  format = req.params.format
  if scheme is "tms"
    y = req.params.y
  else if scheme is "xyz"
    y = Math.pow(2, z) - 1 - req.params.y
    console.log "fliped your y from " + req.params.y + " to " + y
  else
    err
  console.log "reading " + tileset + "/1.0.0/" + tileset + "/" + z + "/" + x + "/" + y + "." + format
  fs.readFile "tiles/" + tileset + "/1.0.0/" + tileset + "/" + z + "/" + x + "/" + y + "." + format, (err, data) ->
    if err
      res.json "oh noes!", 500
      console.log "couldnt find it"
    else
      console.log "found it"
      req.data = data
      next()
exports.blendTile = blendTile    
exports.getTile = getTile
exports.getGrid = getGrid
