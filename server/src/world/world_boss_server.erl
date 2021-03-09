%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%     boss_server
%%% @end
%%% Created : 14. 七月 2017 19:19
%%%-------------------------------------------------------------------
-module(world_boss_server).
-author("laijichang").
-include("global.hrl").
-include("world_boss.hrl").
-include("monster.hrl").
-include("act.hrl").
-include("cross.hrl").
-include("proto/mod_role_item.hrl").

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
    info/1,
    call/1,
    add_drop_lop/2,
    add_reward_role/2,
    world_boss_dead/3,

    get_cross_world_boss_info/2,
    get_cross_all_world_boss/0,
    get_cross_world_boss/1,

    gm_clear_boss_cd/0,
    gm_clear_mythical_cd/0,
    gm_clear_ancients_cd/0,
    clear_the_world_boss_cd/2,
    clear_all_floor_world_boss_cd/2,

    role_first_boss_enter/2,
    role_first_boss_leave/2,
    role_enter_boss/2,
    role_leave_boss/2,

    cave_act_change/1
]).

-export([
	get_world_boss/1,
    get_all_world_boss/0,
    get_mythical_config/1,
    get_ancients_config/1,
    get_floor_role/1
]).

i() ->
    call(i).

start() ->
    world_sup:start_child(?MODULE, get_mod_name()).

start_link() ->
    gen_server:start_link({local, get_mod_name()}, ?MODULE, [], []).

add_drop_lop(RareLogs, NormalLogs) ->
    info({add_drop_lop, RareLogs, NormalLogs}).

add_reward_role(RoleID, TypeID) ->
    info({add_reward_role, RoleID, TypeID}).

world_boss_dead(TypeID, KillerRoleID, KillerRoleName) ->
    info({boss_dead, TypeID, KillerRoleID, KillerRoleName}).

gm_clear_boss_cd() ->
    pname_server:send(?MODULE, gm_clear_boss_cd),
    catch pname_server:send(?CROSS_WORLD_BOSS_SERVER, gm_clear_boss_cd).

clear_the_world_boss_cd(IsCross, TypeID) ->
    call(get_mod_name(IsCross), {clear_the_world_boss_cd, TypeID}).

clear_all_floor_world_boss_cd(IsCross, MapID) ->
    info(get_mod_name(IsCross), {clear_all_floor_world_boss_cd, MapID}).

role_first_boss_enter(RoleID, TypeID) ->
    info({role_first_boss_enter, RoleID, TypeID}).
role_first_boss_leave(RoleID, TypeID) ->
    info({role_first_boss_leave, RoleID, TypeID}).

role_enter_boss(RoleID, MapID) ->
    info({role_enter_boss, RoleID, MapID}).
role_leave_boss(RoleID, MapID) ->
    info({role_leave_boss, RoleID, MapID}).

cave_act_change(Status) ->
    info({cave_act_change, Status}).

gm_clear_mythical_cd() ->
    pname_server:send(?MODULE, gm_clear_mythical_cd),
    catch pname_server:send(?CROSS_WORLD_BOSS_SERVER, gm_clear_mythical_cd).

gm_clear_ancients_cd() ->
    pname_server:send(?MODULE, gm_clear_ancients_cd).

get_cross_world_boss_info(Type, Floor) ->
    case catch pname_server:call(?CROSS_WORLD_BOSS_SERVER, {get_cross_world_boss_info, Type, Floor}) of
        {ok, BossInfoList, RoleNum} ->
            {BossInfoList, RoleNum};
        _ ->
            {[], 0}
    end.

get_cross_all_world_boss() ->
    case catch pname_server:call(?CROSS_WORLD_BOSS_SERVER, {func, world_boss_server, get_all_world_boss, []}) of
        [_|_] = List ->
            List;
        _ ->
            []
    end.

