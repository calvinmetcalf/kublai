Image = require 'image'
pngparse = require 'pngparse'
async = require 'async'
im = require 'imagemagick'    
    
parsePng = (buff, cb)->    
	im.readMetadata buff.toString(), (e,m)->
		console.log m
	pngparse.parse buff, (err, data) ->
		if err
			cb err
			console.log err
		else
			cb null, data.data
 
composit = (a,b,cb)->
	if a and not b
		cb null, a
		return
	else if not a and b
		cb null, b
		return
	else if not a and not b
		cb(true)
		return
	async.map [a,b], parsePng, (err, tiles)->
		if tiles.length == 0
			cb true
			return
		else if tiles.length == 1
			cb null, a
			return
		base = tiles[0]
		top = tiles[1]
		console.log "starting compositing"
		i = 0
		len = base.length
		while i < len
			j = i+((4 - ((i+1) % 4)) %4)
			if (j - i ) == 3
				top[j] = 0xff - top[j]
				base[j] = 0xff - base[j]
			b = base[i]
			t = top[i]
			c = (255-top[j]) / 255
			base[i]= b + c * (t - b)
			i++
		cb null, new Image('png', "rgba").encodeSync(base, 256, 256)

cbo = 
	set:()->undefined
	json:()->@send(undefined)
	jsonp:()->undefined
	
Blender = (opt, routes, o)->
	@base = opt.layers[0]
	@overlay = opt.layers[1]
	@routes = routes
	@opts = o
	@

exports.open = (opt, routes, o) ->
	new Blender opt, routes, o
	
Blender::getTile = (z,x,y, cb) ->
	#console.log "getting"
	@opts.layer = @base
	@routes.getTile @opts, (err, base)=>
		#console.log "getting base"
		@opts.layer = @overlay
		@routes.getTile @opts, (err, overlay)=>
			composit base, overlay, cb
		
