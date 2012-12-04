config = require './config.json'
sqlite3 = require 'sqlite3'

parseMeta = (array)->
	out = {}
	array.forEach (v)->
		out[v.name] = v.value
	out

exports.get = (opt, file, cb) ->
	db = new sqlite3.cached.Database file, sqlite3.OPEN_READONLY
	y = parseInt opt.y
	z = parseInt opt.zoom
	x = parseInt opt.x
	db.all "SELECT * from metadata;", (err, results)->
		if err
			cb err
		else	
			result = parseMeta results
			if parseFloat(result.version)<2
				y = (1 << z) - 1 - y
			if result.minzoom < z < result.maxzoom
				db.get 'SELECT tile_data FROM tiles WHERE zoom_level = ? AND tile_column = ? AND tile_row = ?',z, x, y, (err2, tile)->
					if err2 
						cb err2
					if !tile or !("tile_data" of tile)
						cb true
					else
						cb null, tile.tile_data
