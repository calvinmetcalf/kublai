-module(kublai).
-compile(export_all).
getTile(Map,Z,X,Y)->
{ok, Db} = sqlite3:start_link(Map,[{file, filename:join([filename:absname(""),"tiles",lists:concat([Map, ".mbtiles"])])}]),
Tilename = lists:concat([Y, ".png"]),
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
[Tilename, Tile].

getTileName(Map,Z,X,Y) ->
hd(getTile(Map,Z,X,Y)).

getTileBin(Map,Z,X,Y) ->
tl(getTile(Map,Z,X,Y)).

