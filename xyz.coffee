express = require("express")
fs = require("fs")

getTile = (req, res) ->
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
  fs.readFile __dirname + "/tiles/" + tileset + "/1.0.0/" + tileset + "/" + z + "/" + x + "/" + y + "." + format, (err, data) ->
    if err
      res.json "oh noes!", 500
      console.log "couldnt find it"
    else
      console.log "found it"
      res.send data,
        "Content-Type": "image/png"
      , 200
    
exports.getTile = getTile
