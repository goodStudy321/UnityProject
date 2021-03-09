%%%-------------------------------------------------------------------
%%% @doc 角色Sup
%%%-------------------------------------------------------------------
-module(role_sup).

-behaviour(supervisor).

%% API
-export([
    all_children/0,
    start_role/2,
    start_link/0
]).

%% Supervisor callbacks
-export([init/1]).

%%%===================================================================
%%% API functions
%%%===================================================================
all_children() ->
    Children = supervisor:which_children(?MODULE),
    [Pid || {_, Pid, _, _} <- Children].

%% 启动玩家进程
start_role(GatewayPID, IP) ->
    supervisor:start_child(?MODULE, [GatewayPID, IP]).

%% 启动回调
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
init([]) ->
    RestartStrategy = simple_one_for_one,
    
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,
    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},
    
    Restart = temporary,
    Shutdown = 20000,
    Type = worker,

    AChild = {role_server, {role_server, start_link, []},
              Restart, Shutdown, Type, [role_server]},

    {ok, {SupFlags, [AChild]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
