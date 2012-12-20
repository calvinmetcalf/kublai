redis = require "redis"
crypto = require 'crypto'

quad = (z,x,y) ->
	bX = parseInt(x,10).toString(2)
	bY = parseInt(y,10).toString(2)
	z = parseInt z
	while bX.length < z
		bX = '0'+bX
	while bY.length < z
		bY = '0'+bY
	i = 0;
	tab={"0":{"0":"a","1":"b"},"1":{"0":"c","1":"d"}}
	r =[]
	while i < z
		r.push(tab[bX[i]][bY[i]])
		i++
	if z > 0
		return r.join ''
	else
		return "z"

Cache = ()->
	vcap = JSON.parse process.env.VCAP_SERVICES
	creds = vcap["redis-2.2"][0].credentials
	@client = redis.createClient creds.port,creds.host, {detect_buffers : true}
	@client.auth creds.password
	@

exports.cache = ()->
	new Cache
	
Cache::get = (o, cb)->
	[layer, z, x, y, format] = [o.layer,o.zoom, o.x,o.y,o.format]
	key = "#{ layer }-#{ quad(z,x,y) }.#{ o.format }"
	@client.get key, (e,d)->
		if e
			cb e
		else if Buffer.isBuffer d
			md5 = crypto.createHash 'md5'
			md5.update d
			cb null, d, { 'Content-Type': "image/png",'etag':'"'+md5.digest("base64")+'"'}
		else
			cb null, JSON.parse d

Cache::put = (o, tile)->
	[layer, z, x, y,format] = [o.layer,o.zoom, o.x,o.y,o.format]
	key = "#{ layer }-#{ quad(z,x,y) }.#{ o.format }"
	if Buffer.isBuffer tile
		@client.set key, tile
	else
		@client.set key, JSON.stringify tile
		
exports.test = (cb)->
	@client["config get"]("maxmemory", cb)