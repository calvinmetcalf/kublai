-module(kublai).
-compile(export_all).
getTile(M,Z,X,Y)->
Db = element(2,sqlite3:start_link(m,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}])),
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
Tile.

getInfo(M) ->
{ok, Db} = sqlite3:start_link(m,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
V = sqlite3:read_all(Db, metadata),
sqlite3:close(Db),
%with much thanks to http://stackoverflow.com/questions/3923400/erlang-tuple-list-into-json for the following
Original = lists:map(fun({B,C})->{binary_to_list(B),binary_to_list(C)} end,element(2,hd(tl(V)))),
StingConverted = [ {X,list_to_binary(Y)} || {X,Y} <- Original ],
mochijson2:encode(StingConverted).

getGrid(M,Z,X,Y)->
{ok, Db} = sqlite3:start_link(m,[{file, filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])])}]),
[{columns,["grid"]},{rows,[{{blob,Grid}}]}] = sqlite3:sql_exec(Db, lists:concat(["SELECT grid FROM grids WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
[{columns,["key_name","key_json"]},{rows,Key}] = sqlite3:sql_exec(Db, lists:concat(["select key_name, key_json FROM grid_data WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])),
sqlite3:close(Db),
A = zlib:open(),
zlib:inflateInit(A),
G = zlib:inflate(A, Grid),
zlib:inflateEnd(A),
StingConverted = [ {binary_to_list(X1),Y1} || {X1,Y1} <- Key ],
lists:append(G,mochijson2:encode(StingConverted)).

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

	handle(Req:get(method), Req:resource([urldecode]), Req).


handle('GET', [], Req) ->
	Req:ok([{"Content-Type", "text/plain"}], "Main home page.");


handle('GET', ["tile", Map, Zoom, X, Y], Req) ->
	tile(Req, Map, Zoom, X, Y);

handle('GET', ["info", Map], Req) ->
	info(Req, Map);


handle(_, _, Req) ->
	Req:ok([{"Content-Type", "text/plain"}], "OH NOES!").
	
tile(Req, Map, Zoom, X, Y) ->
	Req:ok([{"Content-Type", "image/png"}], getTile(Map, Zoom, X, Y)).
info(Req, Map) ->
	Req:ok([{"Content-Type", "application/json"}], getInfo(Map)).
