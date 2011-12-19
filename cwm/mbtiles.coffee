express = require("express")
fs = require("fs")
sqlite3 = require("sqlite3").verbose()

getTile = (req, res) ->
  console.log "looking up"
  tileset = req.params.tileset
  x = req.params.x
  z = req.params.z
  y = Math.pow(2, z) - 1 - req.params.y
  format = req.params.format
  console.log "opening " + tileset + ".mbtiles"
  db = new sqlite3.Database "tiles/" + tileset + ".mbtiles"
  console.log "grabbing it"
  db.get "SELECT tile_data AS data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?", z, x, y, (err, row) ->
    if err
      console.log "shit"
    else
      console.log "got it"
      res.send row.data,
        "Content-Type": "image/png"
      , 200
    
exports.getTile = getTile
