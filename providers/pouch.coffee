pouch = require "pouchdb"

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


Cache = (type,name)->
	db = undefined
	pouch "http://calvin.iriscouch.com:80/kublai", (err, d)=>
		if err
			console.log err
			return
		db = d
		@db = db
	@

number =
	map : (doc)->
		if doc._id and doc.time
			emit null, {time:doc.time, id:doc._id}
	reduce :(keys, values)->
		values.reduce (a,b)->
			if a.time >= b.time
				b
			else
				a

tot = 
	map : (doc)->
		if doc._id and doc.tile
			emit 1, 1
	reduce:(keys, values, rereduce) ->
		values.length

Cache::check = ()->
	@db.query "tile/tot", {reduce:true}, (err, resp)=>
		console.log JSON.stringify resp
		if not err and resp.rows.length > 0
			count = resp.rows[0].value
			console.log count
			if count > 200
				@db.query "tile/number", {reduce:true}, (ee,rr)=>
					unless ee
						if rr.rows.length > 0
							id = rr.rows[0].value.id
							console.log id
							@db.get id, (err, doc)=>
								unless err
									@db.remove doc, ()-> true
			


exports.cache = (name)->
	new Cache "ldb", name

Cache::get = (params..., cb)->
	if params.length == 4
		[layer, z, x, y] = params
	else
		cb "wrong number of args"
		return
	key = "#{ layer }-#{ quad(z,x,y) }"
	@db.get key, (err, doc)=>
		if err or not('tile' of doc)
			cb err
		else if 'tile' of doc
			cb null, new Buffer(doc.tile,"base64")
			doc.time = (new Date()).getTime()
			@db.put doc, ()->true
			
Cache::put = (params..., tile)->
	if params.length == 4
		[layer, z, x, y] = params
	else
		console.log "wrong number of args"
		return
	key = "#{ layer }-#{ quad(z,x,y) }"
	if Buffer.isBuffer tile
		doc = {_id : key, tile : tile.toString("base64"), time : (new Date()).getTime()}
		@db.put doc, (err, resp)=>
			if err
				@db.get key, (e,r)=>
					if !e
						doc._rev = r._rev
						@db.put doc, (e2, r2)=>
							if e2
								console.log "couldn't put #{key} in"
							else
								"put it again"
								@check()
					else
						console.log "couldn't put #{key} in"
			else
				console.log "put it"
				@check()