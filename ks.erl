-module(ks).
-compile(export_all).

for(Max, Max, F) -> [F(Max)];
for(I, Max, F) -> [F(I)|for(I+1, Max, F)].
for(Min, Max) -> for(Min, Max, fun(I) -> I end).

z(D, End) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(zoom_level) from tiles"]))))))).

zmin(D) -> z(D, min).
zmax(D) -> z(D, max).

x(D, End, Z) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(tile_column) from tiles WHERE zoom_level = ", Z]))))))).

xmin(D, Z) -> x(D, min, Z).

xmax(D, Z) -> x(D, max, Z).

y(D, End, Z, X) ->
element(1,hd(element(2,hd(tl(sqlite3:sql_exec(D, lists:concat(["SELECT ", End, "(tile_row) from tiles WHERE zoom_level = ", Z, " AND tile_column = ", X]))))))).

ymin(D, Z, X) -> y(D, min, Z, X).

ymax(D, Z, X) -> y(D, max, Z, X).

newCdb(M,S) ->
couchbeam:create_db(S, atom_to_list(M)).

deleteCdb(M) -> httpc:request(delete, {lists:concat([getHost(),"/",M]),[]},[],[]).


iTile(D,T,Z,X,Y) ->
ets:insert(T,{lists:concat(["z",Z,"x",X,"y",Y,"t"]),kublai:fetchTile(D,Z,X,Y)}).

iGrid(D,T,Z,X,Y) ->
ets:insert(T,{lists:concat(["z",Z,"x",X,"y",Y,"g"]),list_to_binary(kublai:fetchGrids(D,Z,X,Y))}).

dumpGrid(M) ->
D = kublai:openMBTILES(M),
T = ets:new(M,[]),
try lists:usort(lists:flatten(lists:map(fun(Q) -> dumpGrid(D,T,Q) end, for(zmin(D),zmax(D))))) of
[true] -> uploadGrid(T,M)
after
sqlite3:close(D)
end.

dumpGrid(D,T,Z) ->
lists:map(fun(Q) -> dumpGrid(D,T,Z,Q) end, for(xmin(D,Z),xmax(D,Z))).

dumpGrid(D,T,Z,X) ->
lists:map(fun(Q) -> iGrid(D,T,Z,X,Q) end, for(ymin(D,Z,X),ymax(D,Z,X))).

dump(M) ->
D = kublai:openMBTILES(M),
T = ets:new(M,[]),
try lists:usort(lists:flatten(lists:map(fun(Q) -> dump(D,T,Q) end, for(zmin(D),zmax(D))))) of
[true] -> upload(T,M)
after
sqlite3:close(D)
end.

dump(D,T,Z) ->
lists:map(fun(Q) -> dump(D,T,Z,Q) end, for(xmin(D,Z),xmax(D,Z))).

dump(D,T,Z,X) ->
lists:map(fun(Q) -> iTile(D,T,Z,X,Q) end, for(ymin(D,Z,X),ymax(D,Z,X))).

getHost() ->
{ok, S} = file:open("config.dat", read),
H = element(2,io:read(S,'')),
file:close(S),
H.

upload(T,M) ->
couchbeam:start(),
S = couchbeam:server_connection(),
couchbeam:create_db(S, atom_to_list(M)),
{ok,Dd} = couchbeam:open_db(S, atom_to_list(M)),
try lists:foreach(fun({A,B}) -> couchbeam:put_attachment(Dd,A,"tile.png",B,[{content_type, "image/png"}]) end, ets:tab2list(T))
after
couchbeam:stop()
end.

uploadGrid(T,M) ->
couchbeam:start(),
S = couchbeam:server_connection(),
couchbeam:create_db(S, atom_to_list(M)),
{ok,Dd} = couchbeam:open_db(S, atom_to_list(M)),
try lists:foreach(fun({A,B}) -> couchbeam:put_attachment(Dd,A,"grid",B,[{content_type, "application/javascript"}]) end, ets:tab2list(T))
after
couchbeam:stop()
end.


nDump(M,tiles) ->
D = kublai:openMBTILES(M),
try sqlite3:read_all(D,tiles) of
[{columns,["zoom_level","tile_column","tile_row","tile_data"]},{rows,L}] -> L
after
sqlite3:close(D)
end;
nDump(M,grids) ->
D = kublai:openMBTILES(M),
try sqlite3:read_all(D,grids) of
[{columns,["zoom_level","tile_column","tile_row","grid"]},{rows,Grid}] -> Grid
after
sqlite3:close(D)
end;
nDump(M,key) ->
D = kublai:openMBTILES(M),
try sqlite3:read_all(D,grid_data) of
[{columns,["zoom_level","tile_column","tile_row","key_name","key_json"]},{rows,Key}] -> Key
after
sqlite3:close(D)
end.

nMap(M,key) ->
L = nDump(M,key),
lists:map(fun({A,B,C,D,E}) -> {{A,B,C},{D,E}} end, L);
nMap(M,V) ->
L = nDump(M,V),
lists:map(fun({A,B,C,{blob,D}}) -> {{A,B,C},D} end, L).

nUpload(M,tiles) ->
L = nMap(M,tiles),
couchbeam:start(),
S = couchbeam:server_connection(),
{ok,Dd} = couchbeam:open_or_create_db(S, atom_to_list(M)),
try lists:usort(lists:map(fun({{Z,X,Y},B}) -> element(1,couchbeam:put_attachment(Dd,lists:concat(["z",Z,"x",X,"y",Y,"t"]),"tile",B,[{content_type, "image/png"}])) end,L)) of
[ok] -> couchbeam:stop()
catch
throw:X -> X
end;
nUpload(M,grids) ->
L = nMap(M,grids),
couchbeam:start(),
S = couchbeam:server_connection(),
{ok,Dd} = couchbeam:open_or_create_db(S, atom_to_list(M)),
try lists:usort(lists:map(fun({{Z,X,Y},B}) -> element(1,couchbeam:put_attachment(Dd,lists:concat(["z",Z,"x",X,"y",Y,"g"]),"grid",B,[{content_type, "text/javascript"}])) end,L)) 
catch
throw:X -> X;
exit:X -> X;
error:X -> X
end.
