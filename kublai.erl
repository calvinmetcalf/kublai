-module(kublai).
-compile(export_all).
writeTile(Map,X,Y,Z)->
{ok, Db} = sqlite3:start_link(mpo,[{file, filename:join([filename:absname(""),"tiles",lists:concat([Map, ".mbtiles"])])}]),

[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, "  AND tile_column = ", X, " AND tile_row = ", Y])),

file:write_file(lists:concat([Y, ".png"]),Tile).
