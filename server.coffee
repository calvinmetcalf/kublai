express = require 'express'
config = require './config.json'
routes = require('./routes').open("./tiles")
fs = require 'fs'
preview = fs.readFileSync './preview.html', 'utf8'
kublai = express()
kublai.use express.compress()
kublai.use express.favicon(__dirname + config.favicon)
kublai.use express.bodyParser()
kublai.use express.logger('dev') 
kublai.use express.static(__dirname + '/public')

kublai.get '/', (req, res)->
    res.jsonp hello: "there"
kublai.get '/:layer/:z/:x/:y.:format(png|jpg|jpeg|grid.json)', (req, res) ->
    opts =
        layer: req.params.layer
        zoom: req.params.z
        x: req.params.x
        y: req.params.y
        format: req.params.format
    routes.getTile opts, res
kublai.get '/:layer.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, res
kublai.get '/:layer/tile.:format', (req, res) ->
	routes.getTileJson {layer:req.params.layer,format:req.params.format, host:req.host,protocol : req.protocol}, res
kublai.get '/:layer/preview', (req, res)->
    res.send preview
int = require './internals.coffee'
int.run(kublai)