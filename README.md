The basic idea is [TileStache](http://tilestache.org/) but in nodejs, and minimizing the number of of external packages so it actually will run on cloud providers.

I was going to go with a name in the style of tilecache and tilestash, something like tilebank or tilehoard, but then screw it, I named it after my cat. 

it works and so far has 2 types of layers, "proxy" which just proxies another tile layer, converting it to png if its a jpeg, and "blend" which composits 2 layers. Curently the only cache is Couchdb which stores it in a couchdb that you have to suply the url for and pretend which is, wait for it, pretend and never has the tile. If you uncomment the two lines at the top of "routes.coffee" and have [node-mbtiles](https://github.com/mapbox/node-mbtiles) installed then any mbtiles in the tiles folder are automatically layers, but [node-sqlite3](https://github.com/developmentseed/node-sqlite3) doesn't build on openshift, so it's not included by default.

example config file is there, if you want to add a new provider it needs to export an open method that takes the options in the config file, and that should return an object that has a getTile method. which accepts 4 arguments, zoom, x, y, and callback, callback returns err, tile, etag. it should be in the providers folder with the same name as the layer you refer to it in config.

cache is the same except instead of open it has cache and instead of getTile it has get and put methods, get takes layer, z, x, y, callback(err,tile,etag), and put takes layer,z,x,y,tile

tiles are all passed around as buffers. 

it has no state, requests to different servers are handled in an identicle manner, i.e. all your subdomains could just be different servers and it would be fine. Currenlty it uses to cluster module to create a process for each cpu  and splits the load

next up will probobly be some sort of quick cache prob not in memory as that is a bit to close to state for me.

Q: should I use this for anything in the wild?  
A:hellz no at the moment consider this alpha at best

[Test version on modulus](http://kublai.aa.am/stamenRoads/preview), (link at the top is to my cat's blog). now 2 out of 4 tile domains are over on app frog while the other 2 are on openshift