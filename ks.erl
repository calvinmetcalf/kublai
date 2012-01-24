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

newCdb(M) ->
element(1,httpc:request(put, {lists:concat(["http://127.0.0.1:5984/",M]),[],"",""},[],[])).

iTile(D,M,Z,X,Y) ->
httpc:request(put, {lists:concat([getHost(),"/",M,"/z",Z,"x",X,"y",Y,"t/attachment"]),[],"image/png",kublai:fetchTile(D,Z,X,Y)},[],[{sync, false}]).

iGrid(D,M,Z,X,Y) ->
httpc:request(put, {lists:concat(["http://127.0.0.1:5984/",M,"/z",Z,"x",X,"y",Y,"g/attachment"]),[],"application/json",kublai:fetchGrids(D,Z,X,Y)},[],[{sync, false}]).

dumpBoth(M) ->
D = kublai:openMBTILES(M),
inets:start(),
newCdb(M),
lists:map(fun(Q) -> dumpBoth2(D,M,Q) end, for(zmin(D),zmax(D))).

dumpBoth2(D,M,Z) ->
lists:map(fun(Q) -> dumpBoth3(D,M,Z,Q) end, for(xmin(D,Z),xmax(D,Z))).

dumpBoth3(D,M,Z,X) ->
lists:map(fun(Q) -> iTile(D,M,Z,X,Q) end, for(ymin(D,Z,X),ymax(D,Z,X))),
lists:map(fun(Q) -> iGrid(D,M,Z,X,Q) end, for(ymin(D,Z,X),ymax(D,Z,X))).

dump(M) ->
D = kublai:openMBTILES(M),
inets:start(),
newCdb(M),
lists:map(fun(Q) -> dump2(D,M,Q) end, for(zmin(D),zmax(D))).

dump2(D,M,Z) ->
lists:map(fun(Q) -> dump3(D,M,Z,Q) end, for(xmin(D,Z),xmax(D,Z))).

dump3(D,M,Z,X) ->
lists:map(fun(Q) -> iTile(D,M,Z,X,Q) end, for(ymin(D,Z,X),ymax(D,Z,X))).

dumpp(M) ->
D = kublai:openMBTILES(M),
inets:start(),
newCdb(M),
lists:map(fun(Q) -> dumpp2(D,M,Q) end, for(zmin(D),zmax(D))).

dumpp2(D,M,Z) ->
lists:map(fun(Q) -> spawn(fun() -> dump3(D,M,Z,Q) end) end, for(xmin(D,Z),xmax(D,Z))).

getHost() ->
{ok, S} = file:open("config.dat", read),
H = element(2,io:read(S,'')),
file:close(S),
H.



