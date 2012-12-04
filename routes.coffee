config = require './config.json'
sources = require './sources.json'

exports.getTile = (opt,res)->
	layer = config.layers[opt.layer]
	cb = (err, tile)->
		if err
			res.send 404
		else if tile
			switch opt.format
				when "png" then res.set 'Content-Type', "image/png"
			res.send tile
	switch layer.type
		when "mbtiles"
			mbtiles = require sources.mbtiles
			mbtiles.get opt, layer.file, cb
    
