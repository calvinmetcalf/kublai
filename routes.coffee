#mbtiles = require 'mbtiles'
tilelive = require 'tilelive'
#mbtiles.registerProtocols tilelive
config = ""
providers = require "./providers"
crypto = require 'crypto'

Tiles = (loc, c)->
	config = c
	providers.open config
	sources = {}
	tilelive.list "./tiles", (e,list)=>
		unless e
			keys = Object.keys list
			keys.forEach (key)->
				tilelive.load list[key], (err, tileSource)->
					sources[key] = tileSource unless err
		for key of config.layers
			sources[key] = providers[config.layers[key].type].open config.layers[key].options, @
		@layers = sources
	@

exports.open = (loc,c)->
	new Tiles loc,c
	
getDomains = (layer, suffix)->
	domains = config.domains
	len = domains.length
	out = []
	i = 0
	while i<len
		out.push "#{domains[i]}/#{layer}/{z}/{x}/{y}.#{suffix}"
		i++
	out	
	

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
					md5 = crypto.createHash 'md5'
					md5.update tile
					callback null, tile, { 'Content-Type': "image/png",'etag':'"'+md5.digest("base64")+'"'}
				if err
					callback err
				
Tiles::getTileJson = (opts, callback) ->
	console.log "getting tile json"
	if opts.layer of config.layers
		layer = config.layers[opts.layer]
		data = layer.info
		data.scheme = "xyz"
		data.tiles = getDomains(opts.layer, "png")
		data.tilejson = "2.0.0"
		if "grid" of layer.options
			data.grids = getDomains(layer.options.grid,"grid.json")
		callback null, data
	else
		layer = @layers[opts.layer]
		layer.getInfo (err,data)->
			data.scheme = "xyz"
			data.tiles = getDomains(opts.layer, "png")
			data.grids = getDomains(opts.layer, "grid.json")
			data.version = "1.0.0"
			callback null, data