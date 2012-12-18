request = require "request"

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


Cache = (urls)->
	@urls = urls.map (url)->
		if process.env[url].slice(-1) != "/"
		#if url.slice(-1) != "/"
			url = process.env[url] + "/"
			#url = url + "/"
		else
			url = process.env[url]
	@


exports.cache = (opts)->
	new Cache opts.db

Cache::url = ()->
	len = @urls.length
	@urls[Math.floor(Math.random()*len)]

Cache::get = (o, cb)->
	url = @url()
	#console.log "getting from #{url}"
	[layer, z, x, y, format] = [o.layer,o.zoom, o.x,o.y,o.format]
	key = "#{ layer }-#{ quad(z,x,y) }"
	if format == "grid.json"
		finalUrl = url + key
	else
		finalUrl = url + key + "?attachments=true"
	request finalUrl,{json:true}, (e,r,b)=>
		if e 
			cb e
			return
		else if r.statusCode == 404
			cb "no such tile"
			return
		else if format == "png" and b._attachments
			cb null, new Buffer(b._attachments["tile.png"].data, "base64"), {"etag":b._attachments["tile.png"].digest.slice(4),'content-type':b._attachments["tile.png"].content_type}
			b.accessed = (new Date()).getTime()
			console.log "updating cache"
			#console.log b
			request url +  key, {json : b, method : "put"}
		else if format == "grid.json" and b.grid
			cb null, b.grid
			b.accessed = (new Date()).getTime()
			#console.log "updating cache"
			#console.log b
			request url +  key, {json : b, method : "put"}
		else
			cb "really no"
			#console.log "format: " + format + "and attachment: " + JSON.stringify b._attachments
Cache::put = (o, tile)->
	url = @url()
	#console.log "putting into #{url}"
	[layer, z, x, y,] = [o.layer,o.zoom, o.x,o.y]
	key = "#{ layer }-#{ quad(z,x,y) }"
	if Buffer.isBuffer tile
		doc = {_id : key, created : (new Date()).getTime(), accessed :(new Date()).getTime(), _attachments:{"tile.png":{"content_type":"image\/png", data : tile.toString("base64")}}}
		request url + doc._id, {method : "PUT", json : doc}, (e1,r1,b1)=>
			if b1.error == "conflict"
				request url + doc._id,{json:true}, (e2,r2,b2)=>
						b2._attachments = doc._attachments
						request url + doc._id, {method : "PUT", json : b2}
	else
		doc = {_id : key, created : (new Date()).getTime(), accessed :(new Date()).getTime(), grid : tile}
		request url + doc._id, {method : "PUT", json : doc}, (e1,r1,b1)=>
			if b1.error == "conflict"
				request url + doc._id,{json:true}, (e2,r2,b2)=>
						b2.grid = doc.grid
						request url + doc._id, {method : "PUT", json : b2}