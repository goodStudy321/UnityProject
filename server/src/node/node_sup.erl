-module(node_sup).
-behaviour(supervisor).

-export([
    start_link/0,
    start_child/1,
    start_child/2,
    all_children/0
]).

%% supervisor callbacks
-export([
    init/1
]).

%%%-------------------------------------------------------------------
%%% API functions
%%%-------------------------------------------------------------------
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% 启动子进程
%% 启动子进程
start_child(Name) ->
    start_child(Name, Name).
start_child(Mod, Name) ->
    {ok, _} = supervisor:start_child(?MODULE, {Name,
        {Mod, start_link, []},
        transient, 3000000, worker,
        [?MODULE]}).

all_children() ->
    Children = supervisor:which_children(?MODULE),
    [Pid || {_, Pid, _, _} <- Children].
    
%%%-------------------------------------------------------------------
%%% supervisor callbacks
%%%-------------------------------------------------------------------
init([]) ->
    {ok,{{one_for_one,10,10}, []}}.

%%%-------------------------------------------------------------------
%%% internal functions
%%%-------------------------------------------------------------------
