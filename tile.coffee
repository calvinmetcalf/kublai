mbtiles = require 'mbtiles'
tilelive = require 'tilelive'
mbtiles.registerProtocols tilelive

Tiles = (loc)->
	tilelive.list "./tiles", (e,list)->
		unless e
			keys = Object.keys list
			sources = {}
			keys.forEach (key)->
				tilelive.load list[key], (err, tileSource)->
					sources[key] = tileSource unless err
			@layers = sources
	@

exports.open = (loc)->
	new Tiles loc
	
Tiles::getTile = (opts, res)->
	if opts.layer of @layers
		layer = @layers[opts.layer]
		y = parseInt opt.y
		z = parseInt opt.zoom
		x = parseInt opt.x
		y = (1 << z) - 1 - y
		layer.getTile z,x,y,(err, tile)->
				switch opt.format
					when "png" then res.set 'Content-Type', "image/png"
				res.send tile