%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     map server
%%% @end
%%% Created : 21. 四月 2017 15:00
%%%-------------------------------------------------------------------
-module(map_server).

-behaviour(gen_server).
-include("global.hrl").

%% API
-export([
    start_link/1,
    kick_all_roles/0,
    delay_kick_roles/0,
    delay_kick_roles/1,
    delay_shutdown/0,
    delay_shutdown/1,
    ets_i/1,
    ets_i/2,
    i/1,
    i/2
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-export([
    reg_role/1,
    dereg_role/1,
    broadcast_by_actors/2,
    broadcast_by_pos/2,
    send_all_role/1,
    send_all_gateway/1,
    send_msg_by_roleids/2,
    send_msg_by_gpids/2,
    send_role_info_by_roleids/2
]).

-export([
    is_map_process/0
]).

-define(SERVER, ?MODULE).

-record(state, {}).
ets_i(MapID) ->
    pname_server:call(map_misc:get_map_pname(MapID, map_branch_manager:get_map_cur_extra_id(MapID)), ets_i).
ets_i(MapID, ExtraID) ->
    pname_server:call(map_misc:get_map_pname(MapID, ExtraID), ets_i).

i(MapID) ->
    pname_server:call(map_misc:get_map_pname(MapID, map_branch_manager:get_map_cur_extra_id(MapID)), i).
i(MapID, ExtraID) ->
    pname_server:call(map_misc:get_map_pname(MapID, ExtraID), i).

start_link({_MapID, MapPName, _ExtraID, _Params} = Args) ->
    gen_server:start_link({local, MapPName}, ?MODULE, Args, []).

%% 踢玩家离开当前地图
kick_all_roles() ->
    send_role_info_by_roleids(mod_map_ets:get_in_map_roles(), {mod, mod_role_map, quit_map}).

%% 地图进程延时踢人
delay_kick_roles() -> %% 默认30秒后踢人
    delay_kick_roles(?ONE_MINUTE div 2).
delay_kick_roles(Sec) ->
    erlang:send_after(Sec * 1000, erlang:self(), {func, fun() -> map_server:kick_all_roles() end}).

%% 地图进程关闭调用
delay_shutdown() ->
    erlang:send_after(?MAP_SHUTDOWN_TIME * 1000, erlang:self(), {map_shutdwon, normal}).

delay_shutdown(Time) ->
    erlang:send_after(Time * 1000, erlang:self(), {map_shutdwon, normal}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init({MapID, MapPName, ExtraID, Params}) ->
    ?INFO_MSG("test:~w", [{MapID, MapPName, ExtraID, Params}]),
    erlang:process_flag(trap_exit, true),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    mod_map_dict:set_is_map_process(true),
    mod_map_ets:map_init(MapID, ExtraID),
    map_common_dict:init(MapID, MapPName, self(), ExtraID),
    mod_map_dict:set_map_params(Params),
    mod_map_dict:set_is_wild_map(map_branch_manager:is_branch_map(MapID)),
    mod_map_dict:set_sub_type(SubType),

    start_msg_server(MapID, MapPName),
    start_other_server(MapID, MapPName, ExtraID),
    start_robot_server(MapID, MapPName, ExtraID),
    hook_map:init(),
    time_tool:reg(map, [1000]),
    {ok, #state{}}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info({map_shutdwon, Reason}, State) -> %% 地图关闭
    ?INFO_MSG("map_shutdwon, test:~w", [Reason]),
    {stop, normal, State};
handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    time_tool:dereg(map, [1000]),
    map_server:kick_all_roles(),
    stop_server(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

reg_role(MapRole) ->
    #r_map_role{
        role_id = RoleID,
        gateway_pid = RoleGPID,
        role_pid = RolePID
    } = MapRole,
    mod_map_ets:set_pid2role(RolePID, RoleID),
    MsgPID = get_hash_pid(RoleID),
    pname_server:send(MsgPID, {reg_role, {RoleID, RolePID, RoleGPID}}).
dereg_role({RoleID, RolePID}) ->
    mod_map_ets:del_pid2role(RolePID),
    MsgPID = get_hash_pid(RoleID),
    pname_server:send(MsgPID, {dereg_role, RoleID}).

broadcast_by_actors(ActorList, DataRecord) ->
    AllSlice = mod_map_slice:get_slices_by_actor_list(ActorList),
    Roles = mod_map_slice:get_roleids_by_slices(AllSlice),
    send_msg_by_roleids(Roles, DataRecord).

broadcast_by_pos(Pos, DataRecord) ->
    RoleList = mod_map_slice:get_9slices_roleids_by_pos(Pos),
    send_msg_by_roleids(RoleList, DataRecord).

send_all_gateway(Data) ->
    send_to_msg_pid({send_all_gateway, Data}).

send_all_role(Info) ->
    send_to_msg_pid({send_all_role, Info}).

send_msg_by_roleids([], _Data) ->
    ok;
send_msg_by_roleids(RoleIDs, Data) ->
    send_to_msg_pid({send_gateway_by_roleid, RoleIDs, Data}).

send_msg_by_gpids([], _Data) ->
    ok;
send_msg_by_gpids(RoleGPIDs,Data) ->
    send_to_msg_pid({send_gateway_by_rolegpid, RoleGPIDs, Data}).

send_to_msg_pid(Info) ->
    [ pname_server:send(PID, Info) || PID <- mod_map_dict:get_msg_server_pid()].

send_role_info_by_roleids([], _Info) ->
    ok;
send_role_info_by_roleids(RoleIDs, Info) ->
    send_to_msg_pid({send_role_by_roleid, RoleIDs, Info}).

is_map_process() ->
    mod_map_dict:get_is_map_process() =:= true.
%%%===================================================================
%%% Internal functions
%%%===================================================================
%%地图每秒大循环
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    hook_map:loop(Now);
do_handle({bc_msg, Msg}) ->
    send_to_msg_pid(Msg);
%% 玩家下线了
do_handle({'DOWN', _, _, RolePID, _}) ->
    case mod_map_ets:get_pid2role(RolePID) of
        undefined ->
            ignore;
        RoleID ->
            mod_map_actor:leave_map(RoleID, {RolePID, false, []})
    end;
%%对指定的模块发送消息,通用,建议使用
do_handle({mod, Module, Info}) ->
    Module:handle(Info);
do_handle({func, M, F, A}) ->
    erlang:apply(M,F,A);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle(ets_i) ->
    do_ets_i();
do_handle(delay_kick_roles) ->
    delay_kick_roles();
do_handle(i) ->
    do_i();
do_handle(_Request) ->
    ?ERROR_MSG("Unknow msg:~p", [_Request]).

start_msg_server(MapID, MapPName) ->
    case lib_config:find(cfg_map_branch, {map_msg_num, MapID}) of
        [MsgNum] when MsgNum >= 1 -> next;
        _ -> [MsgNum] = lib_config:find(cfg_map_branch, default_msg_num)
    end,
    PIDList =
        [begin
             {ok, BSPID} = map_msg_server:start_link(MapPName, WorkerID),
             BSPID
         end || WorkerID <- lists:seq(1, MsgNum)],
    mod_map_dict:set_msg_num(erlang:length(PIDList)),
    mod_map_dict:set_msg_server_pid(PIDList).

start_other_server(MapID, MapPName, ExtraID) ->
    [ begin
          {ok, PID} = Mod:start_link(MapID, MapPName, erlang:self(), ExtraID),
          mod_map_dict:SetFun(PID)
      end || {Mod, SetFun, _GetFun} <- get_other_list()].

%% @doc 地图机器人服务启动
start_robot_server(MapID, MapPName, ExtraID) ->
    [#c_map_base{seqs = Seqs}] = lib_config:find(cfg_map_base, MapID),
    case is_wild_map(Seqs) orelse map_misc:is_copy_equip(MapID) orelse map_misc:is_copy_guide_boss(MapID) orelse map_misc:is_copy_offline_solo(MapID) of
        true ->
            {ok, PID} = map_robot_server:start_link(MapID, MapPName, erlang:self(), ExtraID),
            mod_map_dict:set_robot_pid(PID);
        _ ->
            ok
    end.

stop_server() ->
    [ stop_pid(PID) || PID <- mod_map_dict:get_msg_server_pid()],
    [ stop_pid(mod_map_dict:GetFun()) || {_Mod, _SetFun, GetFun} <- get_other_list()],
    case mod_map_dict:get_robot_pid() of
        undfined ->
            ok;
        RobotPID ->
            stop_pid(RobotPID)
    end.

stop_pid(PID) ->
    catch gen_server:stop(PID).

get_hash_pid(RoleID) ->
    Num = mod_map_dict:get_msg_num(),
    PIDList = mod_map_dict:get_msg_server_pid(),
    N = (RoleID div 1000) rem Num + 1,
    lists:nth(N, PIDList).

is_wild_map([]) ->
    false;
is_wild_map([SeqID|R]) ->
    case lib_config:find(cfg_map_seq, SeqID) of
        [#c_map_seq{monster_type_id = TypeID, min_level = MinLevel}] ->
            ?IF(TypeID > 0 andalso MinLevel > 0, true, is_wild_map(R));
        _ ->
            ?ERROR_MSG("SeqID not found : ~w", [SeqID]),
            is_wild_map(R)
    end.

get_other_list() ->
    [
        {map_monster_server, set_monster_pid, get_monster_pid},
        {map_collection_server, set_collection_pid, get_collection_pid},
        {map_trap_server, set_trap_pid, get_trap_pid}
    ].

do_i() ->
    {dictionary, List} = erlang:process_info(erlang:self(), dictionary),
    lists:foldl(
        fun(Dict, Acc) ->
            case Dict of
                {{_, slice, _}, _} ->
                    Acc;
                _ ->
                    [Dict|Acc]
            end
        end, [], lists:sort(List)).

do_ets_i() ->
    List = [ ets:tab2list(mod_map_ets:get_ets(TabKey))|| {TabKey, _} <- ?ETS_LIST, TabKey =/= ?SLICES_KEY],
    lists:sort(lists:flatten(List)).


