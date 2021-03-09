%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%     游戏功能统计
%%% @end
%%% Created : 02. 十一月 2018 12:20
%%%-------------------------------------------------------------------
-module(world_log_statistics_server).
-author("laijichang").
-include("global.hrl").
-include("log_statistics.hrl").
-include("proto/mod_role_money_tree.hrl").

-behaviour(gen_server).

%% API
-export([
    i/0,
    start/0,
    start_link/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-export([
    role_online/1,
    log_add_times/4
]).

-export([
    info/1,
    call/1
]).


i() ->
    call(i).

start() ->
    world_sup:start_child(?MODULE).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

role_online(RoleID) ->
    info({role_online, RoleID}).

log_add_times(RoleID, Type, Times, SubTimes) ->
    info({log_add_times, RoleID, Type, Times, SubTimes}).


info(Info) ->
    pname_server:send(?MODULE, Info).

call(Info) ->
    pname_server:call(?MODULE, Info).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [0]),
    lib_tool:init_ets(?ETS_ROLE_STATISTICS, #r_role_statistics.role_id),
    init_role_statistics(),
    {ok, []}.

handle_call(Info, _From, State) ->
    Reply = ?DO_HANDLE_CALL(Info, State),
    {reply, Reply, State}.

handle_cast(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

handle_info(Info, State) ->
    ?DO_HANDLE_INFO(Info, State),
    {noreply, State}.

terminate(_Reason, _State) ->
    time_tool:dereg(world, [0]),
    do_dump_statistics(),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle(i) ->
    {world_data:get_statistics_roles(), get_all_statistics()};
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle({money_tree_log, Log}) ->
    do_add_money_tree_log(Log);
do_handle({role_online, RoleID}) ->
    do_role_online(RoleID);
do_handle({log_add_times, RoleID, Type, Times, SubTimes}) ->
    do_log_add_times(RoleID, Type, Times, SubTimes);
do_handle(?TIME_ZERO) ->
    do_zero();
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

init_role_statistics() ->
    RoleStats = world_data:get_role_statistics(),
    set_role_statistics(RoleStats).

do_dump_statistics() ->
    AllStat = get_all_statistics(),
    world_data:set_role_statistics(AllStat).

do_role_online(RoleID) ->
    RoleIDList = world_data:get_statistics_roles(),
    ?IF(lists:member(RoleID, RoleIDList), ok, world_data:set_statistics_roles([RoleID|RoleIDList])).

do_log_add_times(RoleID, Type, Times, SubTimes) ->
    #r_role_statistics{log_list = LogList} = RoleStat = get_role_statistics(RoleID),
    NewLogList =
    case lists:keytake(Type, #r_statistics_log.type, LogList) of
        {value, #r_statistics_log{} = Log, LogList2} ->
            #r_statistics_log{times = OldTimes, sub_times = OldSubTimes} = Log,
            Log2 = Log#r_statistics_log{times = OldTimes + Times, sub_times = OldSubTimes + SubTimes},
            [Log2|LogList2];
        _ ->
            Log = #r_statistics_log{type = Type, times = Times, sub_times = SubTimes},
            [Log|LogList]
    end,
    RoleStat2 = RoleStat#r_role_statistics{log_list = NewLogList},
    set_role_statistics(RoleStat2).

do_zero() ->
    AllStatistics = get_all_statistics(),
    OnlineRoles = world_data:get_statistics_roles(),
    world_data:set_statistics_roles(world_online_server:get_online_role_ids()),
    world_data:del_role_statistics(),
    del_all_statistics(),
    erlang:spawn(fun() -> log_offline_solo_snapshot(AllStatistics) end),
    erlang:spawn(fun() -> do_log_statistics(OnlineRoles, AllStatistics) end),
    erlang:spawn(fun() -> log_role_snapshot() end),
    ok.

do_log_statistics(OnlineRoles, AllStatistics) ->
    OnlineLevelList = [{OnlineRoleID, common_role_data:get_role_level(OnlineRoleID)} || OnlineRoleID <- OnlineRoles],
    LogList =
    lists:foldl(
        fun(#c_log_stat{type = Type, level_args = LevelArgs, sub_list = SubList}, Acc) ->
            StatLevel = get_stat_level(LevelArgs),
            Log = do_log_statistics2(Type, StatLevel, SubList, OnlineLevelList, AllStatistics),
            [Log|Acc]
        end, [], ?LOG_STAT_LIST),
    background_misc:log(LogList),
    ok.

do_log_statistics2(Type, StatLevel, SubList, OnlineLevelList, AllStatistics) ->
    {RoleNum, Times, SubTimes, SubTimesList} = do_log_statistics3(Type, SubList, AllStatistics, 0, 0, 0, []),
    FunctionRoleNum = get_level_role_num(StatLevel, OnlineLevelList),
    #log_function_statistics{
        function_id = Type,
        role_num = RoleNum,
        times = Times,
        sub_times = SubTimes,
        function_level = StatLevel,
        function_role_num = FunctionRoleNum,
        times_string = common_misc:to_kv_string(lists:keysort(#p_kv.id, SubTimesList))
    }.

do_log_statistics3(_Type, _SubList, [], RoleNumAcc, TimesAcc, SubTimesAcc, SubTimeListAcc) ->
    {RoleNumAcc, TimesAcc, SubTimesAcc, SubTimeListAcc};
do_log_statistics3(Type, SubList, [RoleStat|R], RoleNumAcc, TimesAcc, SubTimesAcc, SubTimeListAcc) ->
    #r_role_statistics{log_list = LogList} = RoleStat,
    case lists:keyfind(Type, #r_statistics_log.type, LogList) of
        #r_statistics_log{times = Times, sub_times = SubTimes} ->
            RoleNumAcc2 = RoleNumAcc + 1,
            TimesAcc2 = TimesAcc + Times,
            SubTimesAcc2 = SubTimesAcc + SubTimes,
            SubTimeListAcc2 = get_sub_list(SubTimes, SubList, SubTimeListAcc),
            do_log_statistics3(Type, SubList, R, RoleNumAcc2, TimesAcc2, SubTimesAcc2, SubTimeListAcc2);
        _ ->
            do_log_statistics3(Type, SubList, R, RoleNumAcc, TimesAcc, SubTimesAcc, SubTimeListAcc)
    end.

get_stat_level(LevelArgs) ->
    case LevelArgs of
        {activity, ActivityID} ->
            case lib_config:find(cfg_activity, ActivityID) of
                [#c_activity{min_level = MinLevel}] ->
                    MinLevel;
                _ ->
                    1
            end;
        {copy, CopyID} ->
            copy_misc:get_copy_min_level(CopyID);
        {mfa, Mod, Function, Args} ->
            case erlang:function_exported(Mod, Function, erlang:length(Args)) of
                true ->
                    erlang:apply(Mod, Function, Args);
                _ ->
                    ?ERROR_MSG("log_statistics unknow function : ~w", [{Mod, Function, Args}]),
                    100
            end;
        _ ->
            LevelArgs
    end.

get_level_role_num(StatLevel, OnlineLevelList) ->
    lists:foldl(
        fun({_RoleID, Level}, Acc) ->
            ?IF(Level >= StatLevel, Acc + 1, Acc)
        end, 0, OnlineLevelList).

get_sub_list(_SubTimes, [], SubTimeListAcc) ->
    SubTimeListAcc;
get_sub_list(SubTimes, [NeedTimes|R], SubTimeListAcc) ->
    case SubTimes >= NeedTimes of
        true ->
            NewSubTimeListAcc =
            case lists:keytake(NeedTimes, #p_kv.id, SubTimeListAcc) of
                {value, #p_kv{val = OldNum} = KV, SubTimeListAcc2} ->
                    [KV#p_kv{val = OldNum + 1}|SubTimeListAcc2];
                _ ->
                    [#p_kv{id = NeedTimes, val = 1}|SubTimeListAcc]
            end,
            get_sub_list(SubTimes, R, NewSubTimeListAcc);
        _ ->
            get_sub_list(SubTimes, R, SubTimeListAcc)
    end.

log_role_snapshot() ->
    AttrList = db_lib:all(?DB_ROLE_ATTR_P),
    log_equip_snapshot(),
    log_vip_snapshot(AttrList),
    log_all_level(AttrList),
    log_level_snapshot(AttrList),
    log_all_confine().

log_offline_solo_snapshot(AllStatistics) ->
    OfflineList = get_offline_solo_snapshot(AllStatistics, []),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_OFFLINE_SOLO, get_snapshot_log(OfflineList)).

log_equip_snapshot() ->
    RoleEquipList = db_lib:all(?DB_ROLE_EQUIP_P),
    {StarList, RefineList, StoneList} =
    lists:foldl(
        fun(#r_role_equip{equip_list = EquipList}, {Acc1, Acc2, Acc3}) ->
            {AllStarLevel, AllRefineLevel, AllStoneLevel} = mod_role_equip:get_equip_snapshot(EquipList),
            {[AllStarLevel|Acc1], [AllRefineLevel|Acc2], [AllStoneLevel|Acc3]}
        end, {[], [], []}, RoleEquipList),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_EQUIP_STARS, get_snapshot_log(StarList)),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_EQUIP_REFINE, get_snapshot_log(RefineList)),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_STONE_LEVEL, get_snapshot_log(StoneList)).

log_vip_snapshot(AttrList) ->
    VipList = db_lib:all(?DB_ROLE_VIP_P),
    Now = time_tool:now(),
    {VipLevelList, LevelList} =
    lists:foldl(
        fun(#r_role_vip{role_id = RoleID, expire_time = ExpireTime, level = VipLevel}, {Acc1, Acc2}) ->
            VipLevel2 = ?IF(ExpireTime >= Now, VipLevel, 0),
            NewAcc1 = [VipLevel2|Acc1],
            NewAcc2 =
            case VipLevel2 > 0 of
                true ->
                    case lists:keyfind(RoleID, #r_role_attr.role_id, AttrList) of
                        #r_role_attr{level = RoleLevel} ->
                            [RoleLevel|Acc2];
                        _ ->
                            Acc2
                    end;
                _ ->
                    Acc2
            end,
            {NewAcc1, NewAcc2}
        end, {[], []}, VipList),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_VIP_LEVEL, get_snapshot_log(VipLevelList)),
    log_role_snapshot2(?LOG_ROLE_SNAPSHOT_LEVEL_VIP, get_snapshot_log(LevelList)).

log_role_snapshot2(Type, String) ->
    Log = #log_role_snapshot{
        snapshot_type = Type,
        snapshot_string = String
    },
    background_misc:log(Log).

log_all_level(AttrList) ->
    AllLevelList = [RoleLevel || #r_role_attr{level = RoleLevel} <- AttrList],
    String = get_snapshot_log(AllLevelList),
    Log = #log_all_level{string = String},
    background_misc:log(Log).

log_level_snapshot(_AttrList) ->
    ok.
%%    LogList = [ #log_level_snapshot{role_id = RoleID, role_level = RoleLevel} || #r_role_attr{role_id = RoleID, level = RoleLevel} <- AttrList],
%%    background_misc:log(LogList).

log_all_confine() ->
    AllConfineID = [ConfineID || #r_role_confine{confine = ConfineID} <- db_lib:all(?DB_ROLE_CONFINE_P)],
    String = get_snapshot_log(AllConfineID),
    Log = #log_all_confine{string = String},
    background_misc:log(Log).

get_snapshot_log(List) ->
    List2 =
    lists:foldl(
        fun(Key, Acc) ->
            case lists:keyfind(Key, #p_kv.id, Acc) of
                #p_kv{val = OldVal} = KV ->
                    lists:keyreplace(Key, #p_kv.id, Acc, KV#p_kv{val = OldVal + 1});
                _ ->
                    [#p_kv{id = Key, val = 1}|Acc]
            end
        end, [], List),
    List3 = lists:keysort(#p_kv.id, List2),
    common_misc:to_kv_string(List3).

get_offline_solo_snapshot([], Acc) ->
    Acc;
get_offline_solo_snapshot([RoleStat|R], Acc) ->
    #r_role_statistics{log_list = LogList} = RoleStat,
    Acc2 =
    case lists:keyfind(?LOG_STAT_OFFLINE_SOLO, #r_statistics_log.type, LogList) of
        #r_statistics_log{times = Times} ->
            [Times|Acc];
        _ ->
            Acc
    end,
    get_offline_solo_snapshot(R, Acc2).
%%%===================================================================
%%% dict
%%%===================================================================
get_all_statistics() ->
    ets:tab2list(?ETS_ROLE_STATISTICS).
set_role_statistics(RoleStat) ->
    ets:insert(?ETS_ROLE_STATISTICS, RoleStat).
del_all_statistics() ->
    ets:delete_all_objects(?ETS_ROLE_STATISTICS).
get_role_statistics(RoleID) ->
    case ets:lookup(?ETS_ROLE_STATISTICS, RoleID) of
        [#r_role_statistics{} = RoleStat] ->
            RoleStat;
        _ ->
            #r_role_statistics{role_id = RoleID}
    end.


%%------------------------------------其他异步日志--------------------------


do_add_money_tree_log(Log) ->
    common_broadcast:bc_record_to_world(#m_money_tree_log_toc{other_log = Log}),
    List = world_data:get_money_tree(),
    lib_tool:add_log(List, Log, 30),
    world_data:set_money_tree([Log|List]).








