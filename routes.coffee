#mbtiles = require 'mbtiles'
tilelive = require 'tilelive'
#mbtiles.registerProtocols tilelive
config = require './config.json'
proxy = require './providers/proxy'
blend = require './providers/blend'

Tiles = (loc)->
	sources = {}
	tilelive.list "./tiles", (e,list)=>
		unless e
			keys = Object.keys list
			keys.forEach (key)->
				tilelive.load list[key], (err, tileSource)->
					sources[key] = tileSource unless err
		for key of config.layers
			switch config.layers[key].type
				when "proxy"
					sources[key] = proxy.open config.layers[key].options
				when "blend"
					sources[key] = blend.open config.layers[key].options, @
		@layers = sources
	@

exports.open = (loc)->
	new Tiles loc
	

Tiles::getTile = (opts, callback)->
	if opts.layer of @layers
		layer = @layers[opts.layer]
		y = parseInt opts.y
		z = parseInt opts.zoom
		x = parseInt opts.x
		#y = (1 << z) - 1 - y
		if opts.format == "grid.json"
			layer.getGrid z,x,y,(err, grid)->
				callback(err) if err
				callback(null, grid) unless err

		else
			layer.getTile z,x,y,(err, tile)->
				unless err
					callback null, tile
				if err
					callback err
				
Tiles::getTileJson = (opts, callback) ->
	if opts.layer of config.layers
		layer = config.layers[opts.layer]
		data = layer.info
		data.scheme = "xyz"
		data.tiles = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.png"]
		data.tilejson = "2.0.0"
		if "grid" of layer.options
			data.grids = [opts.protocol+"://"+opts.host+"/"+layer.options.grid+"/{z}/{x}/{y}.grid.json"]
		callback null, data
	else
		layer = @layers[opts.layer]
		layer.getInfo (err,data)->
			data.scheme = "xyz"
			data.tiles = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.png"]
			data.grids = [opts.protocol+"://"+opts.host+"/"+opts.layer+"/{z}/{x}/{y}.grid.json"]
			data.version = "1.0.0"
			callback null, data