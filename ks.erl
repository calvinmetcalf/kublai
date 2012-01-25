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
element(1,httpc:request(put, {lists:concat([getHost(),"/",M]),[],"",""},[],[])).

deleteCdb(M) -> httpc:request(delete, {lists:concat([getHost(),"/",M]),[]},[],[]).


iTile(D,T,Z,X,Y) ->
ets:insert(T,{lists:concat(["z",Z,"x",X,"y",Y,"t"]),kublai:fetchTile(D,Z,X,Y)}).

iGrid(D,T,Z,X,Y) ->
ets:insert(T,{lists:concat(["z",Z,"x",X,"y",Y,"g"]),list_to_binary(kublai:fetchGrids(D,Z,X,Y))}).

dumpGrid(M) ->
D = kublai:openMBTILES(M),
T = ets:new(M,[]),
try lists:usort(lists:flatten(lists:map(fun(Q) -> dumpGrid(D,T,Q) end, for(1,zmax(D))))) of
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
inets:start(),
newCdb(M),
try lists:foreach(fun({A,B}) -> httpc:request(put, {lists:concat([getHost(),"/",M,"/",A,"/attachment"]),[],"image/png",B},[],[]) end, ets:tab2list(T))
after
inets:stop()
end.

uploadGrid(T,M) ->
inets:start(),
try lists:foreach(fun({A,B}) -> httpc:request(put, {lists:concat([getHost(),"/",M,"/",A,"/attachment"]),[],"application/json",B},[],[]) end, ets:tab2list(T))
after
inets:stop()
end.
