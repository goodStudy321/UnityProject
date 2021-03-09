%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 17:26
%%%-------------------------------------------------------------------
-module(mod_role_confine).
-author("WZP").
-include("role.hrl").
-include("confine.hrl").
-include("suit.hrl").
-include("copy.hrl").
-include("proto/mod_role_confine.hrl").
-include("proto/mod_role_equip.hrl").
-include("proto/mod_role_suit.hrl").
-include("proto/mod_role_map_panel.hrl").
-include("proto/mod_role_skill.hrl").
-include("monster.hrl").
-include("mission.hrl").
-include("offline_solo.hrl").
-include("bg_act.hrl").
-include("act.hrl").
-include("discount_pay.hrl").

%% API
-export([
    init/1,
    online/1,
    handle/2,
    calc/1,
    level_up/3
]).

-export([
    gm_set_confine/3,
    gm_up_confine/1,
    gm_war_spirit/2,
    gm_add_mission/2,
    gm_set_mission/1,
    gm_add_war_spirit_refine_exp/2,
    get_mission_by_confine/1
]).
-export([
    do_trigger_confine_mission/4,
    add_equips/2,
%%    add_war_god_pieces/2,
    get_confine/1,
    get_confine_id/1,
    do_confine_up/2,
    check_can_in/2,
    is_bag_full/2
]).

%% FOR TEST
-export([
    get_war_spirit/2,
    get_new_level_exp/4
]).

%% FOR BUG
-export([
    cfg_confine_update/1,
    cfg_confine_update/0,
    update_mission/1,
    update_confine_status/1,
    need_fresh_mission/1
]).

-export([
    get_armor_orange_step_num/2,
    get_equip_orange_step_num/2
]).

-export([
    god_weapon_level_up/2,
    magic_weapon_level_up/2,
    wing_level_up/2,
    mount_step_up/2,
    pet_step_up/2,
    all_equip_Level/2,
    equip_stone/3,
    equip_stone_level/2,
    copy_tower/2,
%%    copy_yard/1,
    copy_ruins/1,
    copy_vault/1,
    copy_forest/1,
    copy_equip/1,
    three_start_copy/3,
    suit_num/2,
    all_rune_level/2,
    rune_num/3,
    up_level/2,
    up_power/2,
    kill_boss/2,
    kill_monster/2,
    join_off_line_solo/1,
    off_line_solo_win/2,
    solo_step/2,
    solo_times/1,
    answer_rank/2,
    battle/1,
    family_td/1,
    family_as/1,
    family_bs/1,
    family_bt/1,
    main_mission/2,
    check_equip_list/5,
%%    friend_num/2,
    answer_rank_i/2,
    pet_level/2,
    pos_suit/4,
    learn_skill/1,
    open_skill/1,
    role_enter_map/1,
    immortal_soul/2,
    family_mission/1,
    family_escort/1,
    equip_concise/1,
    open_box/2,
    copy_five_elements/2
]).

%%------------------------------------战灵开启等级配置表调整补丁----------------------------------------------


cfg_confine_update(#r_role{role_confine = undefined} = State) ->
    State;
cfg_confine_update(#r_role{role_confine = RoleConfine} = State) ->
    #r_role_confine{confine = Confine} = RoleConfine,
    case Confine > 1100 andalso 1300 > Confine of
        true ->
            open_war_spirit(State, 10101);
        _ ->
            State
    end.
cfg_confine_update() ->
    erlang:send(erlang:self(), {mod_role_confine, cfg_confine_update, []}).

%%-------------------------------------------------------------------------------------------------------------

%% %%------------------------------------任务补丁----------------------------------------------


update_mission(#r_role{role_confine = undefined} = State) ->
    State;
update_mission(#r_role{role_confine = RoleConfine, role_id = RoleID} = State) ->
    #r_role_confine{mission_list = MissionList} = RoleConfine,
    {NewMissionList, TriggerList} = lists:foldl(
        fun(#p_confine_mission{status = Status, mission_id = MissionID} = Mission, {AccList, AccTriggerList}) ->
            case Status =:= ?ACT_REWARD_CANNOT_GET of
                false ->
                    {[Mission|AccList], AccTriggerList};
                _ ->
                    [Config] = lib_config:find(cfg_confine_mission, MissionID),
                    case Config#c_confine_mission.complete_type =:= ?CONFINE_COMPLETE_OFFLINE_SOLO of
                        true ->
                            JoinTimes = case world_offline_solo_server:get_offline_solo(State#r_role.role_id) of
                                            [#r_role_offline_solo{challenge_times = Times}] ->
                                                ?DEFAULT_CHALLENGE_TIMES - Times;
                                            _ ->
                                                0
                                        end,
                            [Param] = Config#c_confine_mission.complete_param,
                            case JoinTimes >= Param of
                                true ->
                                    NewMission = Mission#p_confine_mission{times = Param, status = ?ACT_REWARD_CAN_GET};
                                _ ->
                                    NewMission = Mission#p_confine_mission{times = JoinTimes}
                            end,
                            {[NewMission|AccList], [NewMission|AccTriggerList]};
                        _ ->
                            {[Mission|AccList], AccTriggerList}
                    end
            end
        end,
        {[], []}, MissionList),
    common_misc:unicast(RoleID, #m_confine_mission_toc{update_mission = TriggerList}),
    RoleConfine2 = RoleConfine#r_role_confine{mission_list = NewMissionList},
    State#r_role{role_confine = RoleConfine2};
update_mission(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {?MODULE, update_mission, []});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, update_mission, [RoleID]})
    end.

%%-------------------------------------------------------------------------------------------------------------


%% %%------------------------------------任务重新取进度补丁----------------------------------------------


update_confine_status(#r_role{role_confine = undefined} = State) ->
    State;
update_confine_status(#r_role{role_confine = RoleConfine, role_id = RoleID} = State) ->
    #r_role_confine{mission_list = MissionList, confine = Confine} = RoleConfine,
    [Config] = lib_config:find(cfg_confine, Confine),
    MissionList2 = [begin
                        case Mission#p_confine_mission.status =:= ?ACT_REWARD_CANNOT_GET of
                            true ->
                                [ConfigMission] = lib_config:find(cfg_confine_mission, Mission#p_confine_mission.mission_id),
                                {Times, Status} = get_confine_mission_params(State, ConfigMission),
                                Mission#p_confine_mission{status = Status, times = Times};
                            _ ->
                                Mission
                        end
                    end || Mission <- MissionList],
    RoleConfine2 = RoleConfine#r_role_confine{mission_list = MissionList2},
    State2 = State#r_role{role_confine = RoleConfine2},
    common_misc:unicast(RoleID, #m_confine_mission_toc{update_mission = MissionList2}),
    case check_mission_all_complete(MissionList2) of
        true ->
            [Config] = lib_config:find(cfg_confine, RoleConfine#r_role_confine.confine),
            case Config#c_confine.map_id =:= 0 of
                false ->
                    State2;
                _ ->
                    GoodsList = get_all_reward(MissionList2),
                    do_confine_up(State2, Config, GoodsList)
            end;
        _ ->
            State2
    end;
update_confine_status(RoleID) ->
    case role_misc:is_online(RoleID) of
        true ->
            role_misc:info_role(RoleID, {?MODULE, update_confine_status, []});
        _ ->
            world_offline_event_server:add_event(RoleID, {?MODULE, update_confine_status, [RoleID]})
    end.

%%-------------------------------------------------------------------------------------------------------------


god_weapon_level_up(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_GOD_WEAPON, Level, 0, State).

magic_weapon_level_up(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_MAGIC_WEAPON, Level, 0, State).

wing_level_up(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_WING, Level, 0, State).

mount_step_up(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_MOUNT, Level, 0, State).

pet_step_up(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_PET, Level, 0, State).

all_equip_Level(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_EQUIP_REFINE, Level, 0, State).

equip_stone(AllLevel, Type, State) ->
    MissionType = ?IF(Type =:= ?STONE_HP, ?CONFINE_COMPLETE_EQUIP_STONE2, ?CONFINE_COMPLETE_EQUIP_STONE1),
    do_trigger_confine_mission(MissionType, AllLevel, 0, State).

equip_stone_level(LevelNumList, State) ->
    lists:foldl(
        fun({Level, Num}, StateAcc) ->
            ?IF(Num =:= 0, StateAcc, do_trigger_confine_mission(?CONFINE_COMPLETE_EQUIP_STONE_LEVEL, Num, Level, StateAcc))
        end,
        State, LevelNumList).

copy_tower(Num, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_PAGODA, Num, 0, State).

%%copy_yard(State) ->
%%    do_trigger_confine_mission(?CONFINE_COMPLETE_YARD, 1, 0, State).

copy_ruins(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_RUINS, 1, 0, State).

copy_vault(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_VAULT, 1, 0, State).

copy_forest(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FOREST, 1, 0, State).

copy_equip(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_EQUIP_COPY, 1, 0, State).

all_rune_level(Num, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_RUNE_LEVEL, Num, 0, State).

rune_num(Num, Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_RUNE, Num, Level, State).

up_level(Level, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_LEVEL, Level, 0, State).

up_power(Power, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_POWER, Power, 0, State).

join_off_line_solo(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_OFFLINE_SOLO, 1, 0, State).

off_line_solo_win(Rank, State) ->
    State2 = do_trigger_confine_mission(?CONFINE_COMPLETE_OFFLINE_SOLO_WIN, 1, 0, State),
    off_line_solo_rank(Rank, State2).


off_line_solo_rank(Rank, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_OFFLINE_SOLO_RANK, Rank, 0, State).


solo_step(Score, State) ->
    Step = mod_solo:get_step_by_score(Score),
    do_trigger_confine_mission(?CONFINE_COMPLETE_SOLE, Step, 0, State).

solo_times(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_SOLE_RANK, 1, 0, State).


three_start_copy(Type, MapID, State) ->
    case Type of
        ?COPY_SILVER ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_VAULT_FIRST, 1, MapID, State);
        ?COPY_SINGLE_TD ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_RUINS_FIRST, 1, MapID, State);
        ?COPY_EQUIP ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_EQUIP_COPY_FIRST, 1, MapID, State);
        _ ->
            State
    end.

suit_num(List, State) ->
    lists:foldl(
        fun({SuitID, Num}, State2) ->
            case SuitID of
                ?EQUIP_SUIT_LEVEL_IMMORTAL ->
                    do_trigger_confine_mission(?CONFINE_COMPLETE_ZHUXIAN, Num, 0, State2);
                ?EQUIP_SUIT_LEVEL_GOD ->
                    do_trigger_confine_mission(?CONFINE_COMPLETE_ZHUSHENG, Num, 0, State2);
                _ ->
                    State2
            end
        end, State, List).

kill_boss(TypeID, State) ->
    #c_monster{rarity = Rarity, level = MonsterLevel} = monster_misc:get_monster_config(TypeID),
    case Rarity =:= 1 orelse Rarity =:= 2 of
        false ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_BOSS, MonsterLevel, 1, State);
        _ ->
            State
    end.


kill_monster(TypeID, State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_MONSTER, 1, TypeID, State).

answer_rank(Rank, RoleInfo) ->
    case common_config:is_cross_node() of
        false ->
            answer_rank_i(Rank, RoleInfo);
        _ ->
            node_misc:cross_send_mfa_by_role_id(RoleInfo, {?MODULE, answer_rank_i, [Rank, RoleInfo]})
    end.

answer_rank_i(Rank, RoleInfo) ->
    if
        erlang:is_integer(RoleInfo) ->
            case role_misc:is_online(RoleInfo) of
                true ->
                    role_misc:info_role(RoleInfo, {?MODULE, answer_rank_i, [Rank]});
                _ ->
                    world_offline_event_server:add_event(RoleInfo, {?MODULE, answer_rank_i, [Rank, RoleInfo]})
            end;
        erlang:is_record(RoleInfo, r_role) ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_ANSWER_RANK, Rank, 0, RoleInfo);
        true ->
            RoleInfo
    end.

battle(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_BATTLE, 1, 0, State).

family_td(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_TD, 1, 0, State).

family_as(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_ANSWER, 1, 0, State).

family_bs(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_BOSS, 1, 0, State).

family_bt(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_BT, 1, 0, State).

main_mission(State, Type) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_MAIN_MISSION, Type, 0, State).

family_mission(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_MISSION, 1, 0, State).

copy_five_elements(State, MapID) ->
    do_trigger_confine_mission(?CONFINE_FIVE_ELEMENTS, 1, MapID, State).

family_escort(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_FAMILY_ESCORT, 1, 0, State).

equip_concise(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_XILIAN, 1, 0, State).

open_box(State, List) ->
    lists:foldl(fun({ColorI, NumI}, StateAcc) ->
        case NumI > 0 of
            true ->
                do_trigger_confine_mission(?CONFINE_COMPLETE_BOX_COLOR, NumI, ColorI, StateAcc);
            _ ->
                StateAcc
        end
                end, State, List).


%%friend_num(State, Num) ->
%%    do_trigger_confine_mission(?CONFINE_COMPLETE_FRIEND, Num, 0, State).

pet_level(State, NewLevel) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_PET_I, NewLevel, 0, State).

pos_suit(State, SubType, Type, CheckList) ->
    MissionType = case Type =:= 1 of
                      true ->
                          ?IF(SubType =:= 1, ?CONFINE_COMPLETE_EQUIP_SEVEN, ?CONFINE_COMPLETE_EQUIP_EIGHT);
                      _ ->
                          ?IF(SubType =:= 1, ?CONFINE_COMPLETE_EQUIP_NINE, ?CONFINE_COMPLETE_EQUIP_TEM)
                  end,
    lists:foldl(fun({NumI, StepI}, StateAcc) ->
        do_trigger_confine_mission(MissionType, NumI, StepI, StateAcc)
                end, State, CheckList).

learn_skill(State) ->
    do_trigger_confine_mission(?CONFINE_COMPLETE_UP_SKILL, 1, 0, State).

open_skill(State) ->
    Num = get_role_skill_num(State),
    do_trigger_confine_mission(?CONFINE_COMPLETE_LEARN_SKILL, Num, 0, State).

role_enter_map(#r_role{role_map = RoleMap} = State) ->
    case lib_config:find(cfg_copy, RoleMap#r_role_map.map_id) of
        [#c_copy{copy_type = CopyType}] ->
            #r_role{role_copy = #r_role_copy{exp_now_merge_times = Times}} = State,
            ?IF(?COPY_EXP =:= CopyType, do_trigger_confine_mission(?CONFINE_COMPLETE_YARD, Times, 0, State), State);
        _ ->
            State
    end.

immortal_soul(ColorList, State) ->
    lists:foldl(
        fun({Num, Color}, AccState) ->
            if
                Color =:= 4 -> do_trigger_confine_mission(?CONFINE_COMPLETE_IMMORTAL_SOUL_O, Num, Color, AccState);
                Color =:= 5 -> do_trigger_confine_mission(?CONFINE_COMPLETE_IMMORTAL_SOUL_R, Num, Color, AccState);
                true ->
                    AccState
            end
        end,
        State, ColorList).



check_equip_list(State, EquipList, Step, Quality, Star) ->
    CheckList = get_mission_type_check_list(?CONFINE_COMPLETE_EQUIP_LIST, [], Step, Quality, Star),
    CheckList2 = check_equip_list(CheckList, EquipList),
    lists:foldl(
        fun({_MissionQuality, _MissionStar, MissionType, MissionStep, MissionNum}, StateAcc) ->
            case MissionNum =/= 0 of
                true ->
                    do_trigger_confine_mission(MissionType, MissionNum, MissionStep, StateAcc);
                _ ->
                    StateAcc
            end
        end, State, CheckList2).


get_mission_type_check_list([], List, _Step, _Quality, _Star) ->
    List;
get_mission_type_check_list([{MissionQuality, MissionStar, MissionType}|T], List, Step, Quality, Star) ->
    CheckList = get_mission_type_check_list_i(MissionQuality, MissionStar, MissionType, Step, []),
    get_mission_type_check_list(T, CheckList ++ List, Step, Quality, Star).

get_mission_type_check_list_i(MissionQuality, MissionStar, MissionType, Step, List) when Step > 0 ->
    get_mission_type_check_list_i(MissionQuality, MissionStar, MissionType, Step - 1, [{MissionQuality, MissionStar, MissionType, Step, 0}|List]);
get_mission_type_check_list_i(_, _, _, _, List) ->
    List.



check_equip_list(CheckList, []) ->
    CheckList;
check_equip_list(CheckList, [#p_equip{equip_id = EquipID}|EquipList]) ->
    [#c_equip{quality = Quality2, star = Star2, step = Step2}] = lib_config:find(cfg_equip, EquipID),
    CheckList2 = check_equip_list_i(Quality2, Star2, Step2, CheckList, []),
    check_equip_list(CheckList2, EquipList).

check_equip_list_i(_Quality, _Star, _Step, [], List) ->
    List;
check_equip_list_i(Quality, Star, Step, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum}|T], List) ->
    if
        Step > MissionStep ->
            check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum + 1}|List]);
        Step =:= MissionStep ->
            if
                Quality > MissionQuality ->
                    check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum + 1}|List]);
                Quality =:= MissionQuality ->
                    case Star >= MissionStar of
                        true ->
                            check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum + 1}|List]);
                        _ ->
                            check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum}|List])
                    end;
                true ->
                    check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum}|List])
            end;
        true ->
            check_equip_list_i(Quality, Star, Step, T, [{MissionQuality, MissionStar, MissionType, MissionStep, MissionNum}|List])
    end.





