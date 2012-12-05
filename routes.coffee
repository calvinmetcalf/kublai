mbtiles = require 'mbtiles'
tilelive = require 'tilelive'
mbtiles.registerProtocols tilelive
config = require './config.json'
proxy = require './proxy'

Tiles = (loc)->
	tilelive.list "./tiles", (e,list)=>
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
		y = parseInt opts.y
		z = parseInt opts.zoom
		x = parseInt opts.x
		#y = (1 << z) - 1 - y
		if opts.format == "grid.json"
			layer.getGrid z,x,y,(err, grid)->
				res.jsonp grid

		else
			layer.getTile z,x,y,(err, tile)->
					switch opts.format
						when "png" then res.set 'Content-Type', "image/png"
					res.send tile
	else if opts.layer of config.layers
		layer = config.layers[opts.layer]
		y = parseInt opts.y
		z = parseInt opts.zoom
		x = parseInt opts.x
		switch layer.type
			when "proxy"
				proxyLayer = proxy.open layer.options
				proxyLayer.getTile z,x,y,(err, tile)->
					if err
						res.json err
					else
						switch opts.format
							when "png" then res.set 'Content-Type', "image/png"
						res.send tile
				
Tiles::getTileJson = (opts, res) ->
	if opts.layer of @layers
		layer = @layers[opts.layer]
		layer.getInfo (err,data)->
			data.scheme = "xyz"
			data.tiles = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.png"]
			data.grids = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.grid.json"]
			data.version = "1.0.0"
			switch opts.format
				when "jsonp" then res.jsonp data
				when "json" then res.json data
	else if opts.layer of config.layers
		layer = config.layers[opts.layer]
		switch layer.type
			when "proxy"
				data = layer.info
				data.scheme = "xyz"
				data.tiles = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.png"]
				data.tilejson = "2.0.0"
				if "grid" of layer.options
					data.grids = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.grid.json"]
				switch opts.format
					when "jsonp" then res.jsonp data
					when "json" then res.json data