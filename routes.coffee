config = require './config.json'
sources = require './sources.json'
cache = require('./cache').open("nstoreCach.db")
fs = require 'fs'
blank = fs.readFileSync './blank.png'

layers = {}

for key of config.layers
	layerType = config.layers[key].type
	layers[key] = require(sources[layerType]).open(config.layers[key].options)

respond = (tile, opt, res, c)->
	switch opt.format
		when "png" then res.set 'Content-Type', "image/png"
	cache.set opt, tile if c
	res.send tile

exports.getTile = (opt, res)->
	cb = (err, tile)->
		if err
			console.log "not cached"
			fetchTile opt, res
		else if tile
			console.log "fetched"
			respond tile, opt, res
	cache.get opt, cb

fetchTile = (opt,res)->
	layer = config.layers[opt.layer]
	console.log "getting tile"
	cb = (err, tile)->
		if err
			respond blank, opt, res, true
		else if tile
			console.log "got tile"
			respond tile, opt, res, true
	layers[opt.layer].get opt, cb
