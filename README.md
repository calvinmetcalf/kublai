change of plan, kublai is written in erlang now

to depends on erlang and sqlite3, also if you want to auto install the erlang dependencies you'll need git, 

	sudo apt-get install erlang sqlite3 git

if your on linux you can run ./start.sh from the main directory to automatically install everything and set it up.

currently the main functions are as follows

	kublai:getTile(map,zoom,x,y).

this returns the tile binary, at the momment map is one and the same as mbtiles filename without the extention located in the tile directory to use this with the example tileset run

	kublai:getTile(mpo,8,77,161).

next we have

	kublai:getGrid(map,zoom,x,y).

this returns the grid json so you can test with

	kublai:getGrid(mpo,8,77,161).

there is also a very basic server which you can start with 

	kublai:start(port).

if you leave port blank it defaults to 7027 localhost:7027/mpo/8/77/94.png can be used to test that n(notice the fliped y cordinates). localhost:7027/mpo/8/77/94.grid.json and localhost:7027/mpo.jsonp will also return you stuff. 

ks.erl is for use with couchdb, running 

	ks:dump(mpo). 

will dump every single tile from the mpo tileset into the couchdb database called mpo, currently it, like the rest of it assumes the tileset is located in the tile folder, that you want the datavase to be named the same as the tile file, and that you have admin party turned on (whoch is bad to do).

