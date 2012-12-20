fs = require 'fs'

exports.open = (config)->
	list = fs.readdirSync "./lib/providers"
	list.forEach (v)->
		unless v == "index.coffee"
			name = v.split('.')[0]
			exports[name] = require "./#{name}"
			true