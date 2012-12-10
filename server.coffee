express = require 'express'
config = require './config.json'
routes = require('./routes').open("./tiles")
fs = require 'fs'
pouch = require './providers/pouch'
cache = pouch.cache "cache.db"
preview = fs.readFileSync './preview.html', 'utf8'
kublai = express()
kublai.use express.compress()
kublai.use express.favicon(__dirname + config.favicon)
kublai.use express.bodyParser()
kublai.use express.logger('dev') 
kublai.use express.static(__dirname + '/public')

kublai.get '/', (req, res)->
	res.jsonp hello: "there"
#kublai.get '/test/:z/:x/:y.png', (req,res)->
#    cb = (e,d)->
#        res.set 'Content-Type', "image/png"
#        res.send d
#    getRoad.getRoad req.params.z,req.params.x,req.params.y,cb
kublai.get '/:layer/:z/:x/:y.:format(png|jpg|jpeg|grid.json)', (req, res) ->
	console.log "getting #{ req.path }"
	opts =
		layer: req.params.layer
		zoom: req.params.z
		x: req.params.x
		y: req.params.y
		format: req.params.format
	#console.log req.get "Host"
	cache.get opts.layer, opts.zoom, opts.x, opts.y, (e,t)->
		console.log "checking cache"
		if e
			console.log "not in cache"
			routes.getTile opts, (err, tile)->
				if err
					res.json 404, err
				else
					if opts.format == "grid.json"
						res.jsonp tile
					else
						res.set 'Content-Type', "image/png"
						res.send tile
						cache.put opts.layer, opts.zoom, opts.x, opts.y, tile
		else unless e
			console.log "in cache"
			res.set 'Content-Type', "image/png"
			res.send t
kublai.get '/:layer.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, (err, tileJson)->
		switch req.params.format
				when "jsonp" then res.jsonp tileJson
				when "json" then res.json tileJson
kublai.get '/:layer/tile.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, (err, tileJson)->
		switch req.params.format
				when "jsonp" then res.jsonp tileJson
				when "json" then res.json tileJson
kublai.get '/:layer/preview', (req, res)->
	res.send preview
int = require './internals.coffee'
int.run(kublai)