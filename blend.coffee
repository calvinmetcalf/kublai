gm = require 'gm'
routes = require('./routes').open("./tiles")

cbo = 
	set:()->undefined
	json:()->undefined
	jsonp:()->undefined
	
Blender = (opt)->
	@base = opt.layers[0]
	@overlay = opt.layers[1]
	

exports.open = (opt) ->
	new Blender opt
	
	
Blender::getTile = (z,x,y, cb) ->
	opts.layer = @base
	cbo.send = (base)->
		console.log "getting base"
		opts.layer = @overlay
		cbo.send = (overlay)->
			console.log "getting overlay"
			gm(base, y+".png").append(overlay, y+".png").stream y+".png", (err, stdout, stderr)->
				unless err
					cb null, gm.utils.buffer stout
		routes.getTile opts, cbo
	routes.getTile opts, cbo
		