get_cross_world_boss(TypeID) ->
    case catch pname_server:call(?CROSS_WORLD_BOSS_SERVER, {func, world_boss_server, get_world_boss, [TypeID]}) of
        [#r_world_boss{} = WorldBoss] ->
            [WorldBoss];
        _ ->
            undefined
    end.

info(Info) ->
    pname_server:send(get_mod_name(), Info).
info(Mod, Info) ->
    pname_server:send(Mod, Info).

call(Info) ->
    pname_server:call(get_mod_name(), Info).
call(Mod, Info) ->
    pname_server:call(Mod, Info).

get_mod_name() ->
    get_mod_name(common_config:is_cross_node()).
get_mod_name(IsCross) ->
    ?IF(IsCross, ?CROSS_WORLD_BOSS_SERVER, ?MODULE).
%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    erlang:process_flag(trap_exit, true),
    time_tool:reg(world, [0, 1000]),
    lib_tool:init_ets(?ETS_FLOOR_ROLE, #r_floor_role.key),
    start_world_boss_map(),
    modify_boss_list(),
    init_mythical_refresh(),
    init_ancients_refresh(),
    init_map_to_floor(),
    ?IF(common_config:is_cross_node(), pname_server:reg(?CROSS_WORLD_BOSS_SERVER, erlang:self()), ok),
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
    time_tool:dereg(world, [0, 1000]),
    [ set_world_boss(Info#r_world_boss{is_alive = false, next_refresh_time = 0}) ||
        #r_world_boss{is_alive = true} = Info <- get_all_world_boss()],
    ?IF(common_config:is_cross_node(), pname_server:dereg(?CROSS_WORLD_BOSS_SERVER), ok),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

start_world_boss_map() ->
    IsCrossNode = common_config:is_cross_node(),
    [ ?IF(map_misc:is_world_boss_map(MapID), map_sup:start_map(MapID, ?DEFAULT_EXTRA_ID), ok) || {MapID, _Config} <- cfg_map_base:list(),
        map_misc:is_map_node_match(MapID, IsCrossNode)].

modify_boss_list() ->
    CfgList = cfg_world_boss:list(),
    %% 旧的boss是否删除
    [begin
         case WorldBoss of
             #r_world_boss{type_id = TypeID} ->
                 case lib_config:find(cfg_world_boss, TypeID) of
                     [#c_world_boss{boss_type = BossType}] when ?IS_WORLD_BOSS_TYPE(BossType) ->
                         ok;
                     _ ->
                         del_world_boss(TypeID)
                 end;
             _ ->
                 del_world_boss(erlang:element(#r_world_boss.type_id, WorldBoss))
         end
     end || WorldBoss <- get_all_world_boss()],
    IsCrossNode = common_config:is_cross_node(),
    %% 新加boss
    [ begin
          #c_world_boss{
              type = Type,
              boss_type = BossType,
              map_id = MapID} = Config,
          case Type =/= ?BOSS_TYPE_PERSONAL andalso ?IS_WORLD_BOSS_TYPE(BossType) andalso map_misc:is_map_node_match(MapID, IsCrossNode) of
              true ->
                  case get_world_boss(TypeID) of
                      [#r_world_boss{is_alive = IsAlive} = Info] ->
                          %% 不正常关闭时，修正boss存活状态
                          ?IF(IsAlive, set_world_boss(Info#r_world_boss{is_alive = false, next_refresh_time = 0}), ok);
                      _ ->
                          Info = #r_world_boss{type_id = TypeID, is_alive = false, next_refresh_time = 0},
                          set_world_boss(Info)
                  end;
              _ ->
                  del_world_boss(TypeID),
                  ok
          end
      end|| {TypeID, Config} <- CfgList].

init_mythical_refresh() ->
    Now = time_tool:now(),
    IsCrossNode = common_config:is_cross_node(),
    List1 =
        [#r_mythical_refresh{
            map_id = MapID,
            collect_refresh_time = Now + 2,
            monster_refresh_time = Now + 2} || {MapID, _Config} <- lib_config:list(cfg_mythical_refresh), map_misc:is_map_node_match(MapID, IsCrossNode)],
    set_mythical_refresh(List1),
    ok.

init_ancients_refresh() ->
    Now = time_tool:now(),
    IsCrossNode = common_config:is_cross_node(),
    MapBossList =
        lists:foldl(
            fun({BossTypeID, #c_world_boss{boss_type = BossType, map_id = MapID}}, Acc) ->
                case BossType =:=?BOSS_TYPE_HIDDEN_BOSS andalso map_misc:is_map_node_match(MapID, IsCrossNode) of
                    true ->
                        KV = #p_kv{id = BossTypeID, val = 0},
                        case lists:keytake(MapID, 1, Acc) of
                            {value, {MapID, BossList}, AccT} ->
                                [{MapID, [KV|BossList]}|AccT];
                            _ ->
                                [{MapID, [KV]}|Acc]
                        end;
                    _ ->
                        Acc
                end
            end, [], lib_config:list(cfg_world_boss)),
    RefreshList =
        lists:foldl(
            fun({MapID, _Config}, Acc) ->
                case map_misc:is_map_node_match(MapID, IsCrossNode) of
                    true ->
                        BossList =
                            case lists:keyfind(MapID, 1, MapBossList) of
                                {_, BossListT} ->
                                    BossListT;
                                _ ->
                                    []
                            end,
                        map_misc:info(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), {mod, mod_map_world_boss, {change_hidden_boss_list, BossList}}),
                        [#r_ancients_refresh{
                            map_id = MapID,
                            collect_refresh_time = Now + 2,
                            monster_refresh_time = Now + 2,
                            hidden_boss = #r_ancients_hidden_boss{boss_list = BossList}}|Acc];
                    _ ->
                        Acc
                end
            end, [], lib_config:list(cfg_ancients_refresh)),
    set_ancients_refresh(RefreshList),
    ok.

init_map_to_floor() ->
    [ begin
          #c_world_boss{
              map_id = MapID,
              type = Type,
              floor = Floor} = Config,
          set_map_to_floor(MapID, {Type, Floor})
      end || {_TypeID, Config} <- lib_config:list(cfg_world_boss)].
%%%===================================================================
%%% Internal functions
%%%===================================================================
do_handle({loop_sec, Now}) ->
    time_tool:now_cached(Now),
    do_loop(Now);
do_handle({boss_dead, TypeID, KillerRoleID, KillerRoleName}) ->
    do_boss_dead(TypeID, KillerRoleID, KillerRoleName);
do_handle({add_drop_lop, RareLogs, NormalLogs}) ->
    do_add_drop_log(RareLogs, NormalLogs);
do_handle({add_reward_role, RoleID, TypeID}) ->
    do_add_reward_role(RoleID, TypeID);
do_handle({role_first_boss_enter, RoleID, TypeID}) ->
    do_role_first_boss_enter(RoleID, TypeID);
do_handle({role_first_boss_leave, RoleID, TypeID}) ->
    do_role_first_boss_leave(RoleID, TypeID);
do_handle({role_enter_boss, RoleID, MapID}) ->
    do_role_enter_boss(RoleID, MapID);
do_handle({role_leave_boss, RoleID, MapID}) ->
    do_role_leave_boss(RoleID, MapID);
do_handle({cave_act_change, NowStatus}) ->
    do_cave_act_change(NowStatus);
do_handle(gm_clear_boss_cd) ->
    do_gm_clear_boss_cd();
do_handle({clear_the_world_boss_cd, TypeID}) ->   %% T 刷新一个世界boss 【世界boss刷新令】
    do_clear_the_world_boss_cd(TypeID);
do_handle({clear_all_floor_world_boss_cd, MapID}) ->   %% T 刷新一个世界boss 【世界boss刷新令】
    do_clear_all_floor_world_boss(MapID);
do_handle(gm_clear_mythical_cd) ->
    do_gm_clear_mythical_cd();
do_handle(gm_clear_ancients_cd) ->
    do_gm_clear_ancients_cd();
do_handle({get_cross_world_boss_info, Type, Floor}) ->
    do_get_cross_world_boss_info(Type, Floor);
do_handle(?TIME_ZERO) ->
    do_zero();
do_handle(i) ->
    do_i();
do_handle({mod, Mod, Info}) ->
    Mod:handle(Info);
do_handle({func, Fun}) when erlang:is_function(Fun) ->
    Fun();
do_handle({func, M, F, A}) ->
    erlang:apply(M, F, A);
do_handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_loop(Now) ->
    do_loop_world_boss(Now),
    do_loop_mythical_refresh(Now),
    do_loop_ancients_refresh(Now).

do_loop_world_boss(Now) ->
    lists:foreach(
        fun(Info) ->
            #r_world_boss{
                type_id = TypeID,
                is_alive = IsAlive,
                is_remind = IsRemind,
                next_refresh_time = NextRefreshTime,
                boss_extra = BossExtra} = Info,
            if
                not IsRemind andalso NextRefreshTime - Now =< 5 -> %% 5秒没提醒过，要去提醒~
                    Info2 = Info#r_world_boss{is_remind = true},
                    set_world_boss(Info2),
                    common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, TypeID, ?CARE_NOTICE_REFRESH}}),
                    ok;
                not IsAlive andalso Now >= NextRefreshTime ->
                    [#c_world_boss{type = Type, map_id = MapID, pos = Pos}] = lib_config:find(cfg_world_boss, TypeID),
                    case map_misc:get_map_pid(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID)) of
                        {ok, MapPID} ->
                            map_misc:info(MapPID, {mod, mod_map_world_boss, {born_boss, TypeID, Pos}}),
                            Info2 = Info#r_world_boss{is_alive = true, boss_extra = get_boss_extra(Type)},
                            set_world_boss(Info2),
                            #c_monster{monster_name = Name} = monster_misc:get_monster_config(TypeID),
                            common_broadcast:send_world_common_notice(?NOTICE_WORLD_BOSS, [Name]);
                        Error ->
                            ?ERROR_MSG("世界bossTypeID:~w 错误，地图进程不存在: ~w", [TypeID, Error])
                    end;
                IsAlive -> %% 初始世界boss 达到特定时间，可以直接发奖励
                    case BossExtra of
                        #r_first_boss{reward_roles = RewardRoles, reward_time = RewardTime, online_roles = OnlineRoles} ->
                            case RewardRoles =/= [] andalso OnlineRoles =:= [] andalso Now >= RewardTime of
                                true ->
                                    [#c_world_boss{map_id = MapID}] = lib_config:find(cfg_world_boss, TypeID),
                                    Info2 = do_first_boss_dead(Info, 0, 0, ""),
                                    set_world_boss(Info2),
                                    mod_map_world_boss:first_world_boss_add_hp(MapID, TypeID);
                                _ ->
                                    ok
                            end;
                        _ ->
                            ok
                    end,
                    ok;
                true ->
                    ok
            end
        end, get_all_world_boss()).

%% 神兽岛刷新机制
do_loop_mythical_refresh(Now) ->
    List = get_mythical_refresh(),
    List2 =
        [begin
             #r_mythical_refresh{
                 map_id = MapID,
                 is_collect_remain = IsCollectRemain,
                 collect_refresh_time = CollectRefreshTime,
                 is_monster_remain = IsMonsterRemain,
                 monster_refresh_time = MonsterRefreshTime} = Refresh,
            {IsCollectRemain2, CollectRefreshTime2} =
             if
                 not IsCollectRemain andalso CollectRefreshTime - Now =< ?ONE_MINUTE -> %% 1分钟没提醒过，要去提醒~
                     #c_mythical_refresh{collect_type_id = CollectTypeID} = get_mythical_config(MapID),
                     common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, CollectTypeID, ?CARE_NOTICE_REFRESH}}),
                     {true, CollectRefreshTime};
                 Now >= CollectRefreshTime ->
                     CollectRefreshTimeT = do_mythical_collect_refresh(Now, MapID),
                    {false, CollectRefreshTimeT};
                 true ->
                     {IsCollectRemain, CollectRefreshTime}
             end,
             {IsMonsterRemain2, MonsterRefreshTime2} =
                 if
                     not IsMonsterRemain andalso MonsterRefreshTime - Now =< ?ONE_MINUTE -> %% 1分钟没提醒过，要去提醒~
                         #c_mythical_refresh{monster_type_id = MonsterTypeID} = get_mythical_config(MapID),
                         common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, MonsterTypeID, ?CARE_NOTICE_REFRESH}}),
                         {true, MonsterRefreshTime};
                     Now >= MonsterRefreshTime ->
                         MonsterRefreshTimeT = do_mythical_monster_refresh(Now, MapID),
                         {false, MonsterRefreshTimeT};
                     true ->
                         {IsMonsterRemain, MonsterRefreshTime}
                 end,
             Refresh#r_mythical_refresh{
                 is_collect_remain = IsCollectRemain2,
                 collect_refresh_time = CollectRefreshTime2,
                 is_monster_remain = IsMonsterRemain2,
                 monster_refresh_time = MonsterRefreshTime2}
         end || Refresh <- List],
    set_mythical_refresh(List2).

