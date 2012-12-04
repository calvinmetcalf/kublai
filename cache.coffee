
Cache = (file)->
	@nstore = require('nstore').new(file)
	@

exports.open = (file)->
	new Cache file 

getKey = (opt) ->
	opt.layer+"/"+opt.zoom+"/"+opt.x+"/"+opt.y+"."+opt.format
	
Cache::get = (opt, cb) ->
	key = getKey opt
	console.log "getting " + key
	@nstore.get key, (err,doc)->
		if err
			cb err
		else
			cb null, new Buffer doc.tile
	
Cache::set = (opt, value)->
	key = getKey opt
	console.log "setting " + key
	@nstore.save key, {tile:value}, (e)->
		if e
			console.log e