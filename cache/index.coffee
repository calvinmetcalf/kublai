Cache = (config)->
	if config.cache
		cache = require "./#{config.cache.type}"
		cache.cache config.cache.options

exports.open = Cache