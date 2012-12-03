config = require './config.json'
sources = require './sources.json'

exports.getTile = (opt,res)->
    layer = config.layers[opt.layer]
    switch layer.type
        when "mbtiles"
            mbtiles = require sources.mbtiles
            mbtiles.get opt, layer.file, res
    