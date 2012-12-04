request = require 'request'

Proxy = (url)->
	@url = url
	@

exports.open = (opt)->
	new Proxy opt.url

template = (str, data) ->
	str.replace /\{ *([\w_]+) *\}/g, (str, key) ->
		value = data[key]
		throw new Error("No value provided for variable " + str)	unless data.hasOwnProperty(key)
		value

Proxy::get = (opt, options, cb) ->
	url = template options.url, {z:opt.zoom, x:opt.x, y:opt.y}
	request url, {encoding:null}, (e,r,b)->
		if e
			cb e
		else
			cb undefined, b
	