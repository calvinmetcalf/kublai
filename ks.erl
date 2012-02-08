-module(ks).
-export([dumpTile/1]).

dumpTile(M) ->
D = openMBTILES(M),
couchbeam:start(),
S = couchbeam:server_connection(),
{ok, Db} = couchbeam:open_or_create_db(S, atom_to_list(M)),
try dumpTile({M,S,Db},D,zmin(D),zmax(D))
after
couchbeam:stop(),
sqlite3:close(D)
end.

dumpTile(_Stuff,_D,Max,Max)->
ok;
dumpTile(Stuff,D,Z,_)->
dumpTile(Stuff,D,Z,xmin(D,Z),xmax(D,Z)).

dumpTile(Stuff,D,Z,Max,Max)->
dumpTile(Stuff,D,Z+1,zmax(D));
dumpTile(Stuff,D,Z,X,_)->
dumpTile(Stuff,D,Z,X,ymin(D,Z,X),ymax(D,Z,X)).

dumpTile(Stuff,D,Z,X,Max,Max)->
dumpTile(Stuff,D,Z,X+1, xmax(D,Z));
dumpTile({M,S,Db},D,Z,X,Y,Max)->
case putTile(Db,getName(Z,X,Y),fetchTile(D,Z,X,Y)) of
{ok,_}->dumpTile({M,S,Db},D,Z,X,Y+1,Max)
end.

putTile(Db,N,T) ->
couchbeam:put_attachment(Db,N,"tile",T,[{content_type, "image/png"}]).

getName(Z,X,Y)->
lists:concat(["z",Z,"x",X,"y",flipY(Y,Z),"t"]).

flipY(Y,Z) ->
round(math:pow(2,Z) - Y - 1).

z(D, End) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(zoom_level) from tiles"]))))))).

zmin(D) -> z(D, min).
zmax(D) -> z(D, max)+1.

x(D, End, Z) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(tile_column) from tiles WHERE zoom_level = ", Z]))))))).

xmin(D, Z) -> x(D, min, Z).

xmax(D, Z) -> x(D, max, Z)+1.

y(D, End, Z, X) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(tile_row) from tiles WHERE zoom_level = ", Z, " AND tile_column = ", X]))))))).

ymin(D, Z, X) -> y(D, min, Z, X).

ymax(D, Z, X) -> y(D, max, Z, X)+1.

newCdb(M,S) ->
couchbeam:create_db(S, atom_to_list(M)).

getTilePath(M) ->
filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])]).

checkMBTILES(M) ->
filelib:is_file(getTilePath(M)).

openMBTILES(M) ->
case checkMBTILES(M) of
true -> element(2,sqlite3:start_link(m,[{file, getTilePath(M)}]));
false -> throw(noSuchTileset)
end.

fetchTile(D,Z,X,Y) ->
case sqlite3:sql_exec(D, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])) of
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] -> Tile;
[{columns,["tile_data"]},{rows,[]}] -> throw(noSuchTile);
true -> throw(noSuchTile)
end.
