-module(node_center).
-include("global.hrl").
-include("common_records.hrl").

-export([
    init/0,
    terminate/1,
    do_handle/1
]).

init() ->
    node_base:subscription().

terminate(_Reason) ->
    ok.

do_handle(Info) ->
    ?ERROR_MSG("unknown info: ~p", [Info]).
