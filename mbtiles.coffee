config = require './config.json'
sqlite3 = require 'sqlite3'

parseMeta = (array)->
    out = {}
    array.forEach (v)->
        out[v.name] = v.value
    out

exports.get = (opt, file, res) ->
    db = new sqlite3.cached.Database file, sqlite3.OPEN_READONLY
    y = parseInt opt.y
    z = parseInt opt.zoom
    x = parseInt opt.x
    db.all "SELECT * from metadata;", (err, results)->
        result = parseMeta results
        if parseFloat(result.version)<2
            y = (1 << z) - 1 - y
        if result.minzoom < z < result.maxzoom
            db.get 'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',z, x, y, (err2, tile)->
                if err2 
                    res.send 404
                unless tile
                    res.send 404
                else
                    tileData = tile.tile_data
                    switch opt.format
                        when "png" then res.set 'Content-Type', "image/png"
                    res.send tileData