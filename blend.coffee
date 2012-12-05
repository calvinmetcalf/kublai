gm = require 'gm'

cbo = 
	set:()->undefined
	json:()->undefined
	jsonp:()->undefined
	
Blender = (opt, routes, o)->
	@base = opt.layers[0]
	@overlay = opt.layers[1]
	@routes = routes
	@opts = o
	@

exports.open = (opt, routes, o) ->
	new Blender opt, routes, o
	
	
Blender::getTile = (z,x,y, res) ->
	console.log "getting"
	@opts.layer = @base
	cbo.send = (base)=>
		console.log "getting base"
		@opts.layer = @overlay
		cbo.send = (overlay)->
			console.log "getting overlay"
			gm(base, y+".png").append(overlay, y+".png").stream y+".png", (err, stdout, stderr)->
				stdout.pipe res
		@routes.getTile @opts, cbo
	@routes.getTile @opts, cbo
		