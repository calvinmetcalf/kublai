Image = require 'image'
pngparse = require 'pngparse'
async = require 'async'
    
parsePng = (buff, cb)->    
    pngparse.parse buff, (err, data) ->
        i = 0
        len = data.data.length
        while i < len
            data.data[i] = 0xff - data.data[i] if i%4 == 3
            i++
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
		base = tiles[0]
		top = tiles[1]
		console.log "starting compositing"
		i = 0
		len = base.length
		while i < len
			j = i+((4 - ((i+1) % 4)) %4)
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
		
