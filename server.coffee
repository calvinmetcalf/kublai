express = require 'express'
config = require './config.json'
routes = require('./routes').open("./tiles", config)
fs = require 'fs'
cache = require("./cache").open(config)
preview = fs.readFileSync './preview.html', 'utf8'
kublai = express()
kublai.use express.compress()
kublai.use express.favicon(__dirname + config.favicon)
kublai.use express.bodyParser()
#kublai.use express.logger('dev') 
kublai.use express.static(__dirname + '/public')

kublai.get '/', (req, res)->
	res.jsonp hello: "there"
kublai.get '/stats', (req, res)->
	numCPUs = require('os').cpus().length
	res.jsonp num : numCPUs
kublai.get '/:layer/:z/:x/:y.:format(png|jpg|jpeg|grid.json)', (req, res) ->
	#console.log "getting #{ req.path }"
	opts =
		layer: req.params.layer
		zoom: req.params.z
		x: req.params.x
		y: req.params.y
		format: req.params.format
	#console.log req.get "Host"
	cache.get opts.layer, opts.zoom, opts.x, opts.y, (e,t,h)->
		#console.log "checking cache"
		if e or !Buffer.isBuffer(t)
			#console.log "not in cache"
			routes.getTile opts, (err, tile, head)->
				if err
					res.json 404, err
				else
					if opts.format == "grid.json"
						res.jsonp tile
					else
						res.set head
						res.send tile
						cache.put opts.layer, opts.zoom, opts.x, opts.y, tile
		else
			#console.log "in cache"
			if h 
				res.set h
				res.send t
kublai.get '/:layer.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, (err, tileJson)->
		if err
			res.send 404
			return
		switch req.params.format
				when "jsonp" then res.jsonp tileJson
				when "json" then res.json tileJson
kublai.get '/:layer/tile.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, (err, tileJson)->
		if err
			res.send 404
			return
		switch req.params.format
				when "jsonp" then res.jsonp tileJson
				when "json" then res.json tileJson
kublai.get '/:layer/preview', (req, res)->
	res.send preview
int = require './internals.coffee'
int.run(kublai)