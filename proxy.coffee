request = require 'request'

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

Proxy::getTile = (z,x,y, cb) ->
	opts = {z:z, x:x, y:y}
	opts.s= @subdomains[Math.floor(Math.random() * @subdomains.length)] if "subdomains" of @
	url = template @url, opts
	request url, {encoding:null}, (e,r,b)->
		if e
			cb e
		else
			cb undefined, b