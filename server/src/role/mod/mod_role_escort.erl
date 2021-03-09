%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 六月 2019 11:04
%%%-------------------------------------------------------------------
-module(mod_role_escort).
-author("WZP").
-include("role.hrl").
-include("family.hrl").
-include("family_escort.hrl").
-include("activity.hrl").
-include("proto/mod_role_escort.hrl").
-include("proto/mod_role_chat.hrl").
-include("proto/mod_role_family.hrl").
-include("proto/mod_map_actor.hrl").
-include("proto/mod_role_map.hrl").
-include("background.hrl").
%%  ets:fun2ms 必用
%%-include_lib("stdlib/include/ms_transform.hrl").

%% API
-export([
    online/1,
    handle/2,
    day_reset/1,
    loop_10min/2,
    role_enter_map/1
]).

-export([
    gm_reset/2,
    gm_escort/1
]).

-export([
    system_open/1,
    get_escort_finish_times/1,
    get_escort_config_times/0,
    send_online_info/2,
    get_escort_list/7
]).

gm_escort(State) ->
    check_escort_c(State, true).

gm_reset(#r_role{role_id = RoleID} = State, Val) ->
    Mod = family_escort_server:get_escort_server(),
    case Val of
        1 ->
            Data = Mod:get_escort_data(RoleID),
            Data2 = Data#r_role_escort{escort_times = 0, rob_times = 0},
            Mod:set_escort_data(Data2);
        2 ->
            [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
            [FairyTimes, RobTimes|_] = GlobalConfig#c_global.list,
            Data = Mod:get_escort_data(RoleID),
            Data2 = Data#r_role_escort{escort_times = FairyTimes, rob_times = RobTimes},
            Mod:set_escort_data(Data2)
    end,
    online(State),
    State.


loop_10min(_Now, State) ->
    case mod_role_function:get_is_function_open(?FUNCTION_FAIRY, State) of
        true ->
            #r_role_attr{power = Power} = State#r_role.role_attr,
            Mod = family_escort_server:get_escort_server(),
            Mod:info({update_fight, State#r_role.role_id, Power}),
            State;
        _ ->
            State
    end.

online(#r_role{role_id = RoleID, role_attr = RoleAttr} = State) ->
    case mod_role_function:get_is_function_open(?FUNCTION_FAIRY, State) andalso ?HAS_FAMILY(RoleAttr#r_role_attr.family_id) of
        true ->
            case family_escort_server:get_escort_server() of
                family_escort_server ->
                    Data = family_escort_server:get_escort_data(RoleID),
                    send_online_info(Data, RoleID);
                _ ->
                    family_escort_cross_server:role_online(RoleID, mod_role_dict:get_gateway_pid())
            end;
        _ ->
            ok
    end,
    State.

system_open(#r_role{role_id = RoleID, role_attr = RoleAttr} = State) ->
    case ?HAS_FAMILY(RoleAttr#r_role_attr.family_id) of
        true ->
            case family_escort_server:get_escort_server() of
                family_escort_server ->
                    Data = family_escort_server:get_escort_data(RoleID),
                    send_online_info(Data, RoleID),
                    family_escort_server:role_name_update(RoleID, RoleAttr#r_role_attr.role_name);
                _ ->
                    family_escort_cross_server:role_online(RoleID, mod_role_dict:get_gateway_pid(), common_config:get_server_name())
            end;
        _ ->
            ok
    end,
    State.

send_online_info(Data, IDOrGPid) ->
    [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
    [FairyTimes, RobTimes|_] = GlobalConfig#c_global.list,
    common_misc:unicast(IDOrGPid, #m_role_escort_info_toc{escort_times = FairyTimes - Data#r_role_escort.escort_times, rob_times = RobTimes - Data#r_role_escort.rob_times,
                                                          escort_end_time = Data#r_role_escort.end_time, type = Data#r_role_escort.fairy_type,
                                                          rob = ?IF(Data#r_role_escort.rob_role_id > 10, 1, Data#r_role_escort.rob_role_id),
                                                          reward = Data#r_role_escort.reward, log_list = Data#r_role_escort.log}).

day_reset(#r_role{role_id = RoleID, role_attr = RoleAttr} = State) ->
    case mod_role_function:get_is_function_open(?FUNCTION_FAIRY, State) andalso ?HAS_FAMILY(RoleAttr#r_role_attr.family_id) of
        true ->
            [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
            [FairyTimes, RobTimes|_] = GlobalConfig#c_global.list,
            common_misc:unicast(RoleID, #m_role_escort_status_toc{value = [#p_kv{id = 1, val = FairyTimes}, #p_kv{id = 2, val = RobTimes}]});
        _ ->
            ok
    end,
    State.



get_escort_finish_times(#r_role{}) ->
    0.



handle({#m_role_escort_list_tos{id = PEscortID, time = PEscortTime}, RoleID, _PID}, State) ->
    do_get_escort_list(RoleID, PEscortID, PEscortTime, State);

handle({#m_role_escort_tos{type = Type}, RoleID, _PID}, State) ->
    do_escort(RoleID, Type, State);

handle({#m_role_escort_reward_tos{}, RoleID, _PID}, State) ->
    do_get_reward(RoleID, State);

handle({#m_role_escort_rob_tos{id = PRoleID}, RoleID, _PID}, State) ->
    do_escort_rob(RoleID, PRoleID, State);

handle({#m_role_escort_rob_back_tos{id = PEscortID}, RoleID, _PID}, State) ->
    do_escort_rob_back(RoleID, PEscortID, State);

handle({#m_role_escort_for_help_tos{}, RoleID, _PID}, State) ->
    do_ask_for_help(RoleID, State);

handle(Info, State) ->
    ?ERROR_MSG("unknow Info:~w", [Info]),
    State.


do_escort(RoleID, Type, State) ->
    case catch check_escort(Type, State) of
        {ok, FairyType, Num, EndTime, BagDoings, State2} ->
            State3 = ?IF(BagDoings =:= [], State2, mod_role_bag:do(BagDoings, State2)),
            common_misc:unicast(RoleID, #m_role_escort_toc{type = Type, type_id = FairyType, num = Num, end_time = EndTime}),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_escort_toc{err_code = ErrCode}),
            State
    end.


check_escort(Type, #r_role{role_attr = RoleAttr} = State) ->
    ?IF(?HAS_FAMILY(RoleAttr#r_role_attr.family_id), ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_001)),
    if
        Type =:= ?ESCORT_START -> check_escort_c(State, false);
        true -> check_escort_a(Type, State)
    end.


check_escort_c(#r_role{role_id = RoleID, role_attr = RoleAttr} = State, IsGM) ->
    #r_activity{status = Status} = world_activity_server:get_activity(?ACTIVITY_FAMILY_ESCORT),
    ?IF(?STATUS_OPEN =:= Status, ok, ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)),
    [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
    Mod = family_escort_server:get_escort_server(),
    Data = Mod:get_escort_data(RoleID),
    [Config] = lib_config:find(cfg_escort, Data#r_role_escort.fairy_type),
    Now = time_tool:now(),
%%    EndTime = Now + 60 * 3,
    EndTime = ?IF(IsGM, Now + 120, Now + Config#c_escort.escort_time * 60),
    [FairyTimes|_] = GlobalConfig#c_global.list,
    ?IF(FairyTimes > Data#r_role_escort.escort_times, ok, ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR)),
    Num = FairyTimes - Data#r_role_escort.escort_times - 1,
    Fight = RoleAttr#r_role_attr.power,
    case mod_family_data:get_family_member_by_ids(RoleAttr#r_role_attr.family_id, RoleID) of
        #p_family_member{title = Title} ->
            Mod:info({fairy_start, RoleID, RoleAttr#r_role_attr.role_name, EndTime, Config#c_escort.fairy_name, Fight, RoleAttr#r_role_attr.family_id, Title, common_config:get_server_name()}),
            mod_role_node:update_role_cross_data(State),
            {ok, Data#r_role_escort.fairy_type, Num, EndTime, [], State};
        _ ->
            ?THROW_ERR(?ERROR_COMMON_ACT_NO_START)
    end.


check_escort_a(UpType, #r_role{role_id = RoleID} = State) ->
    Mod = family_escort_server:get_escort_server(),
    Data = Mod:get_escort_data(RoleID),
    ?IF(Data#r_role_escort.fairy_type =/= ?MAX_FAIRY, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_001)),
    [Config] = lib_config:find(cfg_escort, Data#r_role_escort.fairy_type),
    [NeedItem, NeedNum] = Config#c_escort.need_item,
    MaxNum = lib_tool:ceil(Config#c_escort.max_num * 0.7),
    ?IF(UpType =:= ?ESCORT_MAX_FAIRY andalso MaxNum =:= 0, ?THROW_ERR(?ERROR_ROLE_ESCORT_002), ok),
    {DelNum, FairyType} = ?IF(UpType =:= ?ESCORT_UP_FAIRY, {NeedNum, Data#r_role_escort.fairy_type + 1}, {MaxNum, ?MAX_FAIRY}),
    case lib_config:find(cfg_escort, FairyType) of
        [] ->
            ?THROW_ERR(?ERROR_COMMON_SYSTEM_ERROR);
        _ ->
            ok
    end,
    DecreaseList = mod_role_bag:get_decrease_goods_by_num(NeedItem, DelNum, State),
    BagDoing = [{decrease, ?ITEM_REDUCE_DO_FAIRY, DecreaseList}],
    Data2 = Data#r_role_escort{fairy_type = FairyType},
    [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
    [FairyTimes|_] = GlobalConfig#c_global.list,
    Mod:set_escort_data(Data2),
    {ok, Data2#r_role_escort.fairy_type, FairyTimes - Data#r_role_escort.escort_times, 0, BagDoing, State}.



do_get_reward(RoleID, State) ->
    case catch check_get_reward(RoleID, State) of
        {ok, Exp, BagDoings, Type, OldType, State2} ->
            State3 = mod_role_bag:do(BagDoings, State2),
            State4 = mod_role_level:do_add_exp(State3, Exp, ?EXP_ADD_FROM_FAIRLY),
            common_misc:unicast(RoleID, #m_role_escort_reward_toc{type = Type, reward = 0}),
            hook_role:escort_finish(State4, OldType);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_escort_reward_toc{err_code = ErrCode, reward = 1}),
            State
    end.

check_get_reward(RoleID, #r_role{role_attr = RoleAttr} = State) ->
    Mod = family_escort_server:get_escort_server(),
    Data = Mod:get_escort_data(RoleID),
    ?IF(Data#r_role_escort.reward =:= 1, ok, ?THROW_ERR(?ERROR_ROLE_ESCORT_REWARD_003)),
    Rate = ?IF(Data#r_role_escort.rob_role_id > 10, 0.7, 1),
    [Config] = lib_config:find(cfg_escort, Data#r_role_escort.fairy_type),
    GoodsList = [#p_goods{type_id = Type, num = lib_tool:ceil(Num * Rate)} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_escort.reward)],
    mod_role_bag:check_bag_empty_grid(GoodsList, State),   %%检查包包空间够不够
    BagDoing = [{create, ?ITEM_GAIN_FAIRY, GoodsList}],
    [LevelConfig] = lib_config:find(cfg_role_level, RoleAttr#r_role_attr.level),
    Exp = lib_tool:ceil(LevelConfig#c_role_level.base_exp * Config#c_escort.exp_rate / 10000 * Rate),
    Data2 = Data#r_role_escort{fairy_type = ?INIT_FAIRY, reward = 0, end_time = 0, log = [], help = 0, rob_role_id = 0},
    Mod:set_escort_data(Data2),
    {ok, Exp, BagDoing, Data2#r_role_escort.fairy_type, Data#r_role_escort.fairy_type, State}.


do_get_escort_list(RoleID, PEscortID, PEscortTime, #r_role{role_attr = RoleAttr} = State) ->
%%    MaxTime = erlang:max(PEscortTime, time_tool:now()),
%%    Ms = ets:fun2ms(
%%        fun(#r_role_escort{escort_id = EscortID, end_time = EndTime} = Brief) when EscortID > PEscortID andalso EndTime > MaxTime ->
%%            Brief end
%%    ),
%%    InfoList = ets:match_object(?DB_ROLE_ESCORT_P, Ms, ?ESCORT_LIST_NUM),
    case family_escort_server:get_escort_server() of
        family_escort_server ->
            case PEscortTime =:= 0 of
                true ->
                    case ets:first(?ETS_TIME_LOOP) of
                        '$end_of_table' ->
                            common_misc:unicast(RoleID, #m_role_escort_list_toc{list = []});
                        PEscortTime2 ->
                            [Info] = ets:lookup(?ETS_TIME_LOOP, PEscortTime2),
                            List = get_escort_list(RoleAttr#r_role_attr.family_id, RoleID, PEscortID, Info, ?ESCORT_LIST_NUM, false, []),
                            common_misc:unicast(RoleID, #m_role_escort_list_toc{list = List})
                    end;
                _ ->
                    PEscortTime2 = PEscortTime,
                    case ets:lookup(?ETS_TIME_LOOP, PEscortTime2) of
                        [Info] ->
                            List = get_escort_list(RoleAttr#r_role_attr.family_id, RoleID, PEscortID, Info, ?ESCORT_LIST_NUM, true, []),
                            common_misc:unicast(RoleID, #m_role_escort_list_toc{list = List});
                        _ ->
                            common_misc:unicast(RoleID, #m_role_escort_list_toc{list = []})
                    end
            end;
        _ ->
            family_escort_cross_server:query_list(mod_role_dict:get_gateway_pid(), RoleID, RoleAttr#r_role_attr.family_id, PEscortID, PEscortTime)
    end,
    State.


get_escort_list(FamilyID, RoleID, PEscortID, Info, NeedNum, ComparePEscortID, List) ->
    case get_escort_list_i(FamilyID, RoleID, lists:reverse(Info#r_time_loop.check_list), NeedNum, ComparePEscortID, PEscortID, List) of
        {ok, NewList} ->
            NewList;
        {next_round, NewList, NeedNum2} ->
            case ets:next(?ETS_TIME_LOOP, Info#r_time_loop.time) of
                '$end_of_table' ->
                    NewList;
                Time ->
                    [Info2] = ets:lookup(?ETS_TIME_LOOP, Time),
                    get_escort_list(FamilyID, RoleID, PEscortID, Info2, NeedNum2, false, NewList)
            end
    end.

get_escort_list_i(_, _, _IDList, NeedNum, _ComparePEscortID, _PEscortID, List) when NeedNum =< 0 ->
    {ok, List};
get_escort_list_i(_FamilyID, _RoleID, [], NeedNum, _ComparePEscortID, _PEscortID, List) ->
    {next_round, List, NeedNum};
get_escort_list_i(FamilyID, RoleID, [ID|T], NeedNum, ComparePEscortID, PEscortID, List) ->
    case ets:lookup(?DB_ROLE_ESCORT_P, ID) of
        [] ->
            get_escort_list_i(FamilyID, RoleID, T, NeedNum, ComparePEscortID, PEscortID, List);
        [Info] ->
            case ComparePEscortID of
                true ->
                    case Info#r_role_escort.escort_id > PEscortID andalso Info#r_role_escort.fairy_type =/= ?MAX_FAIRY
                         andalso RoleID =/= Info#r_role_escort.role_id andalso Info#r_role_escort.rob_role_id =:= 0 andalso Info#r_role_escort.family =/= FamilyID of
                        true ->
                            PInfo = #p_escort{id = Info#r_role_escort.escort_id, role_id = Info#r_role_escort.role_id, end_time = Info#r_role_escort.end_time, fight = Info#r_role_escort.fight,
                                              role_name = Info#r_role_escort.name, type = Info#r_role_escort.fairy_type, server_name = Info#r_role_escort.server_name},
                            get_escort_list_i(FamilyID, RoleID, T, NeedNum - 1, ComparePEscortID, PEscortID, [PInfo|List]);
                        _ ->
                            get_escort_list_i(FamilyID, RoleID, T, NeedNum, ComparePEscortID, PEscortID, List)
                    end;
                _ ->
                    case Info#r_role_escort.fairy_type =/= ?MAX_FAIRY andalso RoleID =/= Info#r_role_escort.role_id
                         andalso Info#r_role_escort.rob_role_id =:= 0 andalso Info#r_role_escort.family =/= FamilyID of
                        true ->
                            PInfo = #p_escort{id = Info#r_role_escort.escort_id, role_id = Info#r_role_escort.role_id, end_time = Info#r_role_escort.end_time, fight = Info#r_role_escort.fight,
                                              role_name = Info#r_role_escort.name, type = Info#r_role_escort.fairy_type, server_name = Info#r_role_escort.server_name},
                            get_escort_list_i(FamilyID, RoleID, T, NeedNum - 1, ComparePEscortID, PEscortID, [PInfo|List]);
                        _ ->
                            get_escort_list_i(FamilyID, RoleID, T, NeedNum, ComparePEscortID, PEscortID, List)
                    end
            end
    end.


do_ask_for_help(RoleID, #r_role{role_attr = RoleAttr} = State) ->
    case catch check_ask_for_help(RoleID, #r_role{role_attr = RoleAttr} = State) of
        {ok, State2} ->
            common_misc:unicast(RoleID, #m_role_escort_for_help_toc{}),
            State2;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_escort_for_help_toc{err_code = ErrCode}),
            State
    end.



check_ask_for_help(RoleID, #r_role{} = State) ->
    Mod = family_escort_server:get_escort_server(),
    case Mod:ask_help(RoleID) of
        {error, ErrCode} ->
            {error, ErrCode};
        ok ->
            {ok, State}
    end.




do_escort_rob(RoleID, DestID, State) ->
    case catch check_escort_rob(RoleID, DestID, State) of
        {ok, Exp, GoodList, State2, RobTimes} ->
            State3 = role_misc:create_goods(State2, ?ITEM_GAIN_FAIRY_ROB, GoodList),
            State4 = mod_role_level:do_add_exp(State3, Exp, ?EXP_ADD_FROM_FAIRLY_ROB),
            Reward = [#p_kv{id = TypeID, val = Num} || #p_goods{num = Num, type_id = TypeID} <- GoodList],
            [GlobalConfig] = lib_config:find(cfg_global, ?ESCORT_GLOBAL),
            [_FairyTimes, AllRobTimes|_] = GlobalConfig#c_global.list,
            common_misc:unicast(RoleID, #m_role_escort_rob_toc{res = true, exp = Exp, reward = Reward, rob_times = AllRobTimes - RobTimes}),
            State5 = mod_role_map:do_pre_enter(RoleID, ?MAP_ROB_ESCORT, State4),
            mod_role_node:update_role_cross_data(State),
            hook_role:rob_escort(true, State5);
        {fail, State2} ->
            common_misc:unicast(RoleID, #m_role_escort_rob_toc{res = false}),
            State3 = mod_role_map:do_pre_enter(RoleID, ?MAP_ROB_ESCORT, State2),
            hook_role:rob_escort(false, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_escort_rob_toc{err_code = ErrCode}),
            State
    end.


check_escort_rob(RoleID, DestID, #r_role{role_attr = RoleAttr} = State) ->
    #r_role{role_map = RoleMap} = State,
    #r_role_map{map_id = MapID} = RoleMap,
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), ?THROW_ERR(?ERROR_PRE_ENTER_029), ok),
    ?IF(RoleAttr#r_role_attr.family_id =/= 0, ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_001)),
    Mod = family_escort_server:get_escort_server(),
    case Mod:rob(RoleID, RoleAttr#r_role_attr.power, RoleAttr#r_role_attr.role_name, DestID) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, win, FairyType, RobTimes, EnemyInfo} ->
            set_battle_info(EnemyInfo),
            [Config] = lib_config:find(cfg_escort, FairyType),
            Rate = 0.3,
            GoodsList = [#p_goods{type_id = Type, num = lib_tool:ceil(Num * Rate)} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_escort.reward)],
            [LevelConfig] = lib_config:find(cfg_role_level, RoleAttr#r_role_attr.level),
            Exp = lib_tool:ceil(LevelConfig#c_role_level.base_exp * Config#c_escort.exp_rate / 10000 * Rate),
            {ok, Exp, GoodsList, State, RobTimes};
        {ok, fail, EnemyInfo} ->
            set_battle_info(EnemyInfo),
            {fail, State};
        Err ->
            ?ERROR_MSG("--------------------~w", [Err])
    end.



do_escort_rob_back(RoleID, BeRobRoleID, State) ->
    case catch check_escort_rob_back(RoleID, BeRobRoleID, State) of
        {ok, GoodList, State2} ->
            State3 = role_misc:create_goods(State2, ?ITEM_GAIN_FAIRY_ROB, GoodList),
            common_misc:unicast(RoleID, #m_role_escort_rob_back_toc{res = true, reward = [#p_kv{id = TypeID, val = Num} || #p_goods{num = Num, type_id = TypeID} <- GoodList]}),
            ?TRY_CATCH(mod_role_log_statistics:log_family_rob(State)),
            State4 = mod_role_map:do_pre_enter(RoleID, ?MAP_ROB_BACK_ESCORT, State3),
            hook_role:rob_escort_back(true, State4);
        {fail, State2} ->
            common_misc:unicast(RoleID, #m_role_escort_rob_back_toc{res = false}),
            State3 = mod_role_map:do_pre_enter(RoleID, ?MAP_ROB_BACK_ESCORT, State2),
            hook_role:rob_escort_back(false, State3);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_escort_rob_back_toc{err_code = ErrCode}),
            State
    end.


check_escort_rob_back(RoleID, DestID, #r_role{role_attr = RoleAttr} = State) ->
    #r_role{role_map = RoleMap} = State,
    #r_role_map{map_id = MapID} = RoleMap,
    Mod = family_escort_server:get_escort_server(),
%%    ?IF(RoleID =:= DestID andalso Data#r_role_escort.help =/= 0, ?THROW_ERR(?ERROR_PRE_ENTER_029), ok),
    ?IF(map_misc:is_copy(MapID) orelse map_misc:is_condition_map(MapID), ?THROW_ERR(?ERROR_PRE_ENTER_029), ok),
    ?IF(RoleAttr#r_role_attr.family_id =/= 0, ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_001)),
    case Mod:rob_back(RoleID, RoleAttr#r_role_attr.power, DestID) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, win, FairyType, EnemyInfo} ->
            set_battle_info(EnemyInfo),
            [Config] = lib_config:find(cfg_escort, FairyType),
            GoodsList = case RoleID =:= DestID of
                            true ->
                                [];
                            _ ->
                                [#p_goods{type_id = Type, num = Num} || {Type, Num} <- lib_tool:string_to_intlist(Config#c_escort.rob_back_reward)]
                        end,
            {ok, GoodsList, State};
        {ok, fail, EnemyInfo} ->
            set_battle_info(EnemyInfo),
            {fail, State}
    end.

get_escort_config_times() ->
    [FairyTimes|_] = common_misc:get_global_list(?ESCORT_GLOBAL),
    FairyTimes.



set_battle_info(Info) ->
    erlang:put({?MODULE, battle_info}, Info).

get_battle_info() ->
    erlang:get({?MODULE, battle_info}).


role_enter_map(State) ->
    #r_role{role_id = RoleID, role_map = RoleMap} = State,
    case ?IS_MAP_ROB_ESCORT(RoleMap#r_role_map.map_id) orelse ?IS_MAP_ROB_BACK_ESCORT(RoleMap#r_role_map.map_id) of
        true ->
            {BattleID, Hp, Speed, RoleName, Sex, Category, Level, SkinList, Power} = get_battle_info(),
            [[#c_born_point{}, #c_born_point{mx = Mx2, my = My2, mdir = MDir2}|_]] = map_base_data:get_born_points(RoleMap#r_role_map.map_id),
            DataRecord = #m_map_slice_enter_toc{
                actors = [#p_map_actor{
                    actor_id = BattleID,
                    actor_type = ?ACTOR_TYPE_ROLE,
                    actor_name = RoleName,
                    status = ?MAP_STATUS_NORMAL,
                    move_speed = Speed,
                    hp = Hp,
                    max_hp = Hp,
                    pos = map_misc:pos_encode(map_misc:get_pos_by_meter(Mx2, My2, MDir2)),
                    camp_id = ?DEFAULT_CAMP_MONSTER,
                    pk_mode = ?PK_MODE_CAMP,
                    role_extra = #p_map_role{
                        sex = Sex,
                        category = Category,
                        level = Level,
                        skin_list = SkinList,
                        power = Power
                    }
                }]},
            common_misc:unicast(RoleID, DataRecord);
        _ ->
            ok
    end.