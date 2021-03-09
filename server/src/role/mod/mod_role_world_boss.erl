%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%  世界boss
%%% @end
%%% Created : 17. 一月 2018 17:50
%%%-------------------------------------------------------------------
-module(mod_role_world_boss).
-author("laijichang").
-include("role.hrl").
-include("copy.hrl").
-include("family.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("daily_liveness.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_world_boss.hrl").
-include("proto/mod_role_item.hrl").
-include("proto/mod_map_demon_boss.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    online/1,
    zero/1,
    loop/2,
    handle/2,
    role_pre_enter/2,
    role_enter_map/2,
    role_dead_notice/3,
    role_dead/1,
    level_up/3,
    vip_expire/1
]).

-export([
    add_item_times/2,
    add_mythical_times/2,
    cave_times_update/1
]).

-export([
    get_map_args/1,
    add_world_boss_drop/2,
    add_cave_assist_times/1,
    first_boss_drop/5,
    add_mythical_collect/3,
    add_ancients_time/2,
    kill_guide_boss/1,

    check_guide_boss/1,
    is_time_able/1,
    is_first_boss_able/2,
    check_first_boss/2,

    kill_world_boss/2,
    check_package_times/3,
    gm_clear_times/1,
    gm_reduce_time/2,
    gm_first_world_boss/1,
    clear_the_world_boss_cd/2,
    get_world_boss_guide/1,
    clear_world_boss_all_floor_cd/2
]).

-export([
    is_mythical_boss/1,
    get_first_boss_by_map_id/1
]).

-export([
    get_drop_and_panel_goods/2,
    get_first_boss_default_times/0
]).

