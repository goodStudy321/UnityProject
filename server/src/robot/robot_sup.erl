%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 十一月 2017 10:19
%%%-------------------------------------------------------------------
-module(robot_sup).
-behaviour(supervisor).


-export([
    start/0,
    stop/0,
    start_link/0,
    init/1
]).

-export([
    start_child/1
]).

start() ->
    {ok, _} = supervisor:start_child(
        server_sup,
        {?MODULE, {?MODULE, start_link, []}, transient, 10000, worker, [?MODULE]}).

stop() ->
    supervisor:terminate_child(server_sup, robot_sup),
    supervisor:delete_child(server_sup, robot_sup).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Name) ->
    {ok, _} = supervisor:start_child(?MODULE, {Name,
        {Name, start_link, []},
        transient, 3000000, worker,
        [?MODULE]}).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([]) ->
    RobotClientSup = {robot_client_sup, {robot_client_sup, start_link, []}, temporary, 20000, supervisor, [robot_client_sup]},
    ChildSpec = [RobotClientSup],
    {ok,{{one_for_one,10,10}, ChildSpec}}.

