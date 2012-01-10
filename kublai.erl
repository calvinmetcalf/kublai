-module(kublai).
-compile(export_all).
writeTile(Map,X,Y,Z)->
Path = filename:absname(""),
Pathparts = [Path,"/tiles/",Map,".mbtiles"],
Tileset = lists:concat(Pathparts),
{ok, Db} = sqlite3:start_link(mpo,[{file, Tileset}]),
Qparts = ["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, "  AND tile_column = ", X, " AND tile_row = ", Y],
Sql = lists:concat(Qparts),
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, Sql),
Outputlist = [Y, ".png"],
Outname = lists:concat(Outputlist),
file:write_file(Outname,Tile).
