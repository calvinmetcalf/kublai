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
try lists:append([cleanerGrid(D,Z,X,Y),cleanerKey(D,Z,X,Y),[125,41,59]])
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

cleanerGrid(D,Z,X,Y) ->
G = cleanGrid(D,Z,X,Y),
L = hd(lists:reverse(G)),
R = tl(lists:reverse(G)),
Len = size(L),
C = binary_to_list(L,1,Len-1),
W = lists:append([C,[44,34,100,97,116,97,34,58,123]]),
I = list_to_binary(W),
try lists:reverse(lists:append([[I],R,[40,100,105,114,103]]))
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end.

cleanerKey(D,Z,X,Y) ->
K = cleanKey(D,Z,X,Y),
try lists:reverse(tl(lists:reverse(K)))
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
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
try lists:flatten(lists:map(fun({A,B}) -> [A,58,B,44] end, K))
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end.

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

fetchInfo(D) ->
try sqlite3:read_all(D, metadata)
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end.

cleanInfo(D)->
V = fetchInfo(D),
%with much thanks to http://stackoverflow.com/questions/3923400/erlang-tuple-list-into-json for the following
Original = lists:map(fun({B,C})->{binary_to_list(B),binary_to_list(C)} end,element(2,hd(tl(V)))),
StingConverted = [ {X,list_to_binary(Y)} || {X,Y} <- Original ],
mochijson2:encode(StingConverted).

getInfo(M) ->
D = openMBTILES(M),
try cleanInfo(D)
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
after
sqlite3:close(D)
end.

makeJSONP(M) ->
A = [103,114,105,100,40],
B = getInfo(M),
C = [41,59],
try lists:append([A,B,C])
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end.

start(Port) ->
	misultin:start_link([{port, Port}, {loop, fun(Req) -> handle_http(Req) end}]).
	
start() ->start(7027).
stop() ->
	misultin:stop().
flipY(Y,Z) ->
try round(math:pow(2,Z) - Y - 1)
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end.

handle_http(Req) ->
	handle(Req:get(method), Req:resource([lowercase, urldecode]), Req).

	
handle('GET', [], Req) ->
	template(Req, "Main  home page.");


handle('GET', [M], Req) ->
try string:tokens(M,".") of
[H, "jsonp"] -> info(Req, H);
["favicon", "ico"] -> favicon(Req);
[_,_] ->Req:respond(404,[{"Content-Type", "text/plain"}],"I have no idea what your trying to do")
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end;

handle('GET', [M,Z,X,T], Req) ->
try string:tokens(T,".") of
[H, "png"] -> tile(Req, list_to_atom(M),list_to_integer(Z),list_to_integer(X),list_to_integer(H));
[H, "grid", "json"] -> grid(Req, list_to_atom(M),list_to_integer(Z),list_to_integer(X),list_to_integer(H));
[_, _] -> Req:respond(404,[{"Content-Type", "text/plain"}],"Format Not Supported")
catch
throw:E -> throw(E);
error:E -> throw(E);
exit:E -> throw(E)
end;

handle(_, _, Req) ->
	template(Req, "Page not found.").

info(Req, M) ->
try makeJSONP(M) of
P -> Req:respond(200,[{"Content-Type", "application/json"}],P)
catch
throw:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
error:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
exit:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E)
end.	

tile(Req, M, Z, X, H) ->
Y = flipY(H,Z),
try getTile(M,Z,X,Y) of
P -> Req:respond(200,[{"Content-Type", "image/png"}],P)
catch
throw:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
error:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
exit:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E)
end.

grid(Req, M, Z, X, H) ->
Y = flipY(H,Z),
try getGrid(M,Z,X,Y) of
P -> Req:respond(200,[{"Content-Type", "application/json"}],P)
catch
throw:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
error:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E);
exit:E -> Req:respond(404,[{"Content-Type", "text/plain"}],E)
end.

favicon(Req) ->
{ok,F} = file:read_file(favicon.ico),
Req:ok([{"Content-Type", "image/vnd.microsoft.icon"}],F).

template(Req, Content) ->
	Req:ok([{"Content-Type", "text/html"}], ["<head>
		<meta http-equiv = \"content-type\" content=\"text/html; charset=UTF-8\">
	</head><body>", Content, "</body></html>"]).	

