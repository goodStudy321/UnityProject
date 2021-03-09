%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 五月 2018 15:43
%%%-------------------------------------------------------------------
-module(mod_role_act).
-author("laijichang").
-include("role.hrl").
-include("act.hrl").
-include("role_extra.hrl").
-include("proto/mod_role_act.hrl").

%% API
-export([
    pre_online/1,
    handle/2,
    level_up/3,
    level_up2/3,
    get_days_time/2
]).

-export([
    is_act_open/2,
    is_act_open2/2,
    is_act_open3/2
]).


-export([
    gm_set_game_channel_id/2
]).

pre_online(State) ->
    RoleLevel = mod_role_data:get_role_level(State),
    Now = time_tool:now(),
    ActivityList = [Act || #r_act{id = ID, status = Status, is_visible = IsVisible} = Act <- world_act_server:get_all_act(), ID =/= ?ACT_FAIRY, Status =:= ?ACT_STATUS_OPEN orelse IsVisible],
    {State2, SendList} = lists:foldl(
        fun(#r_act{id = ID, start_time = StartDate} = Act, {StateAcc, AccList}) ->
            [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(ID),
            case RoleLevel >= MinLevel of
                true ->
                    NeedInit = check_need_init(State, StartDate, ID),
                    StateAcc2 = if
                                    NeedInit ->
                                        init_act(ID, StartDate, StateAcc);
                                    true ->%%上线更新Role活动信息
                                        StateAcc
                                end,
                    {StateAcc2, [world_act_server:trans_to_p_act(Act)|AccList]};
                _ ->
                    {StateAcc, AccList}
            end
        end, {State, []}, ActivityList),
    %% 某些活动另外处理（1003，1022，1036）
    SendList2 = lists:foldl(
        fun(ID, AccList) ->
            [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(ID),
            case RoleLevel >= MinLevel of
                true ->
                    {StartTime, EndTime} = get_time(ID, State),
                    case Now >= StartTime andalso Now =< EndTime of
                        true ->
                            PAct = #p_act{id = ID, val = ?ACT_STATUS_OPEN, is_visible = true, start_time = StartTime, end_time = EndTime, start_date = StartTime,
                                end_date = EndTime},
                            [PAct | AccList];
                        _ ->
                            AccList
                    end;
                _ ->
                    AccList
            end
        end, SendList, ?ID_LIST),
    common_misc:unicast(State#r_role.role_id, #m_act_info_toc{act_list = SendList2}),
    State2.

handle({act_update, ID, Status, StartDate}, State) ->
    do_act_update(State, ID, Status, StartDate).

level_up(OldLevel, NewLevel, State) ->
    RoleID = State#r_role.role_id,
    lists:foldl(
        fun(Act, StateAcc) ->
            #r_act{id = ID, status = Status, is_visible = IsVisible, start_date = StartDate} = Act,
            case Status =:= ?ACT_STATUS_OPEN orelse IsVisible of
                true ->
                    [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(ID),
                    if
                        MinLevel =< NewLevel ->
                            StateAcc2 = do_act_level_up(StateAcc, ID, MinLevel, OldLevel, NewLevel),
                            if
                                OldLevel < MinLevel andalso ID =/= ?ACT_FAIRY ->
                                    common_misc:unicast(RoleID, #m_act_update_toc{act = world_act_server:trans_to_p_act(Act)}),
                                    do_act_update(StateAcc2, ID, Status, StartDate);
                                true ->
                                    StateAcc2
                            end;
                        true ->
                            StateAcc
                    end;
                _ ->
                    StateAcc
            end
        end, State, world_act_server:get_all_act()).

%% 某些活动另外处理（1003，1022，1036）
is_act_open2(ID, State) ->
    [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            is_act_open3(ID, State)
    end.

is_act_open3(ID, State) ->
    [#c_act{game_channel_list = GameChannelList}] = world_act_server:get_act_config(ID),
    Now = time_tool:now(),
    RoleID = State#r_role.role_id,
    ID2 = case GameChannelList =:= [] of
              true ->
                  ID;
              _ ->
                  lib_tool:to_integer(lib_tool:to_list(ID) ++ lib_tool:to_list(State#r_role.role_attr#r_role_attr.game_channel_id))
          end,
    {StartTime, EndTime} = get_time(ID2, State),
    case Now >= StartTime andalso Now =< EndTime of
        true ->
            PAct = #p_act{id = ID, val = ?ACT_STATUS_OPEN, is_visible = true, start_time = StartTime, end_time = EndTime, start_date = StartTime,
                end_date = EndTime},
            common_misc:unicast(RoleID, #m_act_update_toc{act = PAct}),
            true;
        _ ->
            PAct = #p_act{id = ID, val = ?ACT_STATUS_CLOSE, is_visible = false, start_time = StartTime, end_time = EndTime, start_date = StartTime,
                end_date = EndTime},
            common_misc:unicast(RoleID, #m_act_update_toc{act = PAct}),
            false
    end.

%% 某些活动另外处理（1003，1022，1036）
level_up2(OldLevel, NewLevel, State) ->
    Now = time_tool:now(),
    RoleID = State#r_role.role_id,
    lists:foldl(
        fun(ID, StateAcc) ->
            [#c_act{min_level = MinLevel}] = world_act_server:get_act_config(ID),
            {StartTime, EndTime} = get_time(ID, State),
            case Now >= StartTime andalso Now =< EndTime of
                true ->
                    if
                        MinLevel =< NewLevel ->
                            StateAcc2 = do_act_level_up(StateAcc, ID, MinLevel, OldLevel, NewLevel),
                            if
                                OldLevel < MinLevel andalso ID =/= ?ACT_FAIRY ->
                                    PAct = #p_act{id = ID, val = ?ACT_STATUS_OPEN, is_visible = true, start_time = StartTime, end_time = EndTime, start_date = StartTime,
                                        end_date = EndTime},
                                    common_misc:unicast(RoleID, #m_act_update_toc{act = PAct}),
                                    do_act_update(StateAcc2, ID, ?ACT_STATUS_OPEN, StartTime);
                                true ->
                                    StateAcc2
                            end;
                        true ->
                            StateAcc
                    end;
                _ ->
                    StateAcc
            end
        end, State, ?ID_LIST).

get_time(ID, State) ->
    #r_role{role_private_attr = RolePrivateAttr} = State,
    #r_role_private_attr{create_time = CreateTime} = RolePrivateAttr,
    [#c_act{create_args = CreateArgs, terminate_args = TerminateArgs}] = world_act_server:get_act_config(ID),
    StartTime = get_days_time(CreateArgs, CreateTime),
    EndTime = get_days_time(TerminateArgs + 1, CreateTime) - 1,
    {StartTime, EndTime}.

get_days_time(Day, CreateTime) ->
    case Day of
        0 ->
            0;
        _ ->
            Time = CreateTime + (Day - 1) * ?ONE_DAY,
            time_tool:midnight(Time)
    end.

%%do_act_update(State, ?ACT_FAIRY, {Status, MinLevel, GameChannelID}) ->
%%    case ?ACT_STATUS_CLOSE =:= Status of
%%        true ->
%%            mod_role_fairy:act_close(State, MinLevel, GameChannelID);
%%        _ ->
%%            mod_role_fairy:act_open(State, MinLevel, GameChannelID)
%%    end;
do_act_update(State, ID, Status, StartDate) ->
    NeedInit = ?IF(Status =:= ?ACT_STATUS_CLOSE, false, check_need_init(State, StartDate, ID)),
    if
        ID =:= ?ACT_LEVEL_ID -> %% 等级ID
            mod_role_act_level:act_update(State);
        ID =:= ?ACT_CLWORD_ID -> %% 等级ID
            State2 = ?IF(NeedInit =:= true, mod_role_act_clword:init_data(State, StartDate), State),
            mod_role_act_hunt_boss:act_update(State2);
        ID =:= ?ACT_DOUBLE_EXP ->
            mod_role_world_level:update_attr(State);
        ID =:= ?ACT_SEVEN_ID ->
            mod_role_act_seven:online(State);
        ID =:= ?ACT_FAMILY_CREATE ->
            mod_role_act_family:online(State);
        ID =:= ?ACT_FAMILY_BATTLE ->
            mod_role_family_bt:system_open_info(State);
        ID =:= ?ACT_LIMITED_TIME_BUY ->
            mod_role_act_limitedtime_buy:system_open_info(State);
        ID =:= ?ACT_HUNT_BOSS_ID ->
            State2 = ?IF(NeedInit =:= true, mod_role_act_hunt_boss:init_data(State, StartDate), State),
            mod_role_act_hunt_boss:act_update(State2);
        ID =:= ?ACT_OSS_WING ->
            mod_role_act_os_second:online(State);
        ID =:= ?ACT_OSS_MAGIC_WEAPON ->
            mod_role_act_os_second:online(State);
        ID =:= ?ACT_OSS_HANDBOOK ->
            mod_role_act_os_second:online(State);
        ID =:= ?ACT_DAYRECHARGE_ID ->
            mod_role_act_dayrecharge:online(State);
        ID =:= ?ACT_OTF ->
            mod_role_act_otf:online(State);
        ID =:= ?ACT_OTF_BIG_GUARD ->
            mod_role_guard:king_guard_online(State);
        ID =:= ?ACT_STORE ->
            State2 = ?IF(NeedInit =:= true, mod_role_act_store:init_data(State, StartDate), State),
            mod_role_act_store:online(State2);
        ID =:= ?ACT_OSS_TREVI_FOUNTAIN ->
            mod_role_act_os_second:online_trevi_fountain(State);
        ID =:= ?ACT_OSS_PANIC_BUY ->
            mod_role_act_os_second:online_panic_buy(State);
        ID =:= ?ACT_OSS_SEVEN ->
            mod_role_act_os_second:online_seven(State);
        ID =:= ?ACT_OSS_WING ->
            mod_role_act_os_second:online_rank(State);
        ID =:= ?ACT_OSS_MAGIC_WEAPON ->
            mod_role_act_os_second:online_rank(State);
        ID =:= ?ACT_OSS_HANDBOOK ->
            mod_role_act_os_second:online_rank(State);
        ID =:= ?ACT_MARRY_THREE_LIFE ->
            mod_role_marry:online(State);
        ID =:= ?ACT_ACCRECHARGE_ID ->
%%            State2 = ?IF(NeedInit =:= true, mod_role_act_accrecharge:init_data(State, StartDate), State),
            mod_role_act_accrecharge:online(State);
        ID =:= ?ACT_DAY_TARGET ->
            mod_role_day_target:online(mod_role_day_target:function_open(State));
        true ->
            State
    end.


check_need_init(State, StartDate, ID) ->
    if
        ID =:= ?ACT_HUNT_BOSS_ID -> %% 等级ID.
            #r_role{role_act_hunt_boss = RoleActHuntBoss} = State,
            RoleActHuntBoss#r_role_act_hunt_boss.start_date =/= StartDate;
        ID =:= ?ACT_CLWORD_ID ->
            #r_role{role_clword = RoleClword} = State,
            RoleClword#r_role_clword.start_date =/= StartDate;
        ID =:= ?ACT_ACCRECHARGE_ID ->
            #r_role{role_act_accrecharge = ActAccRecharge} = State,
            ActAccRecharge#r_role_act_accrecharge.start_time =/= StartDate;
        ID =:= ?ACT_STORE ->
            #r_role{role_act_store = ActStore} = State,
            ActStore#r_role_act_store.start_date =/= StartDate;
        true ->
            false
    end.


init_act(ID, StartTime, State) ->
    if
        ID =:= ?ACT_HUNT_BOSS_ID -> %%
            mod_role_act_hunt_boss:init_data(State, StartTime);
        ID =:= ?ACT_CLWORD_ID ->
            mod_role_act_clword:init_data(State, StartTime);
%%        ID =:= ?ACT_ACCRECHARGE_ID ->
%%            mod_role_act_accrecharge:init_data(State, StartTime);
        ID =:= ?ACT_STORE ->
            mod_role_act_store:init_data(State, StartTime);
        true ->
            State
    end.


is_act_open(ID, State) ->
    [#c_act{min_level = MinLevel, game_channel_list = GameChannelList}] = world_act_server:get_act_config(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            ID2 = case GameChannelList =:= [] of
                      true ->
                          ID;
                      _ ->
                          lib_tool:to_integer(lib_tool:to_list(ID) ++ lib_tool:to_list(State#r_role.role_attr#r_role_attr.game_channel_id))
                  end,
            world_act_server:is_act_open(ID2)
    end.

gm_set_game_channel_id(#r_role{role_attr = RoleAttr} = State, Num) ->
    RoleAttr2 = RoleAttr#r_role_attr{game_channel_id = Num},
    State#r_role{role_attr = RoleAttr2}.


do_act_level_up(State, ID, MinLevel, OldLevel, NewLevel) ->
    if
        ID =:= ?ACT_OTF ->
            mod_role_act_otf:level_up(State, MinLevel, OldLevel, NewLevel);
        true ->
            State
    end.
