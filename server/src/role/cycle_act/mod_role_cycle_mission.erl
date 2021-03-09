%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 二月 2019 10:39
%%%-------------------------------------------------------------------
-module(mod_role_cycle_mission).
-author("WZP").

-include("role.hrl").
-include("bg_act.hrl").
-include("cycle_act.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_cycle_mission.hrl").
-include("proto/mod_role_bg_act.hrl").


%% API
-export([
    init/1,
    handle/2,
    init_mission/3,
    online/1
]).

-export([
    gm_set_money/2
]).


-export([
    recharge/2,
    kill_boss/2,
    role_pre_enter/3,
    equip_treasure/2,
    rune_treasure/2,
    bless_treasure/2,
    daily_mission_treasure/1,
    copy_yard/1,
    copy_ruins/1,
    copy_vault/1,
    copy_forest/1,
    battle/1,
    solo/1,
    summit_tower/1,
    trevi_fountain/2,
    copy_equip/1
]).


gm_set_money(#r_role{role_cycle_mission = RoleCycleMission, role_id = RoleID} = State, NewMoney) ->
    common_misc:unicast(RoleID, #m_cycle_mission_toc{money = NewMoney}),
    NewReward = [begin
                     case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                         false ->
                             Pkv;
                         _ ->
                             [RewardConfig] = lib_config:find(cfg_cycle_mission_reward, Pkv#p_kv.id),
                             ?IF(RewardConfig#c_cycle_mission_reward.money =< NewMoney, Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}, Pkv)
                     end
                 end || Pkv <- RoleCycleMission#r_role_cycle_mission.reward_list],
    RoleCycleMission2 = RoleCycleMission#r_role_cycle_mission{money = NewMoney, reward_list = NewReward},
    State#r_role{role_cycle_mission = RoleCycleMission2}.


init(#r_role{role_cycle_mission = undefined, role_id = RoleID} = State) ->
    RoleCycleMission = #r_role_cycle_mission{role_id = RoleID, start_time = 0, mission_list = [], money = 0},
    State#r_role{role_cycle_mission = RoleCycleMission};
init(State) ->
    State.

init_mission(#r_role{role_id = RoleID, role_cycle_mission = RoleCycleMission} = State, ConfigNum, EditTime) ->
    case EditTime =/= RoleCycleMission#r_role_cycle_mission.start_time of
        true ->
            MissionList = [#r_cycle_mission{id = Config#c_cycle_mission.id, type = Config#c_cycle_mission.type, remaining_times = Config#c_cycle_mission.complete_times, schedule = 0}
                           || {_, Config} <- lib_config:list(cfg_cycle_mission), Config#c_cycle_mission.config_num =:= ConfigNum],
            RewardList = [#p_kv{id = Config#c_cycle_mission_reward.id, val = ?ACT_REWARD_CANNOT_GET}
                          || {_, Config} <- lib_config:list(cfg_cycle_mission_reward), Config#c_cycle_mission_reward.config_num =:= ConfigNum],
            RoleActMission2 = #r_role_cycle_mission{role_id = RoleID, mission_list = MissionList, start_time = EditTime, money = 0, reward_list = RewardList},
            online(State#r_role{role_cycle_mission = RoleActMission2});
        _ ->
            State
    end.



online(#r_role{role_id = RoleID, role_cycle_mission = RoleCycleMission} = State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            List = [begin
                        [Config] = lib_config:find(cfg_cycle_mission, Mission#r_cycle_mission.id),
                        Val = Config#c_cycle_mission.complete_times - Mission#r_cycle_mission.remaining_times,
                        #p_kv{val = Val, id = Mission#r_cycle_mission.id} end || Mission <- RoleCycleMission#r_role_cycle_mission.mission_list],
            common_misc:unicast(RoleID, #m_cycle_mission_toc{money = RoleCycleMission#r_role_cycle_mission.money, list = List, reward = RoleCycleMission#r_role_cycle_mission.reward_list});
        _ ->
            ok
    end,
    State.



handle({#m_cycle_mission_reward_tos{id = ID}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, State, ID).


do_get_reward(RoleID, State, ID) ->
    case catch check_can_get_reward(State, ID) of
        {ok, State2, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_cycle_mission_reward_toc{id = ID}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_cycle_mission_reward_toc{err_code = ErrCode}),
            State
    end.

check_can_get_reward(#r_role{role_cycle_mission = RoleCycleMission} = State, Entry) ->
    ?IF(mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State), ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    case lists:keytake(Entry, #p_kv.id, RoleCycleMission#r_role_cycle_mission.reward_list) of
        false ->
            ?THROW_ERR(?ERROR_BG_ACT_REWARD_003);
        {value, #p_kv{val = Val}, OtherList} ->
            ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
            [Config] = lib_config:find(cfg_cycle_mission_reward, Entry),
%%            ?IF(Config#c_cycle_mission_reward.money =< RoleCycleMission#r_role_cycle_mission.money, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
            GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num, _} <- lib_tool:string_to_intlist(Config#c_cycle_mission_reward.reward)],
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_ACT_CYCLE_MISSION, GoodsList}],
            RoleCycleMission2 = RoleCycleMission#r_role_cycle_mission{reward_list = [#p_kv{id = Entry, val = ?ACT_REWARD_GOT}|OtherList]},
            {ok, State#r_role{role_cycle_mission = RoleCycleMission2}, BagDoings}
    end.



add_schedule_mission(#r_role{role_cycle_mission = RoleCycleMission, role_id = RoleID} = State, Type, AddNumber) ->
    {NewMissionList, AddMoney, UpdateList} = add_schedule_mission_i(RoleCycleMission#r_role_cycle_mission.mission_list, Type, 0, AddNumber, [], []),
    NewMoney = AddMoney + RoleCycleMission#r_role_cycle_mission.money,
    NewReward = [begin
                     case Pkv#p_kv.val =:= ?ACT_REWARD_CANNOT_GET of
                         false ->
                             Pkv;
                         _ ->
                             [RewardConfig] = lib_config:find(cfg_cycle_mission_reward, Pkv#p_kv.id),
                             ?IF(RewardConfig#c_cycle_mission_reward.money =< NewMoney, Pkv#p_kv{val = ?ACT_REWARD_CAN_GET}, Pkv)
                     end
                 end || Pkv <- RoleCycleMission#r_role_cycle_mission.reward_list],
    RoleCycleMission2 = RoleCycleMission#r_role_cycle_mission{money = NewMoney, mission_list = NewMissionList, reward_list = NewReward},
    ?IF(AddMoney =/= 0, common_misc:unicast(RoleID, #m_cycle_mission_update_toc{money = NewMoney, list = UpdateList}), ok),
    State#r_role{role_cycle_mission = RoleCycleMission2}.


add_schedule_mission_i([], _Type, AddMoney, _AddNumber, NewList, UpdateList) ->
    {NewList, AddMoney, UpdateList};
add_schedule_mission_i([#r_cycle_mission{id = ID, type = Type, remaining_times = RemainingTimes, schedule = Schedule} = Mission|T], Type, AddMoney, AddNumber, NewList, UpdateList) ->
    case RemainingTimes > 0 of
        true ->
            NewSchedule = Schedule + AddNumber,
            [Config] = lib_config:find(cfg_cycle_mission, ID),
            case Config#c_cycle_mission.param =< NewSchedule of
                true ->
                    NewSchedule2 = NewSchedule rem Config#c_cycle_mission.param,
                    AddTimes = NewSchedule div Config#c_cycle_mission.param,
                    case AddTimes > RemainingTimes of
                        true ->
                            NewRemainingTimes = 0,
                            NewSchedule3 = 0,
                            AddTimes2 = RemainingTimes;
                        _ ->
                            NewRemainingTimes = RemainingTimes - AddTimes,
                            NewSchedule3 = NewSchedule2,
                            AddTimes2 = AddTimes
                    end,
                    NewMission = Mission#r_cycle_mission{remaining_times = NewRemainingTimes, schedule = NewSchedule3},
                    add_schedule_mission_i(T, Type, AddMoney + Config#c_cycle_mission.money * AddTimes2, AddNumber, [NewMission|NewList], [#p_kv{id = ID, val = Config#c_cycle_mission.complete_times - NewRemainingTimes}|UpdateList]);
                _ ->
                    NewMission = Mission#r_cycle_mission{schedule = NewSchedule},
                    add_schedule_mission_i(T, Type, AddMoney, AddNumber, [NewMission|NewList], UpdateList)
            end;
        _ ->
            add_schedule_mission_i(T, Type, AddMoney, AddNumber, [Mission|NewList], UpdateList)
    end;
add_schedule_mission_i([Mission|T], Type, AddMoney, AddNumber, NewList, UpdateList) ->
    add_schedule_mission_i(T, Type, AddMoney, AddNumber, [Mission|NewList], UpdateList).


recharge(State, Num) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RECHARGE, Num);
        _ ->
            State
    end.


kill_boss(TypeID, State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            [#c_world_boss{type = Rarity}] = lib_config:find(cfg_world_boss, TypeID),
            if
                Rarity =:= 1 -> add_schedule_mission(State, ?BG_MISSION_KILL_WORLD_BOSS, 1);
                Rarity =:= 3 -> add_schedule_mission(State, ?BG_MISSION_KILL_PERSON_BOSS, 1);
                Rarity =:= 2 -> add_schedule_mission(State, ?BG_MISSION_KILL_FUDI_BOSS, 1);
                Rarity =:= 5 -> add_schedule_mission(State, ?BG_MISSION_KILL_MYTHICAL_BOSS, 1);
                Rarity =:= 6 -> add_schedule_mission(State, ?BG_MISSION_KILL_MYTHICAL_BOSS, 1);
                Rarity =:= 7 -> add_schedule_mission(State, ?BG_MISSION_KILL_ANCIENT_BOSS, 1);
                true ->
                    State
            end;
        _ ->
            State
    end.


role_pre_enter(State, BagDoings, PreEnterMap) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            #c_map_base{sub_type = SubType} = map_misc:get_map_base(PreEnterMap),
            if
                BagDoings =:= [] -> State;
                ?SUB_TYPE_WORLD_BOSS_4 =:= SubType -> add_schedule_mission(State, ?BG_MISSION_YOUMING, 1);
                true ->
                    State
            end;
        _ ->
            State
    end.

equip_treasure(State, AddTimes) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_EQUIP_TREASURE, AddTimes);
        _ ->
            State
    end.

rune_treasure(State, AddTimes) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RUNE_TREASURE, AddTimes);
        _ ->
            State
    end.


bless_treasure(State, Times) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_BLESS, Times);
        _ ->
            State
    end.

daily_mission_treasure(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_DAILY, 1);
        _ ->
            State
    end.

copy_yard(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_YARD, 1);
        _ ->
            State
    end.

copy_ruins(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RUINS, 1);
        _ ->
            State
    end.

copy_vault(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_VAULT, 1);
        _ ->
            State
    end.

copy_forest(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_FOREST, 1);
        _ ->
            State
    end.

battle(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_BATTLE, 1);
        _ ->
            State
    end.

solo(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_SOLE, 1);
        _ ->
            State
    end.

summit_tower(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_SUMMIT_TOWER, 1);
        _ ->
            State
    end.

trevi_fountain(State, Times) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_TREVI_FOUNTAIN, Times);
        _ ->
            State
    end.

copy_equip(State) ->
    case mod_role_cycle_act:is_act_open(?CYCLE_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_EQUIP_COPY, 1);
        _ ->
            State
    end.

