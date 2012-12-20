#redis = require("./redis").cache()

Cache = (config)->
	if config.cache
		cache = require "./#{config.cache.type}"
		cache.cache config.cache.options, config

exports.open = Cache
###
Cache::get = (o, cb)->
	redis.get o, (err, tile, header)=>
		if err
			@cache.get o, (err2, tile2, header2)=>
				if err2
					cb "no"
				else if tile2
					redis.set o, tile2
					cb(null, tile2, header2) if header2
					cb(null, tile2) unless header2
		else if tile
			cb(null, tile, header) if header
			cb(null, tile) unless header
			
Cache::put = (o, tile)->
	redis.put(o,tile)
	@cache.put(o.tile)
	###