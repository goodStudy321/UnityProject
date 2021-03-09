%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 九月 2019 16:21
%%%-------------------------------------------------------------------
-module(mod_role_cycle_act).
-author("WZP").
-include("proto/mod_role_cycle_act.hrl").
-include("role.hrl").
-include("cycle_act.hrl").
-include("role_extra.hrl").

%% API
-export([
    handle/2,
    is_act_open/2,
    pre_online/1,
    level_up/3
]).

-export([
    is_act_open_i/2
]).


pre_online(State) ->
    RoleLevel = mod_role_data:get_role_level(State),
    AllAct = world_cycle_act_server:get_all_open_act(RoleLevel),
    {State2, SendList} = lists:foldl(
        fun(#r_cycle_act{id = ID, start_time = StartTime, config_num = ConfigNum} = Act, {StateAcc, AccList}) ->
            NeedInit = not check_open_time(ID, StartTime, StateAcc),
            StateAcc2 = if
                            NeedInit ->
                                init_cycle_act(ID, StartTime, ConfigNum, StateAcc);
                            true ->%%上线更新Role活动信息
                                StateAcc
                        end,
            #r_role{role_act_firstpay = FirstPay} = StateAcc2,
            #r_role_act_firstpay{goods_list = GoodsList} = FirstPay,
            case ID =:= ?CYCLE_ACT_CHARGE andalso GoodsList =/= [] of
                true ->
                    {StateAcc2, AccList};
                _ ->
                    {StateAcc2, [world_cycle_act_server:trans_to_p_cycle_act(Act)|AccList]}
            end
        end, {State, []}, AllAct),
    common_misc:unicast(State#r_role.role_id, #m_cycle_act_info_toc{act_list = SendList}),
    State2.



handle({act_update, ID, Status, StartTime, ConfigNum, MinLevel}, State) ->
    case mod_role_data:get_role_level(State) >= MinLevel of
        true ->
            do_act_update(State, ID, Status, StartTime, ConfigNum);
        _ ->
            State

    end.

do_act_update(State, ID, Status, StartTime, ConfigNum) ->
    case Status =:= ?CYCLE_ACT_STATUS_OPEN of
        false ->
            do_act_close(State, ID, StartTime, ConfigNum);
        _ ->
            case check_open_time(ID, StartTime, State) of
                false ->
                    init_cycle_act(ID, StartTime, ConfigNum, State);
                _ ->
                    send_online_info(State, ID)
            end
    end.


%%   检查开启时间以此判断活动是否重新开启
check_open_time(ID, Time, State) ->
    case ID of
        ?CYCLE_ACT_EGG ->
            RoleCycleAct = State#r_role.role_cycle_act_extra,
            Time =:= RoleCycleAct#r_role_cycle_act_extra.start_egg_time;
        ?CYCLE_ACT_DAY_CYCLE ->
            RoleDayBox = State#r_role.role_day_box,
            Time =:= RoleDayBox#r_role_day_box.start_time;
        ?CYCLE_ACT_CHOOSE ->
            case State#r_role.role_choose of
                #r_role_choose_p{open_time = OpenTime} ->
                    OpenTime =:= Time;
                _ ->
                    false
            end;
        ?CYCLE_ACT_LUCKY_TOKEN ->
            RoleLuckyToken = State#r_role.role_act_lucky_token,
            case RoleLuckyToken of
                #r_role_act_lucky_token{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_IDENTIFY_TREASURE ->
            case State#r_role.role_it of
                #r_role_it{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_LUCKY_CAT ->
            RoleLuckyCat = State#r_role.role_act_luckycat,
            case RoleLuckyCat of
                #r_role_act_lukcycat{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_CHARGE ->
            RoleFirstPay = State#r_role.role_act_firstpay,
            case RoleFirstPay of
                #r_role_act_firstpay{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_TRENCH_CEREMONY ->
            RoleActTrenchCeremony = mod_role_act_trench_ceremony:get_act_trench_ceremony(State#r_role.role_id, State),
            case RoleActTrenchCeremony of
                #r_act_trench_ceremony{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_TOWER ->
            case mod_role_cycle_act_misc:get_data(?CYCLE_MISC_TOWER, false, State) of
                #r_role_cycle_tower{start_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_RED_PACKET ->
            true;
        ?CYCLE_ACT_ESOTERICA ->
            ActEsoterica = State#r_role.role_act_esoterica,
            case ActEsoterica of
                #r_role_act_esoterica{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_TREASURE_CHEST->
            TreasureChest = State#r_role.role_act_treasure_chest,
            case TreasureChest of
                #r_role_act_treasure_chest{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_MISSION->
            RoleCycleMission = State#r_role.role_cycle_mission,
            case RoleCycleMission of
                #r_role_cycle_mission{start_time  = StartTime} ->
                    Time =:= StartTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_COUPLE ->
            ActCouple = State#r_role.role_cycle_act_couple,
            case ActCouple of
                #r_role_cycle_act_couple{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        ?CYCLE_ACT_LIMITED_PANIC_BUY ->
            RoleLimitedPanicBuy = mod_role_act_os_second:get_act_limited_panic_buy(State#r_role.role_id, State),
            case RoleLimitedPanicBuy of
                #r_role_act_limited_panic_buy{open_time = OpenTime} ->
                    Time =:= OpenTime;
                _ ->
                    false
            end;
        _ ->
            false
    end.

%%   链接到各自活动的数据初始化中
init_cycle_act(ID, StartTime, ConfigNum, State) ->
    case ID of
        ?CYCLE_ACT_EGG ->
            mod_role_cycle_act_extra:init_egg(State, StartTime, ConfigNum);
        ?CYCLE_ACT_CHOOSE ->
            mod_role_act_choose:init_data(StartTime, State);
        ?CYCLE_ACT_LUCKY_TOKEN ->
            mod_role_act_lucky_token:init_data(StartTime, State);
        ?CYCLE_ACT_IDENTIFY_TREASURE ->
            mod_role_act_identify_treasure:init_data(StartTime, State);
        ?CYCLE_ACT_LUCKY_CAT ->
            mod_role_act_lucky_cat:init_data(StartTime, State);
        ?CYCLE_ACT_CHARGE ->
            mod_role_act_pay:init_data(StartTime, State);
        ?CYCLE_ACT_TRENCH_CEREMONY ->
            mod_role_act_trench_ceremony:init_data(StartTime, State);
        ?CYCLE_ACT_DAY_CYCLE ->
            mod_role_day_box:init_data(State, StartTime);
        ?CYCLE_ACT_TOWER ->
            mod_role_cycle_act_misc:init_tower_data(State, StartTime);
        ?CYCLE_ACT_ESOTERICA ->
            mod_role_act_esoterica:init_data(StartTime, State);
        ?CYCLE_ACT_TREASURE_CHEST ->
            mod_role_act_treasure_chest:init_data(StartTime, State);
        ?CYCLE_ACT_MISSION ->
            mod_role_cycle_mission:init_mission(State,ConfigNum,StartTime);
        ?CYCLE_ACT_COUPLE ->
            mod_role_cycle_act_couple:init_data(StartTime, State);
        ?CYCLE_ACT_LIMITED_PANIC_BUY ->
            mod_role_act_os_second:init_data(StartTime, State);
        _ ->
            State
    end.


is_act_open(ID, State) ->
    [#c_cycle_act{level = MinLevel}] = world_cycle_act_server:get_act_config(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            world_cycle_act_server:is_act_open(ID)
    end.

is_act_open_i(ID, State) ->
    [#c_cycle_act{level = MinLevel}] = world_cycle_act_server:get_act_config(ID),
    case mod_role_data:get_role_level(State) >= MinLevel of
        false ->
            false;
        _ ->
            #r_cycle_act{status = Status, config_num = ConfigNum} = world_cycle_act_server:get_act(ID),
            case Status =:= ?CYCLE_ACT_STATUS_OPEN of
                true ->
                    {ok, ConfigNum};
                _ ->
                    false
            end
    end.



level_up(OldLevel, NewLevel, State) ->
    RoleID = State#r_role.role_id,
    lists:foldl(fun(Act, StateAcc) ->
        #r_cycle_act{id = ID, status = Status} = Act,
        case Status =:= ?CYCLE_ACT_STATUS_OPEN of
            true ->
                [#c_cycle_act{level = MinLevel}] = world_cycle_act_server:get_act_config(ID),
                if
                    MinLevel =< NewLevel ->
                        StateAcc2 = do_act_level_up(StateAcc, ID, MinLevel, OldLevel, NewLevel),
                        if
                            OldLevel < MinLevel ->
                                common_misc:unicast(RoleID, #m_cycle_update_toc{act = world_cycle_act_server:trans_to_p_cycle_act(Act)}),
                                do_act_update(StateAcc, ID, Status, Act#r_cycle_act.start_time, Act#r_cycle_act.config_num);
                            true ->
                                StateAcc2
                        end;
                    true ->
                        StateAcc
                end;
            _ ->
                StateAcc
        end
                end, State, world_cycle_act_server:get_all_act()).



send_online_info(State, ID) ->
    case ID of
        ?CYCLE_ACT_EGG ->
            mod_role_cycle_act_extra:online(State);
        ?CYCLE_ACT_DAY_CYCLE ->
            mod_role_day_box:online(State);
        ?CYCLE_ACT_CHOOSE ->
            mod_role_act_choose:do_choose_count(State);
        ?CYCLE_ACT_LUCKY_TOKEN ->
            mod_role_act_lucky_token:online(State);
        ?CYCLE_ACT_IDENTIFY_TREASURE ->
            mod_role_act_identify_treasure:do_it_info(State#r_role.role_id, State);
        ?CYCLE_ACT_LUCKY_CAT ->
            mod_role_act_lucky_cat:online(State);
        ?CYCLE_ACT_CHARGE ->
            mod_role_act_pay:online(State);
        ?CYCLE_ACT_TRENCH_CEREMONY ->
            mod_role_act_trench_ceremony:online(State);
        ?CYCLE_ACT_TOWER ->
            mod_role_cycle_act_misc:tower_online(State);
        ?CYCLE_ACT_RED_PACKET ->
            mod_role_act_red_packet:online(State);
        ?CYCLE_ACT_ESOTERICA ->
            mod_role_act_esoterica:online(State);
        ?CYCLE_ACT_TREASURE_CHEST ->
            mod_role_act_treasure_chest:online(State);
        ?CYCLE_ACT_MISSION ->
            mod_role_cycle_mission:online(State);
        ?CYCLE_ACT_COUPLE ->
            mod_role_cycle_act_couple:online(State);
        ?CYCLE_ACT_LIMITED_PANIC_BUY ->
            mod_role_act_os_second:online_panic_buy(State);
        _ ->
            State
    end.

%%活动关闭
do_act_close(State, ID, _StartTime, _ConfigNum) ->
    case ID of
        ?CYCLE_ACT_EGG ->
            mod_role_cycle_act_extra:do_egg_end(State);
%%        ?CYCLE_ACT_DAY_CYCLE ->
%%            mod_role_day_box:act_close(State, ConfigNum);
        ?CYCLE_ACT_ESOTERICA ->
            mod_role_act_esoterica:do_egg_end(State);
        ?CYCLE_ACT_TREASURE_CHEST ->
            mod_role_act_treasure_chest:do_chest_end(State);
        _ ->
            State
    end.


%%各个活动升级所需
do_act_level_up(StateAcc, _ID, _MinLevel, _OldLevel, _NewLevel) ->
    StateAcc.