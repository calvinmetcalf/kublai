Pretender = ()->
	@

exports.cache = ()->
	new Pretender
	
Pretender::get = (params..., cb)->
	cb "this isn't a real cache"
	
Pretender::put = ()->
	true