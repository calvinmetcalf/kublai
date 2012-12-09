Image = require 'image'
pngparse = require 'pngparse'
async = require 'async'
im = require 'imagemagick'    


parsePng = (buff, cb)->    
	pngparse.parse buff, (err, data) ->
		if err
			cb err
		else
			cb null, data.data
 
composit = (buffs,cb)->
	if buffs.length == 1
		cb null, buffs[0]
		return
	else if buffs.length == 0
		cb(true)
		return
	async.map buffs, parsePng, (err, tiles)->
		if tiles.length == 0
			cb true
			return
		else if tiles.length == 1
			cb null, a
			return
		base = tiles[0]
		top = tiles[1]
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
	
Blender = (opt, routes)->
	@layers = opt.layers
	@routes = routes
	@

exports.open = (opt, routes) ->
	new Blender opt, routes
	
Blender::getTile = (z,x,y, cb) ->
	#console.log "getting"
	opts={}
	opts.zoom = z
	opts.y = y
	opts.x = x
	opts.format = "png"
	mapFunc = (l, clb)=>
		opts.layer = l
		@routes.getTile opts, clb
	filterFunc = (a,c)->
		c !!a
	async.map @layers, mapFunc, (err, tilesRaw)->
		async.filter tilesRaw, filterFunc, (tiles)->
			composit tiles, cb
		
