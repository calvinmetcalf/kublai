kublai is now a sligtly less trivial tileserver, as it can serve files in tms but take requests in xyz

usage

	git clone git://github.com/calvinmetcalf/kublai.git
	cd kublai
	npm install
	node server.js
or
	coffee server.coffee

point your browser to the [included example](http://localhost:7027/gc/6/18/23.png)

url usage is /{scheme, tms or xyz or none for xyz}/{folder with tiles, should be in the tiles folder, at the moment, assumes you used mbutil to export, and filename and mapname must match)/z/x/y.png/jpg/jpeg
