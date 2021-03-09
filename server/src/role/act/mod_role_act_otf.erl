%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2019 16:04
%%%-------------------------------------------------------------------
-module(mod_role_act_otf).
-author("WZP").

-include("role.hrl").
-include("act.hrl").
-include("act_otf.hrl").
-include("act_oss.hrl").
-include("family_asm.hrl").
-include("family_escort.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_act_otf.hrl").
%% API
-export([
    online/1,
    handle/2,
    day_reset/1
]).

-export([
    level_up/4
]).

-export([
    do_task/3,
    kill_boss/2,
    role_pre_enter/3,
    gm_add_score/2,
    init_mission/2,
    family_mission/2,
    family_escort/2
]).

gm_add_score(#r_role{role_id = RoleID, role_act_otf = RoleActOtf} = State, Num) ->
    {RewardUpdateList, NewRewardList} = check_reward(Num, RoleActOtf#r_role_act_otf.reward_list, [], []),
    RoleActOtf2 = RoleActOtf#r_role_act_otf{score = Num, reward_list = NewRewardList},
    common_misc:unicast(RoleID, #m_otf_update_reward_toc{score = Num, reward_list = RewardUpdateList}),
    State#r_role{role_act_otf = RoleActOtf2}.





init_reward() ->
    [#p_kv{id = Score, val = ?ACT_REWARD_CANNOT_GET} || {Score, _} <- cfg_otf_reward:list()].

%% p_kvt  id-ID  val-已完成次数  type-完成参数
init_mission(OldLevel, NewLevel) ->
    lists:foldl(fun({_, Config}, {AddScore, AccList}) ->
        case OldLevel < Config#c_otf_mission.level andalso Config#c_otf_mission.level =< NewLevel of
            true ->
                case Config#c_otf_mission.type =:= ?OSS_ENTER of
                    true ->
                        {Config#c_otf_mission.score + AddScore, [#p_kvt{id = Config#c_otf_mission.id, val = 1, type = 0}|AccList]};
                    _ ->
                        {AddScore, [#p_kvt{id = Config#c_otf_mission.id, val = 0, type = 0}|AccList]}
                end;
            _ ->
                {AddScore, AccList}
        end
                end, {0, []}, cfg_otf_mission:list()).

day_reset(State) ->
    State2 = online(State),
    do_task(State2, ?OSS_ENTER, 1).



online(#r_role{role_act_otf = undefined, role_id = RoleID, role_attr = RoleAttr} = State) ->
    case mod_role_act:is_act_open(?ACT_OTF, State) of
        true ->
            RewardList = init_reward(),
            [Config] = lib_config:find(cfg_act, ?ACT_OTF),
            Level = erlang:max(Config#c_act.min_level, RoleAttr#r_role_attr.level),
            {AddScore, MissionList} = init_mission(0, Level),
            RoleActOtf = #r_role_act_otf{role_id = RoleID, reward_list = RewardList, mission_list = MissionList, score = AddScore},
            common_misc:unicast(RoleID, #m_otf_info_toc{score = RoleActOtf#r_role_act_otf.score, mission_list = tran_to_pkv(RoleActOtf#r_role_act_otf.mission_list), reward_list = RoleActOtf#r_role_act_otf.reward_list}),
            State#r_role{role_act_otf = RoleActOtf};
        _ ->
            State
    end;
online(State) ->
    case mod_role_act:is_act_open(?ACT_OTF, State) of
        true ->
            #r_role{role_id = RoleID, role_act_otf = RoleActOtf} = State,
            common_misc:unicast(RoleID, #m_otf_info_toc{score = RoleActOtf#r_role_act_otf.score, mission_list = tran_to_pkv(RoleActOtf#r_role_act_otf.mission_list), reward_list = RoleActOtf#r_role_act_otf.reward_list}),
            State;
        _ ->
            State
    end.

tran_to_pkv(List) ->
    [#p_kv{id = ID, val = Val} || #p_kvt{id = ID, val = Val} <- List].

level_up(#r_role{role_act_otf = undefined} = State, _MinLevel, _OldLevel, _NewLevel) ->
    State;
level_up(#r_role{role_id = RoleID, role_act_otf = RoleActOtf} = State, MinLevel, OldLevel, NewLevel) ->
    {AddScore, NewMission} = init_mission(OldLevel, NewLevel),
    NewScore = AddScore + RoleActOtf#r_role_act_otf.score,
    {RoleActOtf3, RewardUpdateList2} = case AddScore =:= 0 of
                                           false ->
                                               {RewardUpdateList, NewRewardList} = check_reward(NewScore, RoleActOtf#r_role_act_otf.reward_list, [], []),
                                               RoleActOtf2 = RoleActOtf#r_role_act_otf{mission_list = NewMission ++ RoleActOtf#r_role_act_otf.mission_list, score = NewScore, reward_list = NewRewardList},
                                               {RoleActOtf2, RewardUpdateList};
                                           _ ->
                                               RoleActOtf2 = RoleActOtf#r_role_act_otf{mission_list = NewMission ++ RoleActOtf#r_role_act_otf.mission_list},
                                               {RoleActOtf2, []}
                                       end,
    State2 = State#r_role{role_act_otf = RoleActOtf3},
    case MinLevel =< OldLevel of
        true ->
            common_misc:unicast(RoleID, #m_otf_add_mission_toc{mission_list = tran_to_pkv(NewMission)}),
            case NewScore > 0 of
                false ->
                    ok;
                _ ->
                    common_misc:unicast(RoleID, #m_otf_update_reward_toc{score = NewScore, reward_list = RewardUpdateList2})
            end;
        _ ->
            common_misc:unicast(RoleID, #m_otf_info_toc{score = RoleActOtf3#r_role_act_otf.score, mission_list = tran_to_pkv(RoleActOtf3#r_role_act_otf.mission_list), reward_list = RoleActOtf3#r_role_act_otf.reward_list})
    end,
    State2.



handle({#m_otf_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, ID, State).

do_get_reward(RoleID, ID, State) ->
    case catch check_can_get_reward(State, ID) of
        {ok, State2, BagDoings} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            common_misc:unicast(RoleID, #m_otf_reward_toc{id = ID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_otf_reward_toc{err_code = ErrCode}),
            State
    end.


check_can_get_reward(#r_role{role_act_otf = RoleActOtf} = State, ID) ->
    ?IF(mod_role_act:is_act_open(?ACT_OTF, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    case lists:keytake(ID, #p_kv.id, RoleActOtf#r_role_act_otf.reward_list) of
        {value, #p_kv{val = Val}, OtherReward} ->
            ?IF(Val =:= ?ACT_REWARD_CANNOT_GET, ?THROW_ERR(?ERROR_OTF_REWARD_001), ok),
            ?IF(Val =:= ?ACT_REWARD_GOT, ?THROW_ERR(?ERROR_OTF_REWARD_002), ok),
            [Config] = lib_config:find(cfg_otf_reward, ID),
            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true} || {TypeID, Num} <- lib_tool:string_to_intlist(Config#c_otf_reward.reward)],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_ACT_OTF, GoodsList}],
            RoleActOtf2 = RoleActOtf#r_role_act_otf{reward_list = [#p_kv{id = ID, val = ?ACT_REWARD_GOT}|OtherReward]},
            {ok, State#r_role{role_act_otf = RoleActOtf2}, BagDoings};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
    end.


family_mission(State, TaskID) ->
    [Config] = lib_config:find(cfg_family_asm, TaskID),
    case Config#c_family_asm.star_level of
        7 ->
            State2 = do_task(State, ?OSS_FAMILY_MISSION_SEVEN_START, 1),
            State3 = do_task(State2, ?OSS_FAMILY_MISSION_SIX_START, 1),
            State4 = do_task(State3, ?OSS_FAMILY_MISSION_FIVE_START, 1),
            do_task(State4, ?OSS_FAMILY_MISSION_FOUR_START, 1);
        6 ->
            State2 = do_task(State, ?OSS_FAMILY_MISSION_SIX_START, 1),
            State3 = do_task(State2, ?OSS_FAMILY_MISSION_FIVE_START, 1),
            do_task(State3, ?OSS_FAMILY_MISSION_FOUR_START, 1);
        5 ->
            State2 = do_task(State, ?OSS_FAMILY_MISSION_FIVE_START, 1),
            do_task(State2, ?OSS_FAMILY_MISSION_FOUR_START, 1);
        4 ->
            do_task(State, ?OSS_FAMILY_MISSION_FOUR_START, 1);
        _ ->
            State

    end.

family_escort(State, Fairy) ->
    [Config] = lib_config:find(cfg_escort, Fairy),
    case Config#c_escort.quality of
        4 ->
            do_task(State, ?OSS_ORANGE_ESCORT, 1);
        3 ->
            do_task(State, ?OSS_PURPLE_ESCORT, 1);
        2 ->
            do_task(State, ?OSS_BLUE_ESCORT, 1);
        1 ->
            do_task(State, ?OSS_WHITE_ESCORT, 1);
        _ ->
            State

    end.

do_task(State, Type, Param) ->
    case mod_role_act:is_act_open(?ACT_OTF, State) of
        true ->
            do_trigger_mission_i(State, Type, Param);
        _ ->
            State
    end.

do_trigger_mission_i(#r_role{role_act_otf = RoleActOtf} = State, Type, Param) ->
    #r_role_act_otf{mission_list = MissionList} = RoleActOtf,
    {UpdateList, NewList, AddScore} = do_trigger_mission_i(MissionList, Type, [], [], 0, Param),
    case AddScore > 0 of
        false ->
            RoleActOtf2 = RoleActOtf#r_role_act_otf{mission_list = NewList},
            State#r_role{role_act_otf = RoleActOtf2};
        _ ->
            NewScore = RoleActOtf#r_role_act_otf.score + AddScore,
            {RewardUpdateList, NewRewardList} = check_reward(NewScore, RoleActOtf#r_role_act_otf.reward_list, [], []),
            common_misc:unicast(State#r_role.role_id, #m_otf_update_reward_toc{score = NewScore, reward_list = RewardUpdateList, mission_list = tran_to_pkv(UpdateList)}),
            RoleActOtf2 = RoleActOtf#r_role_act_otf{mission_list = NewList, reward_list = NewRewardList, score = NewScore},
            State#r_role{role_act_otf = RoleActOtf2}
    end.

check_reward(_NewScore, [], UpdateList, List) ->
    {UpdateList, List};
check_reward(NewScore, [Reward|T], UpdateList, List) ->
    case Reward#p_kv.id =< NewScore andalso Reward#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            check_reward(NewScore, T, [Reward#p_kv{val = ?ACT_REWARD_CAN_GET}|UpdateList], [Reward#p_kv{val = ?ACT_REWARD_CAN_GET}|List]);
        _ ->
            check_reward(NewScore, T, UpdateList, [Reward|List])
    end.



do_trigger_mission_i([], _Type, UpdateList, List, AddScore, _AddTimes) ->
    {UpdateList, List, AddScore};
do_trigger_mission_i([Mission|T], Type, UpdateList, List, AddScore, AddTimes) ->
    case lib_config:find(cfg_otf_mission, Mission#p_kvt.id) of
        [Config] ->
            case Config#c_otf_mission.type =:= Type andalso Config#c_otf_mission.times > Mission#p_kvt.val of
                true ->
                    case ?OSS_RECHARGE =:= Type of
                        true ->
                            NewMission = Mission#p_kvt{val = Mission#p_kvt.val + 1, type = 0},
                            do_trigger_mission_i(T, Type, [NewMission|UpdateList], [NewMission|List], AddScore + Config#c_otf_mission.score, AddTimes);
                        _ ->
                            NewTimes = AddTimes + Mission#p_kvt.type,
                            AddTimes2 = NewTimes div Config#c_otf_mission.param,
                            NewTimes2 = erlang:min(AddTimes2 + Mission#p_kvt.val, Config#c_otf_mission.times),
                            NewParam = NewTimes rem Config#c_otf_mission.param,
                            NewMission = Mission#p_kvt{val = NewTimes2, type = NewParam},
                            case NewTimes2 =:= Mission#p_kvt.val of
                                true ->
                                    do_trigger_mission_i(T, Type, UpdateList, [NewMission|List], AddScore, AddTimes);
                                _ ->
                                    do_trigger_mission_i(T, Type, [NewMission|UpdateList], [NewMission|List], AddScore + (NewTimes2 - Mission#p_kvt.val) * Config#c_otf_mission.score, AddTimes)
                            end
                    end;
                _ ->
                    do_trigger_mission_i(T, Type, UpdateList, [Mission|List], AddScore, AddTimes)
            end;
        _ ->
            do_trigger_mission_i(T, Type, UpdateList, [Mission|List], AddScore, AddTimes)
    end.




kill_boss(TypeID, State) ->
    case lib_config:find(cfg_world_boss, TypeID) of
        [#c_world_boss{type = Type}] ->
            if
                Type =:= ?BOSS_TYPE_WORLD_BOSS -> do_task(State, ?OSS_WORLD_BOSS, 1);
                Type =:= ?BOSS_TYPE_PERSONAL -> do_task(State, ?OSS_PERSON_BOSS, 1);
                Type =:= ?BOSS_TYPE_FAMILY -> do_task(State, ?OSS_HOME_BOSS, 1);
                true ->
                    State
            end;
        _ ->
            State
    end.

role_pre_enter(State, BagDoings, PreEnterMap) ->
    #c_map_base{sub_type = SubType} = map_misc:get_map_base(PreEnterMap),
    if
        BagDoings =:= [] -> State;
        ?SUB_TYPE_WORLD_BOSS_4 =:= SubType -> do_task(State, ?OSS_YMDJ, 1);
        true ->
            State
    end.

%%recharge(State, Num) ->
%%    do_trigger_mission(State, ?BG_MISSION_RECHARGE, Num).
%%
%%
%%
%%kill_boss(TypeID, State) ->
%%    #c_monster{rarity = Rarity} = monster_misc:get_monster_config(TypeID),
%%    if
%%        Rarity =:= 4 -> do_trigger_mission(State, ?BG_MISSION_KILL_WORLD_BOSS, 1);
%%        Rarity =:= 6 -> do_trigger_mission(State, ?BG_MISSION_KILL_PERSON_BOSS, 1);
%%        Rarity =:= 7 -> do_trigger_mission(State, ?BG_MISSION_KILL_FUDI_BOSS, 1);
%%        Rarity =:= 9 -> do_trigger_mission(State, ?BG_MISSION_KILL_MYTHICAL_BOSS, 1);
%%        Rarity =:= 10 -> do_trigger_mission(State, ?BG_MISSION_KILL_ANCIENT_BOSS, 1);
%%        true ->
%%            State
%%    end.
%%
%%role_pre_enter(State, BagDoings, PreEnterMap) ->
%%    #c_map_base{sub_type = SubType} = map_misc:get_map_base(PreEnterMap),
%%    if
%%        BagDoings =:= [] -> State;
%%        ?SUB_TYPE_WORLD_BOSS_4 =:= SubType -> do_trigger_mission(State, ?BG_MISSION_YOUMING, 1);
%%        true ->
%%            State
%%    end.
%%
%%equip_treasure(State, AddTimes) ->
%%    do_trigger_mission(State, ?BG_MISSION_EQUIP_TREASURE, AddTimes).
%%
%%rune_treasure(State, AddTimes) ->
%%    do_trigger_mission(State, ?BG_MISSION_RUNE_TREASURE, AddTimes).
%%
%%bless_treasure(State, Times) ->
%%    do_trigger_mission(State, ?BG_MISSION_BLESS, Times).
%%
%%daily_mission_treasure(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_DAILY, 1).
%%
%%copy_yard(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_YARD, 1).
%%
%%copy_ruins(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_RUINS, 1).
%%
%%copy_vault(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_VAULT, 1).
%%
%%copy_forest(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_FOREST, 1).
%%
%%battle(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_BATTLE, 1).
%%
%%solo(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_SOLE, 1).
%%
%%summit_tower(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_SUMMIT_TOWER, 1).
%%
%%trevi_fountain(State, Times) ->
%%    do_trigger_mission(State, ?BG_MISSION_TREVI_FOUNTAIN, Times).
%%
%%copy_equip(State) ->
%%    do_trigger_mission(State, ?BG_MISSION_EQUIP_COPY, 1).