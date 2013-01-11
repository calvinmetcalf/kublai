exports.open = (io, routes)->
	io.sockets.on 'connection', (socket) ->
		socket.emit("hello",{hello:"there"})
		socket.on 'getTile', (opts) ->
			console.log "getting tile"
			routes.getTile opts, (err, tile, head)->
				if (not err) and head
					socket.emit(JSON.stringify(opts), {tile:tile.toString("base64"), opts:opts})
  