do_mythical_collect_refresh(Now, MapID) ->
    #c_mythical_refresh{
        collect_type_id = TypeID,
        collect_num = CollectNum,
        collect_pos = CollectPos,
        collect_refresh_min = RefreshMin}  = get_mythical_config(MapID),
    CollectRefreshTime = Now + erlang:max(RefreshMin * ?ONE_MINUTE, 30),
    ?TRY_CATCH(mod_map_world_boss:collect_refresh(MapID, CollectRefreshTime, TypeID, CollectNum, CollectPos)),
    common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_COLLECT_REFRESH, [map_misc:get_map_name(MapID), mod_collection:get_collection_name(TypeID)]),
    CollectRefreshTime.

do_mythical_monster_refresh(Now, MapID) ->
    #c_mythical_refresh{
        monster_type_id = TypeID,
        monster_refresh_args = RefreshArgs,
        monster_refresh_min = RefreshMin} = get_mythical_config(MapID),
    MonsterRefreshTime = Now + erlang:max(RefreshMin * ?ONE_MINUTE, 30),
    ?TRY_CATCH(mod_map_world_boss:monster_refresh(MapID, MonsterRefreshTime, TypeID, RefreshArgs)),
    common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_MONSTER_REFRESH, [map_misc:get_map_name(MapID), monster_misc:get_monster_name(TypeID)]),
    MonsterRefreshTime.

