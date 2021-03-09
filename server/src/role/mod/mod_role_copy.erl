%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. 六月 2017 11:37
%%%-------------------------------------------------------------------
-module(mod_role_copy).
-author("laijichang").
-include("role.hrl").
-include("copy.hrl").
-include("team.hrl").
-include("mission.hrl").
-include("rank.hrl").
-include("marry.hrl").
-include("act_oss.hrl").
-include("proto/mod_role_map.hrl").
-include("proto/mod_role_copy.hrl").
-include("role_extra.hrl").
-include("monster.hrl").
-include("bg_act.hrl").
-include("discount_pay.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    online_i/1,
    zero/1,
    loop_min/2,
    handle/2
]).

-export([
    role_enter_map/1,
    vip_expire/1
]).

-export([
    get_illusion_natintensify/1,
    get_cur_tower_id/1,
    get_cur_five_elements/1,
    get_five_elements_big_floor/1,
    get_tower_act_box/1,
    get_copy_max_id/3,
    is_forge_soul_open/2,
    get_copy_quit_info/1,
    check_copy_enter/2,
    update_role_team/1,
    add_copy_times/3,
    add_limit_times_illusion/4,
    add_illusion/2,
    main_mission/2,
    check_copy_five_elements_open/2,
    get_copy_finish_times/2
]).

-export([
    finish_copy/5,
    finish_team_copy_reward/1,
    copy_failed/2,
    copy_exp_end/3,
    add_marry_copy/1,
    immortal_start/2,
    immortal_auto_summon/1,
    auto_cheer/1,
    five_element_boss_dead/2
]).

-export([
    get_star_finish_goods/3,
    get_copy_exp_multi/1,
    get_copy_times/4,
    get_merge_times/2
]).

-export([
    gm_set_copy_tower/2,
    gm_set_forge_soul/2,
    gm_set_copy_time/2,
    gm_clear_copy_times/1,
    gm_add_copy_times/3,
    gm_copy_exp/1,
    gm_guide_exp/3,
    gm_add_illusion/2,
    gm_add_nat_intensify/2,
    gm_set_universe/2,
    gm_set_five_elements/2
]).

