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


Cache = (url)->
	if url.slice(-1) != "/"
		url = url + "/"
	@url = url
	@


exports.cache = (opts)->
	new Cache opts.db

Cache::get = (params..., cb)->
	if params.length == 4
		[layer, z, x, y] = params
	else
		cb "wrong number of args"
		return
	key = "#{ layer }-#{ quad(z,x,y) }"
	request @url + key + "/tile.png",{encoding:null}, (e,r,b)=>
		if e or r.statusCode == 404
			cb "nope"
			return
		else
			cb null, b, {"etag":r.headers.etag,'content-type':r.headers['content-type'],'content-length':r.headers['content-length']}
			request @url + key, (e2,r2,b2)=>
				if b2.id == key
					b2.accessed = (new Date()).getTime()
				request @url +  key, {json : b2, method : "put"}

Cache::put = (params..., tile)->
	if params.length == 4
		[layer, z, x, y] = params
	else
		console.log "wrong number of args"
		return
	key = "#{ layer }-#{ quad(z,x,y) }"
	if Buffer.isBuffer tile
		doc = {_id : key, created : (new Date()).getTime(), accessed :(new Date()).getTime(), _attachments:{"tile.png":{"content_type":"image\/png", data : tile.toString("base64")}}}
		request @url + doc._id, {method : "PUT", json : doc}, (e1,r1,b1)=>
			if b1.error == "conflict"
				request @url + doc._id,{json:true}, (e2,r2,b2)=>
					if b2.id == key
						doc._rev = b2.rev
						request @url + doc._id, {method : "PUT", json : doc}