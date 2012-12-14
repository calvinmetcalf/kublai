The basic idea is [TileStache](http://tilestache.org/) but in nodejs, and minimizing the number of of external packages so it actually will run on cloud providers.

I was going to go with a name in the style of tilecache and tilestash, something like tilebank or tilehoard, but then screw it, I named it after my cat. 

it works and so far has 2 types of layers, "proxy" which just proxies another tile layer, converting it to png if its a jpeg, and "blend" which composits 2 layers. Curently the only cache is Couchdb. If you uncomment the two lines at the top of "routes.coffee" and have [node-mbtiles](https://github.com/mapbox/node-mbtiles) installed then any mbtiles in the tiles folder are automatically layers, but [node-sqlite3](https://github.com/developmentseed/node-sqlite3) doesn't build on openshift, so it's not included by default.

example config file is there, if you want to add a new provider it needs to export an open method that takes the options in the config file, and that should return an object that has a getTile method. which accepts 4 arguments, zoom, x, y, and callback, callback returns err, tile, etag. it should be in the providers folder with the same name as the layer you refer to it in config.

cache is the same except instead of getTile it has get and put methods, get takes layer, z, x, y, callback(err,tile,etag), and put takes layer,z,x,y,tile

tiles are all passed around as buffers. 

next up will probobly be some sort of in memory cache

[Test version on openshift](http://kublai-cwm.rhcloud.com/stamenRoads/preview), (link at the top is to my cat's blog).