do_loop_ancients_refresh(Now) ->
    List = get_ancients_refresh(),
    List2 =
        [begin
             #r_ancients_refresh{
                 map_id = MapID,
                 is_collect_remain = IsCollectRemain,
                 collect_refresh_time = CollectRefreshTime,
                 is_monster_remain = IsMonsterRemain,
                 monster_refresh_time = MonsterRefreshTime} = Refresh,
             {IsCollectRemain2, CollectRefreshTime2} =
                 if
                     not IsCollectRemain andalso CollectRefreshTime - Now =< ?ONE_MINUTE -> %% 1分钟没提醒过，要去提醒~
                         #c_ancients_refresh{collect_type_id = CollectTypeID} = get_ancients_config(MapID),
                         common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, CollectTypeID, ?CARE_NOTICE_REFRESH}}),
                         {true, CollectRefreshTime};
                     Now >= CollectRefreshTime ->
                         CollectRefreshTimeT = do_ancients_collect_refresh(Now, MapID),
                         {false, CollectRefreshTimeT};
                     true ->
                         {IsCollectRemain, CollectRefreshTime}
                 end,
             {IsMonsterRemain2, MonsterRefreshTime2} = {IsMonsterRemain, MonsterRefreshTime},
%%                 if
%%                     not IsMonsterRemain andalso MonsterRefreshTime - Now =< ?ONE_MINUTE -> %% 1分钟没提醒过，要去提醒~
%%                         #c_ancients_refresh{monster_type_id = MonsterTypeID} = get_ancients_config(MapID),
%%                         common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, MonsterTypeID, ?CARE_NOTICE_REFRESH}}),
%%                         {true, MonsterRefreshTime};
%%                     Now >= MonsterRefreshTime ->
%%                         MonsterRefreshTimeT = do_ancients_monster_refresh(Now, MapID),
%%                         {false, MonsterRefreshTimeT};
%%                     true ->
%%                         {IsMonsterRemain, MonsterRefreshTime}
%%                 end,
             Refresh#r_ancients_refresh{
                 is_collect_remain = IsCollectRemain2,
                 collect_refresh_time = CollectRefreshTime2,
                 is_monster_remain = IsMonsterRemain2,
                 monster_refresh_time = MonsterRefreshTime2}
         end || Refresh <- List],
    set_ancients_refresh(List2).

