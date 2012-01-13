-module(kublai).
-compile(export_all).
getTile(M,Z,X,Y)->
{ok, Db} = sqlite3:start_link(M,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
Tile.

getInfo(M) ->
{ok, Db} = sqlite3:start_link(M,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
V = sqlite3:read_all(Db, metadata),
sqlite3:close(Db),
lists:map(fun({B,C})->{binary_to_list(B),binary_to_list(C)} end,element(2,hd(tl(V)))).

getGrid(M,Z,X,Y)->
{ok, Db} = sqlite3:start_link(M,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
[{columns,["key_name","key_json"]},{rows,Key}] = sqlite3:sql_exec(Db, lists:concat(["select key_name, key_json FROM grid_data WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
[{columns,["grid"]},{rows,[{{blob,Grid}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT grid FROM grids WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
A = zlib:open(),
zlib:inflateInit(A),
G = zlib:inflate(A, Grid),
zlib:inflateEnd(A),
[G,Key].

