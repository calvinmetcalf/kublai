request = require 'request'
im = require('gm').subClass({ imageMagick: true })

Proxy = (options)->
	@url = options.tile
	if "subdomains" of options
		@subdomains=options.subdomains
	@

exports.open = (url) ->
	new Proxy url

template = (str, data) ->
	str.replace /\{ *([\w_]+) *\}/g, (str, key) ->
		value = data[key]
		throw new Error("No value provided for variable " + str)	unless data.hasOwnProperty(key)
		value

toPNG = (jpg,cb)->
	im(jpg).stream 'png', (err,stdout,stder)->
		data = []
		if err
			cb err
			return
		stdout.on 'data', (d)->
			data.push d
		stdout.on 'end', ()->
			cb null, Buffer.concat data
to8 = (png,cb)->
	im(png).bitdepth(8).stream 'png', (err,stdout,stder)->
		data = []
		if err
			cb err
			return
		stdout.on 'data', (d)->
			data.push d
		stdout.on 'end', ()->
			cb null, Buffer.concat data

Proxy::getTile = (z,x,y, cb) ->
	opts = {z:z, x:x, y:y}
	opts.s= @subdomains[Math.floor(Math.random() * @subdomains.length)] if "subdomains" of @
	url = template @url, opts
	request url, {encoding:null}, (e,r,b)->
		if e
			cb e
		else if parseInt(r.statusCode) == 404
			cb "not found"
		else
			#console.log r.headers["content-type"]
			if r.headers["content-type"] == "image/jpeg"
				#console.log "converting"
				toPNG b, cb
			else
				im(b).depth (err, value)->
					#console.log value
					unless value == 16
						cb undefined, b
					else
						to8 b, cb