do_ancients_collect_refresh(Now, MapID) ->
    #c_ancients_refresh{
        collect_type_id = TypeID,
        collect_num = CollectNum,
        collect_pos = CollectPos,
        refresh_hour_list = RefreshHourList}  = get_ancients_config(MapID),
    CollectRefreshTime = get_ancients_refresh_time(Now, RefreshHourList),
    ?TRY_CATCH(mod_map_world_boss:collect_refresh(MapID, CollectRefreshTime, TypeID, CollectNum, CollectPos)),
    common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_COLLECT_REFRESH, [map_misc:get_map_name(MapID), mod_collection:get_collection_name(TypeID)]),
    CollectRefreshTime.

%%do_ancients_monster_refresh(Now, MapID) ->
%%    #c_ancients_refresh{
%%        monster_type_id = TypeID,
%%        monster_refresh_args = RefreshArgs,
%%        refresh_hour_list = RefreshHourList} = get_ancients_config(MapID),
%%    MonsterRefreshTime = get_ancients_refresh_time(Now, RefreshHourList),
%%    ?TRY_CATCH(mod_map_world_boss:monster_refresh(MapID, MonsterRefreshTime, TypeID, RefreshArgs)),
%%    common_broadcast:send_world_common_notice(?NOTICE_MYTHICAL_MONSTER_REFRESH, [map_misc:get_map_name(MapID), monster_misc:get_monster_name(TypeID)]),
%%    MonsterRefreshTime.

do_boss_dead(TypeID, KillRoleID, KillRoleName) ->
    [#c_world_boss{
        boss_type = BossType,
        type = Type,
        map_id = MapID,
        refresh_interval = Interval,
        first_day_interval = ActInterval} = Config] = lib_config:find(cfg_world_boss, TypeID),
    case ?IS_WORLD_BOSS_TYPE(BossType) of
        true ->
            [Info] = get_world_boss(TypeID),
            %% 第一种地图的boss，死亡时给奖励
            #r_world_boss{kill_list = KillList} = Info,
            BossKill = #r_world_boss_kill{kill_role_id = KillRoleID, kill_role_name = KillRoleName, time = time_tool:now()},
            KillList2 = lists:sublist([BossKill|KillList], ?MAX_KILL_LOGS),
            Now = time_tool:now(),
            NextRefreshTime =
                if
                    Type =:= ?BOSS_TYPE_ANCIENTS -> %% 远古遗迹读配置表
                        ?TRY_CATCH(do_ancients_born_hidden_boos(KillRoleName, Config)),
                        Now + Interval;
                    Type =:= ?BOSS_TYPE_WORLD_BOSS -> %% 世界boss，刷新根据人数动态变化
                        FirstInterval = do_first_boss_time(Info, Config),
                        Now + FirstInterval;
                    Type =:= ?BOSS_TYPE_FAMILY -> %% 洞天福地, 活动时间内，boss死亡复活时间减半
                        Interval2 = ?IF(world_act_server:is_act_open(?ACT_CAVE_BOSS_DOUBLE), ActInterval, Interval),
                        Now + Interval2;
                    true ->
                        Now + Interval
                end,
            Info2 = Info#r_world_boss{is_alive = false, is_remind = false, next_refresh_time = NextRefreshTime, kill_list = KillList2},
            Info3 = ?IF(Type =:= ?BOSS_TYPE_WORLD_BOSS, do_first_boss_dead(Info2, KillRoleID, MapID, KillRoleName), Info2),
            set_world_boss(Info3),
            map_misc:info(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), {mod, mod_map_world_boss, {boss_dead, TypeID, NextRefreshTime}}),
            common_broadcast:bc_role_info_to_world({mod, mod_role_world_boss, {care_notice, TypeID, ?CARE_NOTICE_DEAD}});
        _ ->
            ?IF(BossType =:= ?BOSS_TYPE_HIDDEN_BOSS, do_hidden_boss_dead(TypeID, MapID), ok)
    end.

do_first_boss_dead(Info, KillRoleID, MapID, KillRoleName) ->
    #r_world_boss{type_id = TypeID, boss_extra = BossExtra = #r_first_boss{reward_roles = RewardRoles}} = Info,
    [ mod_role_world_boss:first_boss_drop(RewardRoleID, KillRoleID, KillRoleName, TypeID, MapID) || RewardRoleID <- RewardRoles],
    Info#r_world_boss{boss_extra = BossExtra#r_first_boss{reward_roles = []}}.