init(#r_role{role_confine = undefined, role_id = RoleID} = State) ->
    RoleConfine = #r_role_confine{role_id = RoleID, confine = ?CONFINE_INIT_ID},
    State2 = State#r_role{role_confine = RoleConfine},
    NewList = get_mission_by_confine(State2),
    RoleConfine2 = RoleConfine#r_role_confine{mission_list = NewList},
    common_misc:unicast(RoleID, #m_confine_info_toc{confine = RoleConfine2#r_role_confine.confine, war_spirit = RoleConfine2#r_role_confine.war_spirit,
                                                    war_spirit_list = RoleConfine2#r_role_confine.war_spirit_list, mission = RoleConfine2#r_role_confine.mission_list}),
    State2#r_role{role_confine = RoleConfine2};
init(State) ->
    State.

%%function_open(State) ->
%%    State.

online(#r_role{role_confine = undefined} = State) ->
    State;
online(#r_role{role_id = RoleID, role_confine = RoleConfine} = State) ->
    #r_role_confine{
        mission_list = MissionList,
        confine = Confine,
        war_spirit = WarSpirit,
        war_spirit_list = WarSpiritList,
        refine_all_exp = RefineAllExp,
        bag_list = BagList,
        war_god_list = WarGodList,
        war_god_pieces = WarGodPieces,
        lock_info = LockInfo
    } = RoleConfine,
    DataRecord = #m_confine_info_toc{
        reward = not lists:member(RoleConfine#r_role_confine.confine, RoleConfine#r_role_confine.confine_reward),
        mission = MissionList,
        confine = Confine,
        war_spirit = WarSpirit,
        war_spirit_list = WarSpiritList,
        refine_all_exp = RefineAllExp,
        bag_list = BagList,
        war_god_list = WarGodList,
        war_god_pieces = WarGodPieces,
        war_spirit_lock_info = LockInfo},
    common_misc:unicast(RoleID, DataRecord),
    case check_need_auto_get_reward(RoleConfine#r_role_confine.confine_reward) of
        false ->
            State;
        _ ->
            do_confine_calc(State)
    end.

check_need_auto_get_reward([]) ->
    false;
check_need_auto_get_reward([RewardID|T]) ->
    [Config] = lib_config:find(cfg_confine, RewardID),
    case Config#c_confine.map_id =:= 0 of
        true ->
            true;
        _ ->
            check_need_auto_get_reward(T)
    end.



calc(#r_role{role_confine = undefined} = State) ->
    State;
calc(#r_role{role_confine = RoleConfine} = State) ->
    #r_role_confine{confine = Confine, war_god_list = WarGodList} = RoleConfine,
    PkvList = get_pkv_by_confine(Confine),
    CalcAttr1 = common_misc:get_attr_by_kv(PkvList),
    CalcAttr2 = get_attr_by_war_spirit(RoleConfine#r_role_confine.war_spirit_list, #actor_cal_attr{}),
    CalcAttr3 = get_attr_by_war_god(WarGodList, #actor_cal_attr{}),
    ActorCalAttr = common_misc:sum_calc_attr([CalcAttr1, CalcAttr2, CalcAttr3]),
    mod_role_fight:get_state_by_kv(State, ?CALC_KEY_CONFINE, ActorCalAttr).

get_pkv_by_confine(Confine) ->
    case lib_config:find(cfg_confine, Confine) of
        [Config] ->
            [#p_kv{id = ?ATTR_HP, val = Config#c_confine.hp},
             #p_kv{id = ?ATTR_ATTACK, val = Config#c_confine.attack},
             #p_kv{id = ?ATTR_DEFENCE, val = Config#c_confine.defence},
             #p_kv{id = ?ATTR_HURT_RATE, val = Config#c_confine.hurt_rate},
             #p_kv{id = ?ATTR_HURT_DERATE, val = Config#c_confine.hurt_derate},
             #p_kv{id = ?ATTR_ARP, val = Config#c_confine.arp}];
        _ ->
            []
    end.

get_attr_by_war_spirit([], Acc) ->
    Acc;
get_attr_by_war_spirit([#p_war_spirit{id = WarSpiritID, level = Level, equip_list = EquipList, armor_list = ArmorList}|T], Acc) ->
    [Config] = get_war_spirit(WarSpiritID, Level),
    KVList = [
        #p_kv{id = ?ATTR_HP, val = Config#c_war_spirit_up.hp},
        #p_kv{id = ?ATTR_DEFENCE, val = Config#c_war_spirit_up.defence},
        #p_kv{id = ?ATTR_ATTACK, val = Config#c_war_spirit_up.attack},
        #p_kv{id = ?ATTR_ARP, val = Config#c_war_spirit_up.arp},
        #p_kv{id = ?ATTR_RATE_ADD_ATTACK, val = Config#c_war_spirit_up.rate_attack}
    ],
    CalcAttr1 = common_misc:get_attr_by_kv(KVList),
    CalcAttr2 = get_war_spirit_equip_attr(WarSpiritID, EquipList),
    CalcAttr3 = get_war_spirit_armor_attr(ArmorList),
    get_attr_by_war_spirit(T, common_misc:sum_calc_attr([CalcAttr1, CalcAttr2, CalcAttr3, Acc])).

get_war_spirit_equip_attr(WarSpiritID, EquipList) ->
    {EquipAttr, SuitList} =
    lists:foldl(
        fun(Equip, {AttrAcc, SuitAcc}) ->
            #p_war_spirit_equip{
                type_id = TypeID,
                refine_level = RefineLevel,
                excellent_list = ExcellentList
            } = Equip,
            [#c_war_spirit_equip_info{
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp,
                suit_id_list = SuitIDList}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
            BaseAttr =
            #actor_cal_attr{
                max_hp = {AddHp, 0},
                attack = {AddAttack, 0},
                defence = {AddDefence, 0},
                arp = {AddArp, 0}
            },
            RefineAttr =
            case RefineLevel > 0 of
                true ->
                    [#c_war_spirit_equip_refine{
                        add_hp = AddHp2,
                        add_attack = AddAttack2,
                        add_defence = AddDefence2,
                        add_arp = AddArp2
                    }] = lib_config:find(cfg_war_spirit_equip_refine, RefineLevel),
                    %% 基础属性要 > 0 强化属性才生效
                    #actor_cal_attr{
                        max_hp = {?IF(AddHp > 0, AddHp2, 0), 0},
                        attack = {?IF(AddAttack > 0, AddAttack2, 0), 0},
                        defence = {?IF(AddDefence > 0, AddDefence2, 0), 0},
                        arp = {?IF(AddArp > 0, AddArp2, 0), 0}
                    };
                _ ->
                    #actor_cal_attr{}
            end,
            ExcellentList2 = to_excellent_kv(ExcellentList),
            Acc2 = common_misc:sum_calc_attr([BaseAttr, RefineAttr, common_misc:get_attr_by_kv(ExcellentList2), AttrAcc]),
            SuitAcc2 =
            lists:foldl(
                fun(SuitID, Acc) ->
                    case lists:keytake(SuitID, 1, Acc) of
                        {value, {SuitID, OldVal}, SuitAccT} ->
                            [{SuitID, OldVal + 1}|SuitAccT];
                        _ ->
                            [{SuitID, 1}|Acc]
                    end
                end, SuitAcc, SuitIDList),
            {Acc2, SuitAcc2}
        end, {#actor_cal_attr{}, []}, EquipList),
    SuitList2 = lists:sort(                                                     fun({SuitID1, SuitNum1}, {SuitID2, SuitNum2}) ->
        ?IF(SuitNum1 =:= SuitNum2, SuitID1 > SuitID2, SuitNum1 > SuitNum2) end, SuitList),
    case SuitList2 of
        [{SuitID, SuitNum}|_] when SuitNum >= 4 ->
            [#c_war_spirit_equip_suit{
                spirit_list = WarSpiritIDList,
                add_hp = AddHp,
                add_attack = AddAttack,
                add_defence = AddDefence,
                add_arp = AddArp
            }] = lib_config:find(cfg_war_spirit_equip_suit, SuitID),
            case lists:member(WarSpiritID, WarSpiritIDList) of
                true ->
                    SuitAttr =
                    #actor_cal_attr{
                        max_hp = {AddHp, 0},
                        attack = {AddAttack, 0},
                        defence = {AddDefence, 0},
                        arp = {AddArp, 0}
                    },
                    common_misc:sum_calc_attr2(SuitAttr, EquipAttr);
                _ ->
                    EquipAttr
            end;
        _ ->
            EquipAttr
    end.

get_war_spirit_armor_attr(ArmorList) ->
    get_war_spirit_armor_attr2(ArmorList, #actor_cal_attr{}).

get_war_spirit_armor_attr2([], AttrAcc) ->
    AttrAcc;
get_war_spirit_armor_attr2([#p_war_spirit_armor{type_id = TypeID, excellent_list = ExcellentList}|R], AttrAcc) ->
    EquipAttr = mod_role_equip:get_equip_attr(TypeID),
    ExcellentAttr = common_misc:get_attr_by_kv(ExcellentList),
    get_war_spirit_armor_attr2(R, common_misc:sum_calc_attr([AttrAcc, EquipAttr, ExcellentAttr])).


get_attr_by_war_god([], AttrAcc) ->
    AttrAcc;
get_attr_by_war_god([WarGod|R], AttrAcc) ->
    #p_war_god{id = WarGodID, equip_list = EquipList} = WarGod,
    [#c_war_god_base{
        add_hp = AddHp1,
        add_attack = AddAttack1,
        add_defence = AddDefence1,
        add_arp = AddArp1
    }] = lib_config:find(cfg_war_god_base, WarGodID),
    {AddHp2, AddAttack2, AddDefence2, AddArp2, MinRefineLevel} = get_war_god_equip(EquipList, 0, 0, 0, 0, 0),
    {AddRate, SuitAttr} = get_war_god_suit(WarGodID, MinRefineLevel),
    BaseAttr =
    #actor_cal_attr{
        max_hp = {lib_tool:ceil((AddHp1 + AddHp2) * (1 + AddRate / ?RATE_10000)), 0},
        attack = {lib_tool:ceil((AddAttack1 + AddAttack2) * (1 + AddRate / ?RATE_10000)), 0},
        defence = {lib_tool:ceil((AddDefence1 + AddDefence2) * (1 + AddRate / ?RATE_10000)), 0},
        arp = {lib_tool:ceil((AddArp1 + AddArp2) * (1 + AddRate / ?RATE_10000)), 0}
    },
    get_attr_by_war_god(R, common_misc:sum_calc_attr([BaseAttr, SuitAttr, AttrAcc])).

get_war_god_equip([], AddHp, AddAttack, AddDefence, AddArp, MinRefineLevel) ->
    {AddHp, AddAttack, AddDefence, AddArp, MinRefineLevel};
get_war_god_equip([Equip|R], AddHpAcc, AddAttackAcc, AddDefenceAcc, AddArpAcc, MinRefineLevel) ->
    #p_war_god_equip{equip_id = EquipID, refine_level = RefineLevel} = Equip,
    [#c_war_god_refine{
        add_hp = AddHp,
        add_attack = AddAttack,
        add_defence = AddDefence,
        add_arp = AddArp
    }] = lib_config:find(cfg_war_god_refine, {EquipID, RefineLevel}),
    AddHpAcc2 = AddHp + AddHpAcc,
    AddAttackAcc2 = AddAttack + AddAttackAcc,
    AddDefenceAcc2 = AddDefence + AddDefenceAcc,
    AddArpAcc2 = AddArp + AddArpAcc,
    MinRefineLevel2 = erlang:min(MinRefineLevel, RefineLevel),
    get_war_god_equip(R, AddHpAcc2, AddAttackAcc2, AddDefenceAcc2, AddArpAcc2, MinRefineLevel2).

get_war_god_suit(WarGodID, MinRefineLevel) ->
    case lib_config:find(cfg_war_god_suit, {WarGodID, MinRefineLevel}) of
        [PropString] ->
            {Rate, ListAcc} =
            lists:foldl(
                fun(#p_kv{id = ID, val = Val} = KV, {RateAcc, ListAcc}) ->
                    if
                        ID =:= ?ATTR_WAR_GOD_SUIT ->
                            {RateAcc + Val, ListAcc};
                        true ->
                            {RateAcc, [KV|ListAcc]}
                    end
                end, {0, []}, common_misc:get_string_props(PropString)),
            {Rate, common_misc:get_attr_by_kv(ListAcc)};
        _ ->
            {0, #actor_cal_attr{}}
    end.

level_up(NewLevel, _OldLevel, State) ->
    up_level(NewLevel, State).

handle({#m_war_spirit_change_tos{id = ID}, RoleID, _PID}, State) ->
    do_war_spirit_change(ID, State, RoleID);

handle({#m_confine_calc_tos{}, _RoleID, _PID}, State) ->
    do_confine_calc(State);

handle({#m_role_action_tos{action = Action}, _RoleID, _PID}, State) ->
    do_role_action(Action, State);

handle({#m_war_spirit_up_tos{war_spirit = WarSpirit, num = Num}, RoleID, _PID}, State) ->
    do_war_spirit_up(WarSpirit, Num, State, RoleID);

%%handle({#m_confine_up_tos{}, RoleID, _PID}, State) ->
%%    do_confine_up_i(State, RoleID);

handle({#m_confine_process_tree_tos{}, RoleID, _PID}, State) ->
    do_confine_process_tree(RoleID, State);
handle({#m_confine_crossover_tos{}, RoleID, _PID}, State) ->
    do_confine_crossover(RoleID, State);

handle({#m_confine_mission_tos{mission = MissionID}, RoleID, _PID}, State) ->
    do_confine_mission(MissionID, State, RoleID);

handle({#m_war_spirit_equip_load_tos{war_spirit_id = WarSpiritID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_load(RoleID, WarSpiritID, EquipID, State);
handle({#m_war_spirit_equip_unload_tos{war_spirit_id = WarSpiritID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_unload(RoleID, WarSpiritID, EquipID, State);
handle({#m_war_spirit_equip_decompose_tos{equip_id = EquipIDList}, RoleID, _PID}, State) ->
    do_equip_decompose(RoleID, EquipIDList, State);
handle({#m_war_spirit_equip_refine_tos{war_spirit_id = WarSpiritID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_refine(RoleID, WarSpiritID, EquipID, State);
handle({#m_war_spirit_equip_step_tos{war_spirit_id = WarSpiritID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_equip_step(RoleID, WarSpiritID, EquipID, State);
handle({#m_war_spirit_armor_load_tos{war_spirit_id = WarSpiritID, goods_ids = GoodsIDs}, RoleID, _PID}, State) ->
    do_armor_load(RoleID, WarSpiritID, GoodsIDs, State);
handle({#m_war_spirit_armor_unload_tos{war_spirit_id = WarSpiritID, type_ids = TypeIDs}, RoleID, _PID}, State) ->
    do_armor_unload(RoleID, WarSpiritID, TypeIDs, State);
handle({#m_war_god_piece_active_tos{war_god_id = WarGodID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_war_god_piece(RoleID, WarGodID, EquipID, State);
handle({#m_war_god_active_tos{war_god_id = WarGodID}, RoleID, _PID}, State) ->
    do_war_god_active(RoleID, WarGodID, State);
handle({#m_war_god_refine_tos{war_god_id = WarGodID, equip_id = EquipID}, RoleID, _PID}, State) ->
    do_war_god_refine(RoleID, WarGodID, EquipID, State);
handle({#m_war_god_decompose_tos{piece_ids = IDs}, RoleID, _PID}, State) ->
    do_war_god_decompose(RoleID, IDs, State);
handle({#m_war_spirit_armor_lock_info_tos{war_spirit_id = WarSpiritID, index = Index}, RoleID, _PID}, State) ->
    do_armor_lock_info(RoleID, WarSpiritID, Index, State);
handle(Info, State) ->
    ?ERROR_MSG("unkonw Info : ~w", [Info]),
    State.

do_role_action(Action, State) ->
    case Action of
        1 ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_FRIEND, 100, 0, State);
        2 ->
            do_trigger_confine_mission(?CONFINE_COMPLETE_LOOK_XLFB, 1, 0, State);
        3 ->
            case mod_role_bg_act:is_bg_act_open(?BG_ACT_TREVI_FOUNTAIN, State) of
                true ->
                    mod_role_trevi_fountain:close_notice(State);
                _ ->
                    ?IF(mod_role_act:is_act_open(?ACT_OSS_TREVI_FOUNTAIN, State), mod_role_act_os_second:close_notice(State), State)
            end;
        _ ->
            State
    end.

%%战灵升级
do_war_spirit_up(WarSpiritID, Num, State, RoleID) ->
    case catch check_war_spirit_up(WarSpiritID, Num, State) of
        {ok, State2, WarSpirit} ->
            common_misc:unicast(RoleID, #m_war_spirit_up_toc{war_spirit = WarSpirit}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_up_toc{err_code = ErrCode}),
            State
    end.


check_war_spirit_up(WarSpiritID, NumT, #r_role{role_confine = RoleConfine} = State) ->
    case lists:keytake(WarSpiritID, #p_war_spirit.id, RoleConfine#r_role_confine.war_spirit_list) of
        false ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_CHANGE_001);
        {value, #p_war_spirit{level = Level, exp = Exp, id = ID} = WarSpirit, Other} ->
            Num = erlang:max(1, NumT),
            BagDoing = mod_role_bag:check_num_by_type_id(?WAR_SPIRIT_UP_ITEM, Num, ?ITEM_REDUCE_WAR_SPIRIT, State),
            [Config] = lib_config:find(cfg_item, ?WAR_SPIRIT_UP_ITEM),
            [WarConfig] = get_war_spirit(ID, Level),
            ?IF(Exp >= WarConfig#c_war_spirit_up.exp, ?THROW_ERR(?ERROR_WAR_SPIRIT_UP_003), ok),%%确实为境界不足  境界提高后会把超经验战灵提升
            AddExp = lib_tool:to_integer(Config#c_item.effect_args) * Num,
            {NewExp, NewLevel, NewSkill} = get_new_level_exp(Exp + AddExp, WarConfig, WarConfig#c_war_spirit_up.skill, RoleConfine#r_role_confine.confine),
            ?IF(NewExp =:= Exp andalso NewLevel =:= WarConfig#c_war_spirit_up.level, ?THROW_ERR(?ERROR_WAR_SPIRIT_UP_002), ok),
            NewWarSpirit = WarSpirit#p_war_spirit{level = NewLevel, exp = NewExp},
            NewRoleConfine = RoleConfine#r_role_confine{war_spirit_list = [NewWarSpirit|Other]},
            State2 = State#r_role{role_confine = NewRoleConfine},
            State3 = mod_role_bag:do(BagDoing, State2),
            State4 = ?IF(NewSkill =:= WarConfig#c_war_spirit_up.skill andalso WarSpiritID =:= RoleConfine#r_role_confine.war_spirit, State3,
                         skills_change(WarConfig#c_war_spirit_up.skill, NewSkill, State3)),
            State5 = mod_role_fight:calc_attr_and_update(calc(State4), ?ITEM_REDUCE_WAR_SPIRIT, WarConfig#c_war_spirit_up.id),
            {ok, State5, NewWarSpirit}
    end.

get_new_level_exp(Exp, Config, Skill, Confine) ->
    case Config#c_war_spirit_up.exp =< Exp of
        true ->
            case Confine >= Config#c_war_spirit_up.open_confine of
                true ->
                    case get_war_spirit(Config#c_war_spirit_up.war_spirit_id, Config#c_war_spirit_up.level + 1) of
                        [] ->
                            {Exp, Config#c_war_spirit_up.level, Skill};
                        [WarConfig] ->
                            get_new_level_exp(Exp - Config#c_war_spirit_up.exp, WarConfig, WarConfig#c_war_spirit_up.skill, Confine)
                    end;
                _ ->
                    {Exp, Config#c_war_spirit_up.level, Skill}
            end;
        _ ->
            {Exp, Config#c_war_spirit_up.level, Skill}
    end.


skills_change(OldSkills, NewSkills, State) ->
    case lists:sort(OldSkills) =:= lists:sort(NewSkills) of
        true ->
            State;
        _ ->
            skills_change2(NewSkills, State)
    end.

skills_change2(Skills, State) ->
    #r_role{role_confine = #r_role_confine{war_spirit = WarSpiritID, war_god_list = WarGodList}} = State,
    Skills2 =
    case lists:keyfind(WarSpiritID, #p_war_god.id, WarGodList) of
        #p_war_god{is_active = true} ->
            [#c_war_god_base{replace_skill_id = ReplaceSkillID}] = lib_config:find(cfg_war_god_base, WarSpiritID),
            [ReplaceSkillID|Skills];
        _ ->
            Skills
    end,
    mod_role_skill:skill_fun_change(?SKILL_FUN_WAR_SPIRIT, Skills2, State).

%%换战灵
%%  war_spirit_change - 切换战灵时间戳 10CD时间防止刷战灵技能
do_war_spirit_change(ID, State, RoleID) ->
    case catch check_war_spirit_change(ID, State) of
        {ok, State2, WarSpiritList} ->
            common_misc:unicast(RoleID, #m_war_spirit_change_toc{war_spirit = ID, war_spirit_list = WarSpiritList}),
            State2;
        {error, {?ERROR_WAR_SPIRIT_CHANGE_003, Time}} ->   %%前端需
            common_misc:unicast(RoleID, #m_war_spirit_change_toc{err_code = ?ERROR_WAR_SPIRIT_CHANGE_003, time = Time}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_change_toc{err_code = ErrCode}),
            State
    end.

check_war_spirit_change(ID, #r_role{role_confine = RoleConfine} = State) ->
    ?IF(ID =:= RoleConfine#r_role_confine.war_spirit, ?THROW_ERR(?ERROR_WAR_SPIRIT_CHANGE_002), ok),
    case lists:keyfind(ID, #p_war_spirit.id, RoleConfine#r_role_confine.war_spirit_list) of
        false ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_CHANGE_001);
        NewWarSpirit ->
            Now = time_tool:now(),
            ?IF(Now >= RoleConfine#r_role_confine.war_spirit_change + 10, ok, ?THROW_ERR({?ERROR_WAR_SPIRIT_CHANGE_003, RoleConfine#r_role_confine.war_spirit_change + 10 - Now})),
            OldWarSpirit = lists:keyfind(RoleConfine#r_role_confine.war_spirit, #p_war_spirit.id, RoleConfine#r_role_confine.war_spirit_list),
            [OldConfig] = get_war_spirit(OldWarSpirit#p_war_spirit.id, OldWarSpirit#p_war_spirit.level),
            [NewConfig] = get_war_spirit(NewWarSpirit#p_war_spirit.id, NewWarSpirit#p_war_spirit.level),
            NewRoleConfine = RoleConfine#r_role_confine{war_spirit = ID, war_spirit_change = time_tool:now()},
            State2 = State#r_role{role_confine = NewRoleConfine},
            State3 = skills_change(OldConfig#c_war_spirit_up.skill, NewConfig#c_war_spirit_up.skill, State2),
            {ok, State3, RoleConfine#r_role_confine.war_spirit_list}
    end.

check_can_in(_MapID, #r_role{role_confine = undefined} = State) ->
    ?THROW_ERR(?ERROR_COMMON_FUNCTION_NOT_OPEN),
    State;
check_can_in(MapID, #r_role{role_confine = RoleConfine} = State) ->
    [Config] = lib_config:find(cfg_confine, RoleConfine#r_role_confine.confine),
    ?IF(MapID =:= Config#c_confine.map_id, ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_CHANGE_004)),
    case Config#c_confine.item =:= 0 of
        true ->
            ok;
        _ ->
            ItemList = [{?CONFINE_UP_ITEM_THREE, Config#c_confine.item}],
            mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_CONFINE_UP, State)
    end,
    ?IF(
        lists:all(
            fun(Mission) ->
                Mission#p_confine_mission.status =/= ?ACT_REWARD_CANNOT_GET
            end, RoleConfine#r_role_confine.mission_list), ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_CHANGE_004)),
    State.




need_fresh_mission(Confine) ->
    case lib_config:find(cfg_confine, Confine - 1) of
        [ConfineConfig] ->
            ConfineConfig#c_confine.map_id =/= 0;
        _ ->
            ConfineID = (Confine div 100 - 1) * 100,
            ConfineID2 = need_fresh_mission_i(ConfineID),
            [ConfineConfig] = lib_config:find(cfg_confine, ConfineID2),
            ConfineConfig#c_confine.map_id =/= 0
    end.

need_fresh_mission_i(ConfineID) ->
    case lib_config:find(cfg_confine, ConfineID + 1) of
        [_ConfineConfig] ->
            need_fresh_mission_i(ConfineID + 1);
        _ ->
            ConfineID
    end.


do_confine_calc(#r_role{role_confine = RoleConfine, role_id = RoleID} = State) ->
    ConfineReward = RoleConfine#r_role_confine.confine_reward,
    case ConfineReward =:= [] of
        true ->
            State;
        _ ->
            [NewConfineConfig] = lib_config:find(cfg_confine, RoleConfine#r_role_confine.confine),
            Flage = need_fresh_mission(RoleConfine#r_role_confine.confine),
            ?IF(Flage, common_misc:unicast(RoleID, #m_confine_up_toc{confine = RoleConfine#r_role_confine.confine}), ok),
            {State2, ItemNum} = do_confine_calc(State, ConfineReward, 0),
            case ItemNum =:= 0 of
                true ->
                    BagDoing = [];
                _ ->
                    DecreaseList = [{?CONFINE_UP_ITEM_THREE, ItemNum}],
                    BagDoing = mod_role_bag:check_num_by_item_list(DecreaseList, ?ITEM_REDUCE_CONFINE_UP, State)
            end,
            State3 = State2#r_role{role_confine = RoleConfine#r_role_confine{confine_reward = []}},
            State4 = check_war_spirit_up_list(State3),
            State5 = ?IF(NewConfineConfig#c_confine.open_war_spirit =/= 0, open_war_spirit(State4, NewConfineConfig#c_confine.open_war_spirit), State4),
            State6 = ?IF(Flage, after_do_confine_up(State5), State5),
            #r_role{role_confine = RoleConfine2} = State6,
            common_misc:unicast(RoleID, #m_confine_calc_toc{reward = not lists:member(RoleConfine2#r_role_confine.confine, RoleConfine2#r_role_confine.confine_reward),
                                                            update_mission = RoleConfine2#r_role_confine.mission_list}),
            ?IF(BagDoing =:= [], State6, mod_role_bag:do(BagDoing, State6))
    end.

do_confine_calc(State, [], Num) ->
    {State, Num};
do_confine_calc(#r_role{role_attr = RoleAttr} = State, [NewConfineID|T], Num) ->
    case get_skill_or_book(NewConfineID, RoleAttr#r_role_attr.sex) of
        {skill, SkillID, _} ->
            State2 = mod_role_skill:skill_open(SkillID, State);
        {book, RewardGoods2} ->
            State2 = role_misc:create_goods(State, ?ITEM_GAIN_CONFINE, RewardGoods2)
    end,
    [ConfineConfig] = lib_config:find(cfg_confine, get_confine_down(NewConfineID)),
    State3 = mod_role_fight:calc_attr_and_update(do_confine_update_calc(State2), ?POWER_UPDATE_CONFINE_UP, State2#r_role.role_confine#r_role_confine.confine),
    do_confine_calc(State3, T, Num + ConfineConfig#c_confine.item).

%% 境界改变引起的属性重算
do_confine_update_calc(State) ->
    List = [?MODULE, mod_role_skill],
    lists:foldl(fun(Mod, State2) -> Mod:calc(State2) end, State, List).

%%渡劫提升境界
do_confine_up(#r_role{role_confine = RoleConfine, role_id = RoleID} = State, _ConfineConfig, RewardGoods) ->
    {IsBc, NewConfineID} = get_confine_up(RoleConfine#r_role_confine.confine),
    [NewConfineConfig] = lib_config:find(cfg_confine, NewConfineID),
    NewRoleConfine = RoleConfine#r_role_confine{confine = NewConfineID, confine_reward = [NewConfineID|RoleConfine#r_role_confine.confine_reward]},
    State3 = State#r_role{role_confine = NewRoleConfine},
    common_misc:unicast(RoleID, #m_confine_up_toc{confine = NewRoleConfine#r_role_confine.confine}),
    mod_map_role:update_role_confine(mod_role_dict:get_map_pid(), RoleID, NewRoleConfine#r_role_confine.confine),
    ?IF(IsBc, common_broadcast:send_world_common_notice(?NOTICE_CONFINE_UP, [mod_role_data:get_role_name(State3), NewConfineConfig#c_confine.name]), ok),
    State4 = role_misc:create_goods(State3, ?ITEM_GAIN_CONFINE, RewardGoods),
    Log = mod_role_extra:get_confine_log(RoleConfine#r_role_confine.confine, NewConfineID, State4),
    mod_role_dict:add_background_logs(Log),
    after_do_confine_up(State4).

%%打完副本过来
do_confine_up(#r_role{role_confine = RoleConfine, role_id = RoleID, role_attr = RoleAttr} = State, MapID) ->
    [ConfineConfig] = lib_config:find(cfg_confine, RoleConfine#r_role_confine.confine),
    case ConfineConfig#c_confine.map_id =:= MapID of
        false ->
            State;
        _ ->
            {IsBc, NewConfineID} = get_confine_up(RoleConfine#r_role_confine.confine),
            [NewConfineConfig] = lib_config:find(cfg_confine, NewConfineID),
            case get_skill_or_book(NewConfineID, RoleAttr#r_role_attr.sex) of
                {skill, _SkillID, RewardGoods} ->
                    SendList = [#p_kv{id = TypeID, val = Num} || #p_goods{type_id = TypeID, num = Num} <- RewardGoods],
                    common_misc:unicast(State#r_role.role_id, #m_copy_success_toc{goods_list = SendList}),
                    ok;
                {book, RewardGoods} ->
                    SendList = [#p_kv{id = TypeID, val = Num} || #p_goods{type_id = TypeID, num = Num} <- RewardGoods],
                    common_misc:unicast(State#r_role.role_id, #m_copy_success_toc{goods_list = SendList})
            end,
            NewRoleConfine = RoleConfine#r_role_confine{confine = NewConfineID, confine_reward = [NewConfineID|RoleConfine#r_role_confine.confine_reward]},
            State4 = State#r_role{role_confine = NewRoleConfine},
            common_misc:unicast(RoleID, #m_confine_up_toc{confine = NewRoleConfine#r_role_confine.confine}),
            mod_map_role:update_role_confine(mod_role_dict:get_map_pid(), RoleID, NewRoleConfine#r_role_confine.confine),
            ?IF(IsBc, common_broadcast:send_world_common_notice(?NOTICE_CONFINE_UP, [mod_role_data:get_role_name(State4), NewConfineConfig#c_confine.name]), ok),
            Log = mod_role_extra:get_confine_log(RoleConfine#r_role_confine.confine, NewConfineID, State4),
            mod_role_dict:add_background_logs(Log),
            State4
    end.


%%
get_skill_or_book(Confine, Sex) ->
    [Config] = lib_config:find(cfg_confine, Confine),
    case Config#c_confine.skill_book =:= "" of
        true ->
            List = lib_tool:string_to_intlist(Config#c_confine.skill),
            {_, Skill} = lists:keyfind(Sex, 1, List),
            case Config#c_confine.map_id =:= 0 of
                true ->
                    GoodList = [];
                _ ->
                    List2 = lib_tool:string_to_intlist(Config#c_confine.skill_book_show),
                    {_, SkillBookShow} = lists:keyfind(Sex, 1, List2),
                    GoodList = [#p_goods{type_id = SkillBookShow, num = 1, bind = true}]
            end,
            {skill, Skill, GoodList};
        _ ->
            List = lib_tool:string_to_intlist(Config#c_confine.skill_book),
            {_, SkillBook} = lists:keyfind(Sex, 1, List),
            {book, [#p_goods{type_id = SkillBook, num = 1, bind = true}]}
    end.


%%渡劫后初始化任务
after_do_confine_up(#r_role{role_confine = Confine, role_id = RoleID} = State) ->
    NewList = get_mission_by_confine(State),
    CleanIDS = [Mission#p_confine_mission.mission_id || Mission <- Confine#r_role_confine.mission_list],
    common_misc:unicast(RoleID, #m_confine_mission_toc{del_mission = CleanIDS, add_mission = NewList}),
    NewConfine = Confine#r_role_confine{mission_list = NewList},
    State2 = State#r_role{role_confine = NewConfine},
    State3 = do_confine_trigger(Confine#r_role_confine.confine, State2),
    State4 = case check_mission_all_complete(NewList) of
                 true ->
                     [Config] = lib_config:find(cfg_confine, NewConfine#r_role_confine.confine),
                     case Config#c_confine.map_id =:= 0 of
                         false ->
                             State3;
                         _ ->
                             GoodsList = get_all_reward(NewList),
                             do_confine_up(State3, Config, GoodsList)
                     end;
                 _ ->
                     State3
             end,
    State4.

do_confine_trigger(ConfineID, State) ->
    FuncList = [
        fun(StateAcc) -> mod_role_mission:confine_trigger(StateAcc) end,
        fun(StateAcc) -> mod_role_achievement:confine_up(ConfineID, StateAcc) end,
        fun(StateAcc) -> mod_role_function:do_trigger_function(?FUNCTION_TYPE_CONFINE, ConfineID, StateAcc) end,
        fun(StateAcc) -> do_trigger(ConfineID, StateAcc) end
    ],
    role_server:execute_state_fun(FuncList, State).

do_trigger(ConfineID, State) ->
    ConfigList = lib_config:list(cfg_war_spirit_base),
    WarSpiritIDList =
        case ConfigList =/= [] of
            true ->
                lists:foldl(
                    fun({WarSpiritID, Config}, Acc) ->
                        #c_war_spirit_base{consume_goods = ConsumeGoodsString} = Config,
                        ?IF(ConsumeGoodsString =:= [], [WarSpiritID|Acc], Acc)
                    end, [], ConfigList);
            _ ->
                []
        end,
    do_trigger_confine(WarSpiritIDList, ConfineID, State).

do_trigger_confine([], _ConfineID, State) ->
    State;
do_trigger_confine([WarSpiritID|R], ConfineID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{role_id = RoleID, lock_info = LockInfo} = RoleConfine,
    [#c_war_spirit_base{armor_open_list = ArmorOpenList}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    IndexList = lists:seq(1, 10),
    List2 =
        case lists:keyfind(WarSpiritID, #p_war_armor_lock.war_spirit_id, LockInfo) of
            #p_war_armor_lock{list = List0} ->
                List0;
            _ ->
                []
        end,
    List = get_index_list1(IndexList, ArmorOpenList, ConfineID, []),
    LockInfo2 = lists:keystore(WarSpiritID, #p_war_armor_lock.war_spirit_id, LockInfo, #p_war_armor_lock{war_spirit_id = WarSpiritID, list = List}),
    LockInfo3 = [#p_war_armor_lock{war_spirit_id = WarSpiritID1,list = List1} ||  #p_war_armor_lock{war_spirit_id = WarSpiritID1, list = List1} <- LockInfo2, List1 =/=[]],
    case List2 =/= List  of
        true ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_lock_info_toc{armors = LockInfo3}),
            RoleConfine2 = RoleConfine#r_role_confine{lock_info = LockInfo2},
            State2 = State#r_role{role_confine = RoleConfine2},
            do_trigger_confine(R, ConfineID, State2);
        _ ->
            RoleConfine2 = RoleConfine#r_role_confine{lock_info = LockInfo2},
            State2 = State#r_role{role_confine = RoleConfine2},
            do_trigger_confine(R, ConfineID, State2)
    end.

get_index_list1([],_ArmorOpenList, _ConfineID, Acc) ->
    Acc;
get_index_list1([Index|R], ArmorOpenList, ConfineID, Acc) ->
    Acc2 =
        case ConfineID >= lists:nth(Index, ArmorOpenList) of
            true ->
                lists:keystore(Index, #p_war_armor_lock_info.index, Acc, #p_war_armor_lock_info{index = Index, is_open = true});
            _ ->
                Acc
        end,
    get_index_list1(R, ArmorOpenList, ConfineID, Acc2).


%%渡劫提升战灵
check_war_spirit_up_list(#r_role{role_id = RoleID, role_confine = RoleConfine} = State) ->
    {NewList, IsBc, ChangeSkill} = check_war_spirit_up_list(RoleConfine#r_role_confine.war_spirit_list, [], RoleConfine#r_role_confine.war_spirit, false, [], RoleConfine#r_role_confine.confine),
    NewRoleConfine = RoleConfine#r_role_confine{war_spirit_list = NewList},
    ?IF(IsBc, common_misc:unicast(RoleID, #m_war_spirit_change_toc{war_spirit = NewRoleConfine#r_role_confine.war_spirit, war_spirit_list = NewRoleConfine#r_role_confine.war_spirit_list}), ok),
    State2 = State#r_role{role_confine = NewRoleConfine},
    case ChangeSkill =:= [] of
        true ->%%装备战灵技能没变动
            State2;
        _ ->
            {OldSkills, NewSkillS} = ChangeSkill,
            skills_change(OldSkills, NewSkillS, State2)
    end.

check_war_spirit_up_list([], List, _, IsBc, ChangeSkill, _) ->
    {List, IsBc, ChangeSkill};
check_war_spirit_up_list([Info|T], List, NowWarSpirit, IsBc, ChangeSkill, Confine) ->
    [Config] = get_war_spirit(Info#p_war_spirit.id, Info#p_war_spirit.level),
    case Info#p_war_spirit.exp >= Config#c_war_spirit_up.exp of
        true ->
            {NewExp, NewLevel, NewSkill} = get_new_level_exp(Info#p_war_spirit.exp, Config, Config#c_war_spirit_up.skill, Confine),
            NewChangeSkill = ?IF(NewSkill =/= Config#c_war_spirit_up.skill andalso Info#p_war_spirit.id =:= NowWarSpirit, {NewSkill, Config#c_war_spirit_up.skill}, ChangeSkill),
            check_war_spirit_up_list(T, [Info#p_war_spirit{exp = NewExp, level = NewLevel}|List], NowWarSpirit, true, NewChangeSkill, Confine);
        _ ->
            check_war_spirit_up_list(T, [Info|List], NowWarSpirit, IsBc, ChangeSkill, Confine)
    end.

%%完成渡劫任务
do_confine_mission(MissionID, State, RoleID) ->
    case catch check_can_complete(MissionID, State) of
        {ok, State2, BagDoings, NewMission} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_confine_mission_toc{update_mission = [NewMission]}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_up_toc{err_code = ErrCode}),
            State
    end.

check_can_complete(MissionID, #r_role{role_confine = Confine} = State) ->
    case lists:keytake(MissionID, #p_confine_mission.mission_id, Confine#r_role_confine.mission_list) of
        {value, Mission, Other} ->
            [Config] = lib_config:find(cfg_confine_mission, MissionID),
            ?IF(Mission#p_confine_mission.status =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(1)),
            Rewards = lib_tool:string_to_intlist(Config#c_confine_mission.reward),
            GoodsList = [#p_goods{type_id = RID, num = RNum, bind = true} || {RID, RNum} <- Rewards],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
            BagDoings = [{create, ?ITEM_GAIN_CONFINE_MISSION, GoodsList}],
            NewMission = Mission#p_confine_mission{status = ?ACT_REWARD_GOT},
            NewConfine = Confine#r_role_confine{mission_list = [NewMission|Other]},
            {ok, State#r_role{role_confine = NewConfine}, BagDoings, NewMission};
        _ ->
            ?THROW_ERR(1)
    end.


do_confine_process_tree(RoleID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    {IsBc, NewConfineID} = get_confine_up(RoleConfine#r_role_confine.confine),
    [NewConfineConfig] = lib_config:find(cfg_confine, NewConfineID),
    NewRoleConfine = RoleConfine#r_role_confine{confine = NewConfineID, confine_reward = [NewConfineID|RoleConfine#r_role_confine.confine_reward]},
    State4 = State#r_role{role_confine = NewRoleConfine},
    common_misc:unicast(RoleID, #m_confine_up_toc{confine = NewRoleConfine#r_role_confine.confine}),
    mod_map_role:update_role_confine(mod_role_dict:get_map_pid(), RoleID, NewRoleConfine#r_role_confine.confine),
    ?IF(IsBc, common_broadcast:send_world_common_notice(?NOTICE_CONFINE_UP, [mod_role_data:get_role_name(State4), NewConfineConfig#c_confine.name]), ok),
    Log = mod_role_extra:get_confine_log(RoleConfine#r_role_confine.confine, NewConfineID, State4),
    mod_role_dict:add_background_logs(Log),
    State4.

do_confine_crossover(_RoleID, State) ->
    State2 = mod_role_discount_pay:trigger_condition(?DISCOUNT_CONDITION_BUY_CONFINE_CROSSOVER, State),
    mod_role_discount_pay:condition_update(State2).

%%开启战灵
open_war_spirit(#r_role{role_confine = RoleConfine, role_id = RoleID} = State, WarSpirit) ->
    case lists:keyfind(WarSpirit, #p_war_spirit.id, RoleConfine#r_role_confine.war_spirit_list) of
        false ->
            NewWarSpirit = #p_war_spirit{id = WarSpirit, level = 1, exp = 0},
            case RoleConfine#r_role_confine.war_spirit =:= 0 of
                true ->
                    [Config] = get_war_spirit(WarSpirit, 1),
                    State2 = skills_change([], Config#c_war_spirit_up.skill, State),
                    NewWarSpiritID = WarSpirit;
                _ ->
                    NewWarSpiritID = WarSpirit, State2 = State
            end,
            NewRoleConfine = RoleConfine#r_role_confine{war_spirit = NewWarSpiritID, war_spirit_list = [NewWarSpirit|RoleConfine#r_role_confine.war_spirit_list]},
            common_misc:unicast(RoleID, #m_war_spirit_change_toc{war_spirit = NewWarSpiritID, war_spirit_list = NewRoleConfine#r_role_confine.war_spirit_list}),
            State3 = State2#r_role{role_confine = NewRoleConfine},
            mod_role_bless:war_god(erlang:length(NewRoleConfine#r_role_confine.war_spirit_list), State3);
        _ ->
            State
    end.


%%拿战灵 通过ID与等级
get_war_spirit(WarSpirit, Level) ->
    lib_config:find(cfg_war_spirit_up, {WarSpirit, Level}).


%%  返回{大境界，小境界}
get_confine(Confine) ->
    {Confine div 100, Confine rem 100}.

get_confine_up(Confine) ->
    case lib_config:find(cfg_confine, Confine + 1) of
        [_Config] ->
            {false, Confine + 1};
        _ ->
            {true, (Confine div 100 + 1) * 100 + 1}
    end.

get_confine_down(Confine) ->
    Confine2 = Confine - 1,
    case lib_config:find(cfg_confine, Confine2) of
        [_Config] ->
            Confine2;
        _ ->
            {BigConfine, _} = get_confine(Confine2),
            Confine3 = compose_confine(BigConfine - 1, 1),
            get_confine_down_i(Confine3)
    end.

get_confine_down_i(Confine) ->
    case lib_config:find(cfg_confine, Confine + 1) of
        [_Config] ->
            get_confine_down_i(Confine + 1);
        _ ->
            Confine
    end.


get_confine_id(#r_role{role_confine = undefined}) ->
    0;
get_confine_id(#r_role{role_confine = #r_role_confine{confine = ConfineID}}) ->
    ConfineID.

%%  返回{大境界，小境界}
compose_confine(Confine, Stage) ->
    Confine * 100 + Stage.


%%触发完成任务
do_trigger_confine_mission(_Type, _Num1, _Num2, #r_role{role_confine = undefined} = State) ->
    State;
do_trigger_confine_mission(Type, Num1, Num2, #r_role{role_confine = Confine, role_id = RoleID} = State) ->
    {TriggerList, AllList} = check_mission(Type, Num1, Num2, Confine#r_role_confine.mission_list),
    NewConfine = Confine#r_role_confine{mission_list = AllList},
    State2 = State#r_role{role_confine = NewConfine},
    case TriggerList of
        [] ->
            State2;
        _ ->
            case check_mission_all_complete(AllList) of
                true ->
                    case lib_config:find(cfg_confine, Confine#r_role_confine.confine) of
                        [] ->
                            GoodsList = get_all_reward(AllList),
                            ConfineConfig = #c_confine{item = 0},
                            do_confine_up(State2, ConfineConfig, GoodsList);
                        [Config] ->
                            case Config#c_confine.map_id =:= 0 of
                                false ->
                                    common_misc:unicast(RoleID, #m_confine_mission_toc{update_mission = TriggerList}),
                                    State2;
                                _ ->
                                    GoodsList = get_all_reward(AllList),
                                    do_confine_up(State2, Config, GoodsList)
                            end
                    end;
                _ ->
                    common_misc:unicast(RoleID, #m_confine_mission_toc{update_mission = TriggerList}),
                    State2
            end
    end.

check_mission_all_complete(AllList) ->
    lists:all(
        fun(Mission) ->
            Mission#p_confine_mission.status =/= ?ACT_REWARD_CANNOT_GET
        end, AllList).


get_all_reward(AllList) ->
    lists:foldl(
        fun(Mission, GoodsList) ->
            case Mission#p_confine_mission.status =:= ?ACT_REWARD_CAN_GET of
                true ->
                    [Config] = lib_config:find(cfg_confine_mission, Mission#p_confine_mission.mission_id),
                    Rewards = lib_tool:string_to_intlist(Config#c_confine_mission.reward),
                    GoodsList2 = [#p_goods{type_id = RID, num = RNum, bind = true} || {RID, RNum} <- Rewards],
                    GoodsList2 ++ GoodsList;
                _ ->
                    GoodsList
            end
        end, [], AllList).




check_mission(Type, Num1, Num2, List) ->
    lists:foldl(fun(Mission, {TriggerList, AllList}) ->
        case Mission#p_confine_mission.status =:= ?ACT_REWARD_CANNOT_GET of
            true ->
                case lib_config:find(cfg_confine_mission, Mission#p_confine_mission.mission_id) of
                    [#c_confine_mission{complete_type = Type} = Config] ->
                        case Config#c_confine_mission.complete_param of
                            [Param] ->
                                NewMission = case Config#c_confine_mission.acc_type of
                                                 ?CONFINE_ACC_TYPE ->
                                                     case Num1 + Mission#p_confine_mission.times >= Param of
                                                         true ->
                                                             NewTimes = Param, NewStatus = ?ACT_REWARD_CAN_GET;
                                                         _ ->
                                                             NewTimes = Num1 + Mission#p_confine_mission.times,
                                                             NewStatus = ?ACT_REWARD_CANNOT_GET
                                                     end,
                                                     Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                 ?CONFINE_REVERSE_MAX_TYPE ->
                                                     case Num1 =< Param andalso Num1 =/= 0 of
                                                         true ->
                                                             NewTimes = Param, NewStatus = ?ACT_REWARD_CAN_GET;
                                                         _ ->
                                                             NewTimes = Num1,
                                                             NewStatus = ?ACT_REWARD_CANNOT_GET
                                                     end,
                                                     Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                 ?CONFINE_MAX_TYPE ->
                                                     case Num1 >= Param of
                                                         true ->
                                                             NewTimes = Param, NewStatus = ?ACT_REWARD_CAN_GET;
                                                         _ ->
                                                             NewTimes = Num1, NewStatus = ?ACT_REWARD_CANNOT_GET
                                                     end,
                                                     Mission#p_confine_mission{times = NewTimes, status = NewStatus}
                                             end,
                                {[NewMission|TriggerList], [NewMission|AllList]};
                            [Param1, Param2] ->
                                if
                                    Num2 >= Param2 ->
                                        NewMission = case Config#c_confine_mission.acc_type of
                                                         ?CONFINE_ACC_TYPE ->
                                                             case Param2 =:= Num2 of
                                                                 true ->
                                                                     case Num1 + Mission#p_confine_mission.times >= Param1 of
                                                                         true ->
                                                                             NewTimes = Param1,
                                                                             NewStatus = ?ACT_REWARD_CAN_GET;
                                                                         _ ->
                                                                             NewTimes = Num1 + Mission#p_confine_mission.times,
                                                                             NewStatus = ?ACT_REWARD_CANNOT_GET
                                                                     end,
                                                                     Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                                 _ ->
                                                                     Mission
                                                             end;
                                                         ?CONFINE_ACC_TYPE_I ->
                                                             case Num1 + Mission#p_confine_mission.times >= Param1 of
                                                                 true ->
                                                                     NewTimes = Param1, NewStatus = ?ACT_REWARD_CAN_GET;
                                                                 _ ->
                                                                     NewTimes = Num1 + Mission#p_confine_mission.times,
                                                                     NewStatus = ?ACT_REWARD_CANNOT_GET
                                                             end,
                                                             Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                         ?CONFINE_MAX_TYPE_I ->
                                                             case Num1 >= Param1 of
                                                                 true ->
                                                                     NewTimes = Param1,
                                                                     NewStatus = ?ACT_REWARD_CAN_GET;
                                                                 _ ->
                                                                     NewTimes = erlang:max(Num1, Mission#p_confine_mission.times),
                                                                     NewStatus = ?ACT_REWARD_CANNOT_GET
                                                             end,
                                                             Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                         ?CONFINE_MAX_TYPE ->
                                                             case Param2 =:= Num2 of
                                                                 true ->
                                                                     case Num1 >= Param1 of
                                                                         true ->
                                                                             NewTimes = Param1,
                                                                             NewStatus = ?ACT_REWARD_CAN_GET;
                                                                         _ ->
                                                                             NewTimes = erlang:max(Num1, Mission#p_confine_mission.times),
                                                                             NewStatus = ?ACT_REWARD_CANNOT_GET
                                                                     end,
                                                                     Mission#p_confine_mission{times = NewTimes, status = NewStatus};
                                                                 _ ->
                                                                     Mission
                                                             end
                                                     end,
                                        {[NewMission|TriggerList], [NewMission|AllList]};
                                    Type =:= ?CONFINE_COMPLETE_BOSS ->
                                        case Num1 >= Param1 of
                                            false ->
                                                {TriggerList, [Mission|AllList]};
                                            _ ->
                                                case Num2 + Mission#p_confine_mission.times >= Param2 of
                                                    true ->
                                                        NewTimes = Param2, NewStatus = ?ACT_REWARD_CAN_GET;
                                                    _ ->
                                                        NewTimes = Num2 + Mission#p_confine_mission.times,
                                                        NewStatus = ?ACT_REWARD_CANNOT_GET
                                                end,
                                                NewMission = Mission#p_confine_mission{times = NewTimes, status = NewStatus},
                                                {[NewMission|TriggerList], [NewMission|AllList]}
                                        end;
                                    true ->
                                        {TriggerList, [Mission|AllList]}
                                end
                        end;
                    _ ->
                        {TriggerList, [Mission|AllList]}
                end;
            _ ->
                {TriggerList, [Mission|AllList]}
        end
                end, {[], []}, List).

%%检查新建任务进度
get_confine_mission_params(State, #c_confine_mission{check_type = CheckType} = Config) ->
    case CheckType =:= ?CONFINE_CHECK_WHEN_NEW of
        false ->
            {0, ?ACT_REWARD_CANNOT_GET};
        _ ->
            case get_confine_mission_params_i(State, Config) of
                false ->
                    {0, ?ACT_REWARD_CANNOT_GET};
                [Num1, Num2] ->
                    [Param1, Param2] = Config#c_confine_mission.complete_param,
                    if
                        Num2 >= Param2 ->
                            case Config#c_confine_mission.acc_type of
                                ?CONFINE_ACC_TYPE ->
                                    case Param2 =:= Num2 of
                                        true ->
                                            case Num1 >= Param1 of
                                                true ->
                                                    {Param1, ?ACT_REWARD_CAN_GET};
                                                _ ->
                                                    {Num1, ?ACT_REWARD_CANNOT_GET}
                                            end;
                                        _ ->
                                            {0, ?ACT_REWARD_CANNOT_GET}
                                    end;
                                ?CONFINE_ACC_TYPE_I ->
                                    case Num1 >= Param1 of
                                        true ->
                                            {Param1, ?ACT_REWARD_CAN_GET};
                                        _ ->
                                            {Num1, ?ACT_REWARD_CANNOT_GET}
                                    end;
                                ?CONFINE_MAX_TYPE_I ->
                                    case Num1 >= Param1 of
                                        true ->
                                            {Param1, ?ACT_REWARD_CAN_GET};
                                        _ ->
                                            {Num1, ?ACT_REWARD_CANNOT_GET}
                                    end;
                                ?CONFINE_MAX_TYPE ->
                                    case Param2 =:= Num2 of
                                        true ->
                                            case Num1 >= Param1 of
                                                true ->
                                                    {Param1, ?ACT_REWARD_CAN_GET};
                                                _ ->
                                                    {Num1, ?ACT_REWARD_CANNOT_GET}
                                            end;
                                        _ ->
                                            {0, ?ACT_REWARD_CANNOT_GET}
                                    end
                            end;
                        true ->
                            {0, ?ACT_REWARD_CANNOT_GET}
                    end;
                Num1 ->
                    Param = case Config#c_confine_mission.complete_param of
                                [Num2] ->
                                    Num2;
                                [Num2, _] ->
                                    Num2
                            end,
                    case Config#c_confine_mission.acc_type of
                        ?CONFINE_REVERSE_MAX_TYPE ->
                            case Num1 =< Param andalso Num1 =/= 0 of
                                true ->
                                    {Param, ?ACT_REWARD_CAN_GET};
                                _ ->
                                    {Num1, ?ACT_REWARD_CANNOT_GET}
                            end;
                        _ ->
                            case Num1 >= Param of
                                true ->
                                    {Param, ?ACT_REWARD_CAN_GET};
                                _ ->
                                    {Num1, ?ACT_REWARD_CANNOT_GET}
                            end
                    end
            end
    end.


%%境界拿任务
get_mission_by_confine(#r_role{role_confine = RoleConfine} = State) ->
    case RoleConfine of
        #r_role_confine{confine = Confine} ->
            AllList = cfg_confine_mission:list(),
            [
                begin
                    {Times, Status} = get_confine_mission_params(State, Mission),
                    #p_confine_mission{mission_id = Mission#c_confine_mission.id, status = Status, times = Times}
                end
                || {_, Mission} <- AllList, Mission#c_confine_mission.confine =:= Confine];
        _ ->
            []
    end.




gm_set_confine(State, Confine, Step) ->
    ConfineID = compose_confine(Confine, Step),
    ConfineID2 = ?IF(3505 >= ConfineID, ConfineID, 2905),
    CreateList = [#p_goods{type_id = ?CONFINE_UP_ITEM_THREE, num = 300, bind = false}],
    State2 = role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList),
    gm_set_confine_i(State2, ConfineID2).

gm_set_confine_i(#r_role{role_confine = RoleConfine} = State, ConfineID) ->
    case RoleConfine#r_role_confine.confine >= ConfineID of
        true ->
            State;
        _ ->
            State2 = gm_up_confine(State),
            gm_set_confine_i(State2, ConfineID)
    end.

gm_up_confine(#r_role{role_confine = RoleConfine, role_id = RoleID} = State) ->
    [Config] = lib_config:find(cfg_confine, RoleConfine#r_role_confine.confine),
    case Config#c_confine.item > 0 of
        true ->
            CreateList = [#p_goods{type_id = ?CONFINE_UP_ITEM_THREE, num = Config#c_confine.item, bind = false}],
            State2 = role_misc:create_goods(State, ?ITEM_GAIN_GM, CreateList);
        _ ->
            State2 = State
    end,
    State3 = do_confine_up(#r_role{role_confine = RoleConfine, role_id = RoleID} = State2, Config, []),
    do_confine_calc(State3).

gm_war_spirit(State, WarSpirit) ->
    State2 = open_war_spirit(State, WarSpirit),
    [Config] = get_war_spirit(WarSpirit, 1),
    skills_change([], Config#c_war_spirit_up.skill, State2).

gm_add_mission(#r_role{role_id = RoleID, role_confine = RoleConfine} = State, ID) ->
    [Config] = lib_config:find(cfg_confine_mission, ID),
    {Times, Status} = get_confine_mission_params(State, Config),
    NewList = [#p_confine_mission{mission_id = ID, times = Times, status = Status}],
    common_misc:unicast(RoleID, #m_confine_mission_toc{add_mission = NewList}),
    NewList2 = NewList ++ RoleConfine#r_role_confine.mission_list,
    NewRoleConfine = RoleConfine#r_role_confine{mission_list = NewList2},
    State#r_role{role_confine = NewRoleConfine}.

gm_set_mission(#r_role{role_confine = RoleConfine} = State) ->
    NewList2 = [Mission#p_confine_mission{status = ?ACT_REWARD_GOT} || Mission <- RoleConfine#r_role_confine.mission_list],
    NewRoleConfine = RoleConfine#r_role_confine{mission_list = NewList2},
    State2 = State#r_role{role_confine = NewRoleConfine},
    online(State2).

gm_add_war_spirit_refine_exp(AddRefineExp, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{refine_all_exp = RefineAllExp} = RoleConfine,
    RefineAllExp2 = RefineAllExp + AddRefineExp,
    RoleConfine2 = RoleConfine#r_role_confine{refine_all_exp = RefineAllExp2},
    State2 = State#r_role{role_confine = RoleConfine2},
    online(State2).

%%
get_confine_mission_params_i(State, #c_confine_mission{complete_param = CompleteParam, complete_type = Type}) ->
    case Type of
        ?CONFINE_COMPLETE_GOD_WEAPON ->
            RoleGodWeapon = State#r_role.role_god_weapon,
            RoleGodWeapon#r_role_god_weapon.level;
        ?CONFINE_COMPLETE_MAGIC_WEAPON ->
            RoleMagicWeapon = State#r_role.role_magic_weapon,
            RoleMagicWeapon#r_role_magic_weapon.level;
        ?CONFINE_COMPLETE_WING ->
            RoleWing = State#r_role.role_wing,
            RoleWing#r_role_wing.level;
        ?CONFINE_COMPLETE_MOUNT ->
            mod_role_mount:get_mount_step(State);
        ?CONFINE_COMPLETE_PET ->
            mod_role_pet:get_pet_step(State);
        ?CONFINE_COMPLETE_EQUIP_REFINE ->
            mod_role_equip:get_all_refine_level(State);
        ?CONFINE_COMPLETE_EQUIP_STONE1 ->
            mod_role_equip:get_stone_level_by_type(?STONE_AT, State);
        ?CONFINE_COMPLETE_EQUIP_STONE2 ->
            mod_role_equip:get_stone_level_by_type(?STONE_HP, State);
        ?CONFINE_COMPLETE_ZHUXIAN ->
            #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
            List = mod_role_equip:get_suit_list(EquipList),
            case lists:keyfind(?EQUIP_SUIT_LEVEL_IMMORTAL, 2, List) of
                false ->
                    0;
                Num ->
                    Num
            end;
        ?CONFINE_COMPLETE_ZHUSHENG ->
            #r_role{role_equip = #r_role_equip{equip_list = EquipList}} = State,
            List = mod_role_equip:get_suit_list(EquipList),
            case lists:keyfind(?EQUIP_SUIT_LEVEL_GOD, 2, List) of
                false ->
                    0;
                Num ->
                    Num
            end;
        ?CONFINE_COMPLETE_PAGODA ->
            RoleCopy = State#r_role.role_copy,
            ?GET_TOWER_FLOOR(RoleCopy#r_role_copy.tower_id);
        ?CONFINE_COMPLETE_RUNE_LEVEL ->
            RoleRune = State#r_role.role_rune,
            mod_role_rune:get_all_level(RoleRune#r_role_rune.load_runes);
        ?CONFINE_COMPLETE_RUNE ->
            [_, Param] = CompleteParam,
            RoleRune = State#r_role.role_rune,
            mod_role_rune:get_the_quality_num(RoleRune#r_role_rune.load_runes, Param);
        ?CONFINE_COMPLETE_OFFLINE_SOLO_RANK ->
            case world_offline_solo_server:get_offline_solo(State#r_role.role_id) of
                [#r_role_offline_solo{rank = MyRank}] ->
                    MyRank;
                _ ->
                    0
            end;
        ?CONFINE_COMPLETE_SOLE ->
            #r_role_solo{score = Score} = mod_solo:get_role_solo(State#r_role.role_id),
            mod_solo:get_step_by_score(Score);
        ?CONFINE_COMPLETE_LEVEL ->
            State#r_role.role_attr#r_role_attr.level;
        ?CONFINE_COMPLETE_POWER ->
            State#r_role.role_attr#r_role_attr.power;
        ?CONFINE_COMPLETE_LEARN_SKILL ->
            get_role_skill_num(State);
%%        ?CONFINE_COMPLETE_FRIEND ->
%%            mod_role_friend:get_friend_num(State);
%%        ?CONFINE_COMPLETE_PET_I ->
%%            #r_role{role_pet = RolePet} = State,
%%            #r_role_pet{level = Level} = RolePet,
%%            Level;
        ?CONFINE_COMPLETE_EQUIP_ONE ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_ONE, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_TWO ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_TWO, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_THREE ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_THREE, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_FOUR ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_FOUR, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_FIVE ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_FIVE, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_SIX ->
            check_equip_mission_init_param(?CONFINE_COMPLETE_EQUIP_SIX, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_SEVEN ->
            check_suit_mission_init_param(?CONFINE_COMPLETE_EQUIP_SEVEN, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_EIGHT ->
            check_suit_mission_init_param(?CONFINE_COMPLETE_EQUIP_EIGHT, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_NINE ->
            check_suit_mission_init_param(?CONFINE_COMPLETE_EQUIP_NINE, State, CompleteParam);
        ?CONFINE_COMPLETE_EQUIP_TEM ->
            check_suit_mission_init_param(?CONFINE_COMPLETE_EQUIP_TEM, State, CompleteParam);
        ?CONFINE_COMPLETE_MAIN_MISSION ->
            [MissionParam|_] = CompleteParam,
            mod_role_mission:is_main_mission_finish(MissionParam, State);
        ?CONFINE_COMPLETE_IMMORTAL_SOUL_O ->
            [_, Color|_] = CompleteParam,
            Num = mod_role_immortal_soul:get_color_num(Color, State#r_role.role_immortal_soul#r_role_immortal_soul.use_list),
            [Num, Color];
        ?CONFINE_COMPLETE_IMMORTAL_SOUL_R ->
            [_, Color|_] = CompleteParam,
            Num = mod_role_immortal_soul:get_color_num(Color, State#r_role.role_immortal_soul#r_role_immortal_soul.use_list),
            [Num, Color];
        ?CONFINE_COMPLETE_EQUIP_STONE_LEVEL ->
            [_, NeedLevel|_] = CompleteParam,
            Num = mod_role_equip:get_level_num(NeedLevel, State#r_role.role_immortal_soul#r_role_immortal_soul.use_list),
            {Num, NeedLevel};
        ?CONFINE_COMPLETE_YARD ->
            mod_role_copy:get_copy_finish_times(?COPY_EXP, State);
        ?CONFINE_COMPLETE_RUINS ->
            mod_role_copy:get_copy_finish_times(?COPY_SINGLE_TD, State);
        ?CONFINE_COMPLETE_VAULT ->
            mod_role_copy:get_copy_finish_times(?COPY_SILVER, State);
        ?CONFINE_COMPLETE_FOREST ->
            mod_role_copy:get_copy_finish_times(?COPY_IMMORTAL, State);
        ?CONFINE_COMPLETE_EQUIP_COPY ->
            mod_role_copy:get_copy_finish_times(?COPY_EQUIP, State);
        ?CONFINE_FIVE_ELEMENTS ->
            [_, CopyID|_] = CompleteParam,
            #r_role{role_copy = RoleCopy} = State,
            ?IF(RoleCopy#r_role_copy.cur_five_elements >= CopyID, [1, CopyID], [0, CopyID]);
        ?CONFINE_COMPLETE_OFFLINE_SOLO ->
            case world_offline_solo_server:get_offline_solo(State#r_role.role_id) of
                [#r_role_offline_solo{challenge_times = Times, buy_times = BuyTimes}] ->
                    ?DEFAULT_CHALLENGE_TIMES - Times + BuyTimes;
                _ ->
                    0
            end;
        _ ->
            false
    end.

get_role_skill_num(State) ->
    #r_role{role_skill = RoleSkill} = State,
    #r_role_skill{attack_list = AttackList, passive_list = PassiveList} = RoleSkill,
    SkillList = AttackList ++ lists:flatten([PassiveSkillIDList || #p_kvl{list = PassiveSkillIDList} <- PassiveList]),
    erlang:length([SkillID || #p_skill{skill_id = SkillID} <- SkillList, ?GET_SKILL_FUN(SkillID) =:= ?SKILL_FUN_ROLE]).


check_suit_mission_init_param(MissionType, State, CompleteParam) ->
    [_, Param] = CompleteParam,
    case MissionType of
        ?CONFINE_COMPLETE_EQUIP_SEVEN ->
            SubType = 1, Type = 1;
        ?CONFINE_COMPLETE_EQUIP_EIGHT ->
            SubType = 1, Type = 2;
        ?CONFINE_COMPLETE_EQUIP_NINE ->
            SubType = 2, Type = 1;
        ?CONFINE_COMPLETE_EQUIP_TEM ->
            SubType = 2, Type = 2
    end,
    #r_role{role_suit = RoleSuit} = State,
    #r_role_suit{suit_list = SuitList} = RoleSuit,
    #p_suit{place = List} = mod_role_suit:integration_suit(Type, SubType, SuitList),
    AllNum = lists:foldl(
        fun(PlaceID, AccNum) ->
            case lib_config:find(cfg_suit_star, PlaceID) of
                [#c_suit_star{gradation = Gradation}] when Gradation >= Param ->
                    AccNum + 1;
                _ ->
                    AccNum
            end
        end, 0, List),
    [AllNum, Param].


check_equip_mission_init_param(Type, State, CompleteParam) ->
    #r_role{role_equip = RoleEquip} = State,
    #r_role_equip{equip_list = EquipList} = RoleEquip,
    [_, Param] = CompleteParam,
    {MissionQuality, MissionStar, _} = lists:keyfind(Type, 3, ?CONFINE_COMPLETE_EQUIP_LIST),
    AllNum = lists:foldl(
        fun(#p_equip{equip_id = EquipID}, AccNum) ->
            [#c_equip{quality = Quality, star = Star, step = Step}] = lib_config:find(cfg_equip, EquipID),
            if
                Step > Param -> AccNum + 1;
                Step =:= Param ->
                    if
                        Quality > MissionQuality -> AccNum + 1;
                        Quality =:= MissionQuality -> ?IF(Star >= MissionStar, AccNum + 1, AccNum);
                        true ->
                            AccNum
                    end;
                true ->
                    AccNum

            end
        end, 0, EquipList),
    [AllNum, Param].


%%%===================================================================
%%% 战灵装备相关
%%%===================================================================
add_equips([], State) ->
    State;
add_equips(_TypeIDs, #r_role{role_confine = undefined} = State) ->
    State;
add_equips(TypeIDs, State) ->
    #r_role{role_id = RoleID, role_confine = RoleConfine} = State,
    #r_role_confine{bag_id = BagID, bag_list = BagList} = RoleConfine,
    {BagID2, Equips} =
    lists:foldl(
        fun(TypeID, {IndexAcc, EquipsAcc}) ->
            EquipT = #p_war_spirit_equip{
                id = IndexAcc,
                type_id = TypeID,
                excellent_list = get_equip_excellent(TypeID)
            },
            {IndexAcc + 1, [EquipT|EquipsAcc]}
        end, {BagID, []}, TypeIDs),
    RoleConfine2 = RoleConfine#r_role_confine{bag_id = BagID2, bag_list = Equips ++ BagList},
    State2 = State#r_role{role_confine = RoleConfine2},
    notify_add_equips(RoleID, Equips),
    Log = [get_equip_add_log(Equip, State2) || Equip <- Equips],
    mod_role_dict:add_background_logs(Log),
    State2.

get_equip_excellent(TypeID) ->
    [#c_war_spirit_equip_info{
        blue_props_num = BlueProsNum,
        blue_prop_id = BluePropID,
        purple_props_num = PurplePropsNum,
        purple_prop_id = PurplePropsID,
        high_purple_props_num = HighPurplePropsNum,
        high_purple_prop_id = HighPurplePropsID
    }] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    get_equip_excellent2([{BluePropID, BlueProsNum}, {PurplePropsID, PurplePropsNum}, {HighPurplePropsID, HighPurplePropsNum}], [], []).

get_equip_excellent2([], _HasProps, ExcellentAcc) ->
    ExcellentAcc;
get_equip_excellent2([{PropID, PropsNum}|R], HasPropsAcc, ExcellentAcc) ->
    case PropsNum > 0 of
        true ->
            [#c_war_spirit_equip_excellent{
                add_defence = Props1,
                add_hp = Props2,
                add_attack = Props3,
                add_arp = Props4,
                add_hit_rate = Props5,
                add_miss = Props6,
                add_double = Props7,
                add_double_anti = Props8,
                add_defence_rate = Props9,
                add_hp_rate = Props10,
                add_attack_rate = Props11,
                add_arp_rate = Props12,
                add_hit_rate_rate = Props13,
                add_miss_rate = Props14,
                add_double_rate = Props15,
                add_double_anti_rate = Props16
            }] = lib_config:find(cfg_war_spirit_equip_excellent, PropID),
            List = [{1, Props1}, {2, Props2}, {3, Props3}, {4, Props4}, {5, Props5}, {6, Props6}, {7, Props7},
                    {8, Props8}, {9, Props9}, {10, Props10}, {11, Props11}, {12, Props12}, {13, Props13}, {14, Props14},
                    {15, Props15}, {16, Props16}],
            List2 = filter_has_list(List, HasPropsAcc, []),
            WeightList = lib_tool:get_list_by_weight(PropsNum, List2),
            {HasProps, ExcellentList} =
            lists:foldl(
                fun({Index, Key, Val, Score}, {Acc1, Acc2}) ->
                    {[Index|Acc1], [#p_kvt{id = Key, val = Val, type = Score}|Acc2]}
                end, {[], []}, WeightList),
            get_equip_excellent2(R, HasProps ++ HasPropsAcc, ExcellentList ++ ExcellentAcc);
        _ ->
            get_equip_excellent2(R, HasPropsAcc, ExcellentAcc)
    end.

filter_has_list([], _HasProps, PropsAcc) ->
    PropsAcc;
filter_has_list(PropsList, [], PropsAcc) ->
    PropsList2 = [{Weight, {Index, Key, Value, Score}} || {Index, [Weight, Key, Value, Score]} <- PropsList],
    PropsAcc ++ PropsList2;
filter_has_list([{Index, Prop}|R], HasProps, PropsAcc) ->
    case lists:member(Index, HasProps) of
        true ->
            HasProps2 = lists:delete(Index, HasProps),
            filter_has_list(R, HasProps2, PropsAcc);
        _ ->
            PropsAcc2 =
            case Prop of
                [Weight, Key, Value, Score] ->
                    [{Weight, {Index, Key, Value, Score}}|PropsAcc];
                _ ->
                    PropsAcc
            end,
            filter_has_list(R, HasProps, PropsAcc2)
    end.

%% 升阶时替换属性
get_step_excellent(TypeID, ExcellentList) ->
    [#c_war_spirit_equip_info{
        blue_props_num = BlueProsNum,
        blue_prop_id = BluePropID,
        purple_props_num = PurplePropsNum,
        purple_prop_id = PurplePropsID,
        high_purple_props_num = HighPurplePropsNum,
        high_purple_prop_id = HighPurplePropsID
    }] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    PropList = lists:duplicate(BlueProsNum, BluePropID) ++ lists:duplicate(PurplePropsNum, PurplePropsID) ++
                                                           lists:duplicate(HighPurplePropsNum, HighPurplePropsID),
    get_step_excellent2(PropList, lists:reverse(ExcellentList), []).

get_step_excellent2([], _ExcellentList, Acc) ->
    Acc;
get_step_excellent2(_PropID, [], Acc) ->
    Acc;
get_step_excellent2([PropID|R1], [Excellent|R2], Acc) ->
    #p_kvt{id = PropKey} = Excellent,
    [#c_war_spirit_equip_excellent{
        add_defence = Props1,
        add_hp = Props2,
        add_attack = Props3,
        add_arp = Props4,
        add_hit_rate = Props5,
        add_miss = Props6,
        add_double = Props7,
        add_double_anti = Props8,
        add_defence_rate = Props9,
        add_hp_rate = Props10,
        add_attack_rate = Props11,
        add_arp_rate = Props12,
        add_hit_rate_rate = Props13,
        add_miss_rate = Props14,
        add_double_rate = Props15,
        add_double_anti_rate = Props16
    }] = lib_config:find(cfg_war_spirit_equip_excellent, PropID),
    List = [Props1, Props2, Props3, Props4, Props5, Props6, Props7, Props8, Props9, Props10, Props11
        ,   Props12, Props13, Props14, Props15, Props16],
    {Value, Score} = get_step_excellent3(PropKey, List),
    get_step_excellent2(R1, R2, [#p_kvt{id = PropKey, val = Value, type = Score}|Acc]).

get_step_excellent3(_PropKey, []) ->
    false;
get_step_excellent3(PropKey, [[_Weight, Key, Value, Score]|R]) ->
    case PropKey =:= Key of
        true ->
            {Value, Score};
        _ ->
            get_step_excellent3(PropKey, R)
    end.


%% 穿戴装备
do_equip_load(RoleID, WarSpiritID, EquipID, State) ->
    case catch check_equip_load(WarSpiritID, EquipID, State) of
        {ok, AddList, WarSpirit2, EquipTypeID, Log, State2} ->
            mod_role_dict:add_background_logs(Log),
            DataRecord = #m_war_spirit_equip_load_toc{war_spirit = WarSpirit2},
            common_misc:unicast(RoleID, DataRecord),
            notify_del_equips(RoleID, [EquipID]),
            notify_add_equips(RoleID, AddList),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WAR_SPIRIT_EQUIP_LOAD, EquipTypeID),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:war_spirit_equip(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_load_toc{err_code = ErrCode}),
            State
    end.

check_equip_load(WarSpiritID, EquipID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList, bag_list = BagList} = RoleConfine,
    {Equip, BagList2} =
    case lists:keytake(EquipID, #p_war_spirit_equip.id, BagList) of
        {value, EquipT, BagListT} ->
            {EquipT, BagListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_LOAD_001)
    end,
    #p_war_spirit_equip{type_id = TypeID} = Equip,
    [#c_war_spirit_equip_info{index = Index, star = Star, quality = Quality}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    ?IF(Index > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {WarSpirit, BagList3, AddList, ReplaceEquipID, ReplaceTypeID} =
    case lists:keyfind(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        #p_war_spirit{equip_list = EquipListT} = WarSpiritT ->
            case check_same_type(Index, EquipListT, []) of
                {#p_war_spirit_equip{id = ReplaceEquipIDT, type_id = ReplaceTypeIDT} = ReplaceEquip, EquipListT2} ->
                    {WarSpiritT#p_war_spirit{equip_list = EquipListT2}, [ReplaceEquip|BagList2], [ReplaceEquip], ReplaceEquipIDT, ReplaceTypeIDT};
                _ ->
                    {WarSpiritT, BagList2, [], 0, 0}
            end;
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_LOAD_002)
    end,
    #p_war_spirit{equip_list = EquipList, level = Level} = WarSpirit,
%%    [#c_war_spirit_base{equip_quality_limit = LimitQuality}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    [#c_war_spirit_base{equip_quality_limit_string = LimitQualityString}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    LimitQualityList1 = lib_tool:string_to_intlist(LimitQualityString),
    LimitList = [{LimitQuality0, LimitStar0} || {Level0, LimitQuality0, LimitStar0} <- LimitQualityList1, Level >= Level0],
    LimitList2 = lists:last(LimitList),
    ?IF(Quality < erlang:element(1,LimitList2) orelse (Quality =:= erlang:element(1,LimitList2) andalso Star =< erlang:element(2,LimitList2)), ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_LOAD_003)),
    EquipList2 = [Equip|EquipList],
    WarSpirit2 = WarSpirit#p_war_spirit{equip_list = EquipList2},
    WarSpiritList2 = lists:keystore(WarSpiritID, #p_war_spirit.id, WarSpiritList, WarSpirit2),
    RoleConfine2 = RoleConfine#r_role_confine{war_spirit_list = WarSpiritList2, bag_list = BagList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    Log = get_replace_log(WarSpiritID, EquipID, TypeID, ReplaceEquipID, ReplaceTypeID, State2),
    {ok, AddList, WarSpirit2, TypeID, Log, State2}.

check_same_type(_Index, [], _Acc) ->
    ok;
check_same_type(Index, [Equip|R], Acc) ->
    #p_war_spirit_equip{type_id = TypeID} = Equip,
    [#c_war_spirit_equip_info{index = DestIndex}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    ?IF(Index =:= DestIndex, {Equip, R ++ Acc}, check_same_type(Index, R, [Equip|Acc])).

%% 卸载装备
do_equip_unload(RoleID, WarSpiritID, EquipID, State) ->
    case catch check_equip_unload(WarSpiritID, EquipID, State) of
        {ok, UnloadList, WarSpirit, Logs, State2} ->
            mod_role_dict:add_background_logs(Logs),
            DataRecord = #m_war_spirit_equip_unload_toc{war_spirit = WarSpirit},
            common_misc:unicast(RoleID, DataRecord),
            notify_add_equips(RoleID, UnloadList),
            mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WAR_SPIRIT_EQUIP_UNLOAD, EquipID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_load_toc{err_code = ErrCode}),
            State
    end.

check_equip_unload(WarSpiritID, EquipID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList, bag_list = BagList} = RoleConfine,
    {UnloadList, WarSpirit} =
    case lists:keyfind(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        #p_war_spirit{equip_list = EquipListT} = WarSpiritT ->
            {UnloadListT, EquipListT3} =
            case EquipID of
                0 ->
                    {EquipListT, []};
                _ ->
                    case lists:keytake(EquipID, #p_war_spirit_equip.id, EquipListT) of
                        {value, Equip, EquipListT2} ->
                            {[Equip], EquipListT2};
                        _ ->
                            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_UNLOAD_001)
                    end
            end,
            ?IF(is_bag_full2(erlang:length(UnloadListT), erlang:length(BagList)), ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_UNLOAD_002), ok),
            WarSpiritT2 = WarSpiritT#p_war_spirit{equip_list = EquipListT3},
            {UnloadListT, WarSpiritT2};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_UNLOAD_002)
    end,
    WarSpiritList2 = lists:keystore(WarSpiritID, #p_war_spirit.id, WarSpiritList, WarSpirit),
    BagList2 = UnloadList ++ BagList,
    RoleConfine2 = RoleConfine#r_role_confine{war_spirit_list = WarSpiritList2, bag_list = BagList2},
    State2 = State#r_role{role_confine = RoleConfine2},
    Logs = [get_replace_log(WarSpiritID, 0, 0, ReplaceEquipID, ReplaceTypeID, State2) || #p_war_spirit_equip{id = ReplaceEquipID, type_id = ReplaceTypeID} <- UnloadList],
    {ok, UnloadList, WarSpirit, Logs, State2}.

do_equip_decompose(RoleID, EquipIDList, State) ->
    case catch check_equip_decompose(EquipIDList, State) of
        {ok, DelIDList, RefineAllExp2, Log, BagDoings, State2} ->
            notify_del_equips(RoleID, DelIDList),
            State3 = mod_role_bag:do(BagDoings, State2),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_war_spirit_equip_decompose_toc{refine_all_exp = RefineAllExp2}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_decompose_toc{err_code = ErrCode}),
            State
    end.

check_equip_decompose(EquipIDList, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{refine_all_exp = RefineAllExp, bag_list = BagList} = RoleConfine,
    {BagList2, LogGoods, AddGoods, AddExp} = check_equip_decompose2(EquipIDList, BagList, [], [], 0),
    mod_role_bag:check_bag_empty_grid(AddGoods, State),
    BagDoings = ?IF(AddGoods =/= [], [{create, ?ITEM_GAIN_WAR_SPIRIT_DECOMPOSE, AddGoods}], []),
    RefineAllExp2 = RefineAllExp + AddExp,
    Log = get_decompose_log(LogGoods, AddExp, RefineAllExp2, State),
    RoleConfine2 = RoleConfine#r_role_confine{refine_all_exp = RefineAllExp2, bag_list = BagList2},
    State2 = State#r_role{role_confine = RoleConfine2},
    {ok, EquipIDList, RefineAllExp2, Log, BagDoings, State2}.

check_equip_decompose2([], BagAcc, LogGoodsAcc, AddGoods, AddExpAcc) ->
    {BagAcc, LogGoodsAcc, AddGoods, AddExpAcc};
check_equip_decompose2([EquipID|R], BagAcc, LogGoodsAcc, AddGoodsAcc, AddExpAcc) ->
    case lists:keytake(EquipID, #p_war_spirit_equip.id, BagAcc) of
        {value, #p_war_spirit_equip{} = Equip, BagAcc2} ->
            #p_war_spirit_equip{
                type_id = TypeID,
                refine_level = RefineLevel,
                refine_exp = RefineExp,
                first_step_type_id = FirstStepTypeID
            } = Equip,
            [#c_war_spirit_equip_info{decompose_exp = DecomposeExp}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
            AddRefineExp =
            case RefineLevel > 0 of
                true ->
                    [#c_war_spirit_equip_refine{all_exp = AllExp}] = lib_config:find(cfg_war_spirit_equip_refine, RefineLevel),
                    AllExp;
                _ ->
                    0
            end,
            LogGoodsAcc2 =
            case lists:keytake(TypeID, #p_kv.id, LogGoodsAcc) of
                {value, #p_kv{val = OldVal} = KV, LogGoodsAccT} ->
                    [KV#p_kv{val = OldVal + 1}|LogGoodsAccT];
                _ ->
                    [#p_kv{id = TypeID, val = 1}|LogGoodsAcc]
            end,
            AddExpAcc2 = DecomposeExp + AddRefineExp + RefineExp + AddExpAcc,
            AddGoods = check_equip_decompose3(FirstStepTypeID, TypeID, []),
            check_equip_decompose2(R, BagAcc2, LogGoodsAcc2, AddGoods ++ AddGoodsAcc, AddExpAcc2);
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_DECOMPOSE_001)
    end.

check_equip_decompose3(StepTypeID, EquipTypeID, AddGoodsAcc) ->
    if
        StepTypeID =:= 0 ->
            AddGoodsAcc;
        StepTypeID =:= EquipTypeID ->
            AddGoodsAcc;
        true ->
            [#c_war_spirit_equip_info{step_item = StepItem}] = lib_config:find(cfg_war_spirit_equip_info, EquipTypeID),
            AddGoods = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- lib_tool:string_to_intlist(StepItem, ";", ":"), Num > 0],
            check_equip_decompose3(StepTypeID + 1, EquipTypeID, AddGoods ++ AddGoodsAcc)
    end.

do_equip_refine(RoleID, WarSpiritID, EquipID, State) ->
    case catch check_equip_refine(WarSpiritID, EquipID, State) of
        {ok, Equip, Log, IsCalc, RefineAllExp2, State2} ->
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_war_spirit_equip_refine_toc{war_spirit_id = WarSpiritID, equip = Equip, refine_all_exp = RefineAllExp2}),
            ?IF(IsCalc, mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WAR_SPIRIT_EQUIP_REFINE, EquipID), State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_refine_toc{err_code = ErrCode}),
            State
    end.

check_equip_refine(WarSpiritID, EquipID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList, refine_all_exp = RefineAllExp} = RoleConfine,
    ?IF(RefineAllExp > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {WarSpirit, WarSpiritList2} =
    case lists:keytake(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        {value, #p_war_spirit{} = WarSpiritT, WarSpiritListT} ->
            {WarSpiritT, WarSpiritListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_REFINE_001)
    end,
    #p_war_spirit{equip_list = EquipList} = WarSpirit,
    {Equip, EquipList2} =
    case lists:keytake(EquipID, #p_war_spirit_equip.id, EquipList) of
        {value, #p_war_spirit_equip{} = EquipT, EquipListT} ->
            {EquipT, EquipListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_REFINE_002)
    end,
    #p_war_spirit_equip{type_id = TypeID, refine_level = OldLevel, refine_exp = OldExp} = Equip,
    [#c_war_spirit_equip_info{refine_num = MaxRefineLevel}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    ?IF(OldLevel >= MaxRefineLevel, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_REFINE_003), ok),
    {NewLevel, NewExp, RefineAllExp2} = get_refine_level(OldLevel, OldExp, RefineAllExp),
    Equip2 = Equip#p_war_spirit_equip{refine_level = NewLevel, refine_exp = NewExp},
    EquipList3 = [Equip2|EquipList2],
    WarSpirit2 = WarSpirit#p_war_spirit{equip_list = EquipList3},
    WarSpiritList3 = [WarSpirit2|WarSpiritList2],
    RoleConfine2 = RoleConfine#r_role_confine{refine_all_exp = RefineAllExp2, war_spirit_list = WarSpiritList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    Log = get_refine_log(WarSpiritID, EquipID, TypeID, OldLevel, NewLevel, NewExp, RefineAllExp2, State2),
    IsCalc = OldLevel =/= NewLevel,
    {ok, Equip2, Log, IsCalc, RefineAllExp2, State2}.

get_refine_level(Level, Exp, RefineAllExp) ->
    Level2 = Level + 1,
    case lib_config:find(cfg_war_spirit_equip_refine, Level2) of
        [#c_war_spirit_equip_refine{reduce_exp = ReduceExp, need_exp = NeedExp}] ->
            ?IF(RefineAllExp >= ReduceExp, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
            Exp2 = Exp + ReduceExp,
            RefineAllExp2 = RefineAllExp - ReduceExp,
            case Exp2 >= NeedExp of
                true ->
                    {Level2, Exp2 - NeedExp, RefineAllExp2};
                _ ->
                    {Level, Exp2, RefineAllExp2}
            end;
        _ ->
            {Level, 0, RefineAllExp}
    end.

do_equip_step(RoleID, WarSpiritID, EquipID, State) ->
    case catch check_equip_step(WarSpiritID, EquipID, State) of
        {ok, Equip, Log, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_step_toc{war_spirit_id = WarSpiritID, equip = Equip}),
            mod_role_dict:add_background_logs(Log),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_equip_step_toc{err_code = ErrCode}),
            State
    end.

check_equip_step(WarSpiritID, EquipID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList} = RoleConfine,
    {WarSpirit, WarSpiritList2} =
    case lists:keytake(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        {value, #p_war_spirit{} = WarSpiritT, WarSpiritListT} ->
            {WarSpiritT, WarSpiritListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_STEP_001)
    end,
    #p_war_spirit{equip_list = EquipList,level = Level} = WarSpirit,
    {Equip, EquipList2} =
    case lists:keytake(EquipID, #p_war_spirit_equip.id, EquipList) of
        {value, #p_war_spirit_equip{} = EquipT, EquipListT} ->
            {EquipT, EquipListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_STEP_002)
    end,
    #p_war_spirit_equip{
        type_id = TypeID,
        refine_level = OldLevel,
        first_step_type_id = FirstStepTypeID,
        excellent_list = ExcellentList} = Equip,
    [#c_war_spirit_equip_info{star = Star, refine_num = MaxRefineLevel, step_item = StepItem}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    ?IF(OldLevel >= MaxRefineLevel, ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_STEP_003)),
    ItemList = lib_tool:string_to_intlist(StepItem, ";", ":"),
    ?IF(StepItem =/= "", ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_STEP_004)),
    [?IF(ItemNum =:= 0, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_STEP_004), ok) || {_ItemTypeID, ItemNum} <- ItemList],
    BagDoings = mod_role_bag:check_num_by_item_list(ItemList, ?ITEM_REDUCE_WAR_SPIRIT_EQUIP_STEP, State),
    TypeID2 = TypeID + 1,
    [#c_war_spirit_equip_info{quality = Quality}] = lib_config:find(cfg_war_spirit_equip_info, TypeID2),
    [#c_war_spirit_base{equip_quality_limit_string = LimitQualityString}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    LimitQualityList1 = lib_tool:string_to_intlist(LimitQualityString),
    LimitList = [{LimitQuality0,LimitStar0} || {Level0, LimitQuality0, LimitStar0} <- LimitQualityList1, Level >= Level0],
    LimitList2 = lists:last(LimitList),
%%    [#c_war_spirit_base{equip_quality_limit = LimitQuality}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    ?IF(Quality < erlang:element(1, LimitList2) orelse (Quality =:= erlang:element(1, LimitList2) andalso Star =< erlang:element(2, LimitList2)), ok, ?THROW_ERR(?ERROR_WAR_SPIRIT_EQUIP_LOAD_003)),
    FirstStepTypeID2 = ?IF(FirstStepTypeID > 0, FirstStepTypeID, TypeID),
    Equip2 = Equip#p_war_spirit_equip{
        type_id = TypeID2,
        first_step_type_id = FirstStepTypeID2,
        excellent_list = get_step_excellent(TypeID2, ExcellentList)},
    EquipList3 = [Equip2|EquipList2],
    WarSpirit2 = WarSpirit#p_war_spirit{equip_list = EquipList3},
    WarSpiritList3 = [WarSpirit2|WarSpiritList2],
    RoleConfine2 = RoleConfine#r_role_confine{war_spirit_list = WarSpiritList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    Log = get_step_log(WarSpiritID, EquipID, TypeID, TypeID2, State),
    {ok, Equip2, Log, BagDoings, State2}.



is_bag_full(_AddNum, #r_role{role_confine = undefined}) ->
    false;
is_bag_full(AddNum, #r_role{role_confine = RoleConfine}) ->
    #r_role_confine{bag_list = BagList} = RoleConfine,
    is_bag_full2(AddNum, erlang:length(BagList)).

is_bag_full2(AddNum, NowNum) ->
    AddNum + NowNum >= common_misc:get_global_int(?GLOBAL_WAR_SPIRIT_BAG_NUM).

notify_add_equips(_RoleID, []) ->
    ok;
notify_add_equips(RoleID, AddEquips) ->
    common_misc:unicast(RoleID, #m_war_spirit_equip_add_toc{add_list = AddEquips}).

notify_del_equips(_RoleID, []) ->
    ok;
notify_del_equips(RoleID, DelIDs) ->
    common_misc:unicast(RoleID, #m_war_spirit_equip_del_toc{del_list = DelIDs}).

get_equip_add_log(Equip, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #p_war_spirit_equip{
        id = EquipID,
        type_id = TypeID,
        excellent_list = ExcellentList
    } = Equip,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_war_spirit_equip_add{
        role_id = RoleID,
        equip_id = EquipID,
        type_id = TypeID,
        excellent_string = common_misc:to_kv_string(to_excellent_kv(ExcellentList)),
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_replace_log(WarSpiritID, EquipID, TypeID, ReplaceEquipID, ReplaceTypeID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_war_spirit_equip_replace{
        role_id = RoleID,
        war_spirit_id = WarSpiritID,
        load_equip_id = EquipID,
        load_type_id = TypeID,
        replace_equip_id = ReplaceEquipID,
        replace_type_id = ReplaceTypeID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    }.

get_decompose_log(LogGoods, AddRefineExp, RefineAllExp, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_war_spirit_equip_decompose{
        role_id = RoleID,
        goods_string = common_misc:to_kv_string(LogGoods),
        add_refine_exp = AddRefineExp,
        refine_all_exp = RefineAllExp,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_refine_log(WarSpiritID, EquipID, TypeID, OldLevel, NewLevel, NewExp, RefineAllExp, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_war_spirit_equip_refine{
        role_id = RoleID,
        war_spirit_id = WarSpiritID,
        equip_id = EquipID,
        type_id = TypeID,
        old_level = OldLevel,
        new_level = NewLevel,
        new_exp = NewExp,
        refine_all_exp = RefineAllExp,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

get_step_log(WarSpiritID, EquipID, OldTypeID, NewTypeID, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID
    } = RoleAttr,
    #log_war_spirit_equip_step{
        role_id = RoleID,
        equip_id = EquipID,
        war_spirit_id = WarSpiritID,
        old_type_id = OldTypeID,
        new_type_id = NewTypeID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

to_excellent_kv(ExcellentList) ->
    [#p_kv{id = Key, val = Val} || #p_kvt{id = Key, val = Val} <- ExcellentList].

%%%===================================================================
%%% 战灵灵器start
%%%===================================================================

do_armor_load(RoleID, WarSpiritID, GoodsIDs, State) ->
    case catch check_armor_load(WarSpiritID, GoodsIDs, State) of
        {ok, BagDoings, ChangeArmors, State2} ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_load_toc{war_spirit_id = WarSpiritID, change_armors = ChangeArmors}),
            State3 = mod_role_bag:do(BagDoings, State2),
            State4 = mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_WAR_SPIRIT_ARMOR_LOAD, WarSpiritID),
            FunList = [
                fun(StateAcc) -> mod_role_day_target:war_spirit_armor(StateAcc) end
            ],
            role_server:execute_state_fun(FunList, State4);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_load_toc{err_code = ErrCode}),
            State
    end.

check_armor_load(WarSpiritID, GoodsIDs, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{confine = ConfineID, war_spirit_list = WarSpiritList} = RoleConfine,
    {WarSpirit, WarSpiritList2} =
    case lists:keytake(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        {value, #p_war_spirit{} = WarSpiritT, WarSpiritListT} ->
            {WarSpiritT, WarSpiritListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_LOAD_001)
    end,
    #p_war_spirit{armor_list = ArmorList} = WarSpirit,
    [#c_war_spirit_base{armor_open_list = ArmorOpenList}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    {ok, GoodsList} = mod_role_bag:check_bag_by_ids(GoodsIDs, State),
    DeleteDoings = [{delete, ?ITEM_REDUCE_WAR_SPIRIT_ARMOR_LOAD, GoodsIDs}],
    {ArmorList2, ChangeArmors, AddGoodsList} = check_armor_load2(GoodsList, ArmorOpenList, ConfineID, State, ArmorList, [], [], []),
    AddDoings = [{create, ?ITEM_GAIN_WAR_SPIRIT_ARMOR_UNLOAD, AddGoodsList}],
    WarSpirit2 = WarSpirit#p_war_spirit{armor_list = ArmorList2},
    WarSpiritList3 = [WarSpirit2|WarSpiritList2],
    RoleConfine2 = RoleConfine#r_role_confine{war_spirit_list = WarSpiritList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    {ok, DeleteDoings ++ AddDoings, ChangeArmors, State2}.

check_armor_load2([], _ArmorOpenList, _ConfineID, _State, ArmorList, UnloadGoods, ChangeArmors, _IndexList) ->
    {ArmorList, ChangeArmors, UnloadGoods};
check_armor_load2([Goods|R], ArmorOpenList, ConfineID, State, ArmorList, UnloadGoods, ChangeArmors, IndexAcc) ->
    #p_goods{type_id = TypeID, excellent_list = ExcellentList} = Goods,
    mod_role_item:check_common_use(TypeID, State),
    [#c_equip{index = Index}] = lib_config:find(cfg_equip, TypeID),
    ?IF(lists:member(Index, IndexAcc), ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
    case ConfineID >= lists:nth(Index, ArmorOpenList) of
        true ->
            Armor = #p_war_spirit_armor{type_id = TypeID, excellent_list = ExcellentList},
            {ArmorList2, UnloadGoods2} =
            case check_armor_load3(Index, ArmorList, []) of
                {#p_war_spirit_armor{type_id = AddTypeID, excellent_list = AddExcellentList}, ArmorListT} ->
                    ArmorListT2 = [Armor|ArmorListT],
                    UnloadGoodsT = [#p_goods{type_id = AddTypeID, num = 1, excellent_list = AddExcellentList}|UnloadGoods],
                    {ArmorListT2, UnloadGoodsT};
                _ ->
                    {[Armor|ArmorList], UnloadGoods}
            end,
            check_armor_load2(R, ArmorOpenList, ConfineID, State, ArmorList2, UnloadGoods2, [Armor|ChangeArmors], [Index|IndexAcc]);
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_LOAD_002)
    end.


check_armor_load3(_Index, [], _Acc) ->
    false;
check_armor_load3(Index, [#p_war_spirit_armor{type_id = TypeID} = Armor|R], Acc) ->
    [#c_equip{index = ConfigIndex}] = lib_config:find(cfg_equip, TypeID),
    case Index =:= ConfigIndex of
        true ->
            {Armor, R ++ Acc};
        _ ->
            check_armor_load3(Index, R, [Armor|Acc])
    end.


do_armor_unload(RoleID, WarSpiritID, TypeIDs, State) ->
    case catch check_armor_unload(WarSpiritID, TypeIDs, State) of
        {ok, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_unload_toc{war_spirit_id = WarSpiritID, del_type_ids = TypeIDs}),
            State3 = mod_role_bag:do(BagDoings, State2),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_WAR_SPIRIT_ARMOR_UNLOAD, WarSpiritID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_unload_toc{err_code = ErrCode}),
            State
    end.

check_armor_unload(WarSpiritID, TypeIDs, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList} = RoleConfine,
    {WarSpirit, WarSpiritList2} =
    case lists:keytake(WarSpiritID, #p_war_spirit.id, WarSpiritList) of
        {value, #p_war_spirit{} = WarSpiritT, WarSpiritListT} ->
            {WarSpiritT, WarSpiritListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_LOAD_001)
    end,
    #p_war_spirit{armor_list = ArmorList} = WarSpirit,
    {ArmorList2, AddGoodsList} = check_armor_unload2(TypeIDs, ArmorList, []),
    mod_role_bag:check_bag_empty_grid(AddGoodsList, State),
    AddDoings = [{create, ?ITEM_GAIN_WAR_SPIRIT_ARMOR_UNLOAD, AddGoodsList}],
    WarSpirit2 = WarSpirit#p_war_spirit{armor_list = ArmorList2},
    WarSpiritList3 = [WarSpirit2|WarSpiritList2],
    RoleConfine2 = RoleConfine#r_role_confine{war_spirit_list = WarSpiritList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    {ok, AddDoings, State2}.

check_armor_unload2([], ArmorList, AddGoodsAcc) ->
    {ArmorList, AddGoodsAcc};
check_armor_unload2([TypeID|R], ArmorList, AddGoodsAcc) ->
    case lists:keytake(TypeID, #p_war_spirit_armor.type_id, ArmorList) of
        {value, #p_war_spirit_armor{excellent_list = ExcellentList}, ArmorList2} ->
            Goods = #p_goods{type_id = TypeID, num = 1, excellent_list = ExcellentList},
            check_armor_unload2(R, ArmorList2, [Goods|AddGoodsAcc]);
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_UNLOAD_002)
    end.

do_armor_lock_info(RoleID, WarSpiritID, Index, State) ->
    case catch check_armor_lock_info(WarSpiritID, Index, State) of
        {ok, BagDoings, LockInfo, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_war_spirit_armor_lock_info_toc{armors = LockInfo}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_spirit_armor_lock_info_toc{err_code = ErrCode}),
            State
    end.

check_armor_lock_info(WarSpiritID, Index, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{confine = ConfineID, lock_info = LockInfo} = RoleConfine,
    List =
        case lists:keyfind(WarSpiritID, #p_war_armor_lock.war_spirit_id, LockInfo) of
            #p_war_armor_lock{list = List0} ->
                List0;
            _ ->
                []
        end,
    ?IF(Index > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    [#c_war_spirit_base{armor_open_list = ArmorOpenList, consume_goods = ConsumeGoodsString}] = lib_config:find(cfg_war_spirit_base, WarSpiritID),
    ConsumeGoodsList = lib_tool:string_to_intlist(ConsumeGoodsString),
    case ConfineID >= lists:nth(Index, ArmorOpenList)  of
        true ->
            {TypeID0, Num0} = lists:nth(Index, ConsumeGoodsList),
            Num = mod_role_bag:get_num_by_type_id(TypeID0, State),
            case Num >= Num0 of
                true ->
                    DecreaseList = mod_role_bag:get_decrease_goods_by_num(TypeID0, Num0, State),
                    BagDoing = [{decrease, ?ITEM_REDUCE_EQUIP_OPEN, DecreaseList}],
                    List1 = lists:keystore(Index, #p_war_armor_lock_info.index, List, #p_war_armor_lock_info{index = Index, is_open = true}),
                    LockInfo2 = lists:keystore(WarSpiritID, #p_war_armor_lock.war_spirit_id, LockInfo, #p_war_armor_lock{war_spirit_id = WarSpiritID, list = List1}),
                    LockInfo3 = [#p_war_armor_lock{war_spirit_id = WarSpiritID1,list = List2} ||  #p_war_armor_lock{war_spirit_id = WarSpiritID1, list = List2} <- LockInfo2, List2 =/=[]],
                    RoleConfine2 = RoleConfine#r_role_confine{lock_info = LockInfo2},
                    State2 = State#r_role{role_confine = RoleConfine2},
                    {ok, BagDoing, LockInfo3, State2};
                _ ->
                    ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_LOCK_INFO_003)
            end;
        _ ->
            ?THROW_ERR(?ERROR_WAR_SPIRIT_ARMOR_LOCK_INFO_002)
    end.

get_armor_orange_step_num(NeedStep, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList} = RoleConfine,
    get_armor_orange_step_num2(WarSpiritList, NeedStep, 0).

get_armor_orange_step_num2([], _NeedStep, NumAcc) ->
    NumAcc;
get_armor_orange_step_num2([#p_war_spirit{armor_list = ArmorList}|R], NeedStep, NumAcc) ->
    NumAcc2 = get_armor_orange_step_num3(ArmorList, NeedStep, 0) + NumAcc,
    get_armor_orange_step_num2(R, NeedStep, NumAcc2).

get_armor_orange_step_num3([], _NeedStep, NumAcc) ->
    NumAcc;
get_armor_orange_step_num3([#p_war_spirit_armor{type_id = TypeID}|R], NeedStep, NumAcc) ->
    [#c_equip{quality = Quality, step = Step}] = lib_config:find(cfg_equip, TypeID),
    NumAcc2 = ?IF(Quality >= ?QUALITY_ORANGE andalso Step >= NeedStep, NumAcc + 1, NumAcc),
    get_armor_orange_step_num3(R, NeedStep, NumAcc2).

get_equip_orange_step_num(NeedStep, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit_list = WarSpiritList} = RoleConfine,
    get_equip_orange_step_num2(WarSpiritList, NeedStep, 0).

get_equip_orange_step_num2([], _NeedStep, NumAcc) ->
    NumAcc;
get_equip_orange_step_num2([#p_war_spirit{equip_list = EquipList}|R], NeedStep, NumAcc) ->
    NumAcc2 = get_equip_orange_step_num3(EquipList, NeedStep, 0) + NumAcc,
    get_equip_orange_step_num2(R, NeedStep, NumAcc2).

get_equip_orange_step_num3([], _NeedStep, NumAcc) ->
    NumAcc;
get_equip_orange_step_num3([#p_war_spirit_equip{type_id = TypeID}|R], NeedStep, NumAcc) ->
    [#c_war_spirit_equip_info{quality = Quality, step = Step}] = lib_config:find(cfg_war_spirit_equip_info, TypeID),
    NumAcc2 = ?IF(Quality >= ?QUALITY_ORANGE andalso Step >= NeedStep, NumAcc + 1, NumAcc),
    get_equip_orange_step_num3(R, NeedStep, NumAcc2).


%%%===================================================================
%%% 战灵灵器end
%%%===================================================================

%%%===================================================================
%%% 战神套装相关
%%%===================================================================
%% List -- [#p_kv{}|....]
%%add_war_god_pieces([], State) ->
%%    State;
%%add_war_god_pieces(List, State) ->
%%    #r_role{role_id = RoleID, role_confine = RoleConfine} = State,
%%    #r_role_confine{war_god_pieces = WarGodPieces} = RoleConfine,
%%    {WarGodPieces2, UpdatePieces} =
%%    lists:foldl(
%%        fun(#p_kv{id = Key, val = AddVal} = AddKV, {WarGodPiecesAcc, UpdateAcc}) ->
%%            case lists:keytake(Key, #p_kv.id, WarGodPiecesAcc) of
%%                {value, #p_kv{val = OldVal} = KV, WarGodPiecesAcc2} ->
%%                    KV2 = KV#p_kv{val = OldVal + AddVal},
%%                    {[KV2|WarGodPiecesAcc2], [KV2|UpdateAcc]};
%%                _ ->
%%                    {[AddKV|WarGodPiecesAcc], [AddKV|UpdateAcc]}
%%            end
%%        end, {WarGodPieces, []}, common_misc:merge_props(List)),
%%    RoleConfine2 = RoleConfine#r_role_confine{war_god_pieces = WarGodPieces2},
%%    common_misc:unicast(RoleID, #m_war_god_piece_update_toc{pieces = UpdatePieces}),
%%    State#r_role{role_confine = RoleConfine2}.

%% 战神碎片激活
do_war_god_piece(RoleID, WarGodID, EquipID, State) ->
    case catch check_war_god_piece(WarGodID, EquipID, State) of
        {ok, BagDoing, Equip, _UpdatePieces, Log, State2} ->
            mod_role_dict:add_background_logs(Log),
            State3 = mod_role_bag:do(BagDoing, State2),
%%            common_misc:unicast(RoleID, #m_war_god_piece_update_toc{pieces = UpdatePieces}),
            common_misc:unicast(RoleID, #m_war_god_piece_active_toc{war_god_id = WarGodID, war_god_equip = Equip}),
            mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_WAR_GOD_PIECE_ACTIVE, EquipID);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_god_piece_active_toc{err_code = ErrCode}),
            State
    end.

check_war_god_piece(WarGodID, EquipID, State) ->
    #r_role{role_id = RoleID, role_confine = RoleConfine} = State,
    #r_role_confine{war_god_list = WarGodList} = RoleConfine,
    {WarGod, WarGodList2} =
    case lists:keytake(WarGodID, #p_war_god.id, WarGodList) of
        {value, WarGodT, WarGodListT} ->
            {WarGodT, WarGodListT};
        _ ->
            {#p_war_god{id = WarGodID, is_active = false, equip_list = []}, WarGodList}
    end,
    #p_war_god{equip_list = EquipList} = WarGod,
    ?IF(lists:keymember(EquipID, #p_war_god_equip.equip_id, EquipList), ?THROW_ERR(?ERROR_WAR_GOD_PIECE_ACTIVE_001), ok),
    Config =
    case lib_config:find(cfg_war_god_base, WarGodID) of
        [ConfigT] ->
            ConfigT;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #c_war_god_base{
        equip_1 = Equip1,
        equip_1_condition = Equip1Condition,
        equip_2 = Equip2,
        equip_2_condition = Equip2Condition,
        equip_3 = Equip3,
        equip_3_condition = Equip3Condition,
        equip_4 = Equip4,
        equip_4_condition = Equip4Condition
    } = Config,
    {_EquipID, [PieceID, NeedNum]} = lists:keyfind(EquipID, 1, [{Equip1, Equip1Condition}, {Equip2, Equip2Condition}, {Equip3, Equip3Condition}, {Equip4, Equip4Condition}]),
    WarGodPieces = [#p_kv{id = PieceID, val = mod_role_bag:get_num_by_type_id(PieceID, State)}],
    {PieceKV, WarGodPieces2} =
    case lists:keytake(PieceID, #p_kv.id, WarGodPieces) of
        {value, PieceKVT, WarGodPiecesT} ->
            {PieceKVT, WarGodPiecesT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_GOD_PIECE_ACTIVE_002)
    end,
    DecreaseList = mod_role_bag:get_decrease_goods_by_num(PieceID, NeedNum, State),
    BagDoing = [{decrease, ?POWER_UPDATE_WAR_GOD_PIECE_ACTIVE, DecreaseList}],
    #p_kv{val = HasVal} = PieceKV,
    ?IF(HasVal >= NeedNum, ok, ?THROW_ERR(?ERROR_WAR_GOD_PIECE_ACTIVE_002)),
    Equip = #p_war_god_equip{equip_id = EquipID},
    EquipList2 = [Equip|EquipList],
    WarGod2 = WarGod#p_war_god{equip_list = EquipList2},
    WarGodList3 = [WarGod2|WarGodList2],
    PieceKV2 = PieceKV#p_kv{val = HasVal - NeedNum},
    WarGodPieces3 = [PieceKV2|WarGodPieces2],
    RoleConfine2 = RoleConfine#r_role_confine{war_god_list = WarGodList3, war_god_pieces = WarGodPieces3},
    State2 = State#r_role{role_confine = RoleConfine2},
    Log = #log_war_god_piece_active{role_id = RoleID, war_god_id = WarGodID, equip_id = EquipID},
    {ok, BagDoing, Equip, [PieceKV2], Log, State2}.

%% 战神套装激活
do_war_god_active(RoleID, WarGodID, State) ->
    case catch check_war_god_active(WarGodID, State) of
        {ok, IsNew, WarSpiritList, State2} ->
            common_misc:unicast(RoleID, #m_war_god_active_toc{war_god_id = WarGodID}),
            State3 = mod_role_fight:calc_attr_and_update(calc(State2), ?POWER_UPDATE_WAR_GOD_EQUIP_ACTIVE, WarGodID),
            case IsNew of
                true ->
                    #p_war_spirit{level = Level} = lists:keyfind(WarGodID, #p_war_spirit.id, WarSpiritList),
                    [#c_war_spirit_up{skill = Skills}] = get_war_spirit(WarGodID, Level),
                    skills_change2(Skills, State3);
                _ ->
                    State3
            end;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_god_active_toc{err_code = ErrCode}),
            State
    end.

check_war_god_active(WarGodID, State) ->
    #r_role{role_confine = RoleConfine} = State,
    #r_role_confine{war_spirit = WarSpiritID, war_spirit_list = WarSpiritList, war_god_list = WarGodList} = RoleConfine,
    ?IF(lists:keymember(WarGodID, #p_war_spirit.id, WarSpiritList), ok, ?THROW_ERR(?ERROR_WAR_GOD_PIECE_ACTIVE_003)),
    {WarGod, WarGodList2} =
    case lists:keytake(WarGodID, #p_war_god.id, WarGodList) of
        {value, WarGodT, WarGodListT} ->
            {WarGodT, WarGodListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_GOD_ACTIVE_001)
    end,
    #p_war_god{is_active = IsActive, equip_list = EquipList} = WarGod,
    ?IF(IsActive, ?THROW_ERR(?ERROR_WAR_GOD_ACTIVE_002), ok),
    ?IF(EquipList >= 4, ok, ?THROW_ERR(?ERROR_WAR_GOD_ACTIVE_001)),
    WarGod2 = WarGod#p_war_god{is_active = true},
    WarGodList3 = [WarGod2|WarGodList2],
    RoleConfine2 = RoleConfine#r_role_confine{war_god_list = WarGodList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    {ok, WarGodID =:= WarSpiritID, WarSpiritList, State2}.


do_war_god_refine(RoleID, WarGodID, EquipID, State) ->
    case catch check_war_god_refine(WarGodID, EquipID, State) of
        {ok, WarGodEquip, IsLevelUp, AssetDoings, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_war_god_refine_toc{war_god_id = WarGodID, war_god_equip = WarGodEquip}),
            ?IF(IsLevelUp, mod_role_fight:calc_attr_and_update(calc(State3), ?POWER_UPDATE_WAR_GOD_EQUIP_REFINE, EquipID), State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_god_refine_toc{err_code = ErrCode}),
            State
    end.

check_war_god_refine(WarGodID, EquipID, State) ->
    #r_role{role_id = RoleID, role_confine = RoleConfine} = State,
    #r_role_confine{war_god_list = WarGodList} = RoleConfine,
    {WarGod, WarGodList2} =
    case lists:keytake(WarGodID, #p_war_god.id, WarGodList) of
        {value, WarGodT, WarGodListT} ->
            {WarGodT, WarGodListT};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end,
    #p_war_god{is_active = IsActive, equip_list = EquipList} = WarGod,
    ?IF(IsActive, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    {WarEquip, EquipList2} =
    case lists:keytake(EquipID, #p_war_god_equip.equip_id, EquipList) of
        {value, WarEquipT, EquipListT} ->
            {WarEquipT, EquipListT};
        _ ->
            ?THROW_ERR(?ERROR_WAR_GOD_REFINE_001)
    end,
    #p_war_god_equip{refine_level = RefineLevel, refine_exp = RefineExp} = WarEquip,
    case lib_config:find(cfg_war_god_refine, {EquipID, RefineLevel + 1}) of
        [_ConfigT] ->
            ok;
        _ ->
            ?THROW_ERR(?ERROR_WAR_GOD_REFINE_002)
    end,
    [#c_war_god_refine{need_exp = NeedExp, need_score = NeedScore, refine_multi = RefineMulti}] = lib_config:find(cfg_war_god_refine, {EquipID, RefineLevel}),
    {#p_war_god_equip{refine_level = RefineLevel2, refine_exp = RefineExp2} = WarEquip2, AssetDoings} =
    case RefineExp >= NeedExp of
        true ->
            {WarEquip#p_war_god_equip{refine_level = RefineLevel + 1, refine_exp = 0}, []};
        _ ->
            AssetDoingsT = mod_role_asset:check_asset_by_type(?CONSUME_WAR_GOD_SCORE, NeedScore, ?ASSET_SCORE_REDUCE_FROM_WAR_GOD_REFINE, State),
            RefineExpT = RefineExp + 1,
            MultiRate = lists:nth(RefineExpT, RefineMulti),
            RefineExpT2 = ?IF(MultiRate >= lib_tool:random(?RATE_100), NeedExp, RefineExpT),
            {WarEquip#p_war_god_equip{refine_level = RefineLevel, refine_exp = RefineExpT2}, AssetDoingsT}
    end,
    EquipList3 = [WarEquip2|EquipList2],
    WarGod2 = WarGod#p_war_god{equip_list = EquipList3},
    WarGodList3 = [WarGod2|WarGodList2],
    RoleConfine2 = RoleConfine#r_role_confine{war_god_list = WarGodList3},
    State2 = State#r_role{role_confine = RoleConfine2},
    Log = #log_war_god_refine{role_id = RoleID, war_god_id = WarGodID, equip_id = EquipID, old_refine_level = RefineLevel,
                              old_refine_exp = RefineExp, new_refine_level = RefineLevel2, new_refine_exp = RefineExp2},
    {ok, WarEquip2, RefineLevel =/= RefineLevel2, AssetDoings, Log, State2}.


do_war_god_decompose(RoleID, IDs, State) ->
    case catch check_war_god_decompose(IDs, State) of
        {ok, BagDoing, _UpdatePieces, AssetDoings, State2} ->
            State3 = mod_role_asset:do(AssetDoings, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            common_misc:unicast(RoleID, #m_war_god_decompose_toc{}),
%%            common_misc:unicast(RoleID, #m_war_god_piece_update_toc{pieces = UpdatePieces}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_war_god_decompose_toc{err_code = ErrCode}),
            State
    end.

check_war_god_decompose(IDs, State) ->
    #r_role{role_confine = RoleConfine} = State,
%%    #r_role_confine{war_god_pieces = WarGodPieces} = RoleConfine,
    WarGodPieces = [#p_kv{id = Id, val = mod_role_bag:get_num_by_type_id(Id, State)} || Id <- IDs],
    {WarGodPieces2, AddScore, UpdatePieces} = check_war_god_decompose2(IDs, WarGodPieces, 0, []),
    DecreaseList =
    lists:foldl(
        fun(#p_kv{id = ID, val = Val}, Acc) ->
            mod_role_bag:get_decrease_goods_by_num(ID, Val, State) ++ Acc
        end, [], UpdatePieces),
    BagDoing = [{decrease, ?ASSET_WAR_GOD_SCORE_ADD_FROM_DECOMPOSE, DecreaseList}],
    AssetDoings = [{add_score, ?ASSET_WAR_GOD_SCORE_ADD_FROM_DECOMPOSE, ?ASSET_WAR_GOD_SCORE, AddScore}],
    RoleConfine2 = RoleConfine#r_role_confine{war_god_pieces = WarGodPieces2},
    State2 = State#r_role{role_confine = RoleConfine2},
    {ok, BagDoing, UpdatePieces, AssetDoings, State2}.

check_war_god_decompose2([], WarGodPieces, AddScore, UpdatePieces) ->
    {WarGodPieces, AddScore, UpdatePieces};
check_war_god_decompose2([ID|R], WarGodPieces, AddScoreAcc, UpdatePieces) ->
    case lists:keytake(ID, #p_kv.id, WarGodPieces) of
        {value, #p_kv{val = Num}, WarGodPieces2} ->
            #c_item{effect_args = EffectArgs} = mod_role_item:get_item_config(ID),
            AddScore = lib_tool:to_integer(EffectArgs) * Num + AddScoreAcc,
            check_war_god_decompose2(R, WarGodPieces2, AddScoreAcc + AddScore, [#p_kv{id = ID, val = Num}|UpdatePieces]);
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.


