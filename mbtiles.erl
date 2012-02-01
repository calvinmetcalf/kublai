-module(mbtiles).
-behaviour(gen_server).
-export([start/1, stop/0, get/5, get/4]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).


start(Arg) -> gen_server:start_link({local, ?MODULE}, ?MODULE, Arg, []).
stop() -> gen_server:call(?MODULE, stop).

get(What, tms, Z, X, Y) -> gen_server:call(?MODULE, {get, What, Z, X, Y});
get(What, xyz, Z, X, Y) -> gen_server:call(?MODULE, {get, What, Z, X, flipY(Y,Z)}).

get(What, Z, X, Y) -> get(What, xyz, Z, X, Y).

flipY(Y,Z) ->
try round(math:pow(2,Z) - Y - 1)
catch
throw:E -> io:format("ow shit ~p did ~p which I don't understand~n", [?MODULE, E])
end.

handle_call({get,tile,Z,X,Y}, _From, D)->
Reply = case sqlite3:sql_exec(D, lists:concat(["SELECT tile_data FROM tiles WHERE zoom_level = ", Z, " AND tile_column = ", X, " AND tile_row = ", Y])) of
[{columns,["tile_data"]},{rows,[{{blob,Tile}}]}] -> Tile;
[{columns,["tile_data"]},{rows,[]}] -> {noSuchTile, Z, X, Y};
[_] -> throw(noSuchTile2)
end,
{reply, Reply, D};
handle_call(stop, _From, D) ->
{stop, normal, stopped, D}.

init(M) ->
case checkMBTILES(M) of
true -> {ok, element(2,sqlite3:start_link(m,[{file, getTilePath(M)}]))};
false -> throw(noSuchTileset)
end.


getTilePath(M) ->
filename:join([filename:absname(""),"tiles",lists:concat([M, ".mbtiles"])]).

checkMBTILES(M) ->
filelib:is_file(getTilePath(M)).


handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, State) -> 
sqlite3:close(State),
ok.
code_change(_OldVsn, State, _Extra)->{ok, State}.
