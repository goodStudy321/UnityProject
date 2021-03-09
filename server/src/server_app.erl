-module(server_app).
-include("global.hrl").
-behaviour(application).

%% Application callbacks
-export([
    start/2,
    stop/1,
    pre_stop/0
]).

%% ===================================================================
%% Application callbacks
%% ===================================================================
%% 注意节点类型
start(_StartType, _StartArgs) ->
    {ok, PID} = server_sup:start_link(),
    global_data:init(), %% 初始化全局变量ets
    ServerType = common_config:get_server_type(),
    Sups = get_config(ServerType, sups),
    Pres = get_config(ServerType, pre_starts),
    [begin
         ?SYSTEM_LOG("starting sup ~w ...", [Sup]),
         {ok, _Child} = server_sup:start_child(Sup),
         ?SYSTEM_LOG("done~n")
     end || Sup <- Sups],
    start_mods(Pres),
    [db:open(Table, EtsOpts, SqlOpts, ActiveTime) ||
        #c_tab{tab = Table, node = NodeType, ets_opts = EtsOpts, sql_opts = SqlOpts, active_time = ActiveTime} <- ?TABLE_INFO,
        db:is_node_match(NodeType, ServerType)],
    case common_config:is_lite() of
        true -> %% 轻量级启动
            ok;
        _ ->
            update_db(ServerType),
            start_mods(get_config(ServerType, starts))
    end,
    {ok, PID}.

update_db(ServerType) ->
    case common_config:get_version() of
        Version when erlang:is_integer(Version) ->
            DBVersion = world_data:get_db_version(),
            case Version > DBVersion of
                true ->
                    [ begin
                          Mod = lib_tool:list_to_atom("update_" ++ lib_tool:to_list(TmpVersion)),
                          update_common:update(Mod, ServerType)
                      end|| TmpVersion <- lists:seq(DBVersion + 1, Version)],
                    world_data:set_db_version(Version);
                _ ->
                    ok
            end;
        _ ->
            ?SYSTEM_LOG("db_version not found...~n")
    end.

stop(_State) ->
    ok.

start_mods(Mods) ->
    lists:foreach(
        fun({M, F, A}) ->
            ?SYSTEM_LOG("starting ~w ...", [M]),
            erlang:apply(M, F, A),
            ?SYSTEM_LOG("done~n");
           (Mod) ->
               ?SYSTEM_LOG("starting ~w ...", [Mod]),
               Mod:start(),
               ?SYSTEM_LOG("done~n")
        end, Mods).

pre_stop() ->
    gateway_misc:stop_prepare(),
    ServerType = common_config:get_server_type(),
    Pres = get_config(ServerType, pre_stops),
    [begin
         server_sup:stop_child(Sup)
     end || Sup <- Pres].

get_config(ServerType, Key) ->
    case lib_config:find(cfg_server, {ServerType, Key}) of
        [List] -> List;
        _ -> []
    end.


