-module(quad).
-compile(export_all).


toBinary(D) -> 
toBinary((D div 2),[(D rem 2)]).

toBinary(0,T) -> T;
toBinary(H,T) -> toBinary((H div 2),[(H rem 2)|T]).

toQuad(Z,X,Y) ->
toQuad(Z,{toBinary(X), toBinary(Y)}).

toQuad(Z,{Xbin, Ybin}) ->
toQuad(lists:zip(lists:flatten([lists:duplicate((Z - length(Xbin)),0)|Xbin]),lists:flatten([lists:duplicate((Z - length(Ybin)),0)|Ybin]))).

toQuad(L) ->
lists:concat(lists:map(fun({A,B}) -> quad({A,B}) end,L)).


quad({0,0}) -> a;
quad({1,0}) ->d;
quad({0,1}) ->b;
quad({1,1}) ->c.