do_first_boss_time(Info, Config) ->
    #r_world_boss{boss_extra = #r_first_boss{reward_roles = RewardRoles}} = Info,
    RoleNum = erlang:length(RewardRoles),
    #c_world_boss{
        type_id = TypeID,
        refresh_interval = NormalInterval,
        first_day_interval = FirstDayInterval,
        role_num1 = RoleNum1,
        add_time_rate = AddTimeRate,
        role_num2 = RoleNum2,
        reduce_time_rate = ReduceTimeRate
    } = Config,
    Interval = ?IF(common_config:get_open_days() =:= 1, FirstDayInterval, NormalInterval),
    Multi = get_first_boss_time_multi(TypeID),
        if

            RoleNum =< RoleNum1 andalso RoleNum1 =/= 0 ->
                [AddRate, MaxRate] = AddTimeRate,
                MaxTime = lib_tool:ceil(Interval * MaxRate/?RATE_10000),
                Multi2 = ?IF(Multi > 0, Multi + 1, 1),
                set_first_boss_time_multi(TypeID, Multi2),
                FirstDayTime = lib_tool:ceil(Interval * math:pow((1 + AddRate/?RATE_10000), Multi2)),
                erlang:min(MaxTime, FirstDayTime);
            RoleNum >= RoleNum2 andalso RoleNum2 =/= 0 ->
                [ReduceRate, MinReduceRate] = ReduceTimeRate,
                MinTime = lib_tool:ceil(Interval * MinReduceRate/?RATE_10000),
                Multi2 = ?IF(Multi < 0, Multi - 1, -1),
                set_first_boss_time_multi(TypeID, Multi2),
                FirstDayTime = lib_tool:ceil(Interval * math:pow((1 - ReduceRate/?RATE_10000), erlang:abs(Multi2))),
                erlang:max(MinTime, FirstDayTime);
            true ->
                set_first_boss_time_multi(TypeID, 0),
                Interval
        end.

do_add_drop_log(AddRareLogs, AddNormalLogs) ->
    {RareLogs, NormalLogs} = world_data:get_boss_drop_logs(),
    RareLogs2 = lists:sublist(AddRareLogs ++ RareLogs, ?MAX_DROP_LOGS),
    NormalLogs2 = lists:sublist(AddNormalLogs ++ NormalLogs, ?MAX_DROP_LOGS),
    world_data:set_boss_drop_logs({RareLogs2, NormalLogs2}).

