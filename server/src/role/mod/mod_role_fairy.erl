%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 六月 2018 10:57
%%%-------------------------------------------------------------------
-module(mod_role_fairy).
-author("WZP").
-include("role.hrl").
-include("fairy.hrl").
-include("act.hrl").
-include("map.hrl").
-include("mission.hrl").
-include("daily_liveness.hrl").
-include("proto/mod_role_fairy.hrl").
-include("proto/mod_role_act.hrl").


%%%% API
%%-export([
%%    online/1,
%%    day_reset/1,
%%    handle/2,
%%    loop/2
%%]).
%%
%%
%%-export([
%%    get_fairy_finish_times/1,
%%    system_open/1,
%%    check_map_lock/1,
%%    act_close/3,
%%    act_open/3
%%]).
%%
%%-export([
%%    gm_reset/1
%%]).
%%
%%
%%gm_reset(State) ->
%%    day_reset(State).
%%
%%
%%online(#r_role{role_fairy = undefined} = State) ->
%%    State;
%%online(#r_role{role_attr = RoleAttr, role_private_attr = PrivateAttr, role_fairy = RoleFairy, role_id = RoleID} = State) ->
%%    #r_role_attr{last_offline_time = LastOfflineTime} = RoleAttr,
%%    #r_role_private_attr{last_login_time = LastLoginTime} = PrivateAttr,
%%    State3 = case ?FAIRY_OFF_LINE_FAIL_TIME < LastLoginTime - LastOfflineTime of
%%                 false ->
%%                     common_misc:unicast(RoleID, #m_fairy_info_toc{times = RoleFairy#r_role_fairy.times, fairy_id = RoleFairy#r_role_fairy.fairy}),
%%                     State;
%%                 _ ->
%%                     common_misc:unicast(RoleID, #m_fairy_info_toc{times = RoleFairy#r_role_fairy.times, fairy_id = ?FAIRY_FAILED}),
%%                     NewRoleFairy = RoleFairy#r_role_fairy{fairy = ?FAIRY_FAILED},
%%                     State2 = State#r_role{role_fairy = NewRoleFairy},
%%                     mod_role_map:remove_map_lock(State2)
%%             end,
%%    send_act_update(State3#r_role.role_fairy#r_role_fairy.double_time, RoleID),
%%    mod_role_mission:condition_update(State3).
%%
%%day_reset(#r_role{role_fairy = undefined} = State) ->
%%    State;
%%day_reset(#r_role{role_id = RoleID, role_fairy = RoleFairy} = State) ->
%%    NewRoleFairy = RoleFairy#r_role_fairy{role_id = RoleID, fairy = ?FAIRY_BEFORE, times = ?FAIRY_TIMES},
%%    common_misc:unicast(RoleID, #m_fairy_info_toc{times = ?FAIRY_TIMES, fairy_id = ?FAIRY_BEFORE}),
%%    State#r_role{role_fairy = NewRoleFairy}.
%%
%%handle({#m_fairy_finish_task_tos{}, RoleID, _PID}, State) ->
%%    do_finish_fairy_task(RoleID, State);
%%handle({#m_fairy_get_task_tos{fairy_id = Fairy}, RoleID, _PID}, State) ->
%%    do_get_fairy_task(RoleID, Fairy, State).
%%
%%
%%get_fairy_finish_times(State) ->
%%    #r_role{role_fairy = RoleFairy} = State,
%%    case RoleFairy of
%%        #r_role_fairy{times = Times} ->
%%            ?FAIRY_TIMES - Times;
%%        _ ->
%%            0
%%    end.
%%
%%
%%system_open(#r_role{role_fairy = undefined, role_id = RoleID} = State) ->
%%    RoleFairy = #r_role_fairy{role_id = RoleID, fairy = ?FAIRY_BEFORE, times = ?FAIRY_TIMES, double_time = time_tool:now() + 1800},
%%    send_act_update(time_tool:now() + 1800, RoleID),
%%    common_misc:unicast(RoleID, #m_fairy_info_toc{times = RoleFairy#r_role_fairy.times, fairy_id = RoleFairy#r_role_fairy.fairy}),
%%    State#r_role{role_fairy = RoleFairy};
%%system_open(State) ->
%%    State.
%%
%%
%%do_get_fairy_task(RoleID, Fairy, State) ->
%%    case catch check_can_get_task(Fairy, State) of
%%        {ok, State2, BagDoings, Times} ->
%%            common_misc:unicast(RoleID, #m_fairy_get_task_toc{times = Times}),
%%            State3 = mod_role_bag:do(BagDoings, State2),
%%            State4 = mod_role_mission:condition_update(State3),
%%            mod_role_map:add_map_lock(State4, ?MAP_FAIRY_LOCK);
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_fairy_get_task_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_can_get_task(Fairy, #r_role{role_fairy = RoleFairy, role_attr = Attr} = State) ->
%%    ?IF(Attr#r_role_attr.level >= ?FAIRY_LEVEL, ok, ?THROW_ERR(?ERROR_FAIRY_GET_TASK_001)),
%%    ?IF(RoleFairy#r_role_fairy.times > 0, ok, ?THROW_ERR(?ERROR_FAIRY_GET_TASK_002)),
%%    ?IF(RoleFairy#r_role_fairy.fairy =:= ?FAIRY_FAILED orelse RoleFairy#r_role_fairy.fairy =:= ?FAIRY_BEFORE, ok, ?THROW_ERR(?ERROR_FAIRY_GET_TASK_003)),
%%    [Config] = lib_config:find(cfg_fairy, Fairy),
%%    NewTimes = RoleFairy#r_role_fairy.times - 1,
%%    RoleFairy2 = RoleFairy#r_role_fairy{times = NewTimes, fairy = Fairy},
%%    [ItemID, ItemNum] = Config#c_fairy.fairy_item_num,
%%    case ItemNum =:= 0 of
%%        true ->
%%            {ok, State#r_role{role_fairy = RoleFairy2}, [], NewTimes};
%%        _ ->
%%            BagDoings = mod_role_bag:check_num_by_type_id(ItemID, ItemNum, ?ITEM_REDUCE_DO_FAIRY, State),
%%            {ok, State#r_role{role_fairy = RoleFairy2}, BagDoings, NewTimes}
%%    end.
%%
%%
%%
%%do_finish_fairy_task(RoleID, State) ->
%%    case catch check_can_finish_task(State) of
%%        {ok, State2, AssetDoing, AddExp, FairyConfig, Attr} ->
%%            %%全体仙灵均广播
%%            common_broadcast:send_world_common_notice(?NOTICE_FAIRY_COMMIT_BEST, [Attr#r_role_attr.role_name, FairyConfig#c_fairy.fairy_name]),
%%            common_misc:unicast(RoleID, #m_fairy_finish_task_toc{}),
%%            State3 = mod_role_asset:do(AssetDoing, State2),
%%            State4 = mod_role_level:do_add_exp(State3, AddExp, ?EXP_ADD_FROM_FAIRLY),
%%            State5 = mod_role_daily_liveness:trigger_daily_liveness(State4, ?LIVENESS_FAIRY),
%%            State6 = mod_role_mission:condition_update(State5),
%%            State7 = mod_role_mission:daily_mission_trigger(?MISSION_TYPE_FAIRY, State6),
%%            State8 = mod_role_achievement:fairy_times(State7),
%%            State9 = mod_role_day_target:fairy_times(State8),
%%            State10 = mod_role_map:remove_map_lock(State9),
%%            hook_role:do_fairy(State10);
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_fairy_finish_task_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_can_finish_task(#r_role{role_fairy = RoleFairy, role_attr = Attr} = State) ->
%%    #r_role_fairy{fairy = Fairy} = RoleFairy,
%%    ?IF(Fairy =:= ?FAIRY_FAILED orelse Fairy =:= ?FAIRY_BEFORE, ?THROW_ERR(?ERROR_FAIRY_FINISH_TASK_002), ok),
%%    [FairyConfig] = lib_config:find(cfg_fairy, Fairy),
%%    [FairyRewardConfig] = lib_config:find(cfg_fairy_reward, Attr#r_role_attr.level),
%%    Rate = get_reward(RoleFairy#r_role_fairy.double_time),
%%    AssetDoing = [{add_silver, ?ASSET_SILVER_ADD_FROM_GM, FairyConfig#c_fairy.silver * Rate}],
%%    AddExp = lib_tool:to_integer(FairyRewardConfig#c_fairy_reward.exp) * FairyConfig#c_fairy.exp_percent * Rate div 10000,
%%    RoleFairy2 = RoleFairy#r_role_fairy{fairy = ?FAIRY_BEFORE},
%%    State2 = State#r_role{role_fairy = RoleFairy2},
%%    {ok, State2, AssetDoing, AddExp, FairyConfig, Attr}.
%%
%%
%%get_reward(Time) ->
%%    case Time >= time_tool:now() of
%%        false ->
%%            #r_act{status = Status} = world_act_server:get_act(?ACT_FAIRY),
%%            ?IF(Status =:= ?ACT_STATUS_OPEN, 2, 1);
%%        _ ->
%%            2
%%    end.
%%
%%
%%check_map_lock(MapID) ->
%%    [Config] = lib_config:find(cfg_global, ?FAIRY_MAP_LOCK_GLOBAL),
%%    case lists:member(MapID, Config#c_global.list) of
%%        true ->
%%            ok;
%%        _ ->
%%            is_lock
%%    end.
%%
%%
%%send_act_update(DoubleTime, RoleID) ->
%%    Act = world_act_server:get_act(?ACT_FAIRY),
%%    #r_act{start_time = StartTime, end_time = EndTime, start_date = StartDate, end_date = EndDate, status = Status} = Act,
%%    Now = time_tool:now(),
%%    if
%%        DoubleTime > Now ->
%%            if
%%                DoubleTime < StartTime -> StartTime2 = DoubleTime - 1800, EndTime2 = DoubleTime;
%%                DoubleTime > EndTime -> StartTime2 = erlang:min(DoubleTime - 1800, StartTime), EndTime2 = DoubleTime;
%%                true ->
%%                    StartTime2 = erlang:min(DoubleTime - 1800, StartTime), EndTime2 = DoubleTime
%%            end,
%%            Record = #m_act_update_toc{act = #p_act{id = ?ACT_FAIRY, val = ?ACT_STATUS_OPEN, is_visible = true, start_time = StartTime2, end_time = EndTime2, start_date = StartDate, end_date = EndDate}},
%%            common_misc:unicast(RoleID, Record);
%%        Status =:= ?ACT_STATUS_OPEN ->
%%            Record = #m_act_update_toc{act = world_act_server:trans_to_p_act(Act)},
%%            common_misc:unicast(RoleID, Record);
%%        true ->
%%            ok
%%    end.
%%
%%loop(_Now, #r_role{role_fairy = undefined} = State) ->
%%    State;
%%loop(Now, #r_role{role_fairy = RoleFairy} = State) ->
%%    case RoleFairy#r_role_fairy.double_time =:= Now andalso not mod_role_act:is_act_open(?ACT_FAIRY, State) of
%%        true ->
%%            Record = #m_act_update_toc{act = #p_act{id = ?ACT_FAIRY, val = ?ACT_STATUS_CLOSE}},
%%            common_misc:unicast(State#r_role.role_id, Record);
%%        _ ->
%%            ok
%%    end,
%%    State.
%%
%%act_close(#r_role{role_fairy = undefined} = State, _MinLevel, _GameChannelID) ->
%%    State;
%%act_close(#r_role{role_fairy = RoleFairy, role_id = RoleID} = State, MinLevel, _GameChannelID) ->
%%    case RoleFairy#r_role_fairy.double_time < time_tool:now() andalso State#r_role.role_attr#r_role_attr.level > MinLevel of
%%        true ->
%%            DataRecord = #m_act_update_toc{act = #p_act{id = ?ACT_FAIRY, val = ?ACT_STATUS_CLOSE}},
%%            common_misc:unicast(RoleID, DataRecord);
%%        _ ->
%%            ok
%%    end,
%%    State.
%%
%%
%%act_open(#r_role{role_fairy = RoleFairy, role_id = RoleID} = State, _MinLevel, _GameChannelID) ->
%%    send_act_update(RoleFairy#r_role_fairy.double_time, RoleID),
%%    State.