-module(server_sup).

-behaviour(supervisor).

%% API
-export([
    start_link/0,
    start_child/1,
    stop_child/1
    ]).
%% Supervisor callbacks
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Name) ->
    {ok, Child} = supervisor:start_child(?MODULE,
        {Name, {Name, start_link, []}, transient, infinity, supervisor, [?MODULE]}),
    {ok, Child}.

stop_child(Sup) ->
    supervisor:terminate_child(?MODULE, Sup).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, { {one_for_one, 5, 10}, []} }.
