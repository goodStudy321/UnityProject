%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 五月 2017 19:10
%%%-------------------------------------------------------------------
-module(mod_role_mission).
-author("laijichang").
-include("role.hrl").
-include("world_boss.hrl").
-include("mission.hrl").
-include("monster.hrl").
-include("family.hrl").
-include("activity.hrl").
-include("fairy.hrl").
-include("copy.hrl").
-include("proto/mod_role_mission.hrl").


%% API
-export([
    init/1,
    day_reset/1,
    pre_enter/1,
    zero/1,
    handle/2
]).

-export([
    trigger_mission/4
]).

%% 角色内部调用
-export([
    kill_monster/2,
    finish_copy/2,
    daily_mission_trigger/2,
    power_trigger/1,
    refine_trigger/1,
    refine_num_trigger/1,
    refine_level_trigger/1,
    exp_trigger/2,
    daily_active_trigger/1,
    friend_trigger/1,
    world_boss_trigger/2,
    offline_solo_trigger/1,
    compose_trigger/2,
    item_trigger/2,
    confine_trigger/1,
    family_mission/1,
    family_escort/1,
    family_rob_escort/1,
    kill_five_elements_boss/2
]).

-export([
    get_mission_ids/1,
    is_main_mission_finish/2,
    get_main_mission_id/1,
    get_main_mission_id_status/1,
    get_offline_mission_goods/3,
    condition_update/1
]).

-export([
    gm_get_mission/2,
    gm_refresh_daily_mission/1
]).

init(#r_role{role_id = RoleID, role_mission = undefined} = State) ->
    RoleMission = #r_role_mission{role_id = RoleID},
    State#r_role{role_mission = RoleMission};
init(State) ->
    State2 = modify_mission(State),
    State2.

%% 每日重置任务
day_reset(State) ->
    #r_role{role_mission = RoleMission} = State,
    IsWeek = role_misc:is_reset_week(State),
    RoleMission2 = mission_day_reset(RoleMission, IsWeek),
    State2 = State#r_role{role_mission = RoleMission2},
    update_missions(State, State2),
    State2.

%% 0点重置了推送任务
zero(State) ->
    pre_enter(State).

%% 上线时重算一遍任务
pre_enter(State) ->
    State2 = refresh_mission_listener(State),
    {State3, _UpdateDoings, _DelIDs} = refresh_mission(State2),
    do_mission_info(State3),
    State3.

gm_get_mission(MissionID, State) ->
    #r_role{role_id = RoleID, role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    #c_mission{listeners = Listeners} = get_mission_config(MissionID),
    Listen = [#r_mission_listen{type = ListenerType, val = ListenVal, need_num = NeedNum, num = 0, rate = Rate} ||
        {ListenerType, ListenVal, NeedNum, Rate} <- Listeners],
    case get_mission_config(MissionID) of
        #c_mission{type = ?MISSION_TYPE_MAIN, sub_type = SubType} ->
            case lists:keyfind(?MISSION_TYPE_MAIN, #r_mission_doing.type, DoingList) of
                #r_mission_doing{id = MainID} ->
                    MainID;
                _ ->
                    MainID = 0
            end,
            {ok, Doing} = get_new_mission(?MISSION_TYPE_MAIN, SubType, MissionID, State),
            DoingList2 = lists:keystore(?MISSION_TYPE_MAIN, #r_mission_doing.type, DoingList, Doing),
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
            State2 = State#r_role{role_mission = RoleMission2},
            common_misc:unicast(RoleID, #m_mission_update_toc{del = [MainID], update = make_p_doing_mission2([Doing], [])}),
            update_missions(State, State2),
            State2;
        #c_mission{type = ?MISSION_TYPE_BRANCH} ->
            DoingList2 = lists:keydelete(MissionID, #r_mission_doing.id, DoingList),
            Doing = #r_mission_doing{id = MissionID, type = ?MISSION_TYPE_BRANCH, status = ?MISSION_STATUS_DOING, listens = Listen},
            DoingList3 = [Doing|DoingList2],
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList3},
            State2 = State#r_role{role_mission = RoleMission2},
            ?IF(lists:keymember(MissionID, #r_mission_doing.id, DoingList), common_misc:unicast(RoleID, #m_mission_update_toc{del = [MissionID]}), ok),
            common_misc:unicast(RoleID, #m_mission_update_toc{update = make_p_doing_mission2([Doing], [])}),
            update_missions(State, State2),
            try_call_backs(Listen, State2),
            State2;
        #c_mission{type = Type} when ?IS_MISSION_LOOP(Type) ->
            DoingList2 = lists:keydelete(Type, #r_mission_doing.type, DoingList),
            Doing = #r_mission_doing{id = MissionID, type = Type, status = ?MISSION_STATUS_DOING, listens = Listen},
            DoingList3 = [Doing|DoingList2],
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList3},
            State2 = State#r_role{role_mission = RoleMission2},
            ?IF(lists:keymember(MissionID, #r_mission_doing.id, DoingList), common_misc:unicast(RoleID, #m_mission_update_toc{del = [MissionID]}), ok),
            common_misc:unicast(RoleID, #m_mission_update_toc{update = make_p_doing_mission2([Doing], [])}),
            update_missions(State, State2),
            try_call_backs(Listen, State2),
            State2;
        _ ->
            State
    end.



gm_refresh_daily_mission(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    DoingList2 = [Doing || #r_mission_doing{type = Type} = Doing <- DoingList, not ?IS_MISSION_LOOP(Type)],
    DoneList2 = [Done || #r_mission_done{type = Type} = Done <- DoneList, not ?IS_MISSION_LOOP(Type)],
    RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2, done_list = DoneList2},
    State2 = State#r_role{role_mission = RoleMission2},
    pre_enter(State2).

trigger_mission(RoleID, ListenerType, ListenerVal, AddNum) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {trigger_mission, ListenerType, ListenerVal, AddNum}}).

kill_monster(TypeID, State) ->
    State2 = do_trigger_mission(?MISSION_KILL_MONSTER, TypeID, 1, State),
    State3 = do_trigger_mission(?MISSION_RATE, TypeID, 1, State2),
    State4 = do_trigger_item(TypeID, State3),
    State5 = mod_role_confine:kill_monster(TypeID,State4),
    State5.

finish_copy(MapID, State) ->
    State2 = do_trigger_mission(?MISSION_FINISH_COPY, MapID, 1, State),
    State2.

daily_mission_trigger(MissionType, State) ->
    if
        MissionType =:= ?MISSION_TYPE_FAIRY -> %% 仙女任务数据从对应模块取
            Times = mod_role_escort:get_escort_finish_times(State);
        true ->
            #r_role{role_mission = #r_role_mission{done_list = DoneList}} = State,
            Times = get_done_mission_times(MissionType, DoneList)
    end,
    do_trigger_mission(?MISSION_FINISH_DAILY_MISSION, MissionType, Times, State).

power_trigger(State) ->
    #r_role{role_attr = #r_role_attr{max_power = MaxPower}} = State,
    do_trigger_mission(?MISSION_POWER, 0, MaxPower, State).

refine_trigger(State) ->
    State2 = refine_num_trigger(State),
    refine_level_trigger(State2).

refine_num_trigger(State) ->
    LevelList = get_refine_level_list(State),
    lists:foldl(
        fun(NeedLevel, StateAcc) ->
            LevelNum = mod_role_equip:get_refine_level_num(NeedLevel, StateAcc),
            do_trigger_mission(?MISSION_REFINE, NeedLevel, LevelNum, StateAcc)
        end, State, LevelList).

refine_level_trigger(State) ->
    AllLevel = mod_role_equip:get_all_refine_level(State),
    do_trigger_mission(?MISSION_ALL_REFINE_LEVEL, 0, AllLevel, State).

exp_trigger(Exp, State) ->
    do_trigger_mission(?MISSION_GAIN_EXP, Exp, 1, State).

daily_active_trigger(State) ->
    DailyLiveness = mod_role_daily_liveness:get_daily_liveness(State),
    do_trigger_mission(?MISSION_ACTIVE, 0, DailyLiveness, State).

friend_trigger(State) ->
    FriendNum = mod_role_friend:get_friend_num(State),
    do_trigger_mission(?MISSION_FRIEND_NUM, 0, FriendNum, State).

world_boss_trigger(TypeID, State) ->
    #c_monster{level = Level} = monster_misc:get_monster_config(TypeID),
    case lib_config:find(cfg_world_boss, TypeID) of
        [#c_world_boss{type = ?BOSS_TYPE_WORLD_BOSS}] ->
            do_trigger_mission(?MISSION_WORLD_BOSS, Level, 1, State);
        _ ->
            State
    end.

offline_solo_trigger(State) ->
    do_trigger_mission(?MISSION_OFFLINE_SOLO, 0, 1, State).

compose_trigger(TypeID, State) ->
    do_trigger_mission(?MISSION_COMPOSE, TypeID, 1, State).

item_trigger(TypeIDList, State) ->
    lists:foldl(
        fun(TypeID, StateAcc) ->
            case lib_config:find(cfg_mission, {item_missions, TypeID}) of
                [_MissionIDList] ->
                    ItemNum = mod_role_bag:get_num_by_type_id(TypeID, StateAcc),
                    do_trigger_mission(?MISSION_LISTEN_ITEM, TypeID, ItemNum, StateAcc);
                _ ->
                    StateAcc
            end
    end, State, TypeIDList).

confine_trigger(State) ->
    ConfineID = mod_role_confine:get_confine_id(State),
    do_trigger_mission(?MISSION_CONFINE, ConfineID, 1, State).

family_mission(State) ->
    do_trigger_mission(?MISSION_FAMILY_MISSION, 0, 1, State).

family_escort(State) ->
    do_trigger_mission(?MISSION_FAMILY_ESCORT, 0, 1, State).

family_rob_escort(State) ->
    do_trigger_mission(?MISSION_FAMILY_ROB_ESCORT, 0, 1, State).

kill_five_elements_boss(TypeID, State) ->
    #c_monster{level = MonsterLevel} = monster_misc:get_monster_config(TypeID),
    do_trigger_mission(?MISSION_KILL_FIVE_ELEMENT_BOSS, MonsterLevel, 1, State).

get_mission_ids(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = Doings} = RoleMission,
    lists:sort([MissionID || #r_mission_doing{id = MissionID, status = Status} <- Doings, Status =:= ?MISSION_STATUS_DOING]).

is_main_mission_finish(MissionID, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{done_list = DoneList} = RoleMission,
    case lists:keyfind(?MISSION_TYPE_MAIN, #r_mission_done.type, DoneList) of
        #r_mission_done{mission_list = MissionIDList} ->
            lists:member(MissionID, MissionIDList);
        _ ->
            false
    end.

get_main_mission_id(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = Doings} = RoleMission,
    case lists:keyfind(?MISSION_TYPE_MAIN, #r_mission_doing.type, Doings) of
        #r_mission_doing{id = MissionID} ->
            MissionID;
        _ ->
            0
    end.

get_main_mission_id_status(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = Doings} = RoleMission,
    case lists:keyfind(?MISSION_TYPE_MAIN, #r_mission_doing.type, Doings) of
        #r_mission_doing{id = MissionID, status = MissionStatus} ->
            {MissionID, MissionStatus};
        _ ->
            {0, 0}
    end.

get_offline_mission_goods(MonsterTypeID, KillMonster, State) ->
    #c_monster{level = MonsterLevel} = monster_misc:get_monster_config(MonsterTypeID),
    case lib_config:find(cfg_mission, {monster_level, MonsterLevel}) of
        [MissionList] when MissionList =/= [] ->
            #r_role{role_mission = RoleMission} = State,
            #r_role_mission{doing_list = DoingList} = RoleMission,
            get_offline_mission_goods2(DoingList, MissionList, KillMonster, []);
        _ ->
            []
    end.

get_offline_mission_goods2([], _MissionList, _KillMonster, GoodsAcc) ->
    GoodsAcc;
get_offline_mission_goods2(_DoingList, [], _KillMonster, GoodsAcc) ->
    GoodsAcc;
get_offline_mission_goods2([Doing|R], MissionList, KillMonster, GoodsAcc) ->
    #r_mission_doing{id = MissionID, status = Status} = Doing,
    case Status =/= ?MISSION_STATUS_REWARD andalso lists:keytake(MissionID, #r_mission_item_monster.mission_id, MissionList) of
        {value, ItemMonster, MissionList2} ->
            #r_mission_item_monster{item_type_id = TypeID, item_rate = Rate} = ItemMonster,
            Weight = KillMonster * Rate,
            Num = Weight div ?RATE_10000,
            Num2 = ?IF((Weight rem ?RATE_10000) >= lib_tool:random(?RATE_10000), Num + 1, Num),
            GoodsAcc2 = ?IF(Num2 > 0, [#p_goods{type_id = TypeID, num = Num2, bind = false}|GoodsAcc], GoodsAcc),
            get_offline_mission_goods2(R, MissionList2, KillMonster, GoodsAcc2);
        _ ->
            get_offline_mission_goods2(R, MissionList, KillMonster, GoodsAcc)
    end.


condition_update(State) ->
    #r_role{role_id = RoleID, role_mission = RoleMission} = State,
    #r_role_mission{done_list = DoneList} = RoleMission,
    {State2, UpdateDoings, DelIDs} = refresh_mission(State),
    ?IF(UpdateDoings =/= [] orelse DelIDs =/= [], common_misc:unicast(RoleID, #m_mission_update_toc{del = DelIDs, update = make_p_doing_mission2(UpdateDoings, DoneList)}), ok),
    update_missions(State, State2),
    State2.


handle({#m_mission_accept_tos{mission_id = MissionID}, RoleID, _PID}, State) ->
    do_accept_mission(RoleID, MissionID, State);
handle({#m_mission_complete_tos{mission_id = MissionID}, RoleID, _PID}, State) ->
    do_complete_mission(RoleID, MissionID, State);
handle({#m_mission_trigger_tos{type = Type, val = Val}, RoleID, _PID}, State) ->
    do_front_trigger_mission(RoleID, Type, Val, State);
handle({#m_mission_one_key_tos{type = MissionType}, RoleID, _PID}, State) ->
    do_mission_one_key(RoleID, MissionType, State);
handle({trigger_mission, ListenerType, ListenerVal, AddNum}, State) ->
    do_trigger_mission(ListenerType, ListenerVal, AddNum, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.

%% 任务每天重置
mission_day_reset(#r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission, IsWeek) ->
    DoingList2 =
        lists:foldl(
            fun(#r_mission_doing{type = Type} = Doing, Acc) ->
                if
                    Type =:= ?MISSION_TYPE_MAIN orelse Type =:= ?MISSION_TYPE_BRANCH ->
                        [Doing | Acc];
                    true ->
                        ?IF(is_reset(Type, IsWeek), Acc, [Doing | Acc])
                end
            end, [], DoingList),
    DoneList2 =
        lists:foldl(
            fun(#r_mission_done{type = Type} = Done, Acc) ->
                if
                    Type =:= ?MISSION_TYPE_MAIN orelse Type =:= ?MISSION_TYPE_BRANCH ->
                        [Done | Acc];
                    true ->
                        ?IF(is_reset(Type, IsWeek), Acc, [Done | Acc])
                end
            end, [], DoneList),
    RoleMission#r_role_mission{doing_list = DoingList2, done_list = DoneList2}.

is_reset(Type, IsWeek) ->
    if
        Type =:= ?MISSION_TYPE_RING orelse Type =:= ?MISSION_TYPE_DAILY -> %% 日常任务每天重置
            true;
        Type =:= ?MISSION_TYPE_FAMILY andalso IsWeek -> %% 帮派任务每周重置
            true;
        true ->
            false
    end.

%% 上线检查任务侦听器
refresh_mission_listener(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    {DoingList2, ListenAcc} = refresh_mission_listener2(DoingList, [], []),
    try_call_backs(ListenAcc, State),
    RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
    State#r_role{role_mission = RoleMission2}.

refresh_mission_listener2([], DoingAcc, ListenAcc) ->
    {DoingAcc, ListenAcc};
refresh_mission_listener2([Doing|R], DoingAcc, ListenAcc) ->
    #r_mission_doing{id = MissionID, listens = Listens} = Doing,
    #c_mission{listeners = Listeners} = get_mission_config(MissionID),
    ListenConfig = [#r_mission_listen{type = ListenerType, val = ListenVal, need_num = NeedNum, num = 0, rate = Rate} ||
        {ListenerType, ListenVal, NeedNum, Rate} <- Listeners],
    case catch refresh_mission_listener3(Listens, ListenConfig) of
        true ->
            Doing2 = Doing#r_mission_doing{listens = ListenConfig},
            refresh_mission_listener2(R, [Doing2|DoingAcc], ListenConfig ++ ListenAcc);
        _ ->
            refresh_mission_listener2(R, [Doing|DoingAcc], ListenAcc)
    end.

refresh_mission_listener3([], []) ->
    false;
refresh_mission_listener3([], _ListenConfig) ->
    true;
refresh_mission_listener3(_Listeners, []) ->
    true;
refresh_mission_listener3([Listen|R], ListenConfig) ->
    ListenConfig2 = refresh_mission_listener4(Listen, ListenConfig, []),
    refresh_mission_listener3(R, ListenConfig2).

refresh_mission_listener4(_Listen, [], _Acc) ->
    erlang:throw(true);
refresh_mission_listener4(Listen, [Config|R], Acc) ->
    #r_mission_listen{type = Type, val = Val} = Listen,
    #r_mission_listen{type = ConfigType, val = ConfigVal} = Config,
    case Type =:= ConfigType andalso Val =:= ConfigVal of
        true ->
            R ++ Acc;
        _ ->
            refresh_mission_listener4(Listen, R, [Config|Acc])
    end.

refresh_mission(State) ->
    #r_role{role_attr = #r_role_attr{level = Level}, role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    {UpdateDoings, DelIDs, Doings2} = refresh_doing_mission(DoingList, State, [], [], []),
    TypeMission = get_mission_list(Level),
    {Doings3, AddDoings} =
        lists:foldl(
            fun({TypeID, SubType, MissionID}, {Acc1, Acc2}) ->
                case check_can_refresh(TypeID, SubType, MissionID, Acc1, DoneList) andalso not lists:member(MissionID, ?FLIER_MISSION_ID_LIST) of
                    true -> %% 检查通过
                        case catch get_new_mission(TypeID, SubType, MissionID, State) of
                            {ok, Doing} ->
                                {[Doing | Acc1], [Doing | Acc2]};
                            {error, conditon} ->
                                {Acc1, Acc2};
                            Error ->
                                ?ERROR_MSG("获取任务失败 Error:~w", [{Error, TypeID, MissionID}]),
                                {Acc1, Acc2}
                        end;
                    _ ->
                        {Acc1, Acc2}
                end
            end, {Doings2, []}, TypeMission),
    RoleMission2 = RoleMission#r_role_mission{doing_list = Doings3},
    {State#r_role{role_mission = RoleMission2}, UpdateDoings ++ AddDoings, DelIDs}.

refresh_doing_mission([], _State, UpdateAcc, DelAcc, DoingAcc) ->
    {UpdateAcc, DelAcc, DoingAcc};
refresh_doing_mission([Doing | R], State, UpdateAcc, DelAcc, DoingAcc) ->
    #r_mission_doing{id = MissionID, type = Type, status = Status} = Doing,
    if
        Type =:= ?MISSION_TYPE_MAIN -> %% 主线不能删
            if
                Status =:= ?MISSION_STATUS_ACCEPT ->
                    #c_mission{
                        conditions = Conditions,
                        auto_accept = AutoAccept} = get_mission_config(MissionID),
                    case ?IS_AUTO_ACCEPT(AutoAccept) andalso check_conditions(Conditions, State) of
                        true ->
                            Doing2 = Doing#r_mission_doing{status = ?MISSION_STATUS_DOING},
                            UpdateAcc2 = [Doing2 | UpdateAcc],
                            DoingAcc2 = [Doing2 | DoingAcc],
                            refresh_doing_mission(R, State, UpdateAcc2, DelAcc, DoingAcc2);
                        _ ->
                            refresh_doing_mission(R, State, UpdateAcc, DelAcc, [Doing | DoingAcc])
                    end;
                true ->
                    refresh_doing_mission(R, State, UpdateAcc, DelAcc, [Doing | DoingAcc])
            end;
        true -> %% 支线任务 和 其他任务(日常类)
            #c_mission{auto_accept = AutoAccept} = MissionConfig = get_mission_config(MissionID),
            case check_is_condition(MissionConfig, State) of
                true -> %% 可以接续执行
                    case ?IS_AUTO_ACCEPT(AutoAccept) andalso Status =:= ?MISSION_STATUS_ACCEPT of
                        true ->
                            Doing2 = Doing#r_mission_doing{status = ?MISSION_STATUS_DOING},
                            UpdateAcc2 = [Doing2 | UpdateAcc],
                            DoingAcc2 = [Doing2 | DoingAcc],
                            refresh_doing_mission(R, State, UpdateAcc2, DelAcc, DoingAcc2);
                        _ ->
                            refresh_doing_mission(R, State, UpdateAcc, DelAcc, [Doing | DoingAcc])
                    end;
                _ ->
                    refresh_doing_mission(R, State, UpdateAcc, [MissionID | DelAcc], DoingAcc)
            end
    end.

check_can_refresh(?MISSION_TYPE_MAIN, _SubType, MissionID, DoingList, DoneList) -> %% 主线任务
    case lists:keymember(?MISSION_TYPE_MAIN, #r_mission_doing.type, DoingList) of
        true ->
            false;
        _ ->
            case lists:keyfind(?MISSION_TYPE_MAIN, #r_mission_done.type, DoneList) of
                #r_mission_done{mission_list = MissionList} ->
                    ?IF(lists:member(MissionID, MissionList), false, true);
                _ ->
                    true
            end
    end;
check_can_refresh(?MISSION_TYPE_BRANCH, _SubType, MissionID, DoingList, DoneList) -> %% 支线任务
    case lists:keymember(MissionID, #r_mission_doing.id, DoingList) of
        true ->
            false;
        _ ->
            case lists:keyfind(?MISSION_TYPE_BRANCH, #r_mission_done.type, DoneList) of
                #r_mission_done{mission_list = DoneList} ->
                    ?IF(lists:member(MissionID, DoneList), false, true);
                _ ->
                    true
            end
    end;
check_can_refresh(TypeID, SubType, _MissionArgs, DoingList, DoneList) -> %% 其他日常类循环任务
    case lists:keymember(TypeID, #r_mission_doing.type, DoingList) of
        true ->
            false;
        _ ->
            [[{_, MissionIDList} | _]] = lib_config:find(cfg_mission, {daily, SubType}),
            MissionID = lib_tool:random_element_from_list(MissionIDList),
            #c_mission{max_times = MaxTimes} = get_mission_config(MissionID),
            case lists:keyfind(TypeID, #r_mission_done.type, DoneList) of
                #r_mission_done{times = Times} ->
                    ?IF(Times >= MaxTimes, false, true);
                _ ->
                    true
            end
    end.

%% 获取新的任务
get_new_mission(TypeID, _SubType, MissionID, State) when TypeID =:= ?MISSION_TYPE_MAIN orelse TypeID =:= ?MISSION_TYPE_BRANCH ->
    get_new_mission_by_id(MissionID, State);
get_new_mission(TypeID, _SubType, _MissionID, State) when TypeID =:= ?MISSION_TYPE_FAIRY -> %% 护送任务特殊处理
    MissionID = 900000,
    get_new_mission_by_id(MissionID, State);
get_new_mission(TypeID, SubType, _MissionID, State) when ?IS_MISSION_LOOP(TypeID) ->
    #r_role{role_mission = #r_role_mission{done_list = DoneList}} = State,
    case lists:keyfind(TypeID, #r_mission_done.type, DoneList) of
        #r_mission_done{mission_list = FinishList} ->
            ok;
        _ ->
            FinishList = []
    end,
    Level = mod_role_data:get_role_level(State),
    [LevelList] = lib_config:find(cfg_mission, {daily, SubType}),
    MissionID = get_daily_mission_id(Level, FinishList, LevelList),
    get_new_mission_by_id(MissionID, State).

%% 从循环任务的数组中挑选一个
get_daily_mission_id(_Level, _FinishList, []) ->
    erlang:throw(config_error);
get_daily_mission_id(Level, FinishList, [{{MinLevel, MaxLevel}, MissionIDs} | R]) ->
    case MinLevel =< Level andalso Level =< MaxLevel of
        true ->
            case FinishList of
                [LastMissionID|_] ->
                    [#c_mission_excel{times = OneRoundTimes}] = lib_config:find(cfg_mission_excel, LastMissionID),
                    SubLen = erlang:length(FinishList) rem OneRoundTimes,
                    {MissionList, _RemainList} = lib_tool:split(SubLen, FinishList),
                    Times = get_copy_mission_times(MissionList, 0),
                    MissionIDs2 = lists:delete(LastMissionID, MissionIDs) -- ?DEL_DAILY_MISSION_IDS,
                    case Times =< 2 orelse erlang:length(MissionIDs) > ?MISSION_COPY_TIMES of
                        true -> %% 当前不超过2次，或者已经接取过1次副本，就不再出现副本任务
                            MissionIDs3 = [ MissionID || MissionID <- MissionIDs2, not is_copy_mission(MissionID)],
                            lib_tool:random_element_from_list(MissionIDs3);
                        _ ->
                            lib_tool:random_element_from_list(MissionIDs2)
                    end;
                _ ->
                    MissionIDs2 = [ MissionID || MissionID <- MissionIDs, not is_copy_mission(MissionID)] -- ?DEL_DAILY_MISSION_IDS,
                    lib_tool:random_element_from_list(MissionIDs2)
            end;
        _ ->
            get_daily_mission_id(Level, FinishList, R)
    end.

get_copy_mission_times([], Num) ->
    Num;
get_copy_mission_times([MissionID|R], Num) ->
    Num2 = ?IF(is_copy_mission(MissionID), Num + 1, Num),
    get_copy_mission_times(R, Num2).

is_copy_mission(MissionID) ->
    case lib_config:find(cfg_mission_excel, MissionID) of
        [#c_mission_excel{listener_type = ?MISSION_FINISH_COPY}] ->
            true;
        _ ->
            false
    end.

%% 通过ID获取Mission
get_new_mission_by_id(MissionID, State) ->
    #c_mission{
        type = Type,
        auto_accept = AutoAccept,
        listeners = Listeners} = MissionConfig = get_mission_config(MissionID),
    Listens = [#r_mission_listen{type = ListenerType, val = ListenVal, need_num = NeedNum, num = 0, rate = Rate} ||
        {ListenerType, ListenVal, NeedNum, Rate} <- Listeners],
    IsCondition = check_is_condition(MissionConfig, State),
    if
        IsCondition -> %% 满足条件
            ?TRY_CATCH(try_call_backs(Listens, State)),
            case ?IS_AUTO_ACCEPT(AutoAccept) andalso IsCondition of
                true ->
                    {ok, #r_mission_doing{id = MissionID, type = Type, status = ?MISSION_STATUS_DOING, listens = Listens}};
                _ ->
                    {ok, #r_mission_doing{id = MissionID, type = Type, status = ?MISSION_STATUS_ACCEPT, listens = Listens}}
            end;
        Type =:= ?MISSION_TYPE_MAIN -> %% 主线任务不满足条件也一定要接取
            {ok, #r_mission_doing{id = MissionID, type = Type, status = ?MISSION_STATUS_ACCEPT, listens = Listens}};
        true ->
            erlang:throw({error, conditon})
    end.

check_is_condition(MissionConfig, State) ->
    #c_mission{
        id = MissionID,
        type = Type,
        pre_mission = PreMission,
        conditions = Conditions} = MissionConfig,
    check_conditions(Conditions, State) andalso check_pre_mission(Type, MissionID, PreMission, State).

check_conditions([], _State) ->
    true;
check_conditions([Condition | R], State) ->
    #r_role{role_attr = #r_role_attr{level = Level, family_id = FamilyID},
        role_relive = #r_role_relive{relive_level = ReliveLevel, progress = Progress}} = State,
    Flag =
        case Condition of
            {?CONDITION_LEVEL, MinLevel, MaxLevel} ->
                MinLevel =< Level andalso Level =< MaxLevel;
            {?CONDITION_FAMILY, NeedFamily} ->
                ?IF(NeedFamily, ?HAS_FAMILY(FamilyID), true);
            {?CONDITION_RELIVE_ARGS, NeedReliveLevel, NeedProgress} ->
                ReliveLevel =:= NeedReliveLevel andalso Progress >= NeedProgress;
            {?CONDITION_FUNCTION, FunctionID} ->
                mod_role_function:get_is_function_open(FunctionID, State)
        end,
    ?IF(Flag, check_conditions(R, State), false).

check_pre_mission(Type, MissionID, PreMission, State) when Type =:= ?MISSION_TYPE_BRANCH ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{done_list = DoneList} = RoleMission,
    case lists:keyfind(Type, #r_mission_done.type, DoneList) of
        #r_mission_done{mission_list = MissionList} ->
            IsPre = ?IF(PreMission > 0, lists:member(PreMission, MissionList), true),
            IsPre andalso not(lists:member(MissionID, MissionList));
        _ ->
            PreMission =< 0
    end;
check_pre_mission(_Type, _MissionID, _PreMission, _State) ->
    true.

do_mission_info(#r_role{role_id = RoleID, role_mission = RoleMission}) ->
    MissionPInfos = make_p_doing_mission(RoleMission),
    R = #m_mission_info_toc{missions = MissionPInfos},
    common_misc:unicast(RoleID, R).

%% 接受任务
do_accept_mission(RoleID, MissionID, State) ->
    case catch check_can_accept(MissionID, State) of
        {ok, State2, Listens} ->
            common_misc:unicast(RoleID, #m_mission_accept_toc{mission_id = MissionID}),
            update_missions(State, State2),
            try_call_backs(Listens, State2),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mission_accept_toc{err_code = ErrCode}),
            State
    end.

check_can_accept(MissionID, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    case lists:keyfind(MissionID, #r_mission_doing.id, DoingList) of
        #r_mission_doing{status = ?MISSION_STATUS_ACCEPT, listens = Listens} = Doing ->
            #c_mission{conditions = Conditions} = get_mission_config(MissionID),
            ?IF(check_conditions(Conditions, State), ok, ?THROW_ERR(?ERROR_MISSION_ACCEPT_001)),
            Doing2 = Doing#r_mission_doing{status = ?MISSION_STATUS_DOING},
            DoingList2 = lists:keyreplace(MissionID, #r_mission_doing.id, DoingList, Doing2),
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
            {ok, State#r_role{role_mission = RoleMission2}, Listens};
        _ ->
            ?THROW_ERR(?ERROR_MISSION_ACCEPT_002)
    end.

%% 领取任务奖励
do_complete_mission(RoleID, MissionID, State) ->
    case catch check_can_complete(MissionID, State) of
        {ok, BagDoings, State2, Exp, Items, Type} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            CreateList = [#p_goods{type_id = TypeID, bind = ?IS_BIND(BindType), num = Num} || {TypeID, Num, BindType} <- Items],
            do_complete_mission2(RoleID, MissionID, Type, 1, Exp, CreateList, State3);
        {error, ?ERROR_MISSION_COMPLETE_001} ->
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mission_complete_toc{err_code = ErrCode}),
            State
    end.

do_complete_mission2(RoleID, MissionID, MissionType, FinishTimes, AddExp, CreateList, State) ->
    State4 = mod_role_level:do_add_exp(State, AddExp, ?EXP_ADD_FROM_MISSION),
    common_misc:unicast(RoleID, #m_mission_complete_toc{mission_id = MissionID}),
    State5 =
        lists:foldl(
            fun(_, StateAcc) ->
                hook_role:mission_complete(MissionID, MissionType, StateAcc)
            end, State4, lists:seq(1, FinishTimes)),
    State6 = complete_insert_mission(MissionID, State5),
    State7 = ?IF(?IS_MISSION_LOOP(MissionType), daily_mission_trigger(MissionType, State6), State6),
    update_missions(State, State6),
    State8 = role_misc:create_goods(State7, ?ITEM_GAIN_MISSION, CreateList),
    State8.

check_can_complete(MissionID, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    case lists:keytake(MissionID, #r_mission_doing.id, DoingList) of
        {value, #r_mission_doing{type = Type, listens = Listens, status = Status}, DoingList2} ->
            ?IF(Status =:= ?MISSION_STATUS_REWARD, ok, ?THROW_ERR(?ERROR_MISSION_COMPLETE_002)),
            BagDoings = get_complete_bag_doings(Listens, State),
            case lists:keytake(Type, #r_mission_done.type, DoneList) of
                {value, Done, Remain} ->
                    #r_mission_done{times = Times, mission_list = List} = Done,
                    FinishTimes = Times + 1,
                    Done2 = Done#r_mission_done{times = FinishTimes, mission_list = [MissionID | List], last_mission = MissionID},
                    DoneList2 = [Done2 | Remain];
                _ ->
                    FinishTimes = 1,
                    Done2 = #r_mission_done{type = Type, times = FinishTimes, mission_list = [MissionID], last_mission = MissionID},
                    DoneList2 = [Done2 | DoneList]
            end,
            {Exp, Items} = get_mission_reward(State, Type, FinishTimes, MissionID),
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2, done_list = DoneList2},
            {ok, BagDoings, State#r_role{role_mission = RoleMission2}, Exp, Items, Type};
        _ ->
            ?THROW_ERR(?ERROR_MISSION_COMPLETE_001)
    end.

get_complete_bag_doings(Listens, State) ->
    ItemList = [ {TypeID, NeedNum}|| #r_mission_listen{type = ListenType, val = TypeID, need_num = NeedNum} <- Listens, ListenType =:= ?MISSION_LISTEN_ITEM],
    mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_MISSION_ITEM, State).

complete_insert_mission(MissionID, State) ->
    #c_mission{type = Type, sub_type = SubType, next_mission = NextMission} = get_mission_config(MissionID),
    #r_role{role_id = RoleID, role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    if
        Type =:= ?MISSION_TYPE_MAIN andalso NextMission =/= 0 ->
            #c_mission{add_buffs = OldBuffs} = get_mission_config(MissionID),
            {ok, Doing} = get_new_mission(?MISSION_TYPE_MAIN, SubType, NextMission, State),
            common_misc:unicast(RoleID, #m_mission_update_toc{del = [MissionID], update = make_p_doing_mission2([Doing], DoneList)}),
            DoingList2 = [Doing | DoingList],
            RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
            #c_mission{add_buffs = AddBuffs} = get_mission_config(NextMission),
            role_misc:remove_buff(RoleID, OldBuffs),
            AddBuffs2 = [#buff_args{buff_id = BuffID, from_actor_id = RoleID} || BuffID <- AddBuffs],
            role_misc:add_buff(RoleID, AddBuffs2),
            State#r_role{role_mission = RoleMission2};
        true ->
            {State2, UpdateDoings, DelIDs} = refresh_mission(State),
            common_misc:unicast(RoleID, #m_mission_update_toc{del = [MissionID] ++ DelIDs, update = make_p_doing_mission2(UpdateDoings, DoneList)}),
            State2
    end.

%% 前端发起trigger请求
do_front_trigger_mission(RoleID, Type, Val, State) ->
    case catch check_can_trigger(Type, Val) of
        {ok, Val2, AddNum} ->
            State2 = do_trigger_mission(Type, Val2, AddNum, State),
            common_misc:unicast(RoleID, #m_mission_trigger_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mission_trigger_toc{err_code = ErrCode}),
            State
    end.

check_can_trigger(Type, Val) ->
    if
        Type =:= ?MISSION_SPEAK ->
            {ok, Val, 1};
        Type =:= ?MISSION_FRONT ->
            Val2 =
            if
                Val =:= 90001 -> 900010000;
                Val =:= 90004 -> 900040000;
                Val =:= 10023 -> 100230000;
                Val =:= 10017 -> 100170000;
                Val =:= 10006 -> 100060000;
                Val =:= 10010 -> 100100000;
                Val =:= 40006 -> 400060000;
                Val =:= 20012 -> 200120000;
                Val =:= 20003 -> 200030000;
                Val =:= 20002 -> 200020000;
                Val =:= 20006 -> 200060000;
                Val =:= 20007 -> 200070000;
                Val =:= 20008 -> 200080000;
                Val =:= 20010 -> 200100000;
                Val =:= 20011 -> 200110000;
                Val =:= 30011 -> 300110000;
                Val =:= 30010 -> 300100000;
                Val =:= 30008 -> 300080000;
                true ->
                    Val
            end,
            {ok, Val2, 1};
        Type =:= ?MISSION_MOVE ->
            {ok, Val, 1};
        true ->
            ?THROW_ERR(?ERROR_MISSION_TRIGGER_001)
    end.

do_mission_one_key(RoleID, MissionType, State) ->
    case catch check_one_key(MissionType, State) of
        {ok, AssetDoings, MissionID, AddExp, CreateList, FinishTimes, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            do_complete_mission2(RoleID, MissionID, MissionType, FinishTimes, AddExp, CreateList, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_mission_complete_toc{err_code = ErrCode}),
            State
    end.

check_one_key(MissionType, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList, done_list = DoneList} = RoleMission,
    ?IF(lists:member(MissionType, [?MISSION_TYPE_FAMILY]), ok, ?THROW_ERR(?ERROR_MISSION_ONE_KEY_001)),
    [#c_global{list = [NeedLevel, NeedVipLevel|_], int = NeedGold}] = lib_config:find(cfg_global, ?GLOBAL_MISSION_ONE_KEY),
    case mod_role_data:get_role_level(State) >= NeedLevel of
        true ->
            ok;
        _ ->
            ?IF(mod_role_vip:get_vip_level(State) >= NeedVipLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL))
    end,
    {DoingMission, DoingList2} =
        case lists:keytake(MissionType, #r_mission_doing.type, DoingList) of
            {value, MissionT, DoingListT} ->
                {MissionT, DoingListT};
            _ ->
                ?THROW_ERR(?ERROR_MISSION_ONE_KEY_002)
        end,
    {DoneMission, DoneList2} =
        case lists:keytake(MissionType, #r_mission_done.type, DoneList) of
            {value, DoneMissionT, DoneListT} ->
                {DoneMissionT, DoneListT};
            _ ->
                {#r_mission_done{type = MissionType, times = 0}, DoneList}
        end,
    #r_mission_doing{id = MissionID} = DoingMission,
    #r_mission_done{times = FinishTimes, mission_list = DoneIDList} = DoneMission,
    [#c_mission_excel{times = OneRoundTimes}] = lib_config:find(cfg_mission_excel, MissionID),
    AddTimes = OneRoundTimes - FinishTimes rem OneRoundTimes,
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, AddTimes * NeedGold, ?ASSET_GOLD_REDUCE_FROM_MISSION_ONE_KEY, State),
    DoneMission2 = DoneMission#r_mission_done{times = FinishTimes + AddTimes, mission_list = [MissionID|DoneIDList], last_mission = MissionID},
    DoneList3 = [DoneMission2|DoneList2],
    RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2, done_list = DoneList3},
    State2 = State#r_role{role_mission = RoleMission2},
    {Exp, Items} = get_mission_reward(State2, MissionType, FinishTimes, MissionID),
    CreateList = [#p_goods{type_id = TypeID, bind = ?IS_BIND(BindType), num = ItemNum * AddTimes} || {TypeID, ItemNum, BindType} <- Items],
    {ok, AssetDoings, MissionID, Exp * AddTimes, CreateList, AddTimes, State2}.

%% 触发任务
do_trigger_mission(ListenerType, ListenerVal, AddNum, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    {DoingList2, RewardList, CompleteList, ListenerList, UpdateList} =
        lists:foldl(
            fun(Doing, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
                #r_mission_doing{id = MissionID, status = Status, listens = Listens} = Doing,
                case try_trigger_mission(ListenerType, ListenerVal, AddNum, Status, Listens) of
                    {true, true, Listens2} -> %% 侦听器有更新并且任务完成
                        #c_mission{auto_complete = AC} = get_mission_config(MissionID),
                        Doing2 = Doing#r_mission_doing{status = ?MISSION_STATUS_REWARD, listens = Listens2},
                        {NewAcc2, NewAcc3} = ?IF(?IS_AUTO_COMPLETE(AC), {[MissionID | Acc2], Acc3}, {Acc2, [Doing2 | Acc3]}),
                        NewAcc4 = Acc4,
                        NewAcc5 = Acc5;
                    {true, false, Listens2} -> %% 侦听器有更新任务未完成
                        Doing2 = Doing#r_mission_doing{status = ?MISSION_STATUS_DOING, listens = Listens2},
                        NewAcc2 = Acc2, NewAcc3 = Acc3,
                        case Status =:= ?MISSION_STATUS_REWARD of
                            true ->
                                NewAcc4 = Acc4,
                                NewAcc5 = [Doing2|Acc5];
                            _ ->
                                NewAcc4 = [Doing2|Acc4],
                                NewAcc5 = Acc5
                        end;
                    _ -> %% 侦听器没有更新
                        Doing2 = Doing,
                        NewAcc2 = Acc2, NewAcc3 = Acc3, NewAcc4 = Acc4, NewAcc5 = Acc5
                end,
                {[Doing2 | Acc1], NewAcc2, NewAcc3, NewAcc4, NewAcc5}
            end, {[], [], [], [], []}, DoingList),
    RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
    State2 = State#r_role{role_mission = RoleMission2},
    update_missions(State, State2),
    do_trigger_mission2(State2, RewardList, CompleteList, ListenerList, UpdateList).

do_trigger_mission2(#r_role{role_id = RoleID, role_mission = RoleMission} = State, RewardList, CompleteList, ListenerList, UpdateList) ->
    #r_role_mission{done_list = DoneList} = RoleMission,
    %% 通知完成列表变化
    ?IF(CompleteList =/= [], common_misc:unicast(RoleID, #m_mission_update_toc{update = make_p_doing_mission2(CompleteList, DoneList)}), ok),
    ?IF(UpdateList =/= [], common_misc:unicast(RoleID, #m_mission_update_toc{update = make_p_doing_mission2(UpdateList, DoneList)}), ok),
    %% 通知侦听器变化
    case ListenerList =/= [] of
        true ->
            [begin
                 DataRecord = #m_listen_update_toc{mission_id = MissionID, listens = make_p_listen(Listens)},
                 common_misc:unicast(RoleID, DataRecord)
             end || #r_mission_doing{id = MissionID, listens = Listens} <- ListenerList];
        _ ->
            ok
    end,
    %% 自动完成任务
    lists:foldl(
        fun(MissionID, StateAcc) ->
            do_complete_mission(RoleID, MissionID, StateAcc)
        end, State, RewardList).


try_trigger_mission(TriggerType, TriggerVal, TriggerArgs, Status, Listens) ->
    if
        TriggerType =:= ?MISSION_LISTEN_ITEM andalso Status =/= ?MISSION_STATUS_ACCEPT ->
            try_trigger_mission2(TriggerType, TriggerVal, TriggerArgs, Listens);
        Status =:= ?MISSION_STATUS_DOING ->
            try_trigger_mission2(TriggerType, TriggerVal, TriggerArgs, Listens);
        true ->
            false
    end.

try_trigger_mission2(TriggerType, TriggerVal, TriggerArgs, Listens) ->
    lists:foldl(
        fun(Listen, {Acc1, Acc2, Acc3}) ->
            #r_mission_listen{type = Type, need_num = NeedNum, num = Num, rate = Rate} = Listen,
            IsNeedTrigger = ?IF(TriggerType =:= ?MISSION_LISTEN_ITEM, true, Num < NeedNum),
            case Type =:= TriggerType andalso IsNeedTrigger andalso Rate >= lib_tool:random(?RATE_10000) of
                true ->
                    {Listen2, IsTrigger} = try_trigger_mission3(Listen, TriggerVal, TriggerArgs),
                    NewAcc1 = IsTrigger orelse Acc1;
                _ ->
                    Listen2 = Listen,
                    NewAcc1 = Acc1
            end,
            NewAcc2 = (Listen2#r_mission_listen.num =:= NeedNum) andalso Acc2,
            {NewAcc1, NewAcc2, [Listen2 | Acc3]}
        end, {false, true, []}, Listens).

try_trigger_mission3(Listen, TriggerVal, TriggerArgs) ->
    #r_mission_listen{type = Type, val = Val, need_num = NeedNum, num = Num} = Listen,
    if
        %% 最大战战力 || 活跃度 || 好友数量 || 强化等级
        Type =:= ?MISSION_POWER orelse Type =:= ?MISSION_ACTIVE orelse Type =:= ?MISSION_FRIEND_NUM orelse Type =:= ?MISSION_ALL_REFINE_LEVEL ->
            case TriggerArgs =/= Num of
                true ->
                    Num2 = erlang:min(NeedNum, TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                _ ->
                    {Listen, false}
            end;
        %% 强化 || 境界 -> 大于等于条件直接替换
        Type =:= ?MISSION_REFINE orelse Type =:= ?MISSION_CONFINE ->
            case TriggerVal >= Val andalso TriggerArgs > Num of
                true ->
                    Num2 = erlang:min(NeedNum, TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                _ ->
                    {Listen, false}
            end;
        %% 完成日常任务 || 收集道具 条件相同时才替换
        Type =:= ?MISSION_LISTEN_ITEM orelse Type =:= ?MISSION_FINISH_DAILY_MISSION ->
            case TriggerVal =:= Val of
                true ->
                    Num2 = erlang:min(NeedNum, TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                _ ->
                    {Listen, false}
            end;
		%% 世界boss || 击杀五行boss -> 大于等于条件直接替换
        Type =:= ?MISSION_GAIN_EXP orelse Type =:= ?MISSION_WORLD_BOSS orelse Type =:= ?MISSION_KILL_FIVE_ELEMENT_BOSS -> %% 获得经验 -> 满足条件直接增加
            case TriggerVal >= Val of
                true ->
                    Num2 = erlang:min(NeedNum, Num + TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                _ ->
                    {Listen, false}
            end;
        Type =:= ?MISSION_FINISH_COPY -> %% 通关副本特殊处理
            TriggerCopyType = copy_misc:get_copy_type(TriggerVal),
            CopyType = copy_misc:get_copy_type(Val),
            if
                TriggerVal =:= Val ->
                    Num2 = erlang:min(NeedNum, Num + TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                (TriggerCopyType =:= CopyType) andalso TriggerVal >= Val-> %% 相同副本类型，ID比较大就可以算完成
                    Num2 = erlang:min(NeedNum, Num + TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                true ->
                    {Listen, false}
            end;
        true -> %% 其他的都是计数器累加的类型
            case TriggerVal =:= Val of
                true ->
                    Num2 = erlang:min(NeedNum, Num + TriggerArgs),
                    {Listen#r_mission_listen{num = Num2}, true};
                _ ->
                    {Listen, false}
            end
    end.

%% 部分任务在接取的时候尝试触发一下！
try_call_backs(Listens, State) ->
    List = try_call_backs2(Listens, []),
    [
        if
            Type =:= ?MISSION_POWER ->
                role_misc:info_role(erlang:self(), {?MODULE, power_trigger, []});
            Type =:= ?MISSION_REFINE ->
                role_misc:info_role(erlang:self(), {?MODULE, refine_num_trigger, []});
            Type =:= ?MISSION_ACTIVE ->
                role_misc:info_role(erlang:self(), {?MODULE, daily_active_trigger, []});
            Type =:= ?MISSION_FRIEND_NUM ->
                role_misc:info_role(erlang:self(), {?MODULE, friend_trigger, []});
            Type =:= ?MISSION_ALL_REFINE_LEVEL ->
                role_misc:info_role(erlang:self(), {?MODULE, refine_level_trigger, []});
            Type =:= ?MISSION_FINISH_COPY ->
                case map_misc:is_copy_tower(Val) of
                    true ->
                        CurTowerID = mod_role_copy:get_cur_tower_id(State),
                        ?IF(CurTowerID > 0, role_misc:info_role(erlang:self(), {?MODULE, finish_copy, [CurTowerID]}), ok);
                    _ ->
                        ok
                end;
            Type =:= ?MISSION_FINISH_DAILY_MISSION ->
                role_misc:info_role(erlang:self(), {?MODULE, daily_mission_trigger, [Val]});
            Type =:= ?MISSION_LISTEN_ITEM ->
                role_misc:info_role(erlang:self(), {?MODULE, item_trigger, [[Val]]});
            Type =:= ?MISSION_CONFINE ->
                role_misc:info_role(erlang:self(), {?MODULE, confine_trigger, []});
            true ->
                ok
        end|| {Type, Val} <- List].

try_call_backs2([], Acc) ->
    Acc;
try_call_backs2([#r_mission_listen{type = Type, val = Val}|R], Acc) ->
    case lists:member(Type, Acc) of
        true ->
            try_call_backs2(R, Acc);
        _ ->
            try_call_backs2(R, [{Type, Val}|Acc])
    end.

do_trigger_item(MonsterTypeID, State) ->
    #c_monster{level = MonsterLevel} = monster_misc:get_monster_config(MonsterTypeID),
    case lib_config:find(cfg_mission, {monster_level, MonsterLevel}) of
        [MissionList] when MissionList =/= [] ->
            #r_role{role_mission = RoleMission} = State,
            #r_role_mission{doing_list = DoingList} = RoleMission,
            GoodsList = do_trigger_item2(DoingList, MissionList, []),
            role_misc:create_goods(State, ?ITEM_GAIN_MISSION_DROP, GoodsList);
        _ ->
            State
    end.

do_trigger_item2([], _MissionList, GoodsAcc) ->
    GoodsAcc;
do_trigger_item2(_DoingList, [], GoodsAcc) ->
    GoodsAcc;
do_trigger_item2([Doing|R], MissionList, GoodsAcc) ->
    #r_mission_doing{id = MissionID, status = Status} = Doing,
    case Status =/= ?MISSION_STATUS_REWARD andalso lists:keytake(MissionID, #r_mission_item_monster.mission_id, MissionList) of
        {value, ItemMonster, MissionList2} ->
            #r_mission_item_monster{item_type_id = TypeID, item_rate = Rate} = ItemMonster,
            case Rate >= lib_tool:random(?RATE_10000) of
                true ->
                    GoodsAcc2 = [#p_goods{type_id = TypeID, num = 1, bind = false}|GoodsAcc];
                _ ->
                    GoodsAcc2 = GoodsAcc
            end,
            do_trigger_item2(R, MissionList2, GoodsAcc2);
        _ ->
            do_trigger_item2(R, MissionList, GoodsAcc)
    end.

%%%===================================================================
%%% common
%%%===================================================================
make_p_doing_mission(#r_role_mission{doing_list = DoingList, done_list = DoneList}) ->
    make_p_doing_mission2(DoingList, DoneList).

make_p_doing_mission2([], _DoneList) ->
    [];
make_p_doing_mission2([_ | _] = DoingList, DoneList) ->
    [begin
         PListens = make_p_listen(Listens),
         SuccTimes = get_done_mission_times(Type, DoneList),
         #p_mission{mission_id = MissionID, listen = PListens, status = Status, succ_times = SuccTimes + 1}
     end || #r_mission_doing{id = MissionID, type = Type, status = Status, listens = Listens} <- DoingList].

make_p_listen([]) ->
    [];
make_p_listen(Listens) ->
    [#p_listen{type = Type, val = Val, num = Num} || #r_mission_listen{type = Type, val = Val, num = Num} <- Listens].

get_done_mission_times(Type, DoneList) ->
    case lists:keyfind(Type, #r_mission_done.type, DoneList) of
        #r_mission_done{times = Times} -> Times;
        _ -> 0
    end.


update_missions(State, State2) ->
    OldMissions = get_mission_ids(State),
    NewMissions = get_mission_ids(State2),
    #r_role{role_id = RoleID} = State2,
    case OldMissions =/= NewMissions of
        true ->
            mod_map_role:update_role_missions(mod_role_dict:get_map_pid(), RoleID, NewMissions, NewMissions -- OldMissions, OldMissions -- NewMissions);
        _ ->
            ok
    end.
%%%===================================================================
%%% config
%%%===================================================================
get_mission_config(MissionID) ->
    [Mission] = lib_config:find(cfg_mission, MissionID),
    Mission.

get_mission_reward(State, Type, FinishTimes, MissionID) when ?IS_MISSION_LOOP(Type) ->
    #c_mission{item = Items, sub_type = SubType} = Config = get_mission_config(MissionID),
    case lib_config:find(cfg_daily_mission, SubType) of
        [#c_daily_mission{reward_times = RewardTimes, rewards = RewardString}] ->
            Items2 = ?IF((FinishTimes rem RewardTimes) =:= 0, get_daily_mission_reward(RewardString), []);
        _ ->
            Items2 = []
    end,
    Exp = get_mission_exp(Config, State),
    {Exp, Items2 ++ Items};
get_mission_reward(State, _Type, _FinishTimes, MissionID) ->
    #c_mission{item = Items} = Config = get_mission_config(MissionID),
    Exp = get_mission_exp(Config, State),
    {Exp, Items}.

get_mission_exp(Config, State) ->
    #c_mission{exp_type = ExpType, exp = Exp} = Config,
    if
        ExpType > 0 ->
            mod_role_level:get_activity_level_exp(mod_role_data:get_role_level(State), Exp);
        true ->
            Exp
    end.


get_refine_level_list(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    lists:flatten([ get_refine_level_list2(Listens, [])|| #r_mission_doing{listens = Listens} <- DoingList]).

get_refine_level_list2([], Acc) ->
    Acc;
get_refine_level_list2([#r_mission_listen{type = Type, val = Val}|R], Acc) ->
    case Type =:= ?MISSION_REFINE of
        true ->
            Acc2 = [Val|lists:delete(Val, Acc)],
            get_refine_level_list2(R, Acc2);
        _ ->
            get_refine_level_list2(R, Acc)
    end.

get_daily_mission_reward(String) ->
    [TypeID, Num, BindType] = string:tokens(String, ","),
    [{lib_tool:to_integer(TypeID), lib_tool:to_integer(Num), lib_tool:to_integer(BindType)}].

get_mission_list(Level) ->
    [MissionList] = lib_config:find(cfg_mission, {level, Level}),
    MissionList.

modify_mission(State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    DoingList2 = [ Doing || #r_mission_doing{id = ID} = Doing <- DoingList, not lists:member(ID, ?FLIER_MISSION_ID_LIST)],
    RoleMission2 = RoleMission#r_role_mission{doing_list = DoingList2},
    State#r_role{role_mission = RoleMission2}.