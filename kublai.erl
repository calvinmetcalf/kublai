-module(kublai).
-compile(export_all).
getTile(M,Z,X,Y)->
{ok, Db} = sqlite3:start_link(M,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
Tile.

getInfo(M, K) ->
{ok, Db} = sqlite3:start_link(M,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
[{columns,["value"]},{rows,[{V}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT value FROM metadata WHERE 'name' = ", K])),
sqlite3:close(Db),
V.

