express = require 'express'
config = require '../config.json'
#io = require 'socket.io'
routes = require('./routes').open("../tiles", config)
fs = require 'fs'
cache = require("./cache").open(config)
preview = fs.readFileSync './lib/preview.html', 'utf8'
#wsocket = fs.readFileSync './lib/io.html', 'utf8'
f0f = fs.readFileSync './lib/404.jpg'
kublai = express()
#http = require('http')
#server = http.createServer(kublai)
#io = io.listen server
#server.listen 8000
#socks = require "./io"
#socks.open io, routes
kublai.use express.compress()
kublai.use express.favicon(__dirname + config.favicon)
kublai.use express.bodyParser()
kublai.use express.logger('dev') 
kublai.use express.static('./public')

kublai.get '/', (req, res)->
	res.jsonp hello: "there"
kublai.get '/stats', (req, res)->
	numCPUs = require('os').cpus().length
	res.jsonp num : numCPUs#, redis : process.env.VCAP_SERVICES
kublai.get '/:layer/:z/:x/:y.:format(png|grid.json)', (req, res) ->
	#console.log "getting #{ req.path }"
	opts =
		layer: req.params.layer
		zoom: req.params.z
		x: req.params.x
		y: req.params.y
		format: req.params.format
	#console.log req.get "Host"
	cache.get opts, (e,t,h)->
		#console.log "checking cache of " + JSON.stringify opts
		if e
			#console.log "nope getting tile " + JSON.stringify opts
			routes.getTile opts, (err, tile, head)->
				if err or !tile
					res.json 404, err
				else
					if opts.format == "grid.json"
						res.jsonp tile
						cache.put opts, tile
					else
						res.set head
						res.send tile
						cache.put opts, tile
		else
			#console.log "in cache " + JSON.stringify opts
			if h 
				res.set h
				res.send t
			else
				res.jsonp t
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
			res.status(404).sendfile('./lib/404.jpg')
			return
		switch req.params.format
				when "jsonp" then res.jsonp tileJson
				when "json" then res.json tileJson
kublai.get '/:layer/preview', (req, res)->
	res.send preview
#kublai.get '/:layer/io', (req, res)->
#    res.send wsocket
kublai.get '*', (req, res)->
	res.status(404).sendfile('./lib/404.jpg')
int = require './internals.coffee'
int.run(kublai)