init(#r_role{role_id = RoleID, role_world_boss = undefined} = State) ->
    RoleWorldBoss = #r_role_world_boss{role_id = RoleID},
    State#r_role{role_world_boss = RoleWorldBoss};
init(State) ->
    State.

zero(State) ->
    online(State).

day_reset(State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    role_misc:remove_buff(RoleID, ?TIRED_BUFF),
    [_AddScore, _AddNum, CaveAssistTimes|_] = common_misc:get_global_list(?GLOBAL_CAVE_BOSS),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{
        times = get_first_boss_default_times(),
        resume_times = 0,
        resume_time = 0,
        cave_times = 0,
        cave_assist_times = CaveAssistTimes,
        buy_times = 0,
        mythical_times = 0,
        mythical_item_times = 0,
        mythical_collect_times = 0,
        mythical_collect2_times = 0,
        collect_open_list = []},
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    update_role_map_args(State2),
    State2.

online(State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{
        times = Times,
        buy_times = BuyTimes,
        resume_times = ResumeTimes,
        resume_time = ResumeTime,
        hp_recover_time = HpRecoverTime,
        cave_times = CaveTimes,
        cave_assist_times = CaveAssistTime,
        mythical_times = MythicalTimes,
        mythical_item_times = MythicalItemTimes,
        mythical_collect_times = CollectTimes,
        mythical_collect2_times = Collect2Times,
        collect_open_list = ItemList,
        care_list = CareList,
        auto_care_id = AutoCareID,
        max_type_id = MaxTypeID,
        is_guide = IsGuide,
        merge_times = MergeTimes} = RoleWorldBoss,
    DataRecord = #m_world_boss_all_toc{
        times = Times,
        buy_times = BuyTimes,
        resume_times = ResumeTimes,
        resume_time = ResumeTime,
        hp_recover_time = HpRecoverTime,
        cave_times = CaveTimes,
        cave_assist_times = CaveAssistTime,
        mythical_times = MythicalTimes,
        mythical_item_times = MythicalItemTimes,
        mythical_collect_times = CollectTimes,
        mythical_collect2_times = Collect2Times,
        collect_open_list = ItemList,
        care_list = ?IF(AutoCareID > 0, [AutoCareID|CareList], CareList),
        max_type_id = MaxTypeID,
        is_guide = IsGuide,
        merge_times = MergeTimes
    },
    common_misc:unicast(RoleID, DataRecord),
    State.

%% 部分地图时间过了就会踢掉
loop(Now, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{quit_time = QuitTime} = RoleWorldBoss,
    MapID = RoleMap#r_role_map.map_id,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 蛮荒禁地 || 远古遗迹
            ?IF(mod_role_dict:get_pre_enter() =:= undefined andalso Now >= QuitTime, do_role_home(RoleID, MapID), ok);
        true ->
            ok
    end,
    do_first_boss_loop(Now, State).

do_first_boss_loop(Now, State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{
        times = Times,
        resume_times = ResumeTimes,
        resume_time = ResumeTime} = RoleWorldBoss,
    [ConfigTimes, MaxResumeTimes, ConfigResumeTime|_] = common_misc:get_global_list(?GLOBAL_FIRST_BOSS),
    case Times >= ConfigTimes orelse ResumeTimes >= MaxResumeTimes of
        true -> %% 当前次数已经最大 或者不能再恢复了
            State;
        _ ->
            case Now >= ResumeTime of
                true -> %%恢复次数
                    ExtraTime = Now - ResumeTime,
                    AddTimes = erlang:min(erlang:min(ExtraTime div ConfigResumeTime + 1, MaxResumeTimes - ResumeTimes), ConfigTimes - Times),
                    Times2 = Times + AddTimes,
                    ResumeTimes2 = ResumeTimes + AddTimes,
                    ResumeTime2 = ?IF(Times2 < ConfigTimes, Now + (ConfigResumeTime - ExtraTime rem ConfigResumeTime), 0),
                    common_misc:unicast(RoleID, #m_world_boss_times_toc{times = Times2, resume_times = ResumeTimes2, resume_time = ResumeTime2}),
                    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{
                        times = Times2,
                        resume_times = ResumeTimes2,
                        resume_time = ResumeTime2,
                        % 恢复血量次数清空
                        hp_recover_list = []},
                    State#r_role{role_world_boss = RoleWorldBoss2};
                _ ->
                    State
            end
    end.

add_world_boss_drop(RoleID, TypeID) ->
    role_misc:info_role(RoleID, ?MODULE, {add_world_boss_drop, TypeID}).

add_cave_assist_times(RoleID) ->
    role_misc:info_role(RoleID, ?MODULE, add_cave_assist_times).

%% @doc 获取引导次数
get_world_boss_guide(RoleID) ->
    pname_server:call(role_misc:pid(RoleID), {mod, ?MODULE, get_guide}).

%% @doc boss掉落
first_boss_drop(RoleID, KillRoleID, KillRoleName, TypeID, MapID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, ?MODULE, {first_boss_drop, KillRoleID, KillRoleName, TypeID, MapID});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, first_boss_drop, [RoleID, KillRoleID, KillRoleName, TypeID, MapID]})
    end.

add_mythical_collect(RoleID, MapID, TypeID) ->
    role_misc:info_role(RoleID, ?MODULE, {add_mythical_collect, MapID, TypeID}).

add_ancients_time(RoleID, ReduceTime) ->
    role_misc:info_role(RoleID, ?MODULE, {add_ancients_time, ReduceTime}).

kill_guide_boss(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, ?MODULE, kill_guide_boss);
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, kill_guide_boss, [RoleID]})
    end.

is_cave_max_times(_State) ->
    false.

is_mythical_max_times(MythicalTimes, MythicalItemTimes) ->
    get_mythical_times(MythicalTimes, MythicalItemTimes) =< 0.

%% @doc 世界boss引导检测
check_guide_boss(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{is_guide = IsGuide} = RoleWorldBoss,
    ?IF(IsGuide =:= ?COPY_BOSS_GUIDE, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok).

is_time_able(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{quit_time = QuitTime} = RoleWorldBoss,
    ?IF(time_tool:now() >= QuitTime andalso QuitTime =/= 0, false, true).

is_first_boss_able(MapID, State) ->
    BossTypeID = get_first_boss_by_map_id(MapID),
    is_reward_role(State#r_role.role_id, BossTypeID).

is_reward_role(RoleID, BossTypeID) ->
    [#r_world_boss{boss_extra = BossExtra}] = world_boss_server:get_world_boss(BossTypeID),
    is_reward_role2(RoleID, BossExtra).

is_reward_role2(RoleID, BossExtra) ->
    case BossExtra of
        #r_first_boss{reward_roles = RewardRoles} ->
            lists:member(RoleID, RewardRoles);
        _ ->
            ?ERROR_MSG("BossExtra Error : ~w", [BossExtra]),
            false
    end.

%% @doc 检测进入次数
check_first_boss(MapID, State) ->
    #r_role{role_id = RoleID, role_world_boss = #r_role_world_boss{times = Times, merge_times = MergeTimes}} = State,
    BossTypeID = get_first_boss_by_map_id(MapID),
    [#r_world_boss{is_alive = IsAlive, boss_extra = BossExtra}] = world_boss_server:get_world_boss(BossTypeID),
    case IsAlive of
        true ->
            case is_reward_role2(RoleID, BossExtra) of
                true ->
                    true;
                _ ->
                    Times >= erlang:max(1, MergeTimes)
            end;
        _ ->
            false
    end.


kill_world_boss(TypeID, State) ->
    FamilyID = State#r_role.role_attr#r_role_attr.family_id,
    case ?HAS_FAMILY(FamilyID) of
        true ->
            case lib_config:find(cfg_world_boss, TypeID) of
                [#c_world_boss{type = Type}] ->
                    if
%%                        Type =:= ?BOSS_TYPE_FAMILY ->
%%                            family_server:add_box(?GLOBAL_FAMILY_BOX_FUDI_BOSS, TypeID, FamilyID,State#r_role.role_id);
                        Type =:= ?BOSS_TYPE_WORLD_BOSS ->
                            family_server:add_box(?GLOBAL_FAMILY_BOX_WORLD_BOSS, TypeID, FamilyID,State#r_role.role_id);
                        true ->
                            ok
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end,
    State.

check_package_times(EffectType, UseNum, State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{collect_open_list = OpenList} = RoleWorldBoss,
    MaxUseTimes =
        if
            EffectType =:= ?ITEM_MYTHICAL_COLLECT ->
                [MaxUseTimesT|_] = common_misc:get_global_list(?GLOBAL_MYTHICAL_COLLECT),
                MaxUseTimesT;
            EffectType =:= ?ITEM_MYTHICAL_COLLECT2 ->
                [MaxUseTimesT|_] = common_misc:get_global_list(?GLOBAL_MYTHICAL_COLLECT2),
                MaxUseTimesT;
            EffectType =:= ?ITEM_LIMIT_ADD_ILLUSION ->
                common_misc:get_global_int(?GLOBAL_ILLUSION_ITEM_TIMES)
        end,
    {KV, OpenList2} =
        case lists:keytake(EffectType, #p_kv.id, OpenList) of
            {value, KVT, OpenListT} ->
                {KVT, OpenListT};
            _ ->
                {#p_kv{id = EffectType, val = 0}, OpenList}
        end,
    #p_kv{val = UseTimes} = KV,
    UseTimes2 = UseTimes + UseNum,
    ?IF(UseTimes2 > MaxUseTimes, ?THROW_ERR(?ERROR_ITEM_USE_013), ok),
    KV2 = KV#p_kv{val = UseTimes2},
    OpenList3 = [KV2|OpenList2],
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{collect_open_list = OpenList3},
    common_misc:unicast(RoleID, #m_mythical_item_times_toc{item_times = KV2}),
    State#r_role{role_world_boss = RoleWorldBoss2}.

get_map_args(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{
        cave_assist_times = CaveAssistTimes,
        mythical_times = MythicalTimes,
        mythical_item_times = MythicalItemTimes,
        mythical_collect_times = MythicalCollect,
        mythical_collect2_times = MythicalCollect2} = RoleWorldBoss,
    {get_cave_times(State), CaveAssistTimes, get_mythical_times(MythicalTimes, MythicalItemTimes), get_mythical_collect(MythicalCollect), get_mythical_collect2(MythicalCollect2)}.

get_first_boss_default_times() ->
    [Times, _MaxResumeTimes, _ResumeTime|_] = common_misc:get_global_list(?GLOBAL_FIRST_BOSS),
    Times.

get_first_boss_resume_time(Times, ResumeTime) ->
    case Times >= get_first_boss_default_times() of
        true ->
            0;
        _ ->
            [_ConfigTimes, _MaxResumeTimes, ConfigResumeTime|_] = common_misc:get_global_list(?GLOBAL_FIRST_BOSS),
            Now = time_tool:now(),
            ?IF(ResumeTime > Now, ResumeTime, Now + ConfigResumeTime)
    end.

get_cave_times(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{cave_times = CaveTimes} = RoleWorldBoss,
    AddTimes = mod_role_vip:get_add_cave_times(State),
    AddTimes - CaveTimes.

get_cave_assist_times(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{cave_assist_times = CaveAssistTimes} = RoleWorldBoss,
    CaveAssistTimes.

get_mythical_times(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{mythical_times = Times, mythical_item_times = ItemAddTimes} = RoleWorldBoss,
    get_mythical_times(Times, ItemAddTimes).
get_mythical_times(Times, ItemAddTimes) ->
    erlang:max(0, common_misc:get_global_int(?GLOBAL_MYTHICAL_TIMES) + ItemAddTimes - Times).

get_mythical_collect(MythicalCollect) when erlang:is_integer(MythicalCollect) ->
    common_misc:get_global_int(?GLOBAL_MYTHICAL_COLLECT) - MythicalCollect;
get_mythical_collect(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{mythical_collect_times = MythicalCollect} = RoleWorldBoss,
    get_mythical_collect(MythicalCollect).

get_mythical_collect2(MythicalCollect) when erlang:is_integer(MythicalCollect) ->
    common_misc:get_global_int(?GLOBAL_MYTHICAL_COLLECT2) - MythicalCollect;
get_mythical_collect2(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{mythical_collect2_times = MythicalCollect2} = RoleWorldBoss,
    get_mythical_collect2(MythicalCollect2).

gm_clear_times(State) ->
    #r_role{role_id = RoleID} = State,
    role_misc:remove_buff(RoleID, ?TIRED_BUFF),
    State2 = day_reset(State),
    update_role_map_args(State2),
    online(State2).

gm_reduce_time(State, RemainTime) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    case map_misc:is_world_boss_time_map(RoleMap#r_role_map.map_id) of
        true ->
            QuitTime = time_tool:now() + RemainTime,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = QuitTime},
            common_misc:unicast(RoleID, #m_world_boss_quit_time_toc{quit_time = QuitTime}),
            State#r_role{role_world_boss = RoleWorldBoss2};
        _ ->
            State
    end.

%% @doc gm世界boss引导
gm_first_world_boss(State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{is_guide = 0},
    common_misc:unicast(RoleID, #m_world_boss_guide_toc{is_guide = 0}),
    State#r_role{role_world_boss = RoleWorldBoss2}.

is_mythical_boss(TypeID) ->
    [#c_world_boss{boss_type = BossType, type = Type}] = lib_config:find(cfg_world_boss, TypeID),
    lists:member(Type, [?BOSS_TYPE_MYTHICAL, ?BOSS_TYPE_CROSS_MYTHICAL]) andalso ?IS_WORLD_BOSS_TYPE(BossType).

handle(get_guide, #r_role{role_world_boss = RoleWorldBoss} = State) ->
    #r_role_world_boss{is_guide = IsGuide} = RoleWorldBoss,
    {IsGuide, State};
handle({add_world_boss_drop, TypeID}, State) ->
    do_add_world_boss_drop(TypeID, State);
handle(add_cave_assist_times, State) ->
    do_add_cave_assist_times(State);
handle({first_boss_drop, KillRoleID, KillRoleName, TypeID, MapID}, State) ->
    do_first_boss_drop(KillRoleID, KillRoleName, TypeID, MapID, State);
handle({add_mythical_collect, MapID, TypeID}, State) ->
    do_add_mythical_collect(MapID, TypeID, State);
handle({add_ancients_time, ReduceTime}, State) ->
    do_add_ancients_time(ReduceTime, State);
handle(kill_guide_boss, State) ->
    do_kill_guide_boss(State);
handle({care_notice, TypeID, Type}, State) ->
    do_care_notice(TypeID, Type, State);
handle({#m_world_boss_info_tos{type = Type, floor = Floor}, RoleID, _PID}, State) ->
    do_info(RoleID, Type, Floor, State);
handle({#m_world_boss_log_tos{}, RoleID, _PID}, State) ->
    do_log(RoleID),
    State;
handle({#m_world_boss_care_tos{boss_type_id = BossTypeID, type = Type}, RoleID, _PID}, State) ->
    do_boss_care(RoleID, BossTypeID, Type, State);
handle({#m_world_boss_kill_tos{type_id = TypeID}, RoleID, _PID}, State) ->
    do_boss_kill(RoleID, TypeID, State);
handle({#m_world_boss_buy_times_tos{}, RoleID, _PID}, State) ->
    do_buy_times(RoleID, State);
handle({#m_world_boss_seek_help_tos{}, RoleID, _PID}, State) ->
    do_seek_help(RoleID, State);
handle({#m_world_boss_hp_recover_tos{}, RoleID, _PID}, State) ->
    do_hp_recover(RoleID, State);
handle({#m_world_boss_merge_times_tos{merge_times = MergeTimes}, RoleID, _PID}, State) ->
    do_set_merge(RoleID, MergeTimes, State).

%% @doc 预进
role_pre_enter(IsFirst, State) ->
    MapID = mod_role_data:get_role_map_id(State),
    case map_misc:is_world_boss_tired_map(MapID) of
        true ->
            case IsFirst of
                true ->
                    State;
                _ ->
                    FirstBossID = get_first_boss_by_map_id(MapID),
                    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
                    #r_role_world_boss{
                        times = Times,
                        resume_times = ResumeTimes,
                        resume_time = ResumeTime,
                        merge_times = MergeTimes,
                        merge_list = MergeList} = RoleWorldBoss,
                    case is_reward_role(RoleID, FirstBossID) of
                        true ->
                            State;
                        _ ->
                            EnterTimes = erlang:max(1, MergeTimes),
                            Times2 = Times - EnterTimes,
                            ResumeTime2 = get_first_boss_resume_time(Times2, ResumeTime),
                            common_misc:unicast(RoleID, #m_world_boss_times_toc{times = Times2, resume_times = ResumeTimes, resume_time = ResumeTime2}),
                            MergeList2 = lists:keystore(FirstBossID, #p_kv.id, MergeList, #p_kv{id = FirstBossID, val = EnterTimes}),
                            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{times = Times2, resume_time = ResumeTime2, merge_list = MergeList2},
                            world_boss_server:add_reward_role(State#r_role.role_id, FirstBossID),
                            ?TRY_CATCH(log_boss_tired(FirstBossID, Times, Times2, State)),
                            ?TRY_CATCH(mod_role_log_statistics:log_world_boss_tired(State, EnterTimes), Err2),
                            State2 = State#r_role{role_world_boss = RoleWorldBoss2},
                            FunList = [
                                fun(StateAcc) -> mod_role_resource:add_world_boss_times(EnterTimes, StateAcc) end
                            ],
                            role_server:execute_state_fun(FunList, State2)
                    end
            end;
        _ ->
            State
    end.

role_enter_map(IsFirstEnter, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    MapID = RoleMap#r_role_map.map_id,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    case map_misc:is_world_boss_tired_map(MapID) orelse map_misc:is_copy_guide_boss(MapID) of
        true ->
            Num = get_hp_recover_num(MapID, RoleWorldBoss#r_role_world_boss.hp_recover_list),
            common_misc:unicast(RoleID, #m_world_boss_hp_recover_num_toc{hp_recover_num = Num});
        _ ->
            ok
    end,
    mod_role_dict:cancel_home_ref(),
    case ?IS_WORLD_BOSS_SUB_TYPE(SubType) of
        true ->
            #r_role_world_boss{
                quit_time = QuitTime,
                mythical_times = MythicalTimes,
                mythical_item_times = MythicalItemTimes} = RoleWorldBoss,
            MapBossList = get_extra_boss_list(MapID, SubType, true) ++ get_map_boss(MapID),
            common_misc:unicast(RoleID, #m_world_boss_map_info_toc{boss_list = MapBossList}),
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_2 -> %% 洞天福地
                    ?IF(is_cave_max_times(State), role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID}), ok),
                    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = 0},
                    State#r_role{role_world_boss = RoleWorldBoss2};
                SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 有时间限制的地图
                    [#c_map_base{stay_time = StayTime}] = lib_config:find(cfg_map_base, MapID),
                    Now = time_tool:now(),
                    QuitTime2 = ?IF(IsFirstEnter, ?IF(Now >= QuitTime, Now, QuitTime), Now + StayTime),
                    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = QuitTime2},
                    common_misc:unicast(RoleID, #m_world_boss_quit_time_toc{quit_time = QuitTime2}),
                    State#r_role{role_world_boss = RoleWorldBoss2};
                SubType =:= ?SUB_TYPE_MYTHICAL_BOSS -> %% 神兽岛类型
                    ?IF(is_mythical_max_times(MythicalTimes, MythicalItemTimes),
                        role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID}),
                        ok),
                    State;
                true ->
                    State
            end;
        _ ->
            State
    end.


role_dead_notice(NowPos, SrcName, State) ->
    #r_role{role_attr = RoleAttr, role_map = RoleMap} = State,
    MapID = RoleMap#r_role_map.map_id,
    #r_role_attr{role_name = RoleName, family_id = FamilyID} = RoleAttr,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    case ?HAS_FAMILY(FamilyID) andalso lists:member(SubType, [?SUB_TYPE_WORLD_BOSS_2, ?SUB_TYPE_MYTHICAL_BOSS]) of
        true ->
            #r_pos{mx = Mx, my = My} = NowPos,
            {_Distance, TypeID} = get_nearest_boss(MapID, NowPos),
            case TypeID > 0 of
                true ->
                    RoleName = mod_role_data:get_role_name(State),
                    MapName = map_misc:get_map_name(MapID),
                    BossName = monster_misc:get_monster_name(TypeID),
                    StringPos = get_notice_sting_pos(MapID, Mx, My),
                    StringList = [RoleName, MapName, BossName, SrcName, StringPos],
                    common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_WORLD_BOSS_DEAD, StringList);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.


role_dead(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    MapID = RoleMap#r_role_map.map_id,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 幽冥禁地 && 远古遗迹
            #r_role_world_boss{quit_time = QuitTime} = RoleWorldBoss,
            QuitTime2 = QuitTime - ?DEAD_REDUCE_TIME,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = QuitTime2},
            common_misc:unicast(RoleID, #m_world_boss_quit_time_toc{quit_time = QuitTime2}),
            State#r_role{role_world_boss = RoleWorldBoss2};
        SubType =:= ?SUB_TYPE_WORLD_BOSS_2 -> %% Boss之家隔一段时间推出
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = time_tool:now()},
            do_role_home(RoleID, MapID),
            State#r_role{role_world_boss = RoleWorldBoss2};
        true ->
            State
    end.

level_up(OldLevel, Level, State) ->
    List = get_nearest_level_world_boss(OldLevel, Level),
    case List of
        [{_Level, TypeID}|_] ->
            #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
            #r_role_world_boss{care_list = CareList, auto_care_id = AutoCareID} = RoleWorldBoss,
            case lists:member(TypeID, CareList) orelse TypeID =:= AutoCareID of
                true -> %% 现在已经在关注列表
                    State;
                _ ->
                    ?IF(AutoCareID > 0, common_misc:unicast(RoleID, #m_world_boss_care_toc{boss_type_id = AutoCareID, type = 0}), ok),
                    common_misc:unicast(RoleID, #m_world_boss_care_toc{boss_type_id = TypeID, type = 1}),
                    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{auto_care_id = TypeID},
                    State#r_role{role_world_boss = RoleWorldBoss2}
            end;
        _ ->
            State
    end.

vip_expire(State) ->
    #r_role{role_id = RoleID} = State,
    do_set_merge(RoleID, 1, State).

add_item_times(AddTimes, State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{times = Times, resume_times = ResumeTimes, resume_time = ResumeTime} = RoleWorldBoss,
    Times2 = Times + AddTimes,
    ResumeTime2 = get_first_boss_resume_time(Times2, ResumeTime),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{times = Times2, resume_time = ResumeTime2},
    common_misc:unicast(RoleID, #m_world_boss_times_toc{times = Times2, resume_times = ResumeTimes, resume_time = ResumeTime2}),
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    State2.

add_mythical_times(AddTimes, State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{mythical_times = Times, mythical_item_times = ItemAddTimes} = RoleWorldBoss,
    ItemAddTimes2 = ItemAddTimes + AddTimes,
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{mythical_item_times = ItemAddTimes2},
    common_misc:unicast(RoleID, #m_mythical_boss_times_toc{times = Times, item_add_times = ItemAddTimes2}),
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    role_misc:remove_buff(RoleID, ?TIRED_BUFF),
    update_mythical_times(State2),
    State2.

cave_times_update(State) ->
    #r_role{role_id = RoleID} = State,
    case is_cave_max_times(State) of
        true ->
            role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID});
        _ ->
            role_misc:remove_buff(RoleID, ?TIRED_BUFF)
    end,
    update_cave_times(State).

%% 世界疲劳度地图或者时间扣除地图
do_add_world_boss_drop(TypeID, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    MapID = RoleMap#r_role_map.map_id,
    MonsterConfig = monster_misc:get_monster_config(TypeID),
    #c_monster{type_id = TypeID, rarity = Rarity} = MonsterConfig,
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    if
        SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS -> %% 蛮荒禁地
            #c_monster{cost_time = CostTime} = MonsterConfig,
            do_add_time_boss(RoleID, MapID, CostTime, RoleWorldBoss, State);
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS andalso Rarity =:= ?MONSTER_RARITY_WORLD_BOSS -> %% 神兽岛
            do_add_mythical_boss(RoleID, RoleWorldBoss, State);
        true ->
            State
    end.

%% 洞天福地boss挑战次数增加
%%do_add_cave_times(RoleID, RoleWorldBoss, State) ->
%%    #r_role_world_boss{cave_times = CaveTimes, cave_assist_times = CaveAssistTimes} = RoleWorldBoss,
%%    CaveTimes2 = CaveTimes + 1,
%%    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{cave_times = CaveTimes2},
%%    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
%%    ?IF(is_cave_max_times(State2), role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID}), ok),
%%    common_misc:unicast(RoleID, #m_cave_times_update_toc{cave_times = CaveTimes2, cave_assist_times = CaveAssistTimes}),
%%    update_cave_times(State2),
%%    State2.

%% 洞天福地boss援助次数增加
do_add_cave_assist_times(State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{cave_times = CaveTimes, cave_assist_times = CaveAssistTimes} = RoleWorldBoss,
    case CaveAssistTimes > 0 of
        true ->
            CaveAssistTimes2 = CaveAssistTimes - 1,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{cave_assist_times = CaveAssistTimes2},
            State2 = State#r_role{role_world_boss = RoleWorldBoss2},
            common_misc:unicast(RoleID, #m_cave_times_update_toc{cave_times = CaveTimes, cave_assist_times = CaveAssistTimes2}),
            update_cave_assist_times(State2),
            [TypeID, AddNum, _CaveAssistTimes|_] = common_misc:get_global_list(?GLOBAL_CAVE_BOSS),
            GoodsList = [#p_goods{type_id = TypeID, num = AddNum}],
            role_misc:create_goods(State2, ?ITEM_GAIN_CAVE_ASSIST, GoodsList);
        _ ->
            State
    end.


%% 神兽岛采集次数增加
do_add_mythical_collect(MapID, TypeID, State) ->
    #r_role{role_id = RoleID, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{mythical_collect_times = CollectTimes, mythical_collect2_times = Collect2Times} = RoleWorldBoss,
    #c_mythical_refresh{collect_type_id = CollectTypeID} = world_boss_server:get_mythical_config(MapID),
    case TypeID =:= CollectTypeID of
        true ->
            CollectTimes2 = CollectTimes + 1,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{mythical_collect_times = CollectTimes2},
            State2 = State#r_role{role_world_boss = RoleWorldBoss2},
            common_misc:unicast(RoleID, #m_mythical_collect_times_toc{collect_times = CollectTimes2}),
            update_mythical_collect(State2),
            State2;
        _ ->
            Collect2Times2 = Collect2Times + 1,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{mythical_collect2_times = Collect2Times2},
            State2 = State#r_role{role_world_boss = RoleWorldBoss2},
            common_misc:unicast(RoleID, #m_mythical_collect2_times_toc{collect2_times = Collect2Times2}),
            update_mythical_collect2(State2),
            State2
    end.

do_add_ancients_time(ReduceTime, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap, role_world_boss = RoleWorldBoss} = State,
    MapID = RoleMap#r_role_map.map_id,
    do_add_time_boss(RoleID, MapID, ReduceTime, RoleWorldBoss, State).

%% @doc 打完boss引导
do_kill_guide_boss(State) ->
    #r_role{role_attr = RoleAttr, role_world_boss = RoleWorldBoss} = State,
    #r_role_attr{role_id = RoleID, role_name = RoleName} = RoleAttr,
    #r_role_world_boss{is_guide = IsGuide} = RoleWorldBoss,
    case IsGuide =:= ?COPY_BOSS_GUIDE of
        true ->
            State;
        _ ->
            NewIsGuide = IsGuide + 1,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{is_guide = NewIsGuide, hp_recover_list = []},
            common_misc:unicast(RoleID, #m_world_boss_guide_toc{is_guide = NewIsGuide}),
%%            common_misc:unicast(State#r_role.role_id, #m_world_boss_first_kill_toc{}),
            State2 = do_guide_boss_drop(RoleID, RoleName, NewIsGuide, State),
            State2#r_role{role_world_boss = RoleWorldBoss2}
    end.

%% @doc 世界boss引导掉落
do_guide_boss_drop(RoleID, RoleName, Guide, State) ->
    [#c_copy_guide_boss{drop_list = DropIDList, owner_reward = OwnerReward}] = lib_config:find(cfg_copy_guide_boss, Guide),
    {GoodsList, PanelGoods, State2} = get_drop_and_panel_goods(DropIDList, State),
    {OwnerGoods, OwnerPanelGoods} = get_first_boss_owner_goods2(OwnerReward, 1),
    RewardGoods = OwnerGoods ++ GoodsList,
    PanelGoods2 = OwnerPanelGoods ++ PanelGoods,
    common_misc:unicast(RoleID, #m_boss_end_panel_toc{role_name = RoleName, goods = PanelGoods2}),
    role_misc:create_goods(State2, ?ITEM_GAIN_GUIDE_BOSS_REWARD, RewardGoods).

%% 看看是不是关注的boss刷新了
do_care_notice(TypeID, Type, State) ->
    #r_role{role_id = RoleID, role_world_boss = #r_role_world_boss{care_list = CareList, auto_care_id = AutoCareID}} = State,
    ?IF(lists:member(TypeID, CareList) orelse TypeID =:= AutoCareID,
        common_misc:unicast(RoleID, #m_world_boss_care_notice_toc{boss_type_id = TypeID, type = Type}),
        ok),
    State.

%% @doc boss物品掉落
%% 1：怪物配置
%% 2：获取掉落
%% 3：恢复血量次数，boss死亡归零
%% 4：触发活跃
do_first_boss_drop(KillRoleID, KillRoleName, TypeID, BossMapID, State) ->
    #r_role{role_id = RoleID, role_map = #r_role_map{map_id = MapID}, role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{hp_recover_list = HpRecoverList, merge_list = MergeList} = RoleWorldBoss,
    {_, DropIDList} = monster_misc:get_monster_exp_drop(TypeID),
    % 1
    #c_monster{level = MonsterLevel, monster_name = MonsterName, special_drop_id = SpecialDropID} = monster_misc:get_monster_config(TypeID),
    Times =
        case lists:keyfind(TypeID, #p_kv.id, MergeList) of
            #p_kv{val = TimesT} ->
                TimesT;
            _ ->
                1
        end,
    % 2
    State3 =
    case mod_role_data:get_role_level(State) - MonsterLevel =< common_misc:get_global_int(?GLOBAL_WORLD_BOSS_LEVEL) of
        true ->
            {OwnerGoods, OwnerPanels} = ?IF(KillRoleID =:= RoleID, get_first_boss_owner_goods(TypeID, Times), {[], []}),
            SpecialDrops = mod_role_extra:get_data(?EXTRA_KEY_SPECIAL_DROP_LIST, [], State),
            {DropIDList2, AddList} = hook_monster:get_special_drop(SpecialDrops, SpecialDropID),
            DropIDList3 = lists:flatten(lists:duplicate(Times, DropIDList ++ DropIDList2)),
            {GoodsList, PanelGoods, StateT} = get_drop_and_panel_goods(DropIDList3, State),
            State2 = mod_role_extra:do_add_special_drop(AddList, StateT),

            RewardGoods = OwnerGoods ++ GoodsList,
            PanelGoods2 = OwnerPanels ++ PanelGoods,
            Log = #log_world_boss_drop{
                boss_type_id = TypeID,
                drop_goods_list = common_misc:to_goods_string(RewardGoods),
                kill_role_names = unicode:characters_to_binary(KillRoleName)
            },
            mod_role_dict:add_background_logs(Log),
            ?TRY_CATCH(mod_role_extra:do_world_boss_drop(RewardGoods, TypeID, State2)),
            case map_misc:is_world_boss_tired_map(MapID) of
                true ->
                    % 结算面板
                    common_misc:unicast(RoleID, #m_boss_end_panel_toc{role_name = KillRoleName, goods = PanelGoods2}),
                    role_misc:create_goods(State2, ?ITEM_GAIN_FIRST_BOSS_REWARD, RewardGoods);
                _ ->
                    LetterInfo = #r_letter_info{
                        template_id = ?LETTER_TEMPLATE_WORLD_BOSS_REWARD,
                        action = ?ITEM_GAIN_FIRST_BOSS_REWARD,
                        goods_list = RewardGoods,
                        text_string = [MonsterName, lib_tool:to_list(MonsterLevel)]},
                    common_letter:send_letter(RoleID, LetterInfo),
                    State2
            end;
        _ ->
            State
    end,
    % 3
    NewHpRecoverList = lists:keydelete(BossMapID, 1, HpRecoverList),
    MergeList2 = lists:keystore(TypeID, #p_kv.id, MergeList, #p_kv{id = TypeID, val = 1}),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{hp_recover_list = NewHpRecoverList, merge_list = MergeList2},
    % 4
    State4 = State3#r_role{role_world_boss = RoleWorldBoss2},
    lists:foldl(
        fun(_Index, StateAcc) ->
            StateAcc2 = hook_role:kill_world_boss(TypeID, StateAcc),
            ?IF(KillRoleID =:= RoleID, mod_role_day_target:world_boss_owner(StateAcc2), StateAcc2)
        end, State4, lists:seq(1, Times)).

%% @doc 世界boss归属奖励
%% 世界boss表：cfg_world_boss
%% 返回 {Goods, PanelGoods}
get_first_boss_owner_goods(TypeID, Times) ->
    [#c_world_boss{owner_reward = OwnerReward}] = lib_config:find(cfg_world_boss, TypeID),
    get_first_boss_owner_goods2(OwnerReward, Times).

get_first_boss_owner_goods2(TypeIDList, Times) ->
    lists:foldl(
        fun(TypeID, {Acc1, Acc2}) ->
            {[#p_goods{type_id = TypeID, num = Times}|Acc1], [#p_kv{id = TypeID, val = Times}|Acc2]}
        end, {[], []}, TypeIDList).

%% 有时间限制的世界boss地图
do_add_time_boss(RoleID, MapID, ReduceTime, RoleWorldBoss, State) ->
    #r_role_world_boss{quit_time = QuitTime} = RoleWorldBoss,
    QuitTime2 = QuitTime - ReduceTime,
    ?IF(time_tool:now() >= QuitTime2, do_role_home(RoleID, MapID), ok),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{quit_time = QuitTime2},
    common_misc:unicast(RoleID, #m_world_boss_quit_time_toc{quit_time = QuitTime2}),
    State#r_role{role_world_boss = RoleWorldBoss2}.

%% 神兽岛
do_add_mythical_boss(RoleID, RoleWorldBoss, State) ->
    #r_role_world_boss{mythical_times = MythicalTimes, mythical_item_times = MythicalItemTimes} = RoleWorldBoss,
    MythicalTimes2 = MythicalTimes + 1,
    ?IF(is_mythical_max_times(MythicalTimes2, MythicalItemTimes), role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID}), ok),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{mythical_times = MythicalTimes2},
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    common_misc:unicast(RoleID, #m_mythical_times_update_toc{times = MythicalTimes2, item_add_times = MythicalItemTimes}),
    update_mythical_times(State2),
    State2.

do_info(RoleID, Type, Floor, State) ->
    {BossList, RoleNum} =
    case Type =:= ?BOSS_TYPE_CROSS_MYTHICAL orelse Type =:= ?BOSS_TYPE_ANCIENTS of
        true ->
            world_boss_server:get_cross_world_boss_info(Type, Floor);
        _ ->
            #r_floor_role{role_num = RoleNumT} = world_boss_server:get_floor_role({Type, Floor}),
            {world_boss_server:get_all_world_boss(), RoleNumT}
    end,
    {MapID, BossList2} = filter_by_map_id(BossList, RoleID, Type, Floor, 0, []),
    BossList3 = get_extra_boss_list(MapID) ++ BossList2,
    DataRecord = #m_world_boss_info_toc{boss_list = BossList3, role_num = RoleNum},
    common_misc:unicast(RoleID, DataRecord),
    State.

get_extra_boss_list(0) ->
    [];
get_extra_boss_list(MapID) ->
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    get_extra_boss_list(MapID, SubType).
get_extra_boss_list(MapID, SubType) ->
    get_extra_boss_list(MapID, SubType, false).

get_extra_boss_list(MapID, SubType, IsInMap) ->
    if
        SubType =:= ?SUB_TYPE_MYTHICAL_BOSS ->
            get_mythical_boss_list(MapID);
        SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
            get_ancients_boss_list(MapID, IsInMap);
        true ->
            []
    end.

get_mythical_boss_list(MapID) ->
    {CollectTypeID, CollectNum, CollectRefreshTime, MonsterTypeID, MonsterNum, MonsterRefreshTime} = mod_map_world_boss:get_mythical_info(MapID),
    Collect = #p_world_boss{
        map_id = MapID,
        type_id = CollectTypeID,
        is_alive = false,
        next_refresh_time = CollectRefreshTime,
        remain_num = CollectNum
    },
    Monster = #p_world_boss{
        map_id = MapID,
        type_id = MonsterTypeID,
        is_alive = false,
        next_refresh_time = MonsterRefreshTime,
        remain_num = MonsterNum
    },
    [Collect, Monster].

get_ancients_boss_list(MapID, IsInMap) ->
    {CollectTypeID, CollectNum, CollectRefreshTime, _MonsterTypeID, _MonsterNum, _MonsterRefreshTime, _MonsterAreaList, HiddenBossList} = mod_map_world_boss:get_ancients_info(MapID),
    Collect = #p_world_boss{
        map_id = MapID,
        type_id = CollectTypeID,
        is_alive = false,
        next_refresh_time = CollectRefreshTime,
        remain_num = CollectNum
    },
    case IsInMap of
        true ->
%%            MonsterList =
%%            [                     #p_world_boss{
%%                map_id = MapID,
%%                type_id = TypeID,
%%                is_alive = false,
%%                next_refresh_time = MonsterRefreshTime,
%%                remain_num = Num} || #p_kvt{type = TypeID, val = Num} <- MonsterAreaList],
            [Collect];
        _ ->
%%            Monster = #p_world_boss{
%%                map_id = MapID,
%%                type_id = MonsterTypeID,
%%                is_alive = false,
%%                next_refresh_time = MonsterRefreshTime,
%%                remain_num = MonsterNum
%%            },
            HiddenWorldBoss = [
                #p_world_boss{
                    map_id = MapID,
                    type_id = BossTypeID,
                    remain_num = BossNum
                } || #p_kv{id = BossTypeID, val = BossNum} <- HiddenBossList],
            [Collect|HiddenWorldBoss]
    end.

filter_by_map_id(_BossList, _RoleID, ?BOSS_TYPE_PERSONAL, Floor, MapIDAcc, _Acc) -> %% 个人boss特殊处理
    {MapIDAcc, [#p_world_boss{type_id = TypeID, map_id = BossMapID} ||
        {TypeID, #c_world_boss{map_id = BossMapID, boss_type = BossType, type = Type, floor = BossFloor}} <- cfg_world_boss:list(),
                Type =:= ?BOSS_TYPE_PERSONAL andalso BossFloor =:= Floor andalso ?IS_WORLD_BOSS_TYPE(BossType)]};
filter_by_map_id([], _RoleID, _Type, _Floor, MapID, Acc) ->
    {MapID, Acc};
filter_by_map_id([WorldBoss|R], RoleID, Type, Floor, MapIDAcc, Acc) ->
    #r_world_boss{type_id = TypeID, is_alive = IsAlive, next_refresh_time = NextFreshTime, boss_extra = BossExtra} = WorldBoss,
    [#c_world_boss{map_id = BossMapID, boss_type = BossType, type = ConfigType, floor = BossFloor}] = lib_config:find(cfg_world_boss, TypeID),
    case Type =:= ConfigType andalso BossFloor =:= Floor andalso ?IS_WORLD_BOSS_TYPE(BossType) of
        true ->
            {OnlineNum, CanEnter} =
            case BossExtra of
                #r_first_boss{reward_roles = RewardRoles, online_roles = OnlineRoles} ->
                    {erlang:length(OnlineRoles), lists:member(RoleID, RewardRoles)};
                _ ->
                    {0, false}
            end,
            PBoss = #p_world_boss{
                type_id = TypeID,
                is_alive = IsAlive,
                next_refresh_time = NextFreshTime,
                map_id = BossMapID,
                role_num = OnlineNum,
                can_enter = CanEnter},
            Acc2 = [PBoss|Acc],
            MapIDAcc2 = BossMapID;
        _ ->
            Acc2 = Acc,
            MapIDAcc2 = MapIDAcc
    end,
    filter_by_map_id(R, RoleID, Type, Floor, MapIDAcc2, Acc2).

do_log(RoleID) ->
    {RareLogs, NormalLogs} = world_data:get_boss_drop_logs(),
    common_misc:unicast(RoleID, #m_world_boss_log_toc{log_list = to_p_logs(RareLogs), normal_log_list = to_p_logs(NormalLogs)}).

to_p_logs(Logs) ->
    [ #p_world_boss_log{
        role_id = LogRoleID,
        role_name = common_role_data:get_role_name(LogRoleID),
        map_id = MapID,
        monster_type_id = MonsterTypeID,
        item_type_id = ItemTypeID,
        time = Time
    } || #r_world_boss_log{role_id = LogRoleID, map_id = MapID, monster_type_id = MonsterTypeID, item_type_id = ItemTypeID, time = Time} <- Logs].

%% 关注boss
do_boss_care(RoleID, BossTypeID, Type, State) ->
    case catch check_boss_care(BossTypeID, Type, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_world_boss_care_toc{boss_type_id = BossTypeID, type = Type}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_world_boss_care_toc{err_code = ErrCode}),
            State
    end.

check_boss_care(BossTypeID, Type, State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{care_list = CareList, auto_care_id = AutoCareID} = RoleWorldBoss,
    case lib_config:find(cfg_world_boss, BossTypeID) of
        [#c_world_boss{}] ->
            {CareList2, AutoCareID2} =
            case Type > 0 of
                true ->
                    ?IF(lists:member(BossTypeID, CareList) orelse BossTypeID =:= AutoCareID, ?THROW_ERR(?ERROR_WORLD_BOSS_CARE_001), ok),
                    {[BossTypeID|CareList], AutoCareID};
                _ ->
                    case lists:member(BossTypeID, CareList) of
                        true ->
                            {lists:delete(BossTypeID, CareList), AutoCareID};
                        _ ->
                            ?IF(AutoCareID =:= BossTypeID, ok, ?THROW_ERR(?ERROR_WORLD_BOSS_CARE_003)),
                            {CareList, 0}
                    end
            end,
            RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{care_list = CareList2, auto_care_id = AutoCareID2},
            State2 = State#r_role{role_world_boss = RoleWorldBoss2},
            {ok, State2};
        _ ->
            ?THROW_ERR(?ERROR_WORLD_BOSS_CARE_002)
    end.

do_boss_kill(RoleID, TypeID, State) ->
    [#c_world_boss{map_id = MapID}] = lib_config:find(cfg_world_boss, TypeID),
    TheWorldBoss = ?IF(map_misc:is_cross_map(MapID), world_boss_server:get_cross_world_boss(TypeID), world_boss_server:get_world_boss(TypeID)),
    List =
        case TheWorldBoss of
            [#r_world_boss{kill_list = KillList}] ->
                [#p_world_boss_kill{role_id = KillRoleID, role_name = KillRoleName, kill_time = Time}
                    || #r_world_boss_kill{kill_role_id = KillRoleID, kill_role_name = KillRoleName, time = Time} <- KillList];
            _ ->
                []
        end,
    common_misc:unicast(RoleID, #m_world_boss_kill_toc{kill_list = List}),
    State.

do_buy_times(RoleID, State) ->
    case catch check_buy_times(State) of
        {ok, Times2, BuyTimes2, ResumeTime2, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_world_boss_buy_times_toc{
                times = Times2,
                buy_times = BuyTimes2,
                resume_time = ResumeTime2
            }),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:buy_world_boss_times(1, StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_world_boss_buy_times_toc{err_code = ErrCode}),
            State
    end.

check_buy_times(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{
        times = Times,
        buy_times = BuyTimes,
        resume_time = ResumeTime
    } = RoleWorldBoss,
    NeedGold = common_misc:get_global_int(?GLOBAL_FIRST_BOSS),
    MaxTimes = mod_role_vip:get_vip_first_boss_times(State),
    ?IF(BuyTimes >= MaxTimes, ?THROW_ERR(?ERROR_WORLD_BOSS_BUY_TIMES_001), ok),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_FIRST_BOSS_BUY, State),
    Times2 = Times + 1,
    BuyTimes2 = BuyTimes + 1,
    ResumeTime2 = get_first_boss_resume_time(Times2, ResumeTime),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{
        times = Times2,
        buy_times = BuyTimes2,
        resume_time = ResumeTime2
    },
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    {ok, Times2, BuyTimes2, ResumeTime2, AssetDoings, State2}.

%% @doc boss求助
%% 向道庭发送公告
do_seek_help(RoleID, State) ->
    case catch check_seek_help(State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_world_boss_seek_help_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_world_boss_seek_help_toc{err_code = ErrCode}),
            State
    end.

check_seek_help(State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr, role_map = RoleMap} = State,
    #r_role_map{map_id = MapID} = RoleMap,
    MapID = RoleMap#r_role_map.map_id,
    #r_role_attr{role_name = RoleName, family_id = FamilyID} = RoleAttr,
    ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_WORLD_BOSS_SEEK_HELP_001)),
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
    SubTypeLists = common_misc:get_global_list(?GLOBAL_BOSS_SEEK_HELP),
    ?IF(lists:member(SubType, SubTypeLists), ok, ?THROW_ERR(?ERROR_WORLD_BOSS_SEEK_HELP_002)),
    {ok, #r_pos{mx = Mx, my = My} = RecordPos} = mod_map_role:role_get_pos(mod_role_dict:get_map_pid(), RoleID),  %% 得到玩家的场景内的坐标
    {_Distance, TypeID} = get_nearest_boss(MapID, RecordPos),
    RoleName = mod_role_data:get_role_name(State),
    MapName = map_misc:get_map_name(MapID),
    BossName = monster_misc:get_monster_name(TypeID),
    StringPos = get_notice_sting_pos(MapID, Mx, My),
    StringList = [RoleName, MapName, BossName, StringPos],
    common_broadcast:send_family_common_notice(FamilyID, ?NOTICE_BOSS_SEEK_HELP, StringList),
    {ok, State}.


%% @doc 恢复血量
do_hp_recover(RoleID, State) ->
    case catch check_hp_recover(State) of
        {ok, AssetDoings, HpRecoverNum, HpRecoverTime, AddHp, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_world_boss_hp_recover_toc{hp_recover_time = HpRecoverTime, hp_recover_num = HpRecoverNum}),
            mod_map_role:role_buff_heal(mod_role_dict:get_map_pid(), RoleID, AddHp, ?BUFF_ADD_HP, 0),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_world_boss_hp_recover_toc{err_code = ErrCode}),
            State
    end.

check_hp_recover(State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    #r_role_world_boss{hp_recover_time = HpRecoverTime, hp_recover_list = HpRecoverList} = RoleWorldBoss,
    MapID = mod_role_data:get_role_map_id(State),
    ?IF(map_misc:is_world_boss_tired_map(MapID) orelse map_misc:is_copy_guide_boss(MapID), ok, ?THROW_ERR(?ERROR_WORLD_BOSS_HP_RECOVER_001)),
    Now = time_tool:now(),
    ?IF(Now >= HpRecoverTime, ok, ?THROW_ERR(?ERROR_WORLD_BOSS_HP_RECOVER_002)),
    [HpRate, AssetType, CD|L] = common_misc:get_global_list(?GLOBAL_WORLD_BOSS_RECOVER),

    Num = get_hp_recover_num(MapID, HpRecoverList),
    HpRecoverNum = ?IF(Num < length(L), Num + 1, Num),
    NeedGold = lists:nth(HpRecoverNum, L),

    AssetDoings = mod_role_asset:check_asset_by_type(AssetType, NeedGold, ?ASSET_GOLD_REDUCE_FROM_WORLD_BOSS_HP, State),
    MaxHp = mod_role_data:get_role_max_hp(State),
    AddHp = lib_tool:ceil(MaxHp * HpRate / ?RATE_100),
    HpRecoverTime2 = Now + CD,
    NewHpRecoverList = lists:keystore(MapID, 1, HpRecoverList, {MapID, HpRecoverNum}),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{hp_recover_time = HpRecoverTime2, hp_recover_list = NewHpRecoverList},
    State2 = State#r_role{role_world_boss = RoleWorldBoss2},
    {ok, AssetDoings, HpRecoverNum, HpRecoverTime2, AddHp, State2}.

get_hp_recover_num(_MapID, []) ->
    0;
get_hp_recover_num(MapID, HpRecoverList) ->
    case lists:keyfind(MapID, 1, HpRecoverList) of
        {MapID, Nnm} ->
            Nnm;
        _ ->
            0
    end.

do_set_merge(RoleID, MergeTimes, State) ->
    #r_role{role_world_boss = RoleWorldBoss} = State,
    MergeTimes2 = erlang:max(1, erlang:min(MergeTimes, mod_role_vip:get_world_boss_merge_times(State))),
    RoleWorldBoss2 = RoleWorldBoss#r_role_world_boss{merge_times = MergeTimes2},
    common_misc:unicast(RoleID, #m_world_boss_merge_times_toc{merge_times = MergeTimes2}),
    State#r_role{role_world_boss = RoleWorldBoss2}.


do_role_home(RoleID, MapID) ->
    case mod_role_dict:get_home_ref() of
        Ref when erlang:is_reference(Ref) ->
            ok;
        _ ->
            #c_map_base{sub_type = SubType} = map_misc:get_map_base(MapID),
            if
                SubType =:= ?SUB_TYPE_WORLD_BOSS_4 orelse SubType =:= ?SUB_TYPE_ANCIENTS_BOSS ->
                    role_misc:add_buff(RoleID, #buff_args{buff_id = ?TIRED_BUFF, from_actor_id = RoleID}),
                    Time = common_misc:get_global_int(?GLOBAL_WORLD_BOSS_QUIT_TIME),
                    common_misc:unicast(RoleID, #m_world_boss_quit_time_toc{quit_time = time_tool:now()});
                SubType =:= ?SUB_TYPE_WORLD_BOSS_2 ->
                    [Time] = common_misc:get_global_list(?GLOBAL_WORLD_BOSS_QUIT_TIME)
            end,
            TimeRef = role_misc:info_role_after(Time * 1000, erlang:self(), {mod, mod_role_map, quit_map}),
            mod_role_dict:set_home_ref(TimeRef)
    end.

get_map_boss(MapID) ->
    BossList =
    case map_misc:is_cross_map(MapID) of
        true ->
            world_boss_server:get_cross_all_world_boss();
        _ ->
            world_boss_server:get_all_world_boss()
    end,
    get_map_boss2(MapID, BossList, []).

get_map_boss2(_MapID, [], Acc) ->
    Acc;
get_map_boss2(MapID, [WorldBoss|R], Acc) ->
    #r_world_boss{type_id = TypeID, is_alive = IsAlive, next_refresh_time = NextFreshTime} = WorldBoss,
    [#c_world_boss{map_id = BossMapID, boss_type = BossType}] = lib_config:find(cfg_world_boss, TypeID),
    case BossMapID =:= MapID andalso ?IS_WORLD_BOSS_TYPE(BossType) of
        true ->
            Acc2 = [#p_world_boss{map_id = MapID, type_id = TypeID, is_alive = IsAlive, next_refresh_time = NextFreshTime}|Acc],
            get_map_boss2(MapID, R, Acc2);
        _ ->
            get_map_boss2(MapID, R, Acc)
    end.

log_boss_tired(TypeID, Times, Times2, State) ->
    #r_role{role_id = RoleID} = State,
    Log =
    #log_boss_tired{
        role_id = RoleID,
        boss_type_id = TypeID,
        old_value = Times,
        new_value = Times2
    },
    mod_role_dict:add_background_logs(Log).

%% 更新在地图中的数据
update_role_map_args(State) ->
    {CaveTimes, CaveAssistTimes, MythicalTimes, MythicalCollect, MythicalCollect2} = get_map_args(State),
    UpdateList =
    [
        {#r_map_role.cave_times, CaveTimes},
        {#r_map_role.cave_assist_times, CaveAssistTimes},
        {#r_map_role.mythical_times, MythicalTimes},
        {#r_map_role.mythical_collect, MythicalCollect},
        {#r_map_role.mythical_collect2, MythicalCollect2}
    ],
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, UpdateList).

update_cave_times(State) ->
    CaveTimes = get_cave_times(State),
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, [{#r_map_role.cave_times, CaveTimes}]).

update_cave_assist_times(State) ->
    CaveAssistTimes = get_cave_assist_times(State),
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, [{#r_map_role.cave_assist_times, CaveAssistTimes}]).

update_mythical_times(State) ->
    MythicalTimes = get_mythical_times(State),
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, [{#r_map_role.mythical_times, MythicalTimes}]).

update_mythical_collect(State) ->
    MythicalTimes = get_mythical_collect(State),
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, [{#r_map_role.mythical_collect, MythicalTimes}]).

update_mythical_collect2(State) ->
    MythicalTimes2 = get_mythical_collect2(State),
    mod_map_role:update_role_map_args(mod_role_dict:get_map_pid(), State#r_role.role_id, [{#r_map_role.mythical_collect2, MythicalTimes2}]).

get_nearest_boss(MapID, NowPos) -> %% T 返回距离玩家最近的Boss的TypeID
    List = cfg_world_boss:list(),
    List2 = get_nearest_boss2(List, MapID, NowPos, []),
    [{Distance, TypeID}|_] = List2,  %% T 取这个列表中的第一个元素（boss距离和ID）
    {Distance, TypeID}.

get_nearest_boss2([], _MapID, _NowPos, Acc) ->   %% T 返回玩家到该场景中所有Boss的距离列表[]
    lists:keysort(1, Acc);
get_nearest_boss2([{TypeID, Config}|R], MapID, NowPos, Acc) ->
    #c_world_boss{boss_type = BossType, map_id = BossMapID, pos = ConfigPos} = Config,
    case BossMapID =:= MapID andalso ?IS_WORLD_BOSS_TYPE(BossType) andalso ConfigPos of
        [OffsetMx, OffsetMy|_] ->
            BossPos = map_misc:get_pos_by_map_offset_pos(MapID, OffsetMx, OffsetMy),
            Acc2 = [{map_misc:get_dis(NowPos, BossPos), TypeID}|Acc],
            get_nearest_boss2(R, MapID, NowPos, Acc2);
        _ ->
            get_nearest_boss2(R, MapID, NowPos, Acc)
    end.

get_nearest_level_world_boss(OldLevel, Level) ->
    ConfigList = lib_config:list(cfg_world_boss),
    lists:reverse(lists:keysort(1, get_nearest_level_world_boss2(ConfigList, OldLevel, Level, []))).

get_nearest_level_world_boss2([], _OldLevel, _Level, Acc) ->
    Acc;
get_nearest_level_world_boss2([{TypeID, Config}|R], OldLevel, Level, Acc) ->
    #c_world_boss{
        boss_type = BossType,
        type = Type,
        map_id = MapID
    } = Config,
    case TypeID =/= 210001 andalso ?IS_WORLD_BOSS_TYPE(BossType) andalso Type =:= ?BOSS_TYPE_WORLD_BOSS of
        true ->
            #c_map_base{min_level = MinLevel} = map_misc:get_map_base(MapID),
            Acc2 = ?IF(OldLevel < MinLevel andalso MinLevel =< Level, [{MinLevel, TypeID}|Acc], Acc),
            get_nearest_level_world_boss2(R, OldLevel, Level, Acc2);
        _ ->
            get_nearest_level_world_boss2(R, OldLevel, Level, Acc)
    end.

get_first_boss_by_map_id(MapID) ->
    ConfigList = lib_config:list(cfg_world_boss),
    get_first_boss_by_map_id2(MapID, ConfigList).

get_first_boss_by_map_id2(MapID, []) ->
    ?ERROR_MSG("FirstBoss Unknow MapID : ~w", [MapID]),
    0;
get_first_boss_by_map_id2(MapID, [{BossTypeID, #c_world_boss{map_id = ConfigMapID}}|R]) ->
    ?IF(MapID =:= ConfigMapID, BossTypeID, get_first_boss_by_map_id2(MapID, R)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 复活令：复活世界boss(包括神兽岛,幽冥地界)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear_the_world_boss_cd(EffectArgs, State) ->   %% EffectArgs 是可以使用的场景ID 用“，”分隔的string
    EffectArgsList = lib_tool:string_to_integer_list(EffectArgs),
    case catch check_clear_world_boss_cd(EffectArgsList, State) of
        {ok, IsCross, TypeID} ->
            case catch world_boss_server:clear_the_world_boss_cd(IsCross, TypeID) of   %% 在发送给server的时候有可能产生并发
                {ok, _TypeID} ->
                    State;
                {error, ErrCode} ->
                    ?THROW_ERR(ErrCode),
                    State
            end;
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode),
            State
    end.

check_clear_world_boss_cd(EffectArgs, State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    MapID = RoleMap#r_role_map.map_id,
    IsCross = map_misc:is_cross_map(MapID),
    InTheRightMap = lists:member(MapID, EffectArgs),
    ?IF(InTheRightMap, ok, ?THROW_ERR(?ERROR_ITEM_USE_018)),  %% 判断---1--- 在不在指定场景中？
    {ok, RecordPos} = mod_map_role:role_get_pos(mod_role_dict:get_map_pid(), RoleID),  %% 得到玩家的场景内的坐标
    {Distance, TypeID} = get_nearest_boss(MapID, RecordPos),
    case TypeID > 0 of
        true ->
            TheWorldBoss = ?IF(IsCross, world_boss_server:get_cross_world_boss(TypeID), world_boss_server:get_world_boss(TypeID)),
            case TheWorldBoss of
                [#r_world_boss{is_alive = IsAlive}] ->
                    ?IF(IsAlive, ?THROW_ERR(?ERROR_ITEM_USE_019), ok);
                _ ->
                    ok
            end;
        _ ->
            ?ERROR_MSG(?ERROR_ITEM_USE_019)
    end,
    ?IF(Distance =< 800, ok, ?THROW_ERR(?ERROR_ITEM_USE_020)),  %% 判断 ---3--- 看看到这个boss的距离，太远了返回错误码
    {ok, IsCross, TypeID}.

%% 返回{GoodsList, PanelGoods, State2}
get_drop_and_panel_goods(DropIDList, State) ->
    RoleIndexList = mod_role_extra:get_data(?EXTRA_KEY_ITEM_DROP_LIST, [], State),
    {RoleIndexList2, GoodsList, PanelGoods} = get_drop_and_panel_goods(DropIDList, RoleIndexList, [], []),
    State2 = mod_role_extra:do_item_control(RoleIndexList2, State),
    {GoodsList, PanelGoods, State2}.

get_drop_and_panel_goods([], RoleIndexList, GoodsAcc, PanelsAcc) ->
    {RoleIndexList, GoodsAcc, mod_map_demon_boss:sort_panel_goods(common_misc:merge_props(PanelsAcc))};
get_drop_and_panel_goods([DropID|R], RoleIndexList, GoodsAcc, PanelsAcc) ->
    Items = mod_map_drop:get_drop_item_list2(DropID),
    case Items =/= [] of
        true ->
            {IsDrop, RoleIndexList2} = mod_map_drop:do_role_item_control(DropID, RoleIndexList),
            case IsDrop of
                true ->
                    {AddGoods, AddPanels} =
                    lists:foldl(
                        fun({TypeID, Num, IsBind}, {Acc1, Acc2}) ->
                            NewAcc1 = [#p_goods{type_id = TypeID, num = Num, bind = IsBind}|Acc1],
                            NewAcc2 = [#p_kv{id = TypeID, val = Num}|Acc2],
                            {NewAcc1, NewAcc2}
                        end, {[], []}, Items),
                    get_drop_and_panel_goods(R, RoleIndexList2, AddGoods ++ GoodsAcc, AddPanels ++ PanelsAcc);
                _ ->
                    get_drop_and_panel_goods(R, RoleIndexList2, GoodsAcc, PanelsAcc)
            end;
        _ ->
            get_drop_and_panel_goods(R, RoleIndexList, GoodsAcc, PanelsAcc)
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 复活令：复活洞天福地【整层】的boss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear_world_boss_all_floor_cd(EffectArgs, State) ->  %% EffectArgs是场景ID的List
    EffectArgsList = lib_tool:string_to_integer_list(EffectArgs),
    case catch check_clear_world_boss_all_floor_cd(EffectArgsList, State) of
        {ok, MapID} ->
            world_boss_server:clear_all_floor_world_boss_cd(map_misc:is_cross_map(MapID), MapID),
            State;
        {error, ErrCode} ->
            ?THROW_ERR(ErrCode),
            State
    end.

check_clear_world_boss_all_floor_cd(EffectArgsList, State) ->
    #r_role{role_map = RoleMap} = State,
    MapID = RoleMap#r_role_map.map_id,
    InTheRightMap = lists:member(MapID, EffectArgsList),
    ?IF(InTheRightMap, ok, ?THROW_ERR(?ERROR_ITEM_USE_018)),  %% 判断---1--- 在不在指定场景中？
    {ok, MapID}.

get_notice_sting_pos(MapID, Mx, My) ->
    {OffsetMx, OffsetMy} = map_misc:get_offset_meter_by_map_id(MapID, Mx, My),
    lib_tool:to_list(MapID) ++ "_" ++ lib_tool:to_list(OffsetMx) ++ "_" ++ lib_tool:to_list(OffsetMy).