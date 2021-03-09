%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 三月 2018 15:39
%%%-------------------------------------------------------------------
-module(junhai_misc).
-author("laijichang").
-include("global.hrl").
-include("platform.hrl").

%% API
-export([
    log/1
]).

log(Log) ->
    case lib_config:find(common, junhai_log_open) of
        [true] ->
            junhai_log_server:log(Log);
        _ ->
            ok
    end.