%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 二月 2019 10:39
%%%-------------------------------------------------------------------
-module(mod_role_bg_act_mission).
-author("WZP").

-include("role.hrl").
-include("bg_act.hrl").
-include("monster.hrl").
-include("world_boss.hrl").
-include("proto/mod_role_bg_act_mission.hrl").
-include("proto/mod_role_bg_act.hrl").


%% API
-export([
    init/1,
    init_mission/3,
    online_action/2,
    check_can_get_reward/2
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


gm_set_money(#r_role{role_bg_act_mission = RoleBgMission, role_id = RoleID} = State, Money) ->
    RoleBgMission2 = RoleBgMission#r_role_bg_mission{money = Money},
    common_misc:unicast(RoleID, #m_bg_mission_update_toc{money = Money}),
    State#r_role{role_bg_act_mission = RoleBgMission2}.


init(#r_role{role_bg_act_mission = undefined, role_id = RoleID} = State) ->
    RoleBgMission = #r_role_bg_mission{role_id = RoleID, mission_time = 0, mission_list = [], money = 0},
    State#r_role{role_bg_act_mission = RoleBgMission};
init(State) ->
    State.

init_mission(#r_role{role_id = RoleID, role_bg_act_mission = RoleActMission} = State, Config, EditTime) ->
    case EditTime =/= RoleActMission#r_role_bg_mission.mission_time of
        true ->
            MissionList = proplists:get_value(mission_list, Config),
            RoleActMission2 = #r_role_bg_mission{role_id = RoleID, mission_list = MissionList, mission_time = EditTime, money = 0, reward_list = []},
            State#r_role{role_bg_act_mission = RoleActMission2};
        _ ->
            State
    end.



online_action(#r_role{role_id = RoleID, role_bg_act_mission = RoleActMission}, BgInfo) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(BgInfo),
    NewEntryList = [
        begin
            #bg_act_config_info{title = Title, condition = Condition, items = Items, sort = Sort} = EntryInfo,
            Items2 = [#p_item_i{type_id = ItemID, num = ItemNum, is_bind = Bind, special_effect = SpecialEffect} || {ItemID, ItemNum, Bind, SpecialEffect} <- Items],
            case RoleActMission#r_role_bg_mission.money >= Condition of
                true ->
                    Schedule2 = Condition,
                    Status2 = ?IF(lists:member(Sort, RoleActMission#r_role_bg_mission.reward_list), ?ACT_REWARD_GOT, ?ACT_REWARD_CAN_GET);
                _ ->
                    Schedule2 = RoleActMission#r_role_bg_mission.money,
                    Status2 = ?ACT_REWARD_CANNOT_GET
            end,
            #p_bg_act_entry{sort = Sort, items = Items2, title = Title, status = Status2, schedule = Schedule2, num = 0, target = Condition}
        end
        || EntryInfo <- PBgAct#p_bg_act.entry_list],
    PBgAct2 = PBgAct#p_bg_act{entry_list = NewEntryList},
    PBgMission = trans_to_p_bg_mission(RoleActMission#r_role_bg_mission.mission_list),
    KeyWord = proplists:get_value(keyword, BgInfo#r_bg_act.config),
    common_misc:unicast(RoleID, #m_bg_mission_toc{info = PBgAct2, list = PBgMission, money = RoleActMission#r_role_bg_mission.money, keyword = KeyWord}),
    ok.


trans_to_p_bg_mission(List) ->
    trans_to_p_bg_mission(List, []).

trans_to_p_bg_mission([], List) ->
    List;
trans_to_p_bg_mission([Info|T], List) ->
    trans_to_p_bg_mission(T, [#p_bg_mission{id = Info#bg_act_mission.sort, word = Info#bg_act_mission.title, times = Info#bg_act_mission.now_times, all_times = Info#bg_act_mission.all_times,
                                            jump_type = Info#bg_act_mission.type}|List]).


check_can_get_reward(#r_role{role_bg_act_mission = RoleActMission} = State, Entry) ->
    BgInfo = world_bg_act_server:get_bg_act(?BG_ACT_MISSION),
    case lists:keyfind(Entry, #bg_act_config_info.sort, BgInfo#r_bg_act.config_list) of
        false ->
            ?THROW_ERR(?ERROR_BG_ACT_REWARD_003);
        #bg_act_config_info{items = Items, condition = NeedMoney} ->
            ?IF(NeedMoney =< RoleActMission#r_role_bg_mission.money, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
            ?IF(lists:member(Entry, RoleActMission#r_role_bg_mission.reward_list), ?THROW_ERR(?ERROR_BG_ACT_REWARD_002), ok),
            GoodsList = [#p_goods{type_id = TypeID, num = Num, bind = Bind} || {TypeID, Num, Bind, _} <- Items],
            GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_MISSION, Entry),
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_ACT_ENTRY_REWARD, GoodsList}],
            RoleActMission2 = RoleActMission#r_role_bg_mission{reward_list = [Entry|RoleActMission#r_role_bg_mission.reward_list]},
            {ok, BagDoings, State#r_role{role_bg_act_mission = RoleActMission2}}
    end.



add_schedule_mission(#r_role{role_bg_act_mission = RoleActMission, role_id = RoleID} = State, Type, AddNumber) ->
    {NewMissionList, AddMoney, UpdateList} = add_schedule_mission_i(RoleActMission#r_role_bg_mission.mission_list, Type, 0, AddNumber, [], []),
    NewMoney = AddMoney + RoleActMission#r_role_bg_mission.money,
    RoleActMission2 = RoleActMission#r_role_bg_mission{money = NewMoney, mission_list = NewMissionList},
    ?IF(AddMoney =/= 0, common_misc:unicast(RoleID, #m_bg_mission_update_toc{money = NewMoney, list = UpdateList}), ok),
    State#r_role{role_bg_act_mission = RoleActMission2}.


add_schedule_mission_i([], _Type, AddMoney, _AddNumber, NewList, UpdateList) ->
    {NewList, AddMoney, UpdateList};
add_schedule_mission_i([#bg_act_mission{type = Type, now_times = NowTimes, all_times = AllTimes} = Mission|T], Type, AddMoney, AddNumber, NewList, UpdateList) ->
    case AllTimes > NowTimes of
        true ->
            NewSchedule = Mission#bg_act_mission.schedule + AddNumber,
            case Mission#bg_act_mission.target =< NewSchedule of
                true ->
                    NewSchedule2 = NewSchedule rem Mission#bg_act_mission.target,
                    AddTimes = NewSchedule div Mission#bg_act_mission.target,
                    NewTimes = NowTimes + AddTimes,
                    case NewTimes > AllTimes of
                        true ->
                            NewTimes2 = AllTimes,
                            NewSchedule3 = 0,
                            AddTimes2 = AllTimes - NowTimes;
                        _ ->
                            NewTimes2 = NewTimes,
                            NewSchedule3 = NewSchedule2,
                            AddTimes2 = AddTimes
                    end,
                    NewMission = Mission#bg_act_mission{now_times = NewTimes2, schedule = NewSchedule3},
                    add_schedule_mission_i(T, Type, AddMoney + Mission#bg_act_mission.reward * AddTimes2, AddNumber, [NewMission|NewList], [#p_kv{id = Mission#bg_act_mission.sort, val = NewTimes}|UpdateList]);
                _ ->
                    NewMission = Mission#bg_act_mission{schedule = NewSchedule},
                    add_schedule_mission_i(T, Type, AddMoney, AddNumber, [NewMission|NewList], UpdateList)
            end;
        _ ->
            add_schedule_mission_i(T, Type, AddMoney, AddNumber, [Mission|NewList], UpdateList)
    end;
add_schedule_mission_i([Mission|T], Type, AddMoney, AddNumber, NewList, UpdateList) ->
    add_schedule_mission_i(T, Type, AddMoney, AddNumber, [Mission|NewList], UpdateList).


recharge(State, Num) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RECHARGE, Num);
        _ ->
            State
    end.


kill_boss(TypeID, State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
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
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
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
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_EQUIP_TREASURE, AddTimes);
        _ ->
            State
    end.

rune_treasure(State, AddTimes) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RUNE_TREASURE, AddTimes);
        _ ->
            State
    end.


bless_treasure(State, Times) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_BLESS, Times);
        _ ->
            State
    end.

daily_mission_treasure(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_DAILY, 1);
        _ ->
            State
    end.

copy_yard(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_YARD, 1);
        _ ->
            State
    end.

copy_ruins(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_RUINS, 1);
        _ ->
            State
    end.

copy_vault(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_VAULT, 1);
        _ ->
            State
    end.

copy_forest(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_FOREST, 1);
        _ ->
            State
    end.

battle(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_BATTLE, 1);
        _ ->
            State
    end.

solo(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_SOLE, 1);
        _ ->
            State
    end.

summit_tower(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_SUMMIT_TOWER, 1);
        _ ->
            State
    end.

trevi_fountain(State, Times) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_TREVI_FOUNTAIN, Times);
        _ ->
            State
    end.

copy_equip(State) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_MISSION, State) of
        true ->
            add_schedule_mission(State, ?BG_MISSION_EQUIP_COPY, 1);
        _ ->
            State
    end.