%% 初始boss增加奖励人数
do_add_reward_role(RoleID, TypeID) ->
    [#r_world_boss{boss_extra = BossExtra} = WorldBoss] = get_world_boss(TypeID),
    #r_first_boss{reward_time = RewardTime, reward_roles = RewardRoles} = BossExtra,
    [_Times, _MaxResumeTimes, _ResumeTime, RewardConfigTime|_] = common_misc:get_global_list(?GLOBAL_FIRST_BOSS),
    RewardTime2 = ?IF(RewardRoles =:= [], time_tool:now() + RewardConfigTime, RewardTime),
    RewardRoles2 = [RoleID|lists:delete(RoleID, RewardRoles)],
    BossExtra2 = BossExtra#r_first_boss{reward_time = RewardTime2, reward_roles = RewardRoles2},
    WorldBoss2 = WorldBoss#r_world_boss{boss_extra = BossExtra2},
    set_world_boss(WorldBoss2).

do_role_first_boss_enter(RoleID, TypeID) ->
    [#r_world_boss{boss_extra = BossExtra} = WorldBoss] = get_world_boss(TypeID),
    #r_first_boss{online_roles = OnlineRoles} = BossExtra,
    OnlineRoles2 = [RoleID|lists:delete(RoleID, OnlineRoles)],
    BossExtra2 =  BossExtra#r_first_boss{online_roles = OnlineRoles2},
    WorldBoss2 = WorldBoss#r_world_boss{boss_extra = BossExtra2},
    set_world_boss(WorldBoss2).

do_role_first_boss_leave(RoleID, TypeID) ->
    [#r_world_boss{boss_extra = BossExtra} = WorldBoss] = get_world_boss(TypeID),
    #r_first_boss{online_roles = OnlineRoles} = BossExtra,
    OnlineRoles2 = lists:delete(RoleID, OnlineRoles),
    BossExtra2 =  BossExtra#r_first_boss{online_roles = OnlineRoles2},
    WorldBoss2 = WorldBoss#r_world_boss{boss_extra = BossExtra2},
    set_world_boss(WorldBoss2).

do_role_enter_boss(RoleID, MapID) ->
    Key = get_map_to_floor(MapID),
    #r_floor_role{role_list = RoleList} = FloorRole = get_floor_role(Key),
    RoleList2 = [RoleID|lists:delete(RoleID, RoleList)],
    FloorRole2 = FloorRole#r_floor_role{role_list = RoleList2, role_num = erlang:length(RoleList2)},
    set_floor_role(FloorRole2).

do_role_leave_boss(RoleID, MapID) ->
    Key = get_map_to_floor(MapID),
    #r_floor_role{role_list = RoleList} = FloorRole = get_floor_role(Key),
    RoleList2 = lists:delete(RoleID, RoleList),
    FloorRole2 = FloorRole#r_floor_role{role_list = RoleList2, role_num = erlang:length(RoleList2)},
    set_floor_role(FloorRole2).

do_cave_act_change(Status) ->
    [ begin
          [#c_world_boss{
              type = Type,
              map_id = MapID,
              refresh_interval = Interval,
              first_day_interval = ActInterval}] = lib_config:find(cfg_world_boss, TypeID),
          case Type =:= ?BOSS_TYPE_FAMILY of
              true ->
                  case Status of
                      ?ACT_STATUS_OPEN ->
                          set_world_boss(WorldBoss#r_world_boss{next_refresh_time = 0});
                      ?ACT_STATUS_CLOSE ->
                          NextRefreshTime2 = OldRefreshTime + Interval - ActInterval,
                          map_misc:info(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), {mod, mod_map_world_boss, {boss_dead, TypeID, NextRefreshTime2}}),
                          set_world_boss(WorldBoss#r_world_boss{next_refresh_time = NextRefreshTime2})
                  end;
              _ ->
                  ok
          end
      end || #r_world_boss{type_id = TypeID, is_alive = IsAlive, next_refresh_time = OldRefreshTime} = WorldBoss <- get_all_world_boss(), IsAlive =:= false].

do_gm_clear_boss_cd() ->
    List = [ Info#r_world_boss{next_refresh_time = 0}|| Info <- get_all_world_boss()],
    set_world_boss(List).

do_clear_the_world_boss_cd(TypeID) ->   %% 刷新某个世界boss 必须是死的boss不然报错
    case catch do_clear_the_world_boss_cd2(TypeID) of
        {ok, TypeID} ->
            {ok, TypeID};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

do_clear_the_world_boss_cd2(TypeID) ->
    [#r_world_boss{is_alive = IsAlive} = TheWorldBoss] = get_world_boss(TypeID),
    ?IF(IsAlive, ?THROW_ERR(?ERROR_ITEM_USE_019), ok),
    RefreshTheWorldBoss = TheWorldBoss#r_world_boss{next_refresh_time = 0},
    set_world_boss(RefreshTheWorldBoss),
    {ok, TypeID}.

do_clear_all_floor_world_boss(MapID) ->
    BossList = get_all_world_boss(),
    NewBossList = do_clear_all_floor_world_boss2(BossList, MapID, []),
    set_world_boss(NewBossList).

do_clear_all_floor_world_boss2([], _MapID, BossAcc) ->
    BossAcc;
do_clear_all_floor_world_boss2([WorldBoss|R], MapID, BossAcc) ->
    #r_world_boss{type_id = TypeID} = WorldBoss,
    [#c_world_boss{map_id = ConfigMapID}] = lib_config:find(cfg_world_boss, TypeID),
    WorldBoss2 = ?IF(MapID =:= ConfigMapID, WorldBoss#r_world_boss{next_refresh_time = 0}, WorldBoss),
    do_clear_all_floor_world_boss2(R, MapID, [WorldBoss2|BossAcc]).

do_gm_clear_mythical_cd() ->
    List =
        [ MythicalRefresh#r_mythical_refresh{
            collect_refresh_time = time_tool:now() + 2,
            monster_refresh_time = time_tool:now() + 2}|| MythicalRefresh<- get_mythical_refresh()],
    set_mythical_refresh(List).

do_gm_clear_ancients_cd() ->
    List =
        [ AncientRefresh#r_ancients_refresh{
            collect_refresh_time = time_tool:now() + 2,
            monster_refresh_time = time_tool:now() + 2}|| AncientRefresh <- get_ancients_refresh()],
    set_ancients_refresh(List).

do_get_cross_world_boss_info(Type, Floor) ->
    BossList = get_all_world_boss(),
    #r_floor_role{role_num = RoleNum} = get_floor_role({Type, Floor}),
    {ok, BossList, RoleNum}.

do_zero() ->
    List = [ Info#r_world_boss{kill_list = []}|| Info <- get_all_world_boss()],
    set_world_boss(List).

do_ancients_born_hidden_boos(KillRoleName, Config) ->
    #c_world_boss{
        map_id = MapID,
        hidden_boss_rates = HiddenBossRates} = Config,
    RefreshList = get_ancients_refresh(),
    Refresh = lists:keyfind(MapID, #r_ancients_refresh.map_id, RefreshList),
    #r_ancients_refresh{hidden_boss = HiddenBoss} = Refresh,
    #c_ancients_refresh{hidden_boss_pos = HiddenPosList} = get_ancients_config(MapID),
    HiddenBossRates2 = lib_tool:string_to_intlist(HiddenBossRates, ",", ":"),
    HiddenPosList2 = lib_tool:string_to_intlist(HiddenPosList, ":", ","),
    case do_ancients_born_hidden_boos2(HiddenBossRates2, HiddenPosList2, HiddenBoss) of
        {ok, BornTypeID, BornPos, BossList, HiddenBoss2} ->
            Refresh2 = Refresh#r_ancients_refresh{hidden_boss = HiddenBoss2},
            RefreshList2 = lists:keystore(MapID, #r_ancients_refresh.map_id, RefreshList, Refresh2),
            set_ancients_refresh(RefreshList2),
            map_misc:info(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), {mod, mod_map_world_boss, {born_hidden_boss, BornTypeID, BornPos, BossList}}),
            common_broadcast:send_world_common_notice(?NOTICE_HIDDEN_BOSS_BORN, [KillRoleName, monster_misc:get_monster_name(BornTypeID)]);
        _ ->
            ok
    end.

do_ancients_born_hidden_boos2([], _HiddenPosList, _HiddenBoss) ->
    false;
do_ancients_born_hidden_boos2([{Rate, BossTypeID}|R], HiddenPosList, HiddenBoss) ->
    case common_misc:is_active(Rate) of
        true ->
            #r_ancients_hidden_boss{pos_list = PosList, boss_list = BossList} = HiddenBoss,
            [#c_world_boss{hidden_boss_num = MaxNum}] = lib_config:find(cfg_world_boss, BossTypeID),
            {KV, BossList2} =
                case lists:keytake(BossTypeID, #p_kv.id, BossList) of
                    {value, KVT, BossListT} ->
                        {KVT, BossListT};
                    _ ->
                        {#p_kv{id = BossTypeID, val = 0}, BossList}
                end,
            #p_kv{val = OldNum} = KV,
            case OldNum >= MaxNum of
                true ->
                    do_ancients_born_hidden_boos2(R, HiddenPosList, BossList);
                _ ->
                    KV2 = KV#p_kv{val = OldNum + 1},
                    BornPos = lib_tool:random_element_from_list(HiddenPosList -- PosList),
                    PosList2 = [BornPos|PosList],
                    BossList3 = [KV2|BossList2],
                    HiddenBoss2 = HiddenBoss#r_ancients_hidden_boss{pos_list = PosList2, boss_list = BossList3},
                    {ok, BossTypeID, BornPos, BossList3, HiddenBoss2}
            end;
        _ ->
            do_ancients_born_hidden_boos2(R, HiddenPosList, HiddenBoss)
    end.

do_hidden_boss_dead(TypeID, MapID) ->
    RefreshList = get_ancients_refresh(),
    {value, Refresh, RefreshList2} = lists:keytake(MapID, #r_ancients_refresh.map_id, RefreshList),
    #r_ancients_refresh{hidden_boss = HiddenBoss} = Refresh,
    #r_ancients_hidden_boss{boss_list = BossList} = HiddenBoss,
    {value, #p_kv{val = Num} = KV, BossList2} = lists:keytake(TypeID, #p_kv.id, BossList),
    Num2 = Num - 1,
    BossList3 = [KV#p_kv{val = Num2}|BossList2],
    HiddenBoss2 = HiddenBoss#r_ancients_hidden_boss{boss_list = BossList3},
    Refresh2 = Refresh#r_ancients_refresh{hidden_boss = HiddenBoss2},
    RefreshList3 = [Refresh2|RefreshList2],
    set_ancients_refresh(RefreshList3),
    map_misc:info(map_misc:get_map_pname(MapID, ?DEFAULT_EXTRA_ID), {mod, mod_map_world_boss, {change_hidden_boss_list, BossList3}}).

get_ancients_refresh_time(Now, RefreshHourList) ->
    RefreshHourList2 = lists:sort(RefreshHourList),
    {Date, {Hour, _Min, _Sec}} = time_tool:timestamp_to_datetime(Now),
    case get_ancients_refresh_time2(Hour, RefreshHourList2) of
        {ok, RefreshHour} ->
            time_tool:timestamp({Date, {RefreshHour, 0, 0}});
        _ -> %% 下一天
            [FirstHour|_] =  RefreshHourList2,
            time_tool:timestamp({Date, {FirstHour, 0, 0}}) + ?ONE_DAY
    end.

get_ancients_refresh_time2(_Hour, []) ->
    false;
get_ancients_refresh_time2(Hour, [ConfigHour|R]) ->
    ?IF(ConfigHour > Hour, {ok, ConfigHour}, get_ancients_refresh_time2(Hour, R)).

get_boss_extra(?BOSS_TYPE_WORLD_BOSS) ->
    #r_first_boss{};
get_boss_extra(_Type) ->
    undefined.

do_i() ->
    {get_ancients_refresh(), get_mythical_refresh()}.
%%%===================================================================
%%% dict
%%%===================================================================
get_all_world_boss() ->
    db:table_all(?DB_WORLD_BOSS_P).

set_world_boss(Info) ->
    db:insert(?DB_WORLD_BOSS_P, Info).
get_world_boss(TypeID) ->
    ets:lookup(?DB_WORLD_BOSS_P, TypeID).
del_world_boss(TypeID) ->
    db:delete(?DB_WORLD_BOSS_P, TypeID).

get_mythical_config(MapID) ->
    [Config] = lib_config:find(cfg_mythical_refresh, MapID),
    Config.

get_ancients_config(MapID) ->
    [Config] = lib_config:find(cfg_ancients_refresh, MapID),
    Config.

set_mythical_refresh(List) ->
    erlang:put({?MODULE, mythical_refresh}, List).
get_mythical_refresh() ->
    erlang:get({?MODULE, mythical_refresh}).

set_ancients_refresh(List) ->
    erlang:put({?MODULE, ancients_refresh}, List).
get_ancients_refresh() ->
    erlang:get({?MODULE, ancients_refresh}).

get_map_to_floor(MapID) ->
    erlang:get({?MODULE, map_to_floor, MapID}).
set_map_to_floor(MapID, Key) ->
    erlang:put({?MODULE, map_to_floor, MapID}, Key).

get_first_boss_time_multi(TypeID) ->
    case erlang:get({first_boss_time_multi, TypeID}) of
        Multi when erlang:is_integer(Multi) ->
            Multi;
        _ ->
            0
    end.
set_first_boss_time_multi(TypeID, Multi) ->
    erlang:put({first_boss_time_multi, TypeID}, Multi).

get_floor_role(Key) ->
    case ets:lookup(?ETS_FLOOR_ROLE, Key) of
        [#r_floor_role{} = FloorRole] ->
            FloorRole;
        _ ->
            #r_floor_role{key = Key}
    end.
set_floor_role(FloorRole) ->
    ets:insert(?ETS_FLOOR_ROLE, FloorRole).