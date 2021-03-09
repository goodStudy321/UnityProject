%%%-------------------------------------------------------------------
%%% @doc map节点下的map_sup
%%%-------------------------------------------------------------------
-module(map_sup).
-include("global.hrl").

-behaviour(supervisor).

%% API
-export([
    start_link/0,
    start_child/1,
    start_child/2,
    start_child/3,
    start_map/2,
    start_map/3,
    start_map/4,
    stop_map/2,
    stop_map/3
]).

%% Supervisor callbacks
-export([init/1]).

%%%===================================================================
%%% API functions
%%%===================================================================
%% 启动回调
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% 启动普通地图
start_map(MapID, ExtraID) ->
    start_map(MapID, ExtraID, common_config:get_server_id()).
start_map(MapID, ExtraID, ServerID) ->
    start_map(MapID, ExtraID, ServerID, []).
start_map(MapID, ExtraID, ServerID, ExtraParams) ->
    do_start_map(MapID, ExtraID, ServerID, ExtraParams).

stop_map(MapID, ExtraID) ->
    stop_map(MapID, ExtraID, common_config:get_server_id()).
stop_map(MapID, ExtraID, ServerID) ->
    MapPName = map_misc:get_map_pname(MapID, ExtraID, ServerID),
    supervisor:terminate_child(?MODULE, MapPName),
    supervisor:delete_child(?MODULE, MapPName).


%% 启动子进程
start_child(Name) ->
    start_child(Name, Name, []).
start_child(Mod, Name) ->
    start_child(Mod, Name, []).
start_child(Mod, PName, Args) ->
    {ok, _} = supervisor:start_child(?MODULE, {PName,
        {Mod, start_link, Args},
        temporary, 3000000, worker,
        [?MODULE]}).
%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

%%--------------------------------------------------------------------
init([]) ->
    {ok,{{one_for_one,10,10}, []}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

do_start_map(MapID, ExtraID, ServerID, ExtraParams) ->
    MapPName = map_misc:get_map_pname(MapID, ExtraID, ServerID),
    case catch map_base_data:info(MapID) of
        [{_, _}] ->
            case erlang:whereis(MapPName) of
                undefined ->
                    case start_child(map_server, MapPName, [{MapID, MapPName, ExtraID, ExtraParams}]) of
                        {ok, PID} ->
                            {ok, PID};
                        {error, {already_started, PID}} ->
                            {ok, PID};
                        {error, Reason} ->
                            ?ERROR_MSG("~ts ~w ~ts: ~w", ["创建地图", MapID, "失败", Reason]),
                            {error, Reason}
                    end;
                PID ->
                    {ok, PID}
            end;
        _ ->
            ?ERROR_MSG("~ts ~w ~ts: map_data_not_found", ["创建地图", MapID, "失败"]),
            erlang:throw(map_data_not_found)
    end.