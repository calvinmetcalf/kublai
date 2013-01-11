im = require('gm').subClass({ imageMagick: true })

convert = (jpg, cb)->
	im(jpg).stream 'png', (err,stdout,stder)->
		data = []
		stdout.on 'data', (d)->
			data.push d
		stdout.on 'end', ()->
			cb null, Buffer.concat data
			