init(#r_role{role_id = RoleID, role_copy = undefined} = State) ->
    [#c_five_elements_floor{max_illusion = MaxIllusion}] = lib_config:find(cfg_five_elements_floor, 1),
    State#r_role{role_copy = #r_role_copy{role_id = RoleID, copy_list = [], illusion = config_illusion(MaxIllusion), last_add_time = time_tool:now()}};
init(State) ->
    State.

day_reset(#r_role{role_id = RoleID, role_copy = RoleCopy} = State) ->
    #r_role_copy{copy_list = CopyList, tower_id = TowerID} = RoleCopy,
    CopyList2 = [CopyItem#r_role_copy_item{enter_times = 0, buy_times = 0, item_add_times = 0, clean_times = 0} || CopyItem <- CopyList],
    do_daily_tower_reward(RoleID, TowerID),
    State2 = mod_role_extra:set_data(?EXTRA_KEY_COPY_GAIN, 0, State),
    State3 = mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State2),
    State3#r_role{role_copy = RoleCopy#r_role_copy{buy_illusion_times = 0, copy_list = CopyList2}}.

online_i(#r_role{role_id = RoleID, role_copy = RoleCopy} = State) ->
    #r_role_copy{
        tower_id = TowerID,
        tower_reward_list = TowerRewardList,
        copy_list = CopyList,
        exp_enter_times = ExpEnterTimes,
        exp_finish_times = ExpFinishTimes,
        exp_merge_times = ExpMergeTimes,
        cur_five_elements = CurFiveElements,
        unlock_floor = UnlockFloor,
        illusion = Illusion,
        buy_illusion_times = BuyIllusionTimes,
        nat_intensify = NatIntensify,
        max_universe = MaxUniverse,
        universe_use_time = UniverseUseTime} = RoleCopy,
    CopyList2 = [trans_to_p_copy_item(CopyItem) || CopyItem <- CopyList],
    IsHaveCopyMarryTimes = mod_role_extra:get_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State),
    common_misc:unicast(RoleID, #m_copy_list_toc{
        tower_id = TowerID,
        copy_list = CopyList2,
        tower_reward_list = TowerRewardList,
        exp_enter_times = ExpEnterTimes,
        exp_finish_times = ExpFinishTimes,
        exp_merge_times = ExpMergeTimes,
        cur_five_elements = CurFiveElements,
        unlock_floor = UnlockFloor,
        illusion = to_front_illusion(Illusion),
        buy_illusion_times = BuyIllusionTimes,
        nat_intensify = NatIntensify,
        max_universe = MaxUniverse,
        universe_use_time = UniverseUseTime,
        is_have_times = IsHaveCopyMarryTimes}),
    CurHonor = mod_role_extra:get_data(?EXTRA_KEY_COPY_GAIN, 0, State),
    common_misc:unicast(RoleID, #m_team_copy_honor_toc{honor = CurHonor}),
    case loop_min_i(time_tool:now(), State) of
        {ok, State2, Illusion2, NatIntensify2} ->
            {ok, State2, Illusion2 - to_front_illusion(Illusion), NatIntensify2 - NatIntensify};
        State2 ->
            {ok, State2, -1, -1}
    end.

zero(State) ->
    update_role_team(State),
    {ok, State2, _, _} = online_i(State),
    State2.

loop_min(Now, State) ->
    case loop_min_i(Now, State) of
        {ok, State2, _Illusion, _NatIntensify} ->
            State2;
        State2 ->
            State2
    end.
loop_min_i(Now, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{
        last_add_time = LastAddTime,
        unlock_floor = UnlockFloor,
        illusion = Illusion,
        nat_intensify = NatIntensify
    } = RoleCopy,
    case mod_role_function:get_is_function_open(?FUNCTION_COPY_FIVE_ELEMENTS, State) of
        true ->
            {AddMin, LastAddTime2} = get_loop_args(LastAddTime, Now),
            case AddMin > 0 of
                true ->
                    {IsChange, Illusion2, NatIntensify2} = get_add_args(AddMin, Illusion, NatIntensify, UnlockFloor),
                    case IsChange of
                        true ->
                            common_misc:unicast(RoleID, #m_copy_min_update_toc{illusion = to_front_illusion(Illusion2), nat_intensify = NatIntensify2}),
                            RoleCopy2 = RoleCopy#r_role_copy{last_add_time = LastAddTime2, illusion = Illusion2, nat_intensify = NatIntensify2},
                            {ok, State#r_role{role_copy = RoleCopy2}, to_front_illusion(Illusion2), NatIntensify2};
                        _ ->
                            RoleCopy2 = RoleCopy#r_role_copy{last_add_time = LastAddTime2},
                            {ok, State#r_role{role_copy = RoleCopy2}, to_front_illusion(RoleCopy2#r_role_copy.illusion), RoleCopy2#r_role_copy.nat_intensify}
                    end;
                _ ->
                    {ok, State, to_front_illusion(RoleCopy#r_role_copy.illusion), RoleCopy#r_role_copy.nat_intensify}
            end;
        _ ->
            RoleCopy2 = RoleCopy#r_role_copy{last_add_time = Now},
            State#r_role{role_copy = RoleCopy2}
    end.

get_illusion_natintensify(#r_role{role_copy = RoleCopy}) ->
    #r_role_copy{illusion = Illusion, nat_intensify = NatIntensify} = RoleCopy,
    {to_front_illusion(Illusion), NatIntensify}.

handle({finish_copy, MapID, Stars, UseTimeMs, ExtraArgs}, State) ->
    do_finish_copy(MapID, Stars, UseTimeMs, ExtraArgs, State);
handle(finish_team_copy_reward, State) ->
    do_finish_team_copy_reward(State);
handle({copy_failed, MapID}, State) ->
    do_copy_failed(MapID, State);
handle({copy_exp_end, MapID, EndTime}, State) ->
    do_copy_exp_end(EndTime, MapID, State);
handle(add_marry_copy, State) ->
    do_add_marry_copy(State);
handle({immortal_start, GuardList}, State) ->
    do_immortal_start(GuardList, State);
handle(immortal_auto_summon, State) ->
    do_immortal_summon(State#r_role.role_id, false, State);
handle(auto_cheer, State) ->
    do_auto_cheer(State);
handle({five_element_boss_dead, TypeID}, State) ->
    do_five_element_boss_dead(TypeID, State);
handle({#m_copy_cheer_tos{id = ID, asset_type = AssetType}, RoleID, _PID}, State) ->
    do_cheer(RoleID, ID, AssetType, State);
handle({#m_copy_exp_cheer_status_tos{is_silver_auto = IsSilverAuto, is_gold_auto = IsGoldAuto}, _RoleID, _PID}, State) ->
    mod_role_extra:set_data(?EXTRA_KEY_COPY_EXP_AUTO, {IsSilverAuto, IsGoldAuto, true}, State);
handle({#m_copy_exp_merge_times_tos{merge_times = MergeTimes}, RoleID, _PID}, State) ->
    do_exp_merge(RoleID, MergeTimes, State);
handle({#m_copy_clean_tos{map_id = MapID, num = Num, boss_num = BossNum}, RoleID, _PID}, State) ->
    do_clean(RoleID, MapID, Num, BossNum, State);
handle({#m_copy_buy_times_tos{map_id = MapID}, RoleID, _PID}, State) ->
    do_buy_times(RoleID, MapID, State);
handle({#m_copy_cd_remove_tos{copy_id = CopyID}, RoleID, _PID}, State) ->
    do_cd_remove(RoleID, CopyID, State);
handle({#m_copy_restart_tos{}, RoleID, _PID}, State) ->
    do_copy_restart(RoleID, State);
handle({#m_copy_immortal_reset_guard_tos{}, RoleID, _PID}, State) ->
    do_immortal_reset(RoleID, State);
handle({#m_copy_immortal_summon_boss_tos{}, RoleID, _PID}, State) ->
    do_immortal_summon(RoleID, true, State);
handle({#m_copy_five_elements_unlock_tos{unlock_floor = UnlockFloor}, RoleID, _PID}, State) ->
    do_five_elements_unlock(RoleID, UnlockFloor, State);
handle({#m_copy_buy_illusion_tos{buy_times = BuyTimes}, RoleID, _PID}, State) ->
    do_buy_illusion(RoleID, BuyTimes, State);
handle({#m_copy_nat_intensify_tos{}, RoleID, _PID}, State) ->
    do_nat_intensify(RoleID, State);
handle(Info, State) ->
    ?ERROR_MSG("unknow Info: ~w", [Info]),
    State.

role_enter_map(State) ->
    case map_misc:is_copy_exp(mod_role_data:get_role_map_id(State)) of
        true ->
            {IsSilverAuto, IsGoldAuto, HasFirstOpen} = get_copy_exp_auto_status(State),
            common_misc:unicast(State#r_role.role_id, #m_copy_exp_cheer_status_toc{is_silver_auto = IsSilverAuto, is_gold_auto = IsGoldAuto, has_first_open = HasFirstOpen}),
            ok;
        _ ->
            ignore
    end.

vip_expire(State) ->
    do_exp_merge(State#r_role.role_id, 1, State).

get_cur_tower_id(State) ->
    #r_role{role_copy = #r_role_copy{tower_id = TowerID}} = State,
    TowerID.

get_cur_five_elements(State) ->
    #r_role{role_copy = #r_role_copy{cur_five_elements = CurFiveElements}} = State,
    CurFiveElements.

get_five_elements_big_floor(State) ->
    #r_role{role_copy = #r_role_copy{unlock_floor = UnlockFloor}} = State,
    UnlockFloor.

get_tower_act_box(State) ->
    #r_role{role_copy = #r_role_copy{tower_id = TowerID}} = State,
    case lib_config:find(cfg_copy_tower, TowerID) of
        [#c_copy_tower{activity_box_id = BoxID}] ->
            BoxID;
        _ ->
            0
    end.

get_copy_max_id(CopyType, CopyID, State) ->
    #r_role{role_copy = #r_role_copy{copy_list = CopyList}} = State,
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{star_list = StarList} when StarList =/= [] ->
            lists:max([CopyIDT || #p_kv{id = CopyIDT} <- StarList]);
        _ ->
            CopyID
    end.

%% 装备铸魂某个部位是否开启
is_forge_soul_open(CopyID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    case lists:keyfind(?COPY_FORGE_SOUL, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{star_list = StarList} when StarList =/= [] ->
            [#p_kv{id = MaxMapID}|_] = lists:reverse(lists:keysort(#p_kv.id, StarList)),
            MaxMapID >= CopyID;
        _ ->
            false
    end.

get_copy_quit_info(MapID) ->
    ?IF(map_misc:is_copy_front(MapID), ok, get_copy_quit_info2(MapID)).

get_copy_quit_info2(MapID) ->
    [#c_copy{leave_map_id = LeaveMapID, leave_map_pos = MapPos}] = lib_config:find(cfg_copy, MapID),
    case LeaveMapID > 0 of
        true ->
            [Mx, My] = string:tokens(MapPos, ","),
            Pos = map_misc:get_pos_by_meter(lib_tool:to_integer(Mx), lib_tool:to_integer(My)),
            {LeaveMapID, Pos};
        _ ->
            ok
    end.

%% 进入地图前的检查
%% 返回{State, ExtraID, BagDoings, MapParams}
check_copy_enter(MapID, State) ->
    #r_role{role_id = RoleID} = State,
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    if
        ?IS_COPY_OLD_OFFLINE_SOLO(CopyType) ->
            {State, RoleID, [], []};
        ?IS_COPY_OFFLINE_SOLO(CopyType) ->
            ChallengeArgs = mod_role_offline_solo:check_enter(State),
            {State, RoleID, [], ChallengeArgs};
        ?IS_COPY_FRONT(CopyType) ->
            MainExtraID = mod_role_mission:get_main_mission_id(State),
            {State, RoleID * ?MAX_MISSION_ID + MainExtraID, [], []};
        ?IS_COPY_TOWER(CopyType) ->
            {check_copy_tower(MapID, State), RoleID, [], []};
        ?IS_COPY_TREASURE(CopyType) ->
            {State, RoleID, [], []};
        ?IS_COPY_GUIDE_BOSS(CopyType) ->
            mod_role_world_boss:check_guide_boss(State),
            {State, RoleID, [], []};
        ?IS_COPY_EVIL(CopyType) -> %% 心魔副本
            {State2, BagDoings} = check_mission(MapID, State),
            {State2, RoleID, BagDoings, []};
        ?IS_COPY_EXP(CopyType) ->
            {State2, BagDoings} = check_copy_exp(MapID, State),
            {State2, RoleID, BagDoings, []};
        ?IS_COPY_TREASURE_SECRET(CopyType) ->
            check_copy_treasure_secret(State),
            {State, RoleID, [], []};
        ?IS_COPY_FIVE_ELEMENTS(CopyType) ->
            check_copy_five_elements(MapID, State),
            {State, RoleID, [], []};
        ?IS_COPY_UNIVERSE(CopyType) ->
            check_copy_universe(MapID, State),
            {State, RoleID, [], []};
        true ->
            {State2, BagDoings} = check_copy_normal(MapID, State),
            {State2, RoleID, BagDoings, []}
    end.

%% 爬塔副本进入前的检查
check_copy_tower(MapID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{tower_id = TowerID} = RoleCopy,
    ?IF((MapID =:= TowerID + 1) orelse (TowerID =:= 0 andalso MapID =:= ?COPY_FIRST_TOWER), ok, ?THROW_ERR(?ERROR_PRE_ENTER_004)),
    case lib_config:find(cfg_copy, MapID) of
        [#c_copy{enter_level = EnterLevel}] ->
            ?IF(mod_role_data:get_role_level(State) >= EnterLevel, ok, ?THROW_ERR(?ERROR_PRE_ENTER_001)),
            State;
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_004)
    end.

%% 检查有
check_mission(MapID, State) ->
    #r_role{role_mission = RoleMission} = State,
    #r_role_mission{doing_list = DoingList} = RoleMission,
    case catch check_mission2(DoingList, MapID) of
        true ->
            {State, []};
        _ ->
            ?THROW_ERR(?ERROR_PRE_ENTER_019)
    end.

check_mission2([], _MapID) ->
    false;
check_mission2([MissionDoing|R], MapID) ->
    #r_mission_doing{listens = Listens, status = Status} = MissionDoing,
    [?IF(Status =:= ?MISSION_STATUS_DOING andalso NeedMapID =:= MapID, erlang:throw(true), ok) || #r_mission_listen{val = NeedMapID} <- Listens],
    check_mission2(R, MapID).


%% 经验副本次数
check_copy_exp(MapID, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{
        exp_finish_times = ExpFinishTimes,
        exp_enter_times = ExpEnterTimes,
        copy_list = CopyList} = RoleCopy,
    NeedFinishTimes = common_misc:get_global_int(?GLOBAL_COPY_EXP),
    case ExpFinishTimes >= NeedFinishTimes of
        true -> %% 已经完成了N次，按正常流程检测
            check_copy_normal(MapID, State);
        _ -> %% 新手流程
            CopyList2 =
            case lists:keyfind(?COPY_EXP, #r_role_copy_item.copy_type, CopyList) of
                #r_role_copy_item{can_enter_time = CanEnterTime} ->
                    ?IF(time_tool:now() >= CanEnterTime, ok, ?THROW_ERR(?ERROR_PRE_ENTER_008)),
                    CopyList;
                _ ->
                    CopyItem2 = #r_role_copy_item{copy_type = ?COPY_EXP},
                    [CopyItem2|CopyList]
            end,
            [#c_copy{use_item = UseItem}] = lib_config:find(cfg_copy, MapID),
            BagDoings = check_use_item(UseItem, 1, State),
            ?IF(ExpEnterTimes > 0, ok, ?THROW_ERR(?ERROR_PRE_ENTER_002)),
            ExpEnterTimes2 = ExpEnterTimes - 1,
            common_misc:unicast(RoleID, #m_copy_exp_guide_times_toc{exp_finish_times = ExpFinishTimes, exp_enter_times = ExpEnterTimes2}),
            RoleCopy2 = RoleCopy#r_role_copy{exp_enter_times = ExpEnterTimes2, copy_list = CopyList2},
            State2 = State#r_role{role_copy = RoleCopy2},
            {State2, BagDoings}
    end.


%% 五行副本
check_copy_five_elements(MapID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{cur_five_elements = CurFiveElements, unlock_floor = UnlockFloor, illusion = Illusion} = RoleCopy,
    [#c_five_elements_detail{
        floor = EnterFloor,
        is_big_floor = IsBigFloor,
        step_num = StepNum,
        need_illusion = NeedIllusion
    }] = lib_config:find(cfg_five_elements_detail, MapID),
    if
        CurFiveElements >= MapID ->
            ?IF(IsBigFloor > 0, ok, ?THROW_ERR(?ERROR_PRE_ENTER_032));
        CurFiveElements =:= 0 ->
            ?IF(EnterFloor =:= 1 andalso StepNum =:= 1, ok, ?THROW_ERR(?ERROR_PRE_ENTER_033));
        true ->
            ?IF((UnlockFloor =:= EnterFloor andalso MapID =:= CurFiveElements + 1) orelse (UnlockFloor =:= EnterFloor andalso StepNum =:= 1),
                ok,
                ?THROW_ERR(?ERROR_PRE_ENTER_033))
    end,
    Illusion2 = Illusion - config_illusion(NeedIllusion),
    ?IF(Illusion2 > 0, ok, ?THROW_ERR(?ERROR_PRE_ENTER_034)).

%% 五行副本
finish_copy_five_elements(MapID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{illusion = Illusion} = RoleCopy,
    [#c_five_elements_detail{
        need_illusion = NeedIllusion
    }] = lib_config:find(cfg_five_elements_detail, MapID),
    Illusion2 = Illusion - config_illusion(NeedIllusion),
    RoleCopy2 = RoleCopy#r_role_copy{illusion = Illusion2},
    State2 = State#r_role{role_copy = RoleCopy2},
    {State2, Illusion2}.

check_copy_treasure_secret(State) ->
    ?IF(mod_role_bg_act:is_bg_act_open(?BG_ACT_SECRET_TERRITORY, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)).

check_copy_universe(MapID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{max_universe = MaxUniverse} = RoleCopy,
    ?IF(MaxUniverse >= MapID - 1 orelse (MaxUniverse =:= 0 andalso MapID =:= ?COPY_FIRST_UNIVERSE), ok, ?THROW_ERR(?ERROR_PRE_ENTER_004)),
    ok.


check_use_item(UseItem, Times, State) ->
    case UseItem of
        [] ->
            [];
        [TypeID, Num] ->
            mod_role_bag:check_num_by_type_id(TypeID, Num * Times, ?ITEM_REDUCE_ENTER_MAP, State)
    end.

%% 普通副本的检查
check_copy_normal(MapID, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{
        copy_list = CopyList,
        exp_merge_times = ExpMergeTimes
    } = RoleCopy,
    [#c_copy{
        copy_type = CopyType,
        copy_degree = CopyDegree,
        enter_time = _EnterTime,
        times_type = TimesType,
        times = Times,
        enter_level = EnterLevel,
        use_item = UseItem}] = lib_config:find(cfg_copy, MapID),
    ?IF(mod_role_data:get_role_level(State) >= EnterLevel, ok, ?THROW_ERR(?ERROR_PRE_ENTER_001)),
    Flag = mod_role_extra:get_data(?EXTRA_KEY_ENTER_PERSONAL_BOSS, ?NOT_ENTER_PERSONAL_BOSS, State),
    MergeTimes = get_merge_times(CopyType, ExpMergeTimes),
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{star_list = StarList} = CopyItem ->
            NowDegree = get_copy_degree(CopyType, StarList, 0),
            ?IF(NowDegree >= CopyDegree, ok, ?THROW_ERR(?ERROR_PRE_ENTER_004)),
            #r_role_copy_item{enter_times = EnterTimes, can_enter_time = CanEnterTime} = CopyItem,
            CopyTimes = get_copy_times(CopyItem, CopyType, Times, State),
            ?IF(time_tool:now() >= CanEnterTime, ok, ?THROW_ERR(?ERROR_PRE_ENTER_008)),
            case CopyType =:= ?COPY_EQUIP orelse CopyType =:= ?COPY_MARRY of
                true ->
                    ok;
                _ ->
                    ?IF(CopyTimes >= EnterTimes + MergeTimes, ok, ?THROW_ERR(?ERROR_PRE_ENTER_002))
            end,
            %% 在此处肯定之前已进入过，如果flag为0，则置为1
            Flag2 = ?IF(Flag =:= ?NOT_ENTER_PERSONAL_BOSS, ?ENTER_PERSONAL_BOSS, Flag),
            EnterTimes2 =
            case TimesType =:= ?TIMES_TYPE_SUCC of
                true ->
                    EnterTimes;
                _ ->
                    ?IF(CopyTimes < EnterTimes + MergeTimes, CopyTimes, EnterTimes + MergeTimes)
            end,
            IsHaveMarryTimes = ?IF(CopyType =:= ?COPY_MARRY andalso CopyTimes >= EnterTimes2, ?NOT_HAVE_COPY_MARRY_TIMES, ?HAVE_COPY_MARRY_TIMES),
%%            EnterTimes2 = ?IF(TimesType =:= ?TIMES_TYPE_SUCC, EnterTimes, EnterTimes + MergeTimes),
            CopyItem2 = CopyItem#r_role_copy_item{enter_times = EnterTimes2},
            CopyList2 = lists:keystore(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2);
        _ ->
            CopyTimes = get_copy_times(undefined, CopyType, Times, State),
            case CopyType =:= ?COPY_EQUIP orelse CopyType =:= ?COPY_MARRY of
                true ->
                    ok;
                _ ->
                    ?IF(CopyTimes >= MergeTimes, ok, ?THROW_ERR(?ERROR_PRE_ENTER_002))
            end,
            ?IF(CopyDegree =< ?COPY_DEGREE_NORMAL, ok, ?THROW_ERR(?ERROR_PRE_ENTER_004)),
            Flag2 = Flag,
            %% 新号第一次进入个人boss次数不扣除
            EnterTimes =
            case TimesType =:= ?TIMES_TYPE_SUCC of
                true ->
                    0;
                _ ->
                    ?IF(CopyType =:= ?COPY_WORLD_BOSS andalso Flag =:= ?NOT_ENTER_PERSONAL_BOSS,  0, 1)
            end,
            IsHaveMarryTimes = ?IF(CopyType =:= ?COPY_MARRY andalso CopyTimes >= EnterTimes, ?NOT_HAVE_COPY_MARRY_TIMES, ?HAVE_COPY_MARRY_TIMES),
%%            EnterTimes = ?IF(TimesType =:= ?TIMES_TYPE_SUCC, 0, 1),
            CopyItem2 = #r_role_copy_item{copy_type = CopyType, enter_times = EnterTimes},
            CopyList2 = [CopyItem2|CopyList]
    end,
    BagDoings =
    case CopyType of
        ?COPY_WORLD_BOSS -> %% 个人boss读另外配置
            check_personal_boss(CopyItem2, MapID, Flag2, State);
        _ ->
            check_use_item(UseItem, MergeTimes, State)
    end,
    do_copy_item_update(RoleID, CopyItem2),
    RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2, exp_now_merge_times = MergeTimes},
    State2 = mod_role_extra:set_data(?EXTRA_KEY_ENTER_PERSONAL_BOSS, ?ENTER_PERSONAL_BOSS, State),
    State3 = mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, IsHaveMarryTimes, State2),
    State4 = State3#r_role{role_copy = RoleCopy2},
    ?IF(map_misc:is_copy_team(MapID), update_role_team(State4), ok),
    case map_misc:is_copy_confine(MapID) of
        false ->
            {State4, BagDoings};
        _ ->
            State5 = mod_role_confine:check_can_in(MapID, State4),
            {State5, []}
    end.


finish_copy(RoleID, MapID, Stars, UseTimeMs, ExtraArgs) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {finish_copy, MapID, Stars, UseTimeMs, ExtraArgs}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, finish_copy, [RoleID, MapID, Stars, UseTimeMs, ExtraArgs]})
    end.

finish_team_copy_reward(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, finish_team_copy_reward});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, finish_team_copy_reward, [RoleID]})
    end.

copy_failed(RoleID, MapID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {copy_failed, MapID}}).

copy_exp_end(RoleID, MapID, EndTime) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, {copy_exp_end, MapID, EndTime}});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, copy_exp_end, [RoleID, MapID, EndTime]})
    end.

add_marry_copy(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {mod, ?MODULE, add_marry_copy});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, add_marry_copy, [RoleID]})
    end.

immortal_start(RoleID, GuardList) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {immortal_start, GuardList}}).

immortal_auto_summon(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, immortal_auto_summon}).

auto_cheer(RoleID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, auto_cheer}).

five_element_boss_dead(RoleID, TypeID) ->
    role_misc:info_role(RoleID, ?MODULE, {five_element_boss_dead, TypeID}).

gm_set_copy_tower(TowerID, State) ->
    do_finish_copy(TowerID, 3, 0, [], State).

gm_set_forge_soul(CopyID, State) ->
    case CopyID > 50001 of
        true ->
            #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
            #r_role_copy{copy_list = CopyList} = RoleCopy,
            {CopyItem, CopyList2} =
            case lists:keytake(?COPY_FORGE_SOUL, #r_role_copy_item.copy_type, CopyList) of
                {value, CopyItemT, CopyListT} ->
                    {CopyItemT, CopyListT};
                _ ->
                    {#r_role_copy_item{copy_type = ?COPY_FORGE_SOUL}, CopyList}
            end,
            StarList2 = [#p_kv{id = ID, val = 3} || ID <- lists:seq(50001, CopyID - 1)],
            CopyItem2 = CopyItem#r_role_copy_item{star_list = StarList2},
            do_copy_item_update(RoleID, CopyItem2),
            CopyList3 = [CopyItem2|CopyList2],
            RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList3},
            State#r_role{role_copy = RoleCopy2};
        _ ->
            State
    end.

gm_set_copy_time(RemainTime, State) ->
    case map_misc:is_copy(State#r_role.role_map#r_role_map.map_id) of
        true ->
            map_misc:info(mod_role_dict:get_map_pid(), {mod, copy_common, {gm_set_copy_time, RemainTime}});
        _ ->
            ok
    end,
    State.

gm_clear_copy_times(State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    CopyList2 =
    [begin
         CopyItem2 = CopyItem#r_role_copy_item{enter_times = 0},
         do_copy_item_update(RoleID, CopyItem2),
         CopyItem2
     end || CopyItem <- CopyList],
    State2 = mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State),
    State3 = State2#r_role{role_copy = RoleCopy#r_role_copy{copy_list = CopyList2}},
    update_role_team(State3),
    zero(State3).

gm_add_copy_times(CopyType, AddTimes, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{enter_times = EnterTimes} = CopyItem ->
            CopyItem2 = CopyItem#r_role_copy_item{enter_times = EnterTimes + AddTimes};
        _ ->
            CopyItem2 = #r_role_copy_item{copy_type = CopyType, enter_times = AddTimes}
    end,
    CopyList2 = lists:keystore(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2),
    do_copy_item_update(RoleID, CopyItem2),
    State2 = ?IF(CopyType =:= ?COPY_MARRY, mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State), State),
    State3 = State2#r_role{role_copy = RoleCopy#r_role_copy{copy_list = CopyList2}},
    update_role_team(State3),
    State3.

gm_copy_exp(State) ->
    MonsterList = common_misc:get_global_string_list(?GLOBAL_COPY_EXP_MONSTER),
    NumList = [180, 160, 150],
    gm_set_copy_time(0, State),
    gm_copy_exp(NumList, MonsterList, State).

gm_copy_exp([], [], State) ->
    State;
gm_copy_exp([Num|R1], [{_, MonsterTypeID}|R2], State) ->
    StateAcc =
    lists:foldl(
        fun(_, StateAcc) ->
            Level = mod_role_data:get_role_level(StateAcc),
            [Config] = lib_config:find(cfg_dynamic_calc, MonsterTypeID),
            #c_dynamic_calc{exp_multi = ExpMulti} = Config,
            [#c_dynamic_standard{copy_exp = CopyExp}] = lib_config:find(cfg_dynamic_standard, Level),
            Exp = lib_tool:ceil(ExpMulti * CopyExp / 100),
            mod_role_level:do_monster_dead_add_exp(StateAcc, Exp)
        end, State, lists:seq(1, Num)),
    gm_copy_exp(R1, R2, StateAcc).

gm_guide_exp(FinishTimes, EnterTimes, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    RoleCopy2 = RoleCopy#r_role_copy{exp_finish_times = FinishTimes, exp_enter_times = EnterTimes},
    common_misc:unicast(RoleID, #m_copy_exp_guide_times_toc{exp_finish_times = FinishTimes, exp_enter_times = EnterTimes}),
    State#r_role{role_copy = RoleCopy2}.

gm_add_illusion(AddIllusion, State) ->
    add_illusion(AddIllusion, State).

add_illusion(AddIllusion, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{illusion = Illusion} = RoleCopy,
    Illusion2 = Illusion + config_illusion(AddIllusion),
    common_misc:unicast(RoleID, #m_copy_illusion_update_toc{illusion = to_front_illusion(Illusion2)}),
    RoleCopy2 = RoleCopy#r_role_copy{illusion = Illusion2},
    State#r_role{role_copy = RoleCopy2}.

gm_add_nat_intensify(AddIllusion, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{illusion = Illusion, nat_intensify = NatIntensify} = RoleCopy,
    NatIntensify2 = NatIntensify + AddIllusion,
    common_misc:unicast(RoleID, #m_copy_min_update_toc{illusion = to_front_illusion(Illusion), nat_intensify = NatIntensify2}),
    RoleCopy2 = RoleCopy#r_role_copy{nat_intensify = NatIntensify2},
    State#r_role{role_copy = RoleCopy2}.

gm_set_universe(CopyID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    RoleCopy2 = RoleCopy#r_role_copy{max_universe = CopyID},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, State3, _, _} = online_i(State2),
    State3.

gm_set_five_elements(CopyID, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    Floor =
    case CopyID > 0 of
        true ->
            [#c_five_elements_detail{floor = FloorT}] = lib_config:find(cfg_five_elements_detail, CopyID),
            FloorT;
        _ ->
            1
    end,
    mod_role_rank:update_rank(?RANK_COPY_FIVE_ELEMENTS, {RoleID, CopyID, time_tool:now()}),
    RoleCopy2 = RoleCopy#r_role_copy{cur_five_elements = CopyID, unlock_floor = Floor},
    State2 = State#r_role{role_copy = RoleCopy2},
    State3 = mod_role_day_target:copy_five_elements(State2),
    {ok, State4, _, _} = online_i(State3),
    State4.

%% ====================================================================
%%% Internal functions
%% ====================================================================
do_finish_copy(MapID, Stars, UseTimeMs, ExtraArgs, State) ->
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    State2 =
    if
        ?IS_COPY_OFFLINE_SOLO(CopyType) ->
            State;
        ?IS_COPY_FRONT(CopyType) ->
            State;
        ?IS_COPY_TOWER(CopyType) ->
            do_finish_tower(MapID, State);
        ?IS_COPY_TREASURE(CopyType) ->
            State;
        ?IS_COPY_GUIDE_BOSS(CopyType) ->
            do_copy_first_past(CopyType, State);
        ?IS_COPY_FIVE_ELEMENTS(CopyType) ->
            do_finish_five_elements(MapID, CopyType, State);
        ?IS_COPY_UNIVERSE(CopyType) ->
            do_finish_universe(MapID, Stars, UseTimeMs, ExtraArgs, State);
        true ->
            do_finish_normal(MapID, Stars, State)
    end,
    mod_role_mission:finish_copy(MapID, State2).

%% 完成爬塔
do_finish_tower(MapID, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    RoleCopy2 = RoleCopy#r_role_copy{tower_id = MapID},
    common_misc:unicast(RoleID, #m_copy_tower_update_toc{tower_id = MapID}),
    Floor = ?GET_TOWER_FLOOR(MapID),
    mod_role_rank:update_rank(?RANK_COPY_TOWER, {RoleID, Floor, time_tool:now()}),
    [#c_copy_tower{accept_rewards = AcceptRewards, finish_rewards = FinishRewards, finish_box = BoxTypeID}] = lib_config:find(cfg_copy_tower, MapID),
    GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(FinishRewards)],
    State1 = State#r_role{role_copy = RoleCopy2},
    {GoodsList2, State2} = mod_role_package:get_package_goods(BoxTypeID, State1),
    AllGoodsList = GoodsList ++ GoodsList2,
    {PanelGoods, BroadcastGoods} =
    lists:foldl(
        fun(#p_goods{type_id = GoodsTypeID, num = GoodsNum} = Goods, {Acc1, Acc2}) ->
            NewAcc1 = [#p_kv{id = GoodsTypeID, val = GoodsNum}|Acc1],
            #c_item{quality = Quality} = mod_role_item:get_item_config(GoodsTypeID),
            NewAcc2 = ?IF(Quality >= ?QUALITY_RED, [Goods|Acc2], Acc2),
            {NewAcc1, NewAcc2}
        end, {[], []}, AllGoodsList),
    ?IF(BroadcastGoods =/= [], common_broadcast:send_world_common_notice(?NOTICE_RUNE_TOWER, [mod_role_data:get_role_name(State2)], BroadcastGoods), ok),
    %% 这里创建的都是货币类的东西，不会存在背包不足的情况
    BagDoings = [{create, ?ITEM_GAIN_FINISH_TOWER_REWARD, AllGoodsList}],
    State3 = mod_role_map_panel:add_drop(PanelGoods, State2),
    State4 = mod_role_achievement:copy_tower(Floor, State3),
    State5 = mod_role_confine:copy_tower(Floor, State4),
    ?TRY_CATCH(mod_role_log_statistics:copy_finish(MapID, State5)),
    case AcceptRewards =/= "" of
        true ->
            AcceptGoods = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- common_misc:get_item_reward(AcceptRewards)],
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_COPY_TOWER_REWARD,
                text_string = [lib_tool:to_list(Floor)],
                action = ?ITEM_GAIN_TOWER_ACCEPT,
                goods_list = AcceptGoods
            },
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            ok
    end,
    State6 = mod_role_bag:do(BagDoings, State5),
    State7 = do_copy_first_past(?COPY_TOWER, State6),
    mod_role_day_target:copy_tower(State7).

%% 完成太虚
do_finish_universe(MapID, Stars, UseTime, Power, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{max_universe = MaxUniverse, universe_use_time = UniverseUseTime} = RoleCopy,
    {MaxUniverse2, UniverseUseTime2, State2} =
    if
        MapID > MaxUniverse -> %% 记录刷新
            [Config] = lib_config:find(cfg_copy, MapID),
            RoleCopy2 = RoleCopy#r_role_copy{max_universe = MapID, universe_use_time = UseTime},
            StateT = State#r_role{role_copy = RoleCopy2},
            StateT2 = do_finish_normal_reward(Stars, Config, StateT),
            {MapID, UseTime, StateT2};
        MapID =:= MaxUniverse -> %% 同一层
            UniverseUseTimeT = ?IF(UseTime < UniverseUseTime, UseTime, UniverseUseTime),
            RoleCopy2 = RoleCopy#r_role_copy{universe_use_time = UniverseUseTimeT},
            StateT = State#r_role{role_copy = RoleCopy2},
            {MaxUniverse, UniverseUseTimeT, StateT};
        true ->
            {MaxUniverse, UniverseUseTime, State}
    end,
    Status = mod_role_universe:role_finish_copy(MapID, UseTime, Power, State),
    common_misc:unicast(RoleID, #m_copy_max_universe_update_toc{max_universe = MaxUniverse2, universe_use_time = UniverseUseTime2, status = Status}),
    do_copy_first_past(?COPY_UNIVERSE, State2).

%% 完成五行秘境
do_finish_five_elements(MapID, CopyType, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{cur_five_elements = CurFiveElements} = RoleCopy,
    [ #c_five_elements_detail{
        first_reward = FirstReward,
        fist_drop_list = FirstDropList
    } = Config] = lib_config:find(cfg_five_elements_detail, MapID),
    {GoodsList1, PanelGoods1, AllDropIDList, RoleCopy2} =
    case MapID > CurFiveElements of
        true ->
            mod_role_rank:update_rank(?RANK_COPY_FIVE_ELEMENTS, {RoleID, MapID, time_tool:now()}),
            common_misc:unicast(RoleID, #m_copy_five_elements_update_toc{cur_five_elements = MapID}),
            ItemReward = common_misc:get_item_reward(FirstReward),
            RoleCopyT = RoleCopy#r_role_copy{cur_five_elements = MapID},
            {common_misc:get_reward_p_goods(ItemReward), [#p_kv{id = TypeID, val = Num} || {TypeID, Num} <- ItemReward], FirstDropList, RoleCopyT};
        _ ->
            DropIDList = get_five_elements_normal_drop(Config),
            {[], [], DropIDList, RoleCopy}
    end,
    {GoodsList2, PanelGoods2, State2} = mod_role_world_boss:get_drop_and_panel_goods(AllDropIDList, State),
    State3 = mod_role_map_panel:add_drop(PanelGoods1 ++ PanelGoods2, State2),
    State4 = State3#r_role{role_copy = RoleCopy2},
    State5 = role_misc:create_goods(State4, ?ITEM_GAIN_FIVE_ELEMENTS_PASS, GoodsList1 ++ GoodsList2),
    State6 = do_copy_first_past(CopyType, State5),
    case catch finish_copy_five_elements(MapID, State6) of
        {State7, Illusion2} ->
            common_misc:unicast(RoleID, #m_copy_illusion_update_toc{illusion = to_front_illusion(Illusion2)});
        _ ->
            State7 = State6
    end,
    %% 五行密境hook
    FunList = [
        fun(StateAcc) -> mod_role_day_target:copy_five_elements(StateAcc) end,
        fun(StateAcc) -> mod_role_confine:copy_five_elements(StateAcc, MapID) end,
        fun(StateAcc) -> mod_role_act_rank:copy_five_elements(StateAcc) end
    ],
    role_server:execute_state_fun(FunList, State7).

do_finish_normal(MapID, Stars, State) ->
    [#c_copy{copy_type = CopyType} = Config] = lib_config:find(cfg_copy, MapID),
    TempState = do_copy_first_past(CopyType, State),
    State2 = do_finish_normal_update_copy(MapID, Stars, Config, TempState),
    State3 = do_finish_normal_reward(Stars, Config, State2),
    ?IF(map_misc:is_copy_team(MapID), ?TRY_CATCH(update_role_team(State3)), ok),
    do_finish_trigger(CopyType, MapID, Stars, State3).

do_finish_team_copy_reward(State) ->
    #r_role{role_id = RoleID} = State,
    [OneReward, RewardLimit|_] = common_misc:get_global_list(?GLOBAL_TEAM_COPY),
    GoodsID = common_misc:get_global_int(?GLOBAL_TEAM_COPY),
    CurHonor = mod_role_extra:get_data(?EXTRA_KEY_COPY_GAIN, 0, State),
    case CurHonor < RewardLimit of
        true ->
            CurHonor2 = ?IF(CurHonor + OneReward > RewardLimit, RewardLimit, CurHonor + OneReward),
            common_misc:unicast(RoleID, #m_team_copy_honor_toc{honor = CurHonor2}),
            State2 = mod_role_extra:set_data(?EXTRA_KEY_COPY_GAIN, CurHonor2, State),
            GoodsList = [#p_goods{type_id = GoodsID, num = OneReward}],
            PanelGoods = [#p_kv{id = TypeID, val = Num} || #p_goods{type_id = TypeID, num = Num} <- GoodsList],
            State3 = mod_role_map_panel:add_drop(PanelGoods, State2),
            role_misc:create_goods(State3, ?ITEM_GAIN_COPY_FINISH, GoodsList);
        _ ->
            State
    end.

do_finish_trigger(CopyType, MapID, Stars, State) ->
    FunList1 =
    if
        Stars =:= ?COPY_STAR_3 ->
            [
                fun(StateAcc) -> mod_role_achievement:copy_three_star(MapID, StateAcc) end,
                fun(StateAcc) -> mod_role_confine:three_start_copy(CopyType, MapID, StateAcc) end
            ];
        true ->
            []
    end,
    FunList2 =
    case CopyType of
        ?COPY_EXP ->
            [
                fun(StateAcc) -> hook_role:finish_copy_exp(StateAcc) end
            ];
        ?COPY_SINGLE_TD ->
            [
                fun(StateAcc) -> mod_role_confine:copy_ruins(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:copy_pet(StateAcc) end,
                fun(StateAcc) -> mod_role_bg_act_mission:copy_ruins(StateAcc) end,
                fun(StateAcc) -> mod_role_cycle_mission:copy_ruins(StateAcc) end,
                fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_SLG, 1) end,
                fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_SLG, 1) end
            ];
        ?COPY_SILVER ->
            [
                fun(StateAcc) -> mod_role_confine:copy_vault(StateAcc) end,
                fun(StateAcc) -> mod_role_cycle_mission:copy_vault(StateAcc) end,
                fun(StateAcc) -> mod_role_bg_act_mission:copy_vault(StateAcc) end,
                fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_BJW, 1) end,
                fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_BJW, 1) end
            ];
        ?COPY_IMMORTAL ->
            [
                fun(StateAcc) -> mod_role_confine:copy_forest(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:copy_immortal(StateAcc) end,
                fun(StateAcc) -> mod_role_bg_act_mission:copy_forest(StateAcc) end,
                fun(StateAcc) -> mod_role_cycle_mission:copy_forest(StateAcc) end,
                fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_YHL, 1) end,
                fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_YHL, 1) end
            ];
        ?COPY_EQUIP ->
            [
                fun(StateAcc) -> mod_role_confine:copy_equip(StateAcc) end,
                fun(StateAcc) -> mod_role_cycle_mission:copy_equip(StateAcc) end,
                fun(StateAcc) -> mod_role_bg_act_mission:copy_equip(StateAcc) end,
                fun(StateAcc) -> mod_role_day_target:copy_team(StateAcc) end,
                fun(StateAcc) -> mod_role_act_os_second:do_task(StateAcc, ?OSS_EQUIP_MAP, 1) end,
                fun(StateAcc) -> mod_role_act_otf:do_task(StateAcc, ?OSS_EQUIP_MAP, 1) end];
        ?COPY_MARRY ->
            [fun(StateAcc) -> mod_role_day_target:copy_team(StateAcc) end];
        ?COPY_CONFINE ->
            [fun(StateAcc) -> mod_role_confine:do_confine_up(StateAcc, MapID) end];
        _ ->
            []
    end,
    ?TRY_CATCH(mod_role_log_statistics:copy_finish(MapID, State), Err1),
    role_server:execute_state_fun(FunList1 ++ FunList2, State).

do_finish_normal_reward(Stars, Config, State) ->
    GoodsList = get_star_finish_goods(Stars, mod_role_data:get_role_level(State), Config),
    PanelGoods = [#p_kv{id = TypeID, val = Num} || #p_goods{type_id = TypeID, num = Num} <- GoodsList],
    State2 = mod_role_map_panel:add_drop(PanelGoods, State),
    role_misc:create_goods(State2, ?ITEM_GAIN_COPY_FINISH, GoodsList).

do_finish_normal_update_copy(MapID, Stars, Config, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #c_copy{
        copy_type = CopyType,
        times_type = TimesType,
        times = ConfigTimes,
        is_team_map = IsTeamMap} = Config,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    case lists:keytake(CopyType, #r_role_copy_item.copy_type, CopyList) of
        {value, CopyItem, RemainList} ->
            #r_role_copy_item{enter_times = Times, star_list = StarList} = CopyItem,
            Times2 = ?IF(is_first(CopyType, MapID, StarList),
                ?IF(TimesType =:= ?TIMES_TYPE_SUCC, Times, Times - 1),
                update_team_map_times(TimesType, Times, IsTeamMap, CopyItem, CopyType, ConfigTimes, State)),
            case lists:keyfind(MapID, #p_kv.id, StarList) of
                #p_kv{val = OldStars} = MapStar ->
                    case Stars > OldStars of
                        true ->
                            StarList2 = lists:keyreplace(MapID, #p_kv.id, StarList, MapStar#p_kv{val = Stars}),
                            CopyItem2 = CopyItem#r_role_copy_item{enter_times = Times2, star_list = StarList2};
                        _ ->
                            CopyItem2 = CopyItem#r_role_copy_item{enter_times = Times2}
                    end,
                    RoleCopy2 = RoleCopy#r_role_copy{copy_list = [CopyItem2|RemainList]},
                    do_copy_item_update(RoleID, CopyItem2),
                    State#r_role{role_copy = RoleCopy2};
                _ ->
                    StarList2 = lists:keystore(MapID, #p_kv.id, StarList, #p_kv{id = MapID, val = Stars}),
                    CopyItem2 = CopyItem#r_role_copy_item{enter_times = Times2, star_list = StarList2},
                    RoleCopy2 = RoleCopy#r_role_copy{copy_list = [CopyItem2|RemainList]},
                    do_copy_item_update(RoleID, CopyItem2),
                    State#r_role{role_copy = RoleCopy2}
            end;
        _ -> %% 部分特殊情况，直接走这边
            State
    end.

update_team_map_times(TimesType, Times, IsTeamMap, CopyItem, CopyType, ConfigTimes, State) ->
    case ?IS_TEAM_MAP(IsTeamMap) of
        true ->
            CopyTimes = get_copy_times(CopyItem, CopyType, ConfigTimes, State),
            case TimesType =:= ?TIMES_TYPE_SUCC of
                true ->
                    ?IF(Times + 1 > CopyTimes, CopyTimes, Times + 1);
                _ ->
                    Times
            end;
        _ ->
            ?IF(TimesType =:= ?TIMES_TYPE_SUCC, Times + 1, Times)
    end.


do_copy_first_past(CopyType, State) ->
    FirstList = mod_role_extra:get_data(?EXTRA_KEY_COPY_FIRST_LIST, [], State),
    case lists:member(CopyType, FirstList) of
        true ->
            State;
        _ ->
            common_misc:unicast(State#r_role.role_id, #m_copy_first_past_toc{copy_type = CopyType}),
            FirstList2 = [CopyType|FirstList],
            mod_role_extra:set_data(?EXTRA_KEY_COPY_FIRST_LIST, FirstList2, State)
    end.

do_copy_failed(MapID, State) ->
    [#c_copy{copy_type = CopyType}] = lib_config:find(cfg_copy, MapID),
    State4 =
    case CopyType of
        ?COPY_FORGE_SOUL ->
            #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
            #r_role_copy{copy_list = CopyList} = RoleCopy,
            {value, CopyItem, RemainList} = lists:keytake(CopyType, #r_role_copy_item.copy_type, CopyList),
            #r_role_copy_item{enter_times = Times} = CopyItem,
            CopyItem2 = CopyItem#r_role_copy_item{enter_times = Times + 1},
            do_copy_item_update(RoleID, CopyItem2),
            CopyList2 = [CopyItem2|RemainList],
            RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
            State2 = State#r_role{role_copy = RoleCopy2},
            State3 =
            case lib_config:find(cfg_copy, MapID - 1) of
                [Config] ->
                    do_finish_normal_reward(3, Config, State2);
                _ ->
                    State2
            end,
            mod_role_map_panel:copy_success(RoleID, MapID),
            State3;
        ?COPY_FIVE_ELEMENTS ->
            State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_FIVE_ELEMENT_FAILED, State),
            mod_role_discount_pay:condition_update(State2);
        _ ->
            State
    end,
    do_copy_first_past(CopyType, State4).


do_copy_exp_end(EndTime, MapID, State) ->
    State2 = do_copy_exp_guide(MapID, State),
    %% 指引的时候，不扣CD
    do_copy_exp_cd(EndTime, MapID, State2).

%% 通关要设置CD时间
do_copy_exp_cd(EndTime, MapID, State) ->
    [#c_copy{copy_type = CopyType, cd = CD}] = lib_config:find(cfg_copy, MapID),
    Now = time_tool:now(),
    CDTime = EndTime + CD,
    case CD > 0 andalso Now < CDTime of
        true ->
            #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
            #r_role_copy{copy_list = CopyList} = RoleCopy,
            {value, CopyItem, RemainList} = lists:keytake(CopyType, #r_role_copy_item.copy_type, CopyList),
            CopyItem2 = CopyItem#r_role_copy_item{can_enter_time = CDTime},
            do_copy_item_update(RoleID, CopyItem2),
            CopyList2 = [CopyItem2|RemainList],
            RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
            State#r_role{role_copy = RoleCopy2};
        _ ->
            State
    end.

do_copy_exp_guide(MapID, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy, role_map_panel = RoleMapPanel} = State,
    #r_role_copy{exp_finish_times = ExpFinishTimes, exp_enter_times = ExpEnterTimes} = RoleCopy,
    case ExpFinishTimes >= common_misc:get_global_int(?GLOBAL_COPY_EXP) of
        true -> %% 超过次数了
            State;
        _ ->
            ExpFinishTimes2 = ExpFinishTimes + 1,
            RoleCopy2 = RoleCopy#r_role_copy{exp_finish_times = ExpFinishTimes2},
            State2 = State#r_role{role_copy = RoleCopy2},
            #r_role_map_panel{panel_list = PanelList} = RoleMapPanel,
            common_misc:unicast(RoleID, #m_copy_exp_guide_times_toc{exp_finish_times = ExpFinishTimes2, exp_enter_times = ExpEnterTimes}),
            State3 =
            case lists:keyfind(MapID, #r_map_panel.map_id, PanelList) of
                #r_map_panel{exp = GainExp} ->
                    ExpList = common_misc:get_global_list(?GLOBAL_COPY_EXP),
                    Exp = lists:nth(ExpFinishTimes2, ExpList),
                    AddExp = Exp - GainExp,
                    ?IF(AddExp > 0, mod_role_level:do_add_exp(State2, AddExp, ?EXP_ADD_FROM_GUIDE_COPY_EXP), State2);
                _ ->
                    State2
            end,
            State3
    end.


do_add_marry_copy(State) ->
    add_copy_times(?COPY_MARRY, 1, State).

update_role_team(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{team_id = TeamID}, role_copy = RoleCopy} = State,
    case ?HAS_TEAM(TeamID) of
        true ->
            #r_role_copy{copy_list = CopyList} = RoleCopy,
            TeamCopyList =
            [ #p_kvt{
                id = CopyType,
                val = get_copy_degree(CopyType, StarList, 0),
                type = get_copy_times(CopyItem, CopyType, -EnterTimes, State)
            } || #r_role_copy_item{copy_type = CopyType, star_list = StarList, enter_times = EnterTimes} = CopyItem <- CopyList],
            mod_team_role:role_copy_update(RoleID, TeamCopyList);
        _ ->
            ok
    end.

add_copy_times(CopyType, AddTimes, State) ->
    #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{} = CopyItem ->
            ok;
        _ ->
            CopyItem = #r_role_copy_item{copy_type = CopyType}
    end,
    #r_role_copy_item{item_add_times = ItemAddTimes} = CopyItem,
    CopyItem2 = CopyItem#r_role_copy_item{item_add_times = ItemAddTimes + AddTimes},
    CopyList2 = lists:keystore(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2),
    RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
    do_copy_item_update(RoleID, CopyItem2),
    State2 = ?IF(CopyType =:= ?COPY_MARRY andalso AddTimes > 0, mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State), State),
    State3 = State2#r_role{role_copy = RoleCopy2},
    update_role_team(State3),
    add_copy_times_trigger(CopyType, State3).

add_limit_times_illusion(EffectType, EffectArgs, UseNum, State) ->
    State2 = mod_role_world_boss:check_package_times(EffectType, UseNum, State),
    add_illusion(lib_tool:to_integer(EffectArgs) * UseNum, State2).

add_copy_times_trigger(CopyType, State) ->
    FunList = [
        fun(StateAcc) ->
            if
                CopyType =:= ?COPY_EXP ->
                    mod_role_day_target:add_copy_exp_times(StateAcc);
                true ->
                    StateAcc
            end
        end
    ],
    role_server:execute_state_fun(FunList, State).

%% 主线任务完成，会增加次数
main_mission(MissionID, State) ->
    MissionList = common_misc:get_global_string_list(?GLOBAL_COPY_EXP),
    case lists:keyfind(MissionID, 1, MissionList) of
        {MissionID, AddTimes} ->
            #r_role{role_id = RoleID, role_copy = RoleCopy} = State,
            #r_role_copy{exp_finish_times = ExpFinishTimes, exp_enter_times = ExpEnterTimes} = RoleCopy,
            ExpEnterTimes2 = ExpEnterTimes + AddTimes,
            common_misc:unicast(RoleID, #m_copy_exp_guide_times_toc{exp_finish_times = ExpFinishTimes, exp_enter_times = ExpEnterTimes2}),
            RoleCopy2 = RoleCopy#r_role_copy{exp_enter_times = ExpEnterTimes2},
            State#r_role{role_copy = RoleCopy2};
        _ ->
            State
    end.

do_copy_item_update(RoleID, CopyItem) ->
    common_misc:unicast(RoleID, #m_copy_item_update_toc{copy_item = trans_to_p_copy_item(CopyItem)}).

do_cheer(RoleID, ID, AssetType, State) ->
    case catch check_can_cheer(ID, AssetType, State) of
        {ok, AssetDoing, AddBuffID} ->
            case mod_map_role:role_cheer(mod_role_dict:get_map_pid(), RoleID, ID, AssetType) of
                {ok, Cheer} ->
                    common_misc:unicast(RoleID, #m_copy_cheer_toc{cheer = Cheer}),
                    BuffList = [#buff_args{buff_id = AddBuffID, from_actor_id = RoleID}],
                    role_misc:add_buff(RoleID, BuffList),
                    State2 = mod_role_asset:do(AssetDoing, State),
                    mod_role_achievement:copy_exp_cheer(1, State2);
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_copy_exp_cheer_toc{err_code = ErrCode}),
                    State;
                Error ->
                    ?ERROR_MSG("cheer Error:~w", [Error]),
                    common_misc:unicast(RoleID, #m_copy_exp_cheer_toc{err_code = ?ERROR_COMMON_ROLE_DATA_ERROR}),
                    State
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_exp_cheer_toc{err_code = ErrCode}),
            State
    end.

check_can_cheer(ID, AssetType, State) ->
    #r_role{role_id = RoleID, role_map = #r_role_map{map_id = MapID}} = State,
    ?IF(map_misc:is_copy_exp(MapID) orelse map_misc:is_copy_treasure(MapID), ok, ?THROW_ERR(?ERROR_COPY_EXP_CHEER_002)),
    case mod_map_role:role_get_cheer(mod_role_dict:get_map_pid(), RoleID, ID, AssetType) of
        {ok, AssetType2, AssetValue, AddBuffID} ->
            Action = ?IF(AssetType2 =:= ?CONSUME_SILVER, ?ASSET_SILVER_REDUCE_FROM_COPY_CHEER, ?ASSET_GOLD_REDUCE_FROM_COPY_CHEER),
            AssetDoing = mod_role_asset:check_asset_by_type(AssetType2, AssetValue, Action, State),
            {ok, AssetDoing, AddBuffID};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

do_auto_cheer(State) ->
    #r_role{role_id = RoleID} = State,
    {IsSilverAuto, IsGoldAuto, _HasFirstOpen} = get_copy_exp_auto_status(State),
    [#c_global{string = Cost, list = [SilverMaxTimes, MaxTimes]}] = lib_config:find(cfg_global, ?GLOBAL_COPY_EXP_COST),
    CostList = common_misc:get_global_string_list(Cost),
    {SilverTimes, IsSilverMax, SilverDoing} = get_auto_cheer_args(SilverMaxTimes, IsSilverAuto, ?CONSUME_SILVER, CostList, State),
    GoldMaxTimes = MaxTimes - SilverTimes,
    {GoldTimes, IsGoldMax, GoldDoings} = get_auto_cheer_args(GoldMaxTimes, IsGoldAuto, ?CONSUME_ANY_GOLD, CostList, State),
    AssetDoings = SilverDoing ++ GoldDoings,
    TipStatus1 = ?IF(IsSilverMax, 0, 1),
    TipStatus2 = ?IF(IsGoldMax, TipStatus1, 2 + TipStatus1),
    if
        AssetDoings =/= [] ->
            ?IF(TipStatus2 > 0, common_misc:unicast(RoleID, #m_copy_exp_cheer_tip_toc{status = TipStatus2}), ok),
            case mod_map_role:role_auto_cheer(mod_role_dict:get_map_pid(), RoleID, SilverTimes, GoldTimes) of
                ok ->
                    State2 = mod_role_asset:do(AssetDoings, State),
                    mod_role_achievement:copy_exp_cheer(SilverTimes + GoldTimes, State2);
                Error ->
                    ?ERROR_MSG("Unknow Error : ~w", [Error]),
                    State
            end;
        IsSilverAuto orelse IsGoldAuto ->
            common_misc:unicast(RoleID, #m_copy_exp_cheer_tip_toc{status = TipStatus2}),
            State;
        true ->
            State
    end.

get_auto_cheer_args(_MaxTimes, false, _AssetType, _CostList, _State) ->
    {0, false, []};
get_auto_cheer_args(MaxTimes, true, AssetType, CostList, State) ->
    {_, Cost} = lists:keyfind(AssetType, 1, CostList),
    AssetValue = mod_role_asset:get_asset_by_type(AssetType, State),
    CheerTimes = AssetValue div Cost,
    {IsMax, CheerTimes2} = ?IF(CheerTimes >= MaxTimes, {true, MaxTimes}, {false, CheerTimes}),
    Action = ?IF(AssetType =:= ?CONSUME_SILVER, ?ASSET_SILVER_REDUCE_FROM_COPY_CHEER, ?ASSET_GOLD_REDUCE_FROM_COPY_CHEER),
    AssetDoing = ?IF(CheerTimes2 > 0, mod_role_asset:check_asset_by_type(AssetType, CheerTimes2 * Cost, Action, State), []),
    {CheerTimes2, IsMax, AssetDoing}.

do_exp_merge(RoleID, MergeTimes, State) ->
    #r_role{role_copy = RoleCopy} = State,
    MergeTimes2 = erlang:max(1, erlang:min(MergeTimes, mod_role_vip:get_copy_exp_merge_times(State))),
    RoleCopy2 = RoleCopy#r_role_copy{exp_merge_times = MergeTimes2},
    common_misc:unicast(RoleID, #m_copy_exp_merge_times_toc{merge_times = MergeTimes2}),
    State#r_role{role_copy = RoleCopy2}.

%% 五行秘境boss死亡，触发
do_five_element_boss_dead(TypeID, State) ->
    hook_role:kill_five_elements_boss(TypeID, State).


do_clean(RoleID, MapID, Num, BossNum, State) ->
    case catch check_can_clean(MapID, Num, BossNum, State) of
        {ok, GoodsList, Illusion2, State3} -> %% 五行副本扫荡
            common_misc:unicast(RoleID, #m_copy_illusion_update_toc{illusion = to_front_illusion(Illusion2)}),
            common_misc:unicast(RoleID, #m_copy_clean_toc{map_id = MapID, num = Num, goods_list = GoodsList}),
            State4 = role_misc:create_goods(State3, ?ITEM_GAIN_COPY_CLEAN, GoodsList),
            lists:foldl(
                fun(_TimesIndex, StateAcc) ->
                    mod_role_daily_liveness:trigger_copy(?COPY_FIVE_ELEMENTS, StateAcc)
                end, State4, lists:seq(1, Num));
        {ok, CopyItem2, GoodsList, BagDoings, AssetDoings, AddExp, CopyType, Stars, State2} -> %% 正常副本扫荡
            State3 = mod_role_bag:do(BagDoings, State2),
            State4 = mod_role_asset:do(AssetDoings, State3),
            State5 = mod_role_level:do_add_exp(State4, AddExp, ?EXP_ADD_FROM_COPY_CLEAN),
            State6 = role_misc:create_goods(State5, ?ITEM_GAIN_COPY_CLEAN, GoodsList),
            do_copy_item_update(RoleID, CopyItem2),
            common_misc:unicast(RoleID, #m_copy_clean_toc{map_id = MapID, num = Num, goods_list = GoodsList, add_exp = AddExp}),
            lists:foldl(
                fun(_TimesIndex, StateAcc) ->
                    StateAcc2 = do_finish_trigger(CopyType, MapID, Stars, StateAcc),
                    mod_role_daily_liveness:trigger_copy(CopyType, StateAcc2)
                end, State6, lists:seq(1, Num));
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_clean_toc{err_code = ErrCode}),
            State
    end.

check_can_clean(MapID, Num, BossNum, State) ->
    [#c_copy{copy_type = CopyType} = Config] = lib_config:find(cfg_copy, MapID),
    case CopyType of
        ?COPY_FIVE_ELEMENTS ->
            check_five_elements_clean(MapID, Num, State);
        _ ->
            check_clean_normal(MapID, Config, Num, BossNum, State)
    end.

%% 五行副本扫荡
check_five_elements_clean(MapID, Num, State) ->
    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    #r_role_copy{
        cur_five_elements = CurFiveElements,
        illusion = Illusion} = RoleCopy = State#r_role.role_copy,
    [                                 #c_five_elements_detail{
        is_big_floor = IsBigFloor,
        need_illusion = NeedIllusion} = Config] = lib_config:find(cfg_five_elements_detail, MapID),
    DropIDList = get_five_elements_normal_drop(Config),
    ?IF(IsBigFloor > 0, ok, ?THROW_ERR(?ERROR_COPY_CLEAN_001)),
    ?IF(CurFiveElements >= MapID, ok, ?THROW_ERR(?ERROR_COPY_CLEAN_002)),
    Illusion2 = Illusion - config_illusion(NeedIllusion) * Num,
    ?IF(Illusion2 >= 0, ok, ?THROW_ERR(?ERROR_COPY_CLEAN_005)),
    DropIDList2 = lists:flatten(lists:duplicate(Num, DropIDList)),
    {GoodsList, _PanelGoods, State2} = mod_role_world_boss:get_drop_and_panel_goods(DropIDList2, State),
    RoleCopy2 = RoleCopy#r_role_copy{illusion = Illusion2},
    State3 = State2#r_role{role_copy = RoleCopy2},
    {ok, GoodsList, Illusion2, State3}.

%% 常规副本扫荡
check_clean_normal(MapID, Config, Num, BossNum, State) ->
    #c_copy{
        times = Times,
        copy_type = CopyType,
        can_clean = CanClean,
        clean_condition = CleanCondition,
        clean_cost_item = CleanCostItem} = Config,
    #r_role_copy{copy_list = CopyList} = RoleCopy = State#r_role.role_copy,

    ?IF(?CAN_COPY_CLEAN(CanClean), ok, ?THROW_ERR(?ERROR_COPY_CLEAN_001)),
    check_clean_condition(CleanCondition, State),
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{} = CopyItem ->
            ok;
        _ ->
            CopyItem = ?THROW_ERR(?ERROR_COPY_CLEAN_002)
    end,
    CopyTimes = get_copy_times(CopyItem, CopyType, Times, State),
    #r_role_copy_item{
        star_list = StarList,
        clean_times = CleanTimes,
        enter_times = EnterTimes} = CopyItem,
    case lists:keyfind(MapID, #p_kv.id, StarList) of
        #p_kv{val = Star} ->
            Star;
        _ ->
            Star = ?THROW_ERR(?ERROR_COPY_CLEAN_002)
    end,
    ?IF(CopyTimes - EnterTimes >= Num andalso Num > 0, ok, ?THROW_ERR(?ERROR_COPY_CLEAN_004)),
    BagDoings = check_clean_items(Num, CleanTimes, CleanCostItem, State),
    AssetDoings = ?IF(BossNum > 0,
                      mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, common_misc:get_global_int(?GLOBAL_IMMORTAL_GUARD_AND_BOSS) * Num * BossNum, ?ASSET_GOLD_REDUCE_FROM_COPY_CLEAN, State),
                      []),
    RoleLevel = mod_role_data:get_role_level(State),
    CleanArgs = #r_clean_args{
        copy_type = CopyType,
        map_id = MapID,
        role_level = RoleLevel,
        star = Star,
        num = Num,
        boss_num = BossNum},
    {GoodsList, AddExp} = get_clean_reward(CleanArgs, Config),
    CopyItem2 = CopyItem#r_role_copy_item{enter_times = EnterTimes + Num, clean_times = CleanTimes + Num},
    CopyList2 = lists:keyreplace(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2),
    RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, CopyItem2, GoodsList, BagDoings, AssetDoings, AddExp, CopyType, Star, State2}.

check_clean_condition(CleanCondition, State) ->
    List = lib_tool:string_to_intlist(CleanCondition),
    case lists:keyfind(1, 1, List) of
        {_, NeedRoleLevel} ->
            ?IF(mod_role_data:get_role_level(State) >= NeedRoleLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL));
        _ ->
            ok
    end,
    case lists:keyfind(2, 1, List) of
        {_, NeedVipLevel} ->
            ?IF(mod_role_vip:get_vip_level(State) >= NeedVipLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL));
        _ ->
            ok
    end.

check_clean_items(Num, CleanTimes, CleanCostItem, State) ->
    CleanCostItem2 = lib_tool:string_to_intlist(CleanCostItem),
    case CleanCostItem2 =/= [] of
        true ->
            [Last|_] = lists:reverse(CleanCostItem2),
            {TimesConfigList, _Remain} = lib_tool:split(CleanTimes + 1, CleanCostItem2),
            TimesList = lists:seq(CleanTimes + 1, CleanTimes + Num),
            NeedItems = check_clean_items2(TimesList, TimesConfigList, Last, []),
            mod_role_bag:check_num_by_item_list(NeedItems, ?ITEM_REDUCE_COPY_CLEAN, State);
        _ ->
            []
    end.

check_clean_items2([], _TimesConfigList, _Last, Acc) ->
    Acc;
check_clean_items2(List, [], Last, Acc) ->
    lists:duplicate(erlang:length(List), Last) ++ Acc;
check_clean_items2([_Times|R1], [TimesConfig|R2], Last, Acc) ->
    check_clean_items2(R1, R2, Last, [TimesConfig|Acc]).

get_clean_reward(CleanArgs, Config) ->
    #r_clean_args{
        star = Star,
        role_level = RoleLevel,
        num = Num
    } = CleanArgs,
    {_CopyType, CopyMod} = lists:keyfind(CleanArgs#r_clean_args.copy_type, 1, ?COPY_MOD_LIST),
    {ExtraGoods, ExtraExp} =
    case erlang:function_exported(CopyMod, copy_clean, 1) of
        true ->
            CopyMod:copy_clean(CleanArgs);
        _ ->
            {[], 0}
    end,
    StarGoods = get_star_finish_goods(Star, RoleLevel, Config, Num),
    {ExtraGoods ++ StarGoods, ExtraExp}.


%% 爬塔副本日常奖励
do_daily_tower_reward(RoleID, TowerID) ->
    case lib_config:find(cfg_copy_tower, TowerID) of
        [#c_copy_tower{daily_rewards = DailyRewards}] ->
            GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(DailyRewards)],
            case GoodsList =/= [] of
                true ->
                    LetterInfo =
                    #r_letter_info{
                        template_id = ?LETTER_TEMPLATE_TOWER_REWARD,
                        text_string = [lib_tool:to_list(?GET_TOWER_FLOOR(TowerID))],
                        action = ?ITEM_GAIN_LETTER_DAILY_TOWER,
                        goods_list = GoodsList},
                    common_letter:send_letter(RoleID, LetterInfo);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

do_buy_times(RoleID, MapID, State) ->
    case catch check_buy_times(MapID, State) of
        {ok, CopyItem, AssetDoings, CallBack, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_copy_buy_times_toc{}),
            do_copy_item_update(RoleID, CopyItem),
            ?IF(map_misc:is_copy_team(MapID), update_role_team(State3), ok),
            ?TRY_CATCH(CallBack()),
            add_copy_times_trigger(CopyItem#r_role_copy_item.copy_type, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_buy_times_toc{err_code = ErrCode}),
            State
    end.

check_buy_times(MapID, State) ->
    #r_role{role_copy = RoleCopy, role_marry = #r_role_marry{couple_id = CoupleID}} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    [#c_copy{
        copy_type = CopyType,
        buy_times = MaxBuyTimes,
        buy_gold_list = BuyGoldList
    }] = lib_config:find(cfg_copy, MapID),
    CopyItem =
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{} = CopyItemT ->
            CopyItemT;
        _ ->
            #r_role_copy_item{copy_type = CopyType}
    end,
    #r_role_copy_item{buy_times = BuyTimes} = CopyItem,
    %% 优先获取vip购买次数，取两者中的较大值
    VipBuyTimes = mod_role_vip:get_vip_buy_times(CopyType, State),
    ?IF(BuyTimes >= erlang:max(MaxBuyTimes, VipBuyTimes), ?THROW_ERR(?ERROR_COPY_BUY_TIMES_001), ok),
    BuyTimes2 = BuyTimes + 1,
    BuyGold =
    case BuyGoldList =/= [] of
        true ->
            ?IF(BuyTimes2 > erlang:length(BuyGoldList), lists:nth(1, lists:reverse(BuyGoldList)), lists:nth(BuyTimes2, BuyGoldList));
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, BuyGold, ?ASSET_GOLD_REDUCE_FROM_COPY_BUY, State),
    %% 仙侣副本特殊判断
    CallBack =
    case CopyType =:= ?COPY_MARRY of
        true ->
            ?IF(?HAS_COUPLE(CoupleID), ok, ?THROW_ERR(?ERROR_COPY_BUY_TIMES_002)),
            fun() -> ?MODULE:add_marry_copy(CoupleID), common_misc:unicast(CoupleID, #m_marry_copy_buy_toc{}) end;
        _ ->
            fun() -> ok end
    end,
    CopyItem2 = CopyItem#r_role_copy_item{buy_times = BuyTimes + 1},
    CopyList2 = lists:keystore(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2),
    RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
    State2 = ?IF(CopyType =:= ?COPY_MARRY, mod_role_extra:set_data(?EXTRA_KEY_COPY_MARRY_TIMES, 0, State), State),
    State3 = State2#r_role{role_copy = RoleCopy2},
    {ok, CopyItem2, AssetDoings, CallBack, State3}.

%% 清除副本CD
do_cd_remove(RoleID, CopyID, State) ->
    case catch check_cd_remove(CopyID, State) of
        {ok, CopyItem, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            common_misc:unicast(RoleID, #m_copy_cd_remove_toc{}),
            do_copy_item_update(RoleID, CopyItem),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_cd_remove_toc{err_code = ErrCode}),
            State
    end.

check_cd_remove(MapID, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    [#c_copy{
        copy_type = CopyType,
        cd = CD,
        cd_cost = [EveryTime, ReduceGold, AllGold]
    }] = lib_config:find(cfg_copy, MapID),
    CopyItem =
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{} = CopyItemT ->
            CopyItemT;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #r_role_copy_item{can_enter_time = CanEnterTime} = CopyItem,
    Now = time_tool:now(),
    ?IF(Now >= CanEnterTime, ?THROW_ERR(?ERROR_COPY_CD_REMOVE_001), ok),
    NeedGold = AllGold - lib_tool:floor((CD - CanEnterTime + Now) / EveryTime) * ReduceGold,
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_COPY_CD_REMOVE, State),
    CopyItem2 = CopyItem#r_role_copy_item{can_enter_time = 0},
    CopyList2 = lists:keystore(CopyType, #r_role_copy_item.copy_type, CopyList, CopyItem2),
    RoleCopy2 = RoleCopy#r_role_copy{copy_list = CopyList2},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, CopyItem2, AssetDoings, State2}.

do_copy_restart(RoleID, State) ->
    case catch check_copy_restart(RoleID, State) of
        {ok, CallBackList, State2} ->
            [Fun() || Fun <- CallBackList],
            mod_map_role:role_copy_restart(mod_role_dict:get_map_pid(), RoleID),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_restart_toc{err_code = ErrCode}),
            State
    end.

check_copy_restart(RoleID, State) ->
    #r_role{role_private_attr = PrivateAttr, role_map = RoleMap} = State,
    #r_role_private_attr{status = Status} = PrivateAttr,
    #r_role_map{map_id = MapID} = RoleMap,
    CopyType = copy_misc:get_copy_type(MapID),
    if
        CopyType =:= ?COPY_TOWER orelse CopyType =:= ?COPY_UNIVERSE ->
            CallBackList = [
                fun() ->
                    ?IF(Status =:= ?MAP_STATUS_DEAD, mod_map_role:role_relive(mod_role_dict:get_map_pid(), RoleID, ?RELIVE_TYPE_NORMAL), ok) end
            ],
            PrivateAttr2 = PrivateAttr#r_role_private_attr{status = ?MAP_STATUS_NORMAL},
            State2 = State#r_role{role_private_attr = PrivateAttr2},
            {ok, CallBackList, State2};
        true ->
            ?THROW_ERR(?ERROR_COPY_RESTART_001)
    end.

do_immortal_reset(RoleID, State) ->
    GuardList = mod_role_extra:get_data(?EXTRA_KEY_IMMORTAL_GUARD, [], State),
    case copy_data:is_immortal_map(mod_role_data:get_role_map_id(State)) andalso GuardList =/= [] of
        true ->
            copy_immortal:immortal_reset(mod_role_dict:get_map_pid(), RoleID, GuardList);
        _ ->
            common_misc:unicast(RoleID, #m_copy_immortal_reset_guard_toc{err_code = ?ERROR_COPY_IMMORTAL_RESET_GUARD_001})
    end,
    State.

do_immortal_start(GuardList, State) ->
    mod_role_extra:set_data(?EXTRA_KEY_IMMORTAL_GUARD, GuardList, State).

do_immortal_summon(RoleID, IsError, State) ->
    case catch check_immortal_summon(State) of
        {ok, AssetDoing} ->
            case catch copy_immortal:immortal_summon(mod_role_dict:get_map_pid()) of
                {ok, SummonRound} ->
                    common_misc:unicast(RoleID, #m_copy_immortal_summon_boss_toc{summon_boss_round = SummonRound}),
                    mod_role_asset:do(AssetDoing, State);
                {error, ErrCode} ->
                    ?IF(IsError, common_misc:unicast(RoleID, #m_copy_immortal_summon_boss_toc{err_code = ErrCode}), ok),
                    State
            end;
        {error, ErrCode} ->
            ?IF(IsError, common_misc:unicast(RoleID, #m_copy_immortal_summon_boss_toc{err_code = ErrCode}), ok),
            State
    end.

check_immortal_summon(State) ->
    ?IF(copy_data:is_immortal_map(mod_role_data:get_role_map_id(State)), ok, ?THROW_ERR(?ERROR_COPY_IMMORTAL_SUMMON_BOSS_001)),
    Gold = common_misc:get_global_int(?GLOBAL_IMMORTAL_GUARD_AND_BOSS),
    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_ANY_GOLD, Gold, ?ASSET_GOLD_REDUCE_FROM_IMMORTAL_SUMMON, State),
    {ok, AssetDoing}.

%% 解锁五行副本
do_five_elements_unlock(RoleID, UnlockFloor, State) ->
    case catch check_five_elements_unlock(UnlockFloor, State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_copy_five_elements_unlock_toc{unlock_floor = UnlockFloor}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_five_elements_unlock_toc{err_code = ErrCode}),
            State
    end.

check_five_elements_unlock(UnlockFloor, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{cur_five_elements = CurFiveElements, unlock_floor = OldUnlockFloor} = RoleCopy,
    ?IF(CurFiveElements > 0, ok, ?THROW_ERR(?ERROR_COPY_FIVE_ELEMENTS_UNLOCK_001)),
    case lib_config:find(cfg_five_elements_detail, CurFiveElements + 1) of
        [_Config] ->
            ?THROW_ERR(?ERROR_COPY_FIVE_ELEMENTS_UNLOCK_001);
        _ ->
            ok
    end,
    ?IF(UnlockFloor =:= OldUnlockFloor + 1, ok, ?THROW_ERR(?ERROR_COPY_FIVE_ELEMENTS_UNLOCK_001)),
    [#c_five_elements_floor{need_list = NeedList}] = lib_config:find(cfg_five_elements_floor, OldUnlockFloor),
    BookList = mod_role_nature:get_book_list(State),
    ?IF(NeedList -- BookList =:= [], ok, ?THROW_ERR(?ERROR_COPY_FIVE_ELEMENTS_UNLOCK_002)),
    RoleCopy2 = RoleCopy#r_role_copy{unlock_floor = UnlockFloor},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, State2}.

%% 购买星力
do_buy_illusion(RoleID, BuyTimes, State) ->
    case catch check_buy_illusion(BuyTimes, State) of
        {ok, Illusion, HasBuyTimes, AssetDoings, State2} ->
            common_misc:unicast(RoleID, #m_copy_buy_illusion_toc{illusion = to_front_illusion(Illusion), buy_illusion_times = HasBuyTimes}),
            State3 = mod_role_asset:do(AssetDoings, State2),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_buy_illusion_toc{err_code = ErrCode}),
            State
    end.

check_buy_illusion(BuyTimes, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{illusion = Illusion, buy_illusion_times = HasBuyTimes} = RoleCopy,
    HasBuyTimes2 = BuyTimes + HasBuyTimes,
    ?IF(BuyTimes > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ?IF(HasBuyTimes2 > mod_role_vip:get_illusion_buy_times(State), ?THROW_ERR(?ERROR_COPY_BUY_ILLUSION_001), ok),
    [{AddIllusion, _Rate}|_] = common_misc:get_global_string_list(?GLOBAL_ILLUSION_BUY),
    NeedGoldList = common_misc:get_global_list(?GLOBAL_ILLUSION_BUY),
    NeedGold = check_buy_illusion2(lists:seq(HasBuyTimes + 1, HasBuyTimes2), NeedGoldList, 0),
    AssetDoings = ?IF(NeedGold > 0, mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_ILLUSION_BUY, State), []),
    Illusion2 = Illusion + config_illusion(AddIllusion * BuyTimes),
    RoleCopy2 = RoleCopy#r_role_copy{illusion = Illusion2, buy_illusion_times = HasBuyTimes2},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, Illusion2, HasBuyTimes2, AssetDoings, State2}.

check_buy_illusion2([], _NeedGoldList, NeedGoldAcc) ->
    NeedGoldAcc;
check_buy_illusion2([BuyTimes|R], NeedGoldList, NeedGoldAcc) ->
    AddGold = ?IF(BuyTimes > erlang:length(NeedGoldList), lists:nth(1, lists:reverse(NeedGoldList)), lists:nth(BuyTimes, NeedGoldList)),
    check_buy_illusion2(R, NeedGoldList, NeedGoldAcc + AddGold).


%% 领取天机勾玉
do_nat_intensify(RoleID, State) ->
    case catch check_nat_intensify(State) of
        {ok, AddNatIntensify, State2} ->
            common_misc:unicast(RoleID, #m_copy_nat_intensify_toc{nat_intensify = 0}),
            mod_role_nature:add_intensify_nature(AddNatIntensify, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_copy_nat_intensify_toc{err_code = ErrCode}),
            State
    end.

check_nat_intensify(State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{nat_intensify = NatIntensify} = RoleCopy,
    ?IF(NatIntensify > 0, ok, ?THROW_ERR(?ERROR_COPY_NAT_INTENSIFY_001)),
    RoleCopy2 = RoleCopy#r_role_copy{nat_intensify = 0},
    State2 = State#r_role{role_copy = RoleCopy2},
    {ok, NatIntensify, State2}.


get_copy_times(CopyItem, CopyType, Times, State) ->
    case CopyItem of
        #r_role_copy_item{buy_times = BuyTimes, item_add_times = ItemAddTimes} ->
            Times1 = BuyTimes + ItemAddTimes;
        _ ->
            Times1 = 0
    end,
    VipTimes = mod_role_vip:get_vip_copy_times(CopyType, State),
    Times1 + VipTimes + Times.

trans_to_p_copy_item(CopyItem) ->
    #r_role_copy_item{
        copy_type = CopyType,
        enter_times = EnterTimes,
        buy_times = BuyTimes,
        can_enter_time = CanEnterTime,
        item_add_times = ItemAddTimes,
        star_list = StarList,
        clean_times = CleanTimes} = CopyItem,
    #p_copy_item{
        copy_type = CopyType,
        enter_times = EnterTimes,
        buy_times = BuyTimes,
        can_enter_time = CanEnterTime,
        item_add_times = ItemAddTimes,
        star_list = StarList,
        clean_times = CleanTimes}.

get_copy_degree(_CopyType, [], Degree) ->
    Degree + 1;
get_copy_degree(CopyType, [#p_kv{id = MapID, val = Star}|R], Degree) ->
    [#c_copy{copy_degree = CopyDegree}] = lib_config:find(cfg_copy, MapID),
    Degree2 =
    case lists:member(CopyType, [?COPY_SILVER, ?COPY_SINGLE_TD, ?COPY_WAR_SPIRIT, ?COPY_FORGE_SOUL]) of
        true -> %% 金币副本跟单人td副本 3星通关方可开启下一个等级
            ?IF(Star =:= ?COPY_STAR_3, ?IF(CopyDegree > Degree, CopyDegree, Degree), Degree);
        _ ->
            ?IF(CopyDegree > Degree, CopyDegree, Degree)
    end,
    get_copy_degree(CopyType, R, Degree2).

get_star_finish_goods(Stars, RoleLevel, Config) ->
    get_star_finish_goods(Stars, RoleLevel, Config, 1).
get_star_finish_goods(Stars, RoleLevel, Config, Times) ->
    #c_copy{
        copy_type = CopyType,
        base_rewards = BaseRewardString,
        star_1_rewards = Star1Rewards,
        star_1_drops = Star1Drops,
        star_2_rewards = Star2Rewards,
        star_2_drops = Star2Drops,
        star_3_rewards = Star3Rewards,
        star_3_drops = Star3Drops} = Config,
    BaseRewards = common_misc:get_item_reward(BaseRewardString),
    StarRewards =
    case lists:keyfind(Stars, 1, [{?COPY_STAR_1, Star1Rewards}, {?COPY_STAR_2, Star2Rewards}, {?COPY_STAR_3, Star3Rewards}]) of
        {_, RewardString} ->
            common_misc:get_item_reward(RewardString);
        _ ->
            []
    end,
    ExtraStarGoods = get_extra_star_reward(Stars, RoleLevel, CopyType),
    DropGoodsList =
    case lists:keyfind(Stars, 1, [{?COPY_STAR_1, Star1Drops}, {?COPY_STAR_2, Star2Drops}, {?COPY_STAR_3, Star3Drops}]) of
        {_, DropIDList} ->
            lists:flatten([[#p_goods{type_id = TypeID, num = Num, bind = IsBind} ||
                               {TypeID, Num, IsBind} <- mod_map_drop:get_drop_item_list2(DropID)] || DropID <- DropIDList]);
        _ ->
            []
    end,
    GoodsList = ExtraStarGoods ++ StarRewards ++ BaseRewards,
    Multi = act_double_copy:get_drop_multi_by_type(CopyType),
    GoodsList2 = common_misc:get_reward_p_goods(GoodsList, Multi * Times),
    mod_role_bag:get_create_list(GoodsList2 ++ DropGoodsList).

get_extra_star_reward(Stars, RoleLevel, CopyType) ->
    if
        CopyType =:= ?COPY_IMMORTAL ->
            copy_immortal:get_extra_star_reward(Stars, RoleLevel);
        true ->
            []
    end.

get_copy_exp_multi(State) ->
    MapID = mod_role_data:get_role_map_id(State),
    case ?IS_MAP_COPY_EXP(MapID) of
        true ->
            #r_role{role_copy = #r_role_copy{exp_now_merge_times = Multi}} = State,
            erlang:max(1, Multi);
        _ ->
            1
    end.

check_personal_boss(CopyItem, MapID, Flag, State) ->
    #r_role_copy_item{enter_times = EnterTimes} = CopyItem,
    #c_map_base{use_item_string = UseItemString} = map_misc:get_map_base(MapID),
    TimesList = lib_tool:string_to_intlist(UseItemString, ";", ","),
    case TimesList =/= [] of
        true ->
            case Flag =:= ?NOT_ENTER_PERSONAL_BOSS of
                true ->
                   [];
                _ ->
                    {_Times, TypeID, Num} = lists:keyfind(EnterTimes, 1, TimesList),
                    mod_role_bag:check_num_by_type_id(TypeID, Num, ?ITEM_REDUCE_ENTER_MAP, State)
            end;
        _ ->
            []
    end.
%%            case EnterTimes =:= 1 andalso mod_role_vip:is_boss_first_free(State) of
%%                true ->
%%                    [];
%%                _ ->
%%                    Num2 = ?IF(mod_role_vip:is_boss_item_half(State), lib_tool:ceil(Num / 2), Num),
%%                    mod_role_bag:check_num_by_type_id(TypeID, Num2, ?ITEM_REDUCE_ENTER_MAP, State)
%%            end.

is_first(CopyType, MapID, StarList) ->
    case CopyType =:= ?COPY_WAR_SPIRIT of
        true -> %% 部分副本首次不扣除次数
            case lists:keyfind(MapID, #p_kv.id, StarList) of
                #p_kv{} ->
                    false;
                _ ->
                    true
            end;
        _ ->
            false
    end.

%% 获取当前副本完成次数
get_copy_finish_times(CopyType, State) ->
    #r_role{role_copy = RoleCopy} = State,
    #r_role_copy{copy_list = CopyList} = RoleCopy,
    case lists:keyfind(CopyType, #r_role_copy_item.copy_type, CopyList) of
        #r_role_copy_item{enter_times = EnterTimes} ->
            EnterTimes;
        _ ->
            0
    end.

%% 五行副本是否可以进入
check_copy_five_elements_open(MapID, State) ->
    [#c_copy{
        need_props = NeedProps,
        need_confine_id = NeedConfineID
    }] = lib_config:find(cfg_copy, MapID),
    ?IF(mod_role_confine:get_confine_id(State) >= NeedConfineID, ok, ?THROW_ERR(?ERROR_PRE_ENTER_030)),
    PropList = lib_tool:string_to_intlist(NeedProps),
    #r_role{role_fight = #r_role_fight{base_attr = BaseAttr}} = State,
    check_props(PropList, BaseAttr).

check_props([], _BaseAttr) ->
    ok;
check_props([{Key, Value}|R], BaseAttr) ->
    #actor_fight_attr{
        metal = Metal,
        wood = Wood,
        water = Water,
        fire = Fire,
        earth = Earth
    } = BaseAttr,
    Bool =
    if
        Key =:= ?ATTR_METAL ->
            Metal >= Value;
        Key =:= ?ATTR_WOOD ->
            Wood >= Value;
        Key =:= ?ATTR_WATER ->
            Water >= Value;
        Key =:= ?ATTR_FIRE ->
            Fire >= Value;
        Key =:= ?ATTR_EARTH ->
            Earth >= Value;
        true ->
            true
    end,
    ?IF(Bool, ok, ?THROW_ERR(?ERROR_PRE_ENTER_031)),
    check_props(R, BaseAttr).


%% 返回{IsSilverAuto, IsGoldAuto, HasFirstOpen}
get_copy_exp_auto_status(State) ->
    case mod_role_extra:get_data(?EXTRA_KEY_COPY_EXP_AUTO, {false, false, false}, State) of
        {IsSilverAuto, IsGoldAuto} -> %% 兼容第一版本
            {IsSilverAuto, IsGoldAuto, true};
        {IsSilverAuto, IsGoldAuto, HasFirstOpen} ->
            {IsSilverAuto, IsGoldAuto, HasFirstOpen}
    end.

get_merge_times(?COPY_EXP, ExpMergeTimes) ->
    erlang:max(1, ExpMergeTimes);
get_merge_times(_CopyType, _ExpMergeTimes) ->
    1.

%%
get_loop_args(LastAddTime, Now) ->
    Diff = Now - LastAddTime,
    case Now > LastAddTime of
        true ->
            AddMin = Diff div ?ONE_MINUTE,
            LastAddTime2 = LastAddTime + AddMin * ?ONE_MINUTE,
            {AddMin, LastAddTime2};
        _ ->
            {0, LastAddTime}
    end.


get_add_args(AddMin, Illusion, NatIntensify, UnlockFloor) ->
    [#c_five_elements_floor{
        max_illusion = MaxIllusion,
        illusion_min = IllusionMin,
        max_nat_intensify = MaxNatIntensify,
        nat_intensify_min = NatIntensifyMin
    }] = lib_config:find(cfg_five_elements_floor, UnlockFloor),
    Illusion2 = ?IF(Illusion >= config_illusion(MaxIllusion), Illusion, erlang:min(config_illusion(MaxIllusion), Illusion + config_illusion(IllusionMin * AddMin))),
    NatIntensify2 = erlang:min(MaxNatIntensify, NatIntensify + NatIntensifyMin * AddMin),
    {Illusion =/= Illusion2 orelse NatIntensify =/= NatIntensify2, Illusion2, NatIntensify2}.

get_five_elements_normal_drop(Config) ->
    #c_five_elements_detail{
        need_world_level = NeedWorldLevel,
        normal_reward1 = DropIDList1,
        normal_reward2 = DropIDList2
    } = Config,
    ?IF(world_data:get_world_level() >= NeedWorldLevel, DropIDList2, DropIDList1).


%% 传给前端的，要整除10000
to_front_illusion(Illusion) ->
    Illusion div ?RATE_10000.

%% 从配置里获取的，要 * 10000
config_illusion(ConfigIllusion) ->
    lib_tool:ceil(ConfigIllusion * ?RATE_10000).
