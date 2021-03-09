-module(db_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([start_child/1,start_child/2,start_child/3]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, transient, 30000, Type, [I]}).
-define(CHILD(I, Type, Args), {{I, Args}, {I, start_link, Args}, transient, 30000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_child(Mod) ->
    start_child(Mod, [], worker).

start_child(Mod, Args) ->
    start_child(Mod, Args, worker).

start_child(Mod, Args, Type) ->
    Child = ?CHILD(Mod, Type, Args),
    supervisor:start_child(?MODULE, Child).


%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    {ok, { {one_for_one, 10, 10}, []} }.


