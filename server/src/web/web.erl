%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 三月 2018 15:07
%%%-------------------------------------------------------------------
-module(web).
-author("laijichang").
-include("common.hrl").

%% API
-export([
    start/0
]).

start() ->
    web_start().


web_start() ->
    Port = web_misc:get_web_port(),
    WebConfig = [{port, Port}],
    {ok, _PID} = supervisor:start_child(web_sup, {web_server,
        {web_server, start, [WebConfig]},
        permanent, 5000, worker, dynamic}).
