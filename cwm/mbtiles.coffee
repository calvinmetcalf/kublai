express = require("express")
fs = require("fs")
sqlite3 = require("sqlite3").verbose()
blend = require("blend")
Buffer = require("buffer").Buffer
#zlib = require('zlib')

getTile = (req, res, next) ->
  console.log "looking up"
  tileset = req.params.tileset
  x = req.params.x
  y = req.params.y
  z = req.params.z
  y = Math.pow(2, z) - 1 - y
  console.log "opening " + tileset + ".mbtiles"
  db = new sqlite3.Database "tiles/" + tileset + ".mbtiles"
  console.log "grabbing it"
  db.get "SELECT tile_data AS data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?", z, x, y, (err, row) ->
    if err
      console.log "shit"
    else
      console.log "found it"
      req.data = row.data
      next()
    ### 
blendTile = (req, res, next) ->
  console.log "looking up"
  tileset1 = req.params.tileset1
  tileset2 = req.params.tileset2
  x = req.params.x
  z = req.params.z
  y = Math.pow(2, z) - 1 - req.params.y
  format = req.params.format
  console.log "opening " + tileset1 + ".mbtiles"
  db = new sqlite3.Database "tiles/" + tileset1 + ".mbtiles"
  console.log "grabbing it"
  db.get "SELECT tile_data AS data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?", z, x, y, (err, row) ->
    if err
      console.log "shit"
    else
      console.log "found it"
      req.data1 = row.data
      next()

getGrid = (req, res) ->
  console.log "looking up"
  tileset = req.params.tileset
  x = req.params.x
  z = req.params.z
  y = Math.pow(2, z) - 1 - req.params.y
  format = req.params.format
  console.log "opening " + tileset + ".mbtiles"
  db = new sqlite3.Database "tiles/" + tileset + ".mbtiles"
  console.log "grabbing it"
  db.get "SELECT grid AS data FROM grids WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?", z, x, y, (err, row) ->
    if err
      console.log "shit"
    else
      console.log "got it"
      res.send row.data,
        "Content-Type": "application/json"
      , 200    
exports.getGrid = getGrid
exports.blendTile = blendTile
###
exports.getTile = getTile
