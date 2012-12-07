im = require 'imagemagick'

exports.toPNG = (jpg,cb)->
	#console.log "to png"
	opts =
		srcData : jpg
		format : "png"
		srcFormat : "jpg"
		width : 256
	im.resize opts,(err, stdout)->
		if err
			#console.log "oh shit"
			cb err
		else
			#console.log "all good"
			cb null, new Buffer stdout, "binary"