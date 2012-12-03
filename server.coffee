express = require 'express'
kublai = express()
kublai.use express.compress()
kublai.use express.bodyParser()
kublai.use express.logger('dev') 
kublai.use express.static(__dirname + '/public')
kublai.use express.favicon(__dirname + '/favicon.ico')
kublai.get '/', (req, res)->
    res.jsonp hello: "there"
int = require './internals.coffee'
int.run(kublai)