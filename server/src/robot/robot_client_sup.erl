%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_client_sup).
-include("robot.hrl").
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).


start_link() ->
    supervisor:start_link({local, ?CLIENT_SUP}, ?MODULE, []).

init([]) ->
    Strategy = {one_for_one, 10, 5},
    {ok, {Strategy, []}}.
