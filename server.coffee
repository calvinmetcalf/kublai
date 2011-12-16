require('zappa') 'localhost', 7027, ->
	@use static: __dirname + '/tiles'
