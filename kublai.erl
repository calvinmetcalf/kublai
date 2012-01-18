-module(kublai).
-compile(export_all).

getTile(M,Z,X,Y) ->
D = openMBTILES(M),
try fetchTile(D,Z,X,Y)
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
after
sqlite3:close(D)
end.

getTilePath(M) ->
filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])]).

checkMBTILES(M) ->
filelib:is_file(getTilePath(M)).

openMBTILES(M) ->
case checkMBTILES(M) of
true -> element(2,sqlite3:start_link(m,[{file, getTilePath(M)}]));
false -> throw(noSuchTileset)
end.

getGrid(M,Z,X,Y)->
D = openMBTILES(M),
try lists:append(cleanGrid(D,Z,X,Y),cleanKey(D,Z,X,Y))
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
after
sqlite3:close(D)
end.

fetchTile(D,Z,X,Y) ->
case sqlite3:sql_exec(D, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])) of
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] -> Tile;
[{columns,["tile_data"]},{rows,[]}] -> throw(noSuchTile);
true -> throw(noSuchTile)
end.

cleanGrid(D,Z,X,Y) ->
G = fetchGrid(D,Z,X,Y),
A = zlib:open(),
zlib:inflateInit(A),
Grid = zlib:inflate(A, G),
zlib:inflateEnd(A),
Grid.

cleanKey(D,Z,X,Y) ->
K = fetchKey(D,Z,X,Y),
StingConverted = [ {binary_to_list(X1),Y1} || {X1,Y1} <- K ],
mochijson2:encode(StingConverted).

fetchGrid(D,Z,X,Y) ->
case sqlite3:sql_exec(D, lists:concat(["SELECT grid FROM grids WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])) of
[{columns,["grid"]},{rows,[{{blob,Grid}}]}] -> Grid;
[{columns,["grid"]},{rows,[]}] -> throw(noSuchGrid);
true -> throw(noSuchGrid)
end.

fetchKey(D,Z,X,Y) ->
case sqlite3:sql_exec(D, lists:concat(["select key_name, key_json FROM grid_data WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])) of
[{columns,["key_name","key_json"]},{rows,Key}] -> Key;
[{columns,["key_name","key_json"]},{rows,[]}] -> throw(noSuchKey);
true -> throw(noSuchKey)
end.

getInfo(M) ->
{ok, Db} = sqlite3:start_link(m,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
V = sqlite3:read_all(Db, metadata),
sqlite3:close(Db),
%with much thanks to http://stackoverflow.com/questions/3923400/erlang-tuple-list-into-json for the following
Original = lists:map(fun({B,C})->{binary_to_list(B),binary_to_list(C)} end,element(2,hd(tl(V)))),
StingConverted = [ {X,list_to_binary(Y)} || {X,Y} <- Original ],
mochijson2:encode(StingConverted).


start(Port) ->
	misultin:start_link([{port, Port}, {loop, fun(Req) -> handle_http(Req) end}]).
	
handleURL(U) ->
L = string:tokens(U, "/"),
if
length(L) =:= 4 ->
M = list_to_atom(hd(L)),
Z = list_to_integer(lists:nth(2,L)),
X = list_to_integer(lists:nth(3,L)),
Y = round(math:pow(2,Z) - list_to_integer(hd(string:tokens(lists:nth(4,L),"."))) - 1),
F = list_to_atom(hd(tl(string:tokens(lists:nth(4,L),".")))),
if
F =:= png -> getTile(M,Z,X,Y);
F =:= grid -> getGrid(M,Z,X,Y);
true -> throw({badFormat, F})
end;
length(L) =:= 1 ->
[H , "jsonp"] = string:tokens(hd(L),"."),
M = list_to_atom(H),
getInfo(M)
end.
start() ->start(7027).
stop() ->
	misultin:stop().


handle_http(Req) ->
	handle(Req:get(method), Req:get(uri_unquoted), Req).
	


handle('GET', U, Req) ->
	Req:ok(handleURL(U)).
