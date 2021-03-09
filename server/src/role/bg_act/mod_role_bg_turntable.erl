%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 四月 2019 14:52
%%%-------------------------------------------------------------------
-module(mod_role_bg_turntable).
-author("WZP").

-include("role.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_bg_act.hrl").
-include("proto/mod_role_bg_turntable.hrl").
%% API
-export([
    init/1,
    handle/2,
    loop_min/2,
    day_reset/1
]).

%%  test
-export([
    do_task/3,
    gm_add_draw_times/3
]).

-export([
    init_recharge_turntable/3,
    check_can_get_reward_b/2,
    check_can_get_reward_a/2,
    init_active_turntable/3,
    online_action_b/2,
    online_action_a/2,
    add_liveness/2,
    recharge/2
]).

gm_add_draw_times(#r_role{role_bg_turntable = RoleTurnTable} = State, Type, Times) ->
    case Type =:= ?BG_ACT_RECHARGE_TURNTABLE of
        true ->
            RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{draw_times_b = Times},
            State2 = State#r_role{role_bg_turntable = RoleTurnTable2},
            online_action_b(world_bg_act_server:get_bg_act(?BG_ACT_RECHARGE_TURNTABLE), State2),
            State2;
        _ ->
            RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{draw_times_a = Times, reward_a = []},
            State2 = State#r_role{role_bg_turntable = RoleTurnTable2},
            online_action_a(world_bg_act_server:get_bg_act(?BG_ACT_ACTIVE_TURNTABLE), State2),
            State2
    end.


init(#r_role{role_bg_turntable = undefined, role_id = RoleID} = State) ->
    RoleTurnTable = #r_role_bg_turntable{role_id = RoleID},
    State#r_role{role_bg_turntable = RoleTurnTable};
init(State) ->
    State.

online_action_a(Info, #r_role{role_bg_turntable = RoleTurnTable, role_private_attr = RolePrivateAttr, role_id = RoleID} = State) ->
    Liveness = mod_role_daily_liveness:get_daily_liveness(State),
    PInfo = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    EntryList = lists:foldl(
        fun(EntryInfo, AccList) ->
            #bg_act_config_info{title = Title, condition = Condition, sort = Sort, items = Times} = EntryInfo,
            case lists:keyfind(Sort, #bg_active_turntable_mission.id, RoleTurnTable#r_role_bg_turntable.mission_a) of
                false ->
                    AccList;
                #bg_active_turntable_mission{status = Status, type = Type} ->
                    case Status =:= ?ACT_REWARD_CANNOT_GET of
                        false ->
                            Condition2 = ?IF(Type =:= ?BG_ATURNTABLE_MISSION_TWO, Condition div 60, Condition),
                            [#p_bg_act_entry{sort = Sort, title = Title, status = Status, schedule = Condition2, num = Times, target = Condition2}|AccList];
                        _ ->
                            case Type of
                                ?BG_ATURNTABLE_MISSION_ONE ->
                                    Condition2 = Condition,
                                    Schedule = Condition;
                                ?BG_ATURNTABLE_MISSION_TWO ->
                                    Condition2 = Condition div 60,
                                    Schedule = RolePrivateAttr#r_role_private_attr.today_online_time div 60;
                                _ ->
                                    Condition2 = Condition,
                                    Schedule = Liveness
                            end,
                            [#p_bg_act_entry{sort = Sort, title = Title, status = Status, schedule = Schedule, num = Times, target = Condition2}|AccList]
                    end
            end
        end,
        [], Info#r_bg_act.config_list),
    PInfo2 = PInfo#p_bg_act{entry_list = EntryList},
    Rewards = [#p_item_i{type_id = TypeID, num = Num, is_bind = Bind, special_effect = Special} || {TypeID, Num, Bind, Special} <- proplists:get_value(reward, Info#r_bg_act.config)],
    GotReward = [#p_item_i{type_id = TypeID, num = Num, is_bind = Bind, special_effect = Special}
                 || {Sort, {_, {TypeID, Num, Bind, Special}}} <- proplists:get_value(reward_weight, Info#r_bg_act.config), lists:member(Sort, RoleTurnTable#r_role_bg_turntable.reward_a)],
    common_misc:unicast(RoleID, #m_bg_task_turntable_toc{info = PInfo2, times = RoleTurnTable#r_role_bg_turntable.draw_times_a, reward = Rewards, got_reward = GotReward}),
    ok.

online_action_b(Info, #r_role{role_bg_turntable = RoleTurnTable} = State) ->
    PInfo = bg_act_misc:trans_r_bg_act_to_p_bg_act_without_config_list(Info),
    EntryList = [begin
                     #bg_act_config_info{title = Title, condition = Condition, sort = Sort, items = Times} = EntryInfo,
                     Status = case lists:keyfind(Condition, #p_kv.id, RoleTurnTable#r_role_bg_turntable.mission_b) of
                                  false ->
                                      ?ACT_REWARD_CANNOT_GET;
                                  #p_kv{val = Val} ->
                                      Val
                              end,
                     Schedule = ?IF(Condition >= RoleTurnTable#r_role_bg_turntable.recharge_num, RoleTurnTable#r_role_bg_turntable.recharge_num, Condition),
                     #p_bg_act_entry{sort = Sort, title = Title, status = Status, schedule = Schedule, num = Times, target = Condition}
                 end || EntryInfo <- Info#r_bg_act.config_list],
    PInfo2 = PInfo#p_bg_act{entry_list = EntryList},
    Numbers = proplists:get_value(numbers, Info#r_bg_act.config),
    Rates = proplists:get_value(rate, Info#r_bg_act.config),
    common_misc:unicast(State#r_role.role_id, #m_bg_recharge_turntable_toc{info = PInfo2, gold = Numbers, rate = Rates, recharge = RoleTurnTable#r_role_bg_turntable.recharge_num,
                                                                           times = RoleTurnTable#r_role_bg_turntable.draw_times_b}),
    ok.


init_active_turntable(#r_role{role_bg_turntable = RoleTurnTable} = State, ConfigList, EditTime) ->
    Liveness = mod_role_daily_liveness:get_daily_liveness(State),
    Mission = [
        begin
            Status = if
                         Type =:= ?BG_ATURNTABLE_MISSION_ONE -> ?ACT_REWARD_CAN_GET;
                         Type =:= ?BG_ATURNTABLE_MISSION_THREE ->
                             ?IF(Liveness >= Condition, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET);
                         true ->
                             ?ACT_REWARD_CANNOT_GET
                     end,
            #bg_active_turntable_mission{id = Sort, type = Type, param = Condition, status = Status}
        end
        || #bg_act_config_info{condition = Condition, status = Type, sort = Sort} <- ConfigList],
    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{edit_time_a = EditTime, mission_a = Mission, draw_times_a = 0, reward_a = [], online_time = 0},
    State#r_role{role_bg_turntable = RoleTurnTable2}.


init_recharge_turntable(#r_role{role_bg_turntable = RoleTurnTable} = State, ConfigList, EditTime) ->
    Mission = [#p_kv{id = Condition, val = ?ACT_REWARD_CANNOT_GET} || #bg_act_config_info{condition = Condition} <- ConfigList],
    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{edit_time_b = EditTime, mission_b = Mission, draw_times_b = 0, recharge_num = 0},
    State#r_role{role_bg_turntable = RoleTurnTable2}.


day_reset(#r_role{role_bg_turntable = RoleTurnTable} = State) ->
    case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_ACTIVE_TURNTABLE, State) of
        #r_bg_act{config_list = ConfigList} ->
            case lists:keytake(?BG_ATURNTABLE_MISSION_ONE, #bg_active_turntable_mission.type, RoleTurnTable#r_role_bg_turntable.mission_a) of
                {value, Mission, Other} ->
                    case lists:keyfind(Mission#bg_active_turntable_mission.id, #bg_act_config_info.sort, ConfigList) of
                        #bg_act_config_info{title = Title, condition = Condition, sort = Sort, items = Times} ->
                            PInfo = #p_bg_act_entry{sort = Sort, title = Title, status = ?ACT_REWARD_CAN_GET, schedule = Condition, num = Times, target = Condition},
                            common_misc:unicast(State#r_role.role_id, #m_bg_act_entry_update_toc{id = ?BG_ACT_ACTIVE_TURNTABLE, update_list = [PInfo]});
                        _ ->
                            ok
                    end,
                    NewMissions = [Mission#bg_active_turntable_mission{status = ?ACT_REWARD_CAN_GET}|Other],
                    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{mission_a = NewMissions},
                    State#r_role{role_bg_turntable = RoleTurnTable2};
                _ ->
                    State
            end;
        _ ->
            State
    end.

loop_min(_Now, #r_role{role_private_attr = RolePrivateAttr} = State) ->
    do_task(State, ?BG_ATURNTABLE_MISSION_TWO, RolePrivateAttr#r_role_private_attr.today_online_time).
add_liveness(State, Param) ->
    do_task(State, ?BG_ATURNTABLE_MISSION_THREE, Param).


do_task(#r_role{role_bg_turntable = RoleTurnTable, role_id = RoleID} = State, Type, Param) ->
    case mod_role_bg_act:is_bg_act_open_i(?BG_ACT_ACTIVE_TURNTABLE, State) of
        #r_bg_act{config_list = ConfigList} ->
            {NewMission, UpdateMission} = do_task_i(Type, Param, RoleTurnTable#r_role_bg_turntable.mission_a, [], [], ConfigList),
            ?IF(UpdateMission =:= [], ok, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{id = ?BG_ACT_ACTIVE_TURNTABLE, update_list = UpdateMission})),
            RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{mission_a = NewMission},
            State#r_role{role_bg_turntable = RoleTurnTable2};
        _ ->
            State
    end.


do_task_i(_Type, _Param, [], MissionList, UpdateList, _ConfigList) ->
    {MissionList, UpdateList};
do_task_i(Type, Param, [Mission|T], MissionList, UpdateList, ConfigList) ->
    case Mission#bg_active_turntable_mission.status =:= ?ACT_REWARD_CANNOT_GET andalso Mission#bg_active_turntable_mission.type =:= Type of
        false ->
            do_task_i(Type, Param, T, [Mission|MissionList], UpdateList, ConfigList);
        _ ->
            case lists:keyfind(Mission#bg_active_turntable_mission.id, #bg_act_config_info.sort, ConfigList) of
                false ->
                    do_task_i(Type, Param, T, [Mission|MissionList], UpdateList, ConfigList);
                #bg_act_config_info{title = Title, condition = Condition, sort = Sort, items = Times} ->
                    case Param >= Mission#bg_active_turntable_mission.param of
                        false ->
                            case Type =:= ?BG_ATURNTABLE_MISSION_TWO of
                                true ->
                                    Param2 = Param div 60, Condition2 = Condition div 60;
                                _ ->
                                    Param2 = Param, Condition2 = Condition
                            end,
                            PInfo = #p_bg_act_entry{sort = Sort, title = Title, status = ?ACT_REWARD_CANNOT_GET, schedule = Param2, num = Times, target = Condition2},
                            do_task_i(Type, Param, T, [Mission|MissionList], [PInfo|UpdateList], ConfigList);
                        _ ->
                            Condition2 = ?IF(Type =:= ?BG_ATURNTABLE_MISSION_TWO, Condition div 60, Condition),
                            PInfo = #p_bg_act_entry{sort = Sort, title = Title, status = ?ACT_REWARD_CAN_GET, schedule = Condition2, num = Times, target = Condition2},
                            do_task_i(Type, Param, T, [Mission#bg_active_turntable_mission{status = ?ACT_REWARD_CAN_GET}|MissionList], [PInfo|UpdateList], ConfigList)
                    end
            end
    end.

recharge(#r_role{role_bg_turntable = RoleTurnTable, role_id = RoleID} = State, PayGold) ->
    NewRecharge = PayGold + RoleTurnTable#r_role_bg_turntable.recharge_num,
    BgAct = world_bg_act_server:get_bg_act(?BG_ACT_RECHARGE_TURNTABLE),
    {NewMission, UpdateMission} = recharge_i(NewRecharge, RoleTurnTable#r_role_bg_turntable.mission_b, BgAct#r_bg_act.config_list, [], []),
    ?IF(UpdateMission =:= [], ok, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{id = ?BG_ACT_RECHARGE_TURNTABLE, update_list = UpdateMission})),
    common_misc:unicast(RoleID, #m_bg_act_update_a_toc{id = ?BG_ACT_RECHARGE_TURNTABLE, val = NewRecharge}),
    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{recharge_num = NewRecharge, mission_b = NewMission},
    State#r_role{role_bg_turntable = RoleTurnTable2}.

recharge_i(_NewRecharge, [], _, MissionList, UpdateList) ->
    {MissionList, UpdateList};
recharge_i(NewRecharge, [Mission|T], EntryList, MissionList, UpdateList) ->
    case Mission#p_kv.val =:= ?ACT_REWARD_CANNOT_GET andalso NewRecharge >= Mission#p_kv.id of
        true ->
            case lists:keyfind(Mission#p_kv.id, #bg_act_config_info.condition, EntryList) of
                false ->
                    recharge_i(NewRecharge, T, EntryList, [Mission|MissionList], UpdateList);
                #bg_act_config_info{title = Title, condition = Condition, sort = Sort, items = Times} ->
                    Schedule = ?IF(Condition >= NewRecharge, NewRecharge, Condition),
                    PInfo = #p_bg_act_entry{sort = Sort, title = Title, status = ?ACT_REWARD_CAN_GET, schedule = Schedule, num = Times, target = Condition},
                    recharge_i(NewRecharge, T, EntryList, [Mission#p_kv{val = ?ACT_REWARD_CAN_GET}|MissionList], [PInfo|UpdateList])
            end;
        _ ->
            recharge_i(NewRecharge, T, EntryList, [Mission|MissionList], UpdateList)
    end.

handle({#m_bg_tturntable_draw_tos{}, RoleID, _PID}, State) ->
    do_tturntable_draw(RoleID, State);
handle({#m_bg_rturntable_draw_tos{}, RoleID, _PID}, State) ->
    do_rturntable_draw(RoleID, State).


do_rturntable_draw(RoleID, State) ->
    case catch check_can_rturntable_draw(State) of
        {ok, State2, AssetDoing, Rate, Gold} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            common_misc:unicast(RoleID, #m_bg_rturntable_draw_toc{rate = Rate, gold = Gold}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bg_rturntable_draw_toc{err_code = ErrCode}),
            State
    end.

check_can_rturntable_draw(#r_role{role_bg_turntable = RoleTurnTable} = State) ->
    Res = mod_role_bg_act:is_bg_act_open_i(?BG_ACT_RECHARGE_TURNTABLE, State),
    ?IF(Res =:= false, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START), ok),
    ?IF(RoleTurnTable#r_role_bg_turntable.draw_times_b > 0, ok, ?THROW_ERR(?ERROR_BG_RTURNTABLE_DRAW_001)),
    #r_bg_act{config = Config} = Res,
    NumbersWeight = proplists:get_value(numbers_weight, Config),
    RateWeight = proplists:get_value(rate_weight, Config),
    Number = lib_tool:get_weight_output(NumbersWeight),
    Rate = lib_tool:get_weight_output(RateWeight),
    AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_BG_TURNTABLE, 0, Number * Rate}],
    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{draw_times_b = RoleTurnTable#r_role_bg_turntable.draw_times_b - 1},
    {ok, State#r_role{role_bg_turntable = RoleTurnTable2}, AssetDoing, Rate, Number}.

check_can_get_reward_b(State, Entry) ->
    #r_role{role_bg_turntable = RoleTurnTable} = State,
    #r_role_bg_turntable{mission_b = Mission} = RoleTurnTable,
    #r_bg_act{config_list = ConfigList} = world_bg_act_server:get_bg_act(?BG_ACT_RECHARGE_TURNTABLE),
    case lists:keyfind(Entry, #bg_act_config_info.sort, ConfigList) of
        false ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR);
        #bg_act_config_info{items = AddTimes, condition = Condition} ->
            {value, #p_kv{val = Val}, Other} = lists:keytake(Condition, #p_kv.id, Mission),
            ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
            NewMission = [#p_kv{id = Condition, val = ?ACT_REWARD_GOT}|Other],
            RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{mission_b = NewMission, draw_times_b = AddTimes + RoleTurnTable#r_role_bg_turntable.draw_times_b},
            State2 = State#r_role{role_bg_turntable = RoleTurnTable2},
            {num, State2, RoleTurnTable2#r_role_bg_turntable.draw_times_b}
    end.


check_can_get_reward_a(State, Entry) ->
    #r_role{role_bg_turntable = RoleTurnTable} = State,
    #r_role_bg_turntable{mission_a = Mission} = RoleTurnTable,
    #r_bg_act{config_list = ConfigList} = world_bg_act_server:get_bg_act(?BG_ACT_ACTIVE_TURNTABLE),
    case lists:keyfind(Entry, #bg_act_config_info.sort, ConfigList) of
        false ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR);
        #bg_act_config_info{items = AddTimes, sort = Sort} ->
            {value, #bg_active_turntable_mission{status = Val, type = Type, param = Param}, Other} = lists:keytake(Sort, #bg_active_turntable_mission.id, Mission),
            ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
            NewMission = [#bg_active_turntable_mission{id = Sort, status = ?ACT_REWARD_GOT, type = Type, param = Param}|Other],
            RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{mission_a = NewMission, draw_times_a = AddTimes + RoleTurnTable#r_role_bg_turntable.draw_times_a},
            State2 = State#r_role{role_bg_turntable = RoleTurnTable2},
            {num, State2, RoleTurnTable2#r_role_bg_turntable.draw_times_a}
    end.


do_tturntable_draw(RoleID, State) ->
    case catch check_can_tturntable_draw(State) of
        {ok, State2, Reward, BagDoing} ->
            State3 = mod_role_bag:do(BagDoing, State2),
            common_misc:unicast(RoleID, #m_bg_tturntable_draw_toc{reward = Reward}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_bg_tturntable_draw_toc{err_code = ErrCode}),
            State
    end.


check_can_tturntable_draw(#r_role{role_bg_turntable = RoleTurnTable} = State) ->
    Res = mod_role_bg_act:is_bg_act_open_i(?BG_ACT_ACTIVE_TURNTABLE, State),
    ?IF(Res =:= false, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START), ok),
    ?IF(RoleTurnTable#r_role_bg_turntable.draw_times_a > 0, ok, ?THROW_ERR(?ERROR_BG_TTURNTABLE_DRAW_001)),
    #r_bg_act{config = Config} = Res,
    RewardWeight = proplists:get_value(reward_weight, Config),
    RewardWeight2 = get_reward(RewardWeight, RoleTurnTable#r_role_bg_turntable.reward_a, []),
    ?IF(RewardWeight2 =:= [], ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR), ok),
    {Sort, {TypeID, Num, Bind, Special}} = lib_tool:get_weight_output(RewardWeight2),
    GoodList = [#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(Bind)}],
    mod_role_bag:check_bag_empty_grid(GoodList, State),
    BagDoing = [{create, ?ITEM_GAIN_BG_ACTIVE_TURNTABLE, GoodList}],
    RoleTurnTable2 = RoleTurnTable#r_role_bg_turntable{draw_times_a = RoleTurnTable#r_role_bg_turntable.draw_times_a - 1, reward_a = [Sort|RoleTurnTable#r_role_bg_turntable.reward_a]},
    {ok, State#r_role{role_bg_turntable = RoleTurnTable2}, #p_item_i{type_id = TypeID, num = Num, is_bind = Bind, special_effect = Special}, BagDoing}.


get_reward([], _GotList, List) ->
    List;
get_reward([{Sort, {RewardWeight, Reward}}|T], GotList, List) ->
    case lists:member(Sort, GotList) of
        true ->
            get_reward(T, GotList, List);
        _ ->
            get_reward(T, GotList, [{RewardWeight, {Sort, Reward}}|List])
    end.



