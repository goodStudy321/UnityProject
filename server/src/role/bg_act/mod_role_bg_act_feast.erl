%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 06. 七月 2018 8:37
%%%-------------------------------------------------------------------
-module(mod_role_bg_act_feast).
-author("laijichang").
-include("role.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_act_feast.hrl").
-include("proto/mod_role_bg_act.hrl").

%% API
-export([
    init/1,
    init_feast_entry/4,
    init_acc_pay/3,
    init_feast_regression/3,
    init_acc_consume/3,
    init_feast_recharge/2
]).

-export([
    check_act_entry_reward/2,
    check_acc_pay_reward/2,
    check_regression_reward/2,
    check_acc_consume_reward/2,
    check_recharge_reward/1
]).

-export([
    get_feast_entry_online_info/2,
    get_feast_acc_pay_online_info/2,
    get_feast_regression_online_info/2,
    get_feast_acc_consume_online_info/2,
    feast_recharge_online_action/2
]).


-export([
    entry_config_list_change/6,
    acc_pay_config_list_change/6,
    acc_consume_config_list_change/6,
    regression_config_list_change/6
]).

-export([
    act_entry_day_reset/1,
    act_acc_pay_add/2,
    act_acc_consume_add/2,
    trigger/3,
    trigger/4,
    recharge/1
]).

-export([
    tran_to_p_item_i/1
]).


tran_to_p_item_i(List) ->
    [#p_item_i{type_id = TypeID, num = Num, is_bind = Bind, special_effect = SpecialEffect} || {TypeID, Num, Bind, SpecialEffect} <- List].



init(#r_role{role_act_feast = RoleActFeast} = State) when erlang:is_record(RoleActFeast, r_role_act_feast) ->
    State;
init(#r_role{role_id = RoleID} = State) ->
    RoleActFeast = #r_role_act_feast{role_id = RoleID},
    State#r_role{role_act_feast = RoleActFeast}.


%%%===================================================================
%%% 回归豪礼 start
%%%===================================================================

init_feast_regression(#r_role{role_act_feast = RoleActFeast} = State, ConfigList, EditTime) ->
    RewardList = [
        begin
            [Condition, Param] = Info#bg_act_config_info.condition,
            #bg_regression{id = Info#bg_act_config_info.sort, status = ?ACT_REWARD_CANNOT_GET, type = Condition, param = Param}
        end || Info <- ConfigList],
    RewardList2 = check_reward(RewardList, State),
    RoleActFeast2 = RoleActFeast#r_role_act_feast{regression_reward_list = RewardList2, regression_time = EditTime},
    State#r_role{role_act_feast = RoleActFeast2}.

%%检查条件达成情况
check_reward(RewardList, State) ->
    check_trigger_list_i(RewardList, [], State).

check_trigger_list_i([], List, _State) ->
    List;
check_trigger_list_i([Info|T], List, State) ->
    #bg_regression{type = Type, param = Param1, schedule = Schedule, status = Status} = Info,
    case Type of
        ?BG_VIP ->
            VipLevel = mod_role_vip:get_vip_level(State),
            Status2 = ?IF(VipLevel >= Param1, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET),
            Schedule2 = Schedule;
        ?BG_LOVING ->
            Param = ?IF(marry_misc:has_couple(State#r_role.role_id), 1, 0),
            Status2 = ?IF(Param =:= Param1, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET),
            Schedule2 = Schedule;
        ?BG_LOGIN ->
            Status2 = ?ACT_REWARD_CAN_GET, Schedule2 = Schedule;
        _ ->
            Status2 = Status,
            Schedule2 = Schedule
    end,
    Info2 = Info#bg_regression{status = Status2, schedule = Schedule2},
    check_trigger_list_i(T, [Info2|List], State).

trigger(State, Type, Param) ->
    case mod_role_bg_act:is_bg_act_open(?BG_ACT_REGRESSION, State) of
        true ->
            trigger(State, Type, Param, true);
        _ ->
            State
    end.

trigger(#r_role{role_act_feast = RoleActFeast, role_id = RoleID} = State, Type, Param, IsBc) ->
    #r_role_act_feast{regression_reward_list = RewardList} = RoleActFeast,
    {TList, Other} = check_trigger_list(RewardList, [], [], Type, Param),
    if
        IsBc andalso TList =/= [] ->
            SendList = [#p_kvt{id = ID, val = Schedule, type = Status} || #bg_regression{id = ID, schedule = Schedule, status = Status} <- TList],
            common_misc:unicast(RoleID, #m_bg_act_reward_condition_toc{id = ?BG_ACT_REGRESSION, list = SendList});
        true ->
            ok
    end,
    RoleActFeast2 = RoleActFeast#r_role_act_feast{regression_reward_list = TList ++ Other},
    State#r_role{role_act_feast = RoleActFeast2}.

check_trigger_list([], TList, List, _Type, _Param) ->
    {TList, List};
check_trigger_list([Info|T], TList, List, Type, Param) ->
    case Info of
        #bg_regression{type = Type, status = ?ACT_REWARD_CANNOT_GET, param = Param1, schedule = Schedule} ->
            case Type of
                ?BG_REGRESSION ->
                    Status2 = ?IF(Param >= Param1, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET),
                    Schedule2 = Schedule;
                ?BG_VIP ->
                    {Status2, Schedule2} = ?IF(Param >= Param1, {?ACT_REWARD_CAN_GET, Param1}, {?ACT_REWARD_CANNOT_GET, Param});
                ?BG_LOVING ->
                    Status2 = ?IF(Param =:= Param1, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET),
                    Schedule2 = Schedule;
                ?BG_RECHARGE ->
                    {Status2, Schedule2} = ?IF(Param + Schedule >= Param1, {?ACT_REWARD_CAN_GET, Param1}, {?ACT_REWARD_CANNOT_GET, Param + Schedule});
                _ ->
                    Status2 = ?ACT_REWARD_CANNOT_GET,
                    Schedule2 = Schedule
            end,
            Info2 = Info#bg_regression{status = Status2, schedule = Schedule2},
            case Info2 =:= Info of
                true ->
                    check_trigger_list(T, TList, [Info|List], Type, Param);
                _ ->
                    check_trigger_list(T, [Info2|TList], List, Type, Param)
            end;
        _ ->
            check_trigger_list(T, TList, [Info|List], Type, Param)
    end.

get_feast_regression_online_info(#r_role{role_act_feast = RoleActFeast}, #p_bg_act{entry_list = EntryList} = PBgAct) ->
    #r_role_act_feast{regression_reward_list = RewardList} = RoleActFeast,
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#p_bg_act_entry.sort, #bg_regression.id, RewardList) of
                false ->
                    EntryInfo;
                RoleEntryInfo ->
                    EntryInfo#p_bg_act_entry{status = RoleEntryInfo#bg_regression.status}
            end
        end
        || EntryInfo <- EntryList],
    {ok, PBgAct#p_bg_act{entry_list = NewEntryList}}.

check_regression_reward(State, Entry) ->
    #r_role{role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{regression_reward_list = RewardList} = RoleActFeast,
    {value, #bg_regression{status = Val} = Info, Other} = lists:keytake(Entry, #bg_regression.id, RewardList),
    ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
    GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_REGRESSION, Entry),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_RETURN_REWARD, GoodsList}],
    RewardList2 = [Info#bg_regression{id = Entry, status = ?ACT_REWARD_GOT}|Other],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{regression_reward_list = RewardList2},
    State2 = State#r_role{role_act_feast = RoleActFeast2},
    {ok, BagDoings, State2}.


regression_config_list_change(#r_role{role_id = RoleID, role_act_feast = RoleFeast} = State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList) ->
    #r_role_act_feast{regression_reward_list = RewardList} = RoleFeast,
    RewardList2 = lists:foldl(
        fun(DelID, AccList) ->
            lists:keydelete(DelID, #bg_regression.id, AccList)
        end, RewardList, DelConfigList
    ),
    {RewardList3, UpdateList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = [Condition, Param], items = Items, title = Title}, {AccList, AccUpdateList}) ->
            case lists:keytake(Sort, #bg_regression.id, AccList) of
                {value, RewardInfo, Other} ->
                    case Condition =:= RewardInfo#bg_regression.type of
                        false ->
                            NewRewardInfo = #bg_regression{type = Condition, param = Param, schedule = 0},
                            [NewRewardInfo2] = check_reward([NewRewardInfo], State),
                            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo2#bg_regression.status, schedule = NewRewardInfo2#bg_regression.schedule,
                                                         target = NewRewardInfo2#bg_regression.param, num = -1},
                            {[NewRewardInfo2|Other], [UpdateInfo|AccUpdateList]};
                        _ ->
                            case Param =:= RewardInfo#bg_regression.param of
                                false ->
                                    UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = RewardInfo#bg_regression.status, schedule = RewardInfo#bg_regression.schedule,
                                                                 target = RewardInfo#bg_regression.param, num = -1},
                                    {[RewardInfo|Other], [UpdateInfo|AccUpdateList]};
                                _ ->
                                    NewRewardInfo = #bg_regression{param = Param, schedule = 0},
                                    [NewRewardInfo2] = check_reward([NewRewardInfo], State),
                                    UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo2#bg_regression.status, schedule = NewRewardInfo2#bg_regression.schedule,
                                                                 target = NewRewardInfo2#bg_regression.param, num = -1},
                                    {[NewRewardInfo2|Other], [UpdateInfo|AccUpdateList]}
                            end
                    end;
                _ ->
                    {AccList, AccUpdateList}
            end
        end, {RewardList2, []}, UpdateConfigList
    ),
    {RewardList4, AddList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = [Condition, Param], items = Items, title = Title}, {AccList, AccAddList}) ->
            NewRewardInfo = #bg_regression{type = Condition, param = Param, schedule = 0},
            [NewRewardInfo2] = check_reward([NewRewardInfo], State),
            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo2#bg_regression.status, schedule = NewRewardInfo2#bg_regression.schedule,
                                         target = NewRewardInfo2#bg_regression.param, num = -1},
            {[NewRewardInfo2|AccList], [UpdateInfo|AccAddList]}
        end, {RewardList3, []}, AddConfigList
    ),
    ?IF(IsBc, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{del_list = DelConfigList, add_list = AddList, update_list = UpdateList}), ok),
    RoleFeast2 = RoleFeast#r_role_act_feast{regression_reward_list = RewardList4, regression_time = EditTime},
    State#r_role{role_act_feast = RoleFeast2}.
%%%===================================================================
%%% 回归豪礼 end
%%%===================================================================


%%%===================================================================
%%% 累积充值 start
%%%===================================================================

init_acc_pay(#r_role{role_act_feast = RoleActFeast} = State, ConfigList, EditTime) ->
    RewardList = [#p_kvt{id = Info#bg_act_config_info.sort, val = Info#bg_act_config_info.condition, type = ?ACT_REWARD_CANNOT_GET} || Info <- ConfigList],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{pay_reward_list = RewardList, pay_gold = 0, pay_time = EditTime},
    State#r_role{role_act_feast = RoleActFeast2}.


get_feast_acc_pay_online_info(#r_role{role_act_feast = RoleActFeast}, #p_bg_act{entry_list = EntryList} = PBgAct) ->
    #r_role_act_feast{pay_reward_list = RoleEntryList, pay_gold = PayGold} = RoleActFeast,
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#p_bg_act_entry.sort, #p_kvt.id, RoleEntryList) of
                false ->
                    EntryInfo;
                RoleEntryInfo ->
                    EntryInfo#p_bg_act_entry{status = RoleEntryInfo#p_kvt.type, schedule = ?IF(RoleEntryInfo#p_kvt.val > PayGold, PayGold, RoleEntryInfo#p_kvt.val)}
            end
        end
        || EntryInfo <- EntryList],
    {ok, PBgAct#p_bg_act{entry_list = NewEntryList}}.


act_acc_pay_add(AddGold, State) ->
    #r_role{role_id = RoleID, role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{pay_gold = PayGold, pay_reward_list = PayRewardList} = RoleActFeast,
    PayGold2 = PayGold + AddGold,
    {PayRewardList2, UpdateList} = get_change_list(PayGold2, PayRewardList, [], []),
    ?IF(UpdateList =/= [], common_misc:unicast(RoleID, #m_bg_act_reward_condition_toc{id = ?BG_ACT_ACC_PAY, list = UpdateList}), ok),
    RoleActFeast2 = RoleActFeast#r_role_act_feast{pay_gold = PayGold2, pay_reward_list = PayRewardList2},
    State#r_role{role_act_feast = RoleActFeast2}.


get_change_list(_Gold, [], PayRewardList, UpdateList) ->
    {PayRewardList, UpdateList};

get_change_list(Gold, [Info|T], PayRewardList, UpdateList) ->
    case Info#p_kvt.type =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            case Gold >= Info#p_kvt.val of
                true ->
                    get_change_list(Gold, T, [Info#p_kvt{type = ?ACT_REWARD_CAN_GET}|PayRewardList], [Info#p_kvt{type = ?ACT_REWARD_CAN_GET, val = Info#p_kvt.val}|UpdateList]);
                _ ->
                    get_change_list(Gold, T, [Info|PayRewardList], [Info#p_kvt{type = ?ACT_REWARD_CANNOT_GET, val = Gold}|UpdateList])
            end;
        _ ->
            get_change_list(Gold, T, [Info|PayRewardList], UpdateList)
    end.

check_acc_pay_reward(State, Entry) ->
    #r_role{role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{pay_reward_list = PayRewardList} = RoleActFeast,
    {value, #p_kvt{type = Type}, Other} = lists:keytake(Entry, #p_kvt.id, PayRewardList),
    ?IF(Type =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
    GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_ACC_PAY, Entry),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_ACC_PAY_REWARD, GoodsList}],
    PayRewardList2 = [#p_kvt{id = Entry, type = ?ACT_REWARD_GOT}|Other],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{pay_reward_list = PayRewardList2},
    State2 = State#r_role{role_act_feast = RoleActFeast2},
    {ok, BagDoings, State2}.

acc_pay_config_list_change(#r_role{role_id = RoleID, role_act_feast = RoleFeast} = State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList) ->
    #r_role_act_feast{pay_reward_list = RewardList, pay_gold = PayGold} = RoleFeast,
    RewardList2 = lists:foldl(
        fun(DelID, AccList) ->
            lists:keydelete(DelID, #p_kvt.id, AccList)
        end, RewardList, DelConfigList
    ),
    {RewardList3, UpdateList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = Target, items = Items, title = Title}, {AccList, AccUpdateList}) ->
            case lists:keytake(Sort, #bg_regression.id, AccList) of
                {value, RewardInfo, Other} ->
                    case RewardInfo#p_kvt.type =:= ?ACT_REWARD_CANNOT_GET andalso Target =/= RewardInfo#p_kvt.val of
                        false ->
                            NewRewardInfo = RewardInfo#p_kvt{type = ?IF(PayGold >= Target, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET), val = Target},
                            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo#p_kvt.type, schedule = ?IF(NewRewardInfo#p_kvt.val > PayGold, PayGold, NewRewardInfo#p_kvt.val),
                                                         target = Target, num = -1},
                            {[NewRewardInfo|Other], [UpdateInfo|AccUpdateList]};
                        _ ->
                            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = RewardInfo#p_kvt.type, schedule = ?IF(RewardInfo#p_kvt.val > PayGold, PayGold, RewardInfo#p_kvt.val),
                                                         target = Target, num = -1},
                            {AccList, [UpdateInfo|AccUpdateList]}
                    end;
                _ ->
                    {AccList, AccUpdateList}
            end
        end, {RewardList2, []}, UpdateConfigList),
    {RewardList4, AddList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = Target, items = Items, title = Title}, {AccList, AccAddList}) ->
            NewRewardInfo = #p_kvt{id = Sort, type = ?IF(PayGold >= Target, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET), val = Target},
            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo#p_kvt.type, schedule = ?IF(NewRewardInfo#p_kvt.val > PayGold, PayGold, NewRewardInfo#p_kvt.val),
                                         target = Target, num = -1},
            {[NewRewardInfo|AccList], [UpdateInfo|AccAddList]}
        end, {RewardList3, []}, AddConfigList
    ),
    ?IF(IsBc, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{del_list = DelConfigList, add_list = AddList, update_list = UpdateList}), ok),
    RoleFeast2 = RoleFeast#r_role_act_feast{pay_reward_list = RewardList4, pay_time = EditTime},
    State#r_role{role_act_feast = RoleFeast2}.

%%%===================================================================
%%% 累积充值 end
%%%===================================================================


%%%===================================================================
%%% 累积消费 start
%%%===================================================================
init_acc_consume(#r_role{role_act_feast = RoleActFeast, role_asset = RoleAsset} = State, ConfigList, EditTime) ->
    RewardList = [#p_kvt{id = Info#bg_act_config_info.sort, val = Info#bg_act_config_info.condition, type = ?ACT_REWARD_CANNOT_GET} || Info <- ConfigList],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{consume_reward_list = RewardList, consume_gold = RoleAsset#r_role_asset.day_use_gold, consume_time = EditTime},
    State2 = State#r_role{role_act_feast = RoleActFeast2},
    act_acc_consume_add(RoleAsset#r_role_asset.day_use_gold, State2).


get_feast_acc_consume_online_info(#r_role{role_act_feast = RoleActFeast}, #p_bg_act{entry_list = EntryList} = PBgAct) ->
    #r_role_act_feast{consume_reward_list = RoleConsumeList, consume_gold = ConsumeGold} = RoleActFeast,
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#p_bg_act_entry.sort, #p_kvt.id, RoleConsumeList) of
                false ->
                    EntryInfo;
                RoleConsumeInfo ->
                    EntryInfo#p_bg_act_entry{status = RoleConsumeInfo#p_kvt.type, schedule = ?IF(RoleConsumeInfo#p_kvt.val > ConsumeGold, ConsumeGold, RoleConsumeInfo#p_kvt.val)}
            end
        end
        || EntryInfo <- EntryList],
    {ok, PBgAct#p_bg_act{entry_list = NewEntryList}}.


act_acc_consume_add(UseGold, State) ->
    #r_role{role_id = RoleID, role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{consume_gold = ConsumeGold, consume_reward_list = ConsumeRewardList} = RoleActFeast,
    ConsumeGold2 = ConsumeGold + UseGold,
    {ConsumeRewardList2, UpdateList} = get_change_list(ConsumeGold2, ConsumeRewardList, [], []),
    ?IF(UpdateList =/= [], common_misc:unicast(RoleID, #m_bg_act_reward_condition_toc{id = ?BG_ACT_ACC_CONSUME, list = UpdateList}), ok),
    RoleActFeast2 = RoleActFeast#r_role_act_feast{consume_gold = ConsumeGold2, consume_reward_list = ConsumeRewardList2},
    State#r_role{role_act_feast = RoleActFeast2}.

check_acc_consume_reward(State, Entry) ->
    #r_role{role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{consume_reward_list = ConsumeRewardList} = RoleActFeast,
    {value, #p_kvt{type = Type}, Other} = lists:keytake(Entry, #p_kvt.id, ConsumeRewardList),
    ?IF(Type =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
    GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_ACC_CONSUME, Entry),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_ACC_CONSUME, GoodsList}],
    ConsumeRewardList2 = [#p_kvt{id = Entry, type = ?ACT_REWARD_GOT}|Other],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{consume_reward_list = ConsumeRewardList2},
    State2 = State#r_role{role_act_feast = RoleActFeast2},
    {ok, BagDoings, State2}.

acc_consume_config_list_change(#r_role{role_id = RoleID, role_act_feast = RoleFeast} = State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList) ->
    #r_role_act_feast{consume_reward_list = RewardList, consume_gold = ConsumeGold} = RoleFeast,
    RewardList2 = lists:foldl(
        fun(DelID, AccList) ->
            lists:keydelete(DelID, #p_kvt.id, AccList)
        end, RewardList, DelConfigList
    ),
    {RewardList3, UpdateList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = Target, items = Items, title = Title}, {AccList, AccUpdateList}) ->
            case lists:keytake(Sort, #bg_regression.id, AccList) of
                {value, RewardInfo, Other} ->
                    case RewardInfo#p_kvt.type =:= ?ACT_REWARD_CANNOT_GET andalso Target =/= RewardInfo#p_kvt.val of
                        false ->
                            NewRewardInfo = RewardInfo#p_kvt{type = ?IF(ConsumeGold >= Target, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET), val = Target},
                            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo#p_kvt.type, schedule = ?IF(NewRewardInfo#p_kvt.val > ConsumeGold, ConsumeGold, NewRewardInfo#p_kvt.val),
                                                         target = Target, num = -1},
                            {[NewRewardInfo|Other], [UpdateInfo|AccUpdateList]};
                        _ ->
                            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = RewardInfo#p_kvt.type, schedule = ?IF(RewardInfo#p_kvt.val > ConsumeGold, ConsumeGold, RewardInfo#p_kvt.val),
                                                         target = Target, num = -1},
                            {AccList, [UpdateInfo|AccUpdateList]}
                    end;
                _ ->
                    {AccList, AccUpdateList}
            end
        end, {RewardList2, []}, UpdateConfigList
    ),
    {RewardList4, AddList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, condition = Target, items = Items, title = Title}, {AccList, AccAddList}) ->
            NewRewardInfo = #p_kvt{id = Sort, type = ?IF(ConsumeGold >= Target, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET), val = Target},
            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo#p_kvt.type, schedule = ?IF(NewRewardInfo#p_kvt.val > ConsumeGold, ConsumeGold, NewRewardInfo#p_kvt.val),
                                         target = Target, num = -1},
            {[NewRewardInfo|AccList], [UpdateInfo|AccAddList]}
        end, {RewardList3, []}, AddConfigList
    ),
    ?IF(IsBc, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{del_list = DelConfigList, add_list = AddList, update_list = UpdateList}), ok),
    RoleFeast2 = RoleFeast#r_role_act_feast{consume_reward_list = RewardList4, consume_time = EditTime},
    State#r_role{role_act_feast = RoleFeast2}.


%%%===================================================================
%%% 累积消费 end
%%%===================================================================


%%%===================================================================
%%% 登录有礼 start
%%%===================================================================
init_feast_entry(#r_role{role_act_feast = RoleActFeast} = State, ConfigList, EditTime, StartDate) ->
    NowDay = time_tool:diff_date(time_tool:now(), StartDate) + 1,
    RewardList = [#p_kv{id = Info#bg_act_config_info.sort, val = ?IF(Info#bg_act_config_info.sort =:= NowDay, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET)} || Info <- ConfigList],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{entry_list = RewardList, entry_time = EditTime},
    State#r_role{role_act_feast = RoleActFeast2}.


get_feast_entry_online_info(#r_role{role_act_feast = RoleActFeast}, #p_bg_act{entry_list = EntryList} = PBgAct) ->
    #r_role_act_feast{entry_list = RoleEntryList} = RoleActFeast,
    NewEntryList = [
        begin
            case lists:keyfind(EntryInfo#p_bg_act_entry.sort, #p_kv.id, RoleEntryList) of
                false ->
                    EntryInfo;
                RoleEntryInfo ->
                    EntryInfo#p_bg_act_entry{status = RoleEntryInfo#p_kv.val}
            end
        end
        || EntryInfo <- EntryList],
    {ok, PBgAct#p_bg_act{entry_list = NewEntryList}}.

act_entry_day_reset(#r_role{role_id = RoleID} = State) ->
    #r_bg_act{start_date = StartDate} = world_bg_act_server:get_bg_act(?BG_ACT_FEAST_ENTRY),
    NowDay = time_tool:diff_date(time_tool:now(), StartDate) + 1,
    #r_role{role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{entry_list = EntryList} = RoleActFeast,
    case lists:keytake(NowDay, #p_kv.id, EntryList) of
        {value, #p_kv{val = ?ACT_REWARD_CANNOT_GET}, Other} ->
            EntryList2 = [#p_kv{id = NowDay, val = ?ACT_REWARD_CAN_GET}|Other],
            common_misc:unicast(RoleID, #m_bg_act_reward_condition_toc{id = ?BG_ACT_FEAST_ENTRY, list = [#p_kvt{id = NowDay, type = ?ACT_REWARD_CAN_GET}]});
        _ ->
            EntryList2 = EntryList
    end,
    RoleActFeast2 = RoleActFeast#r_role_act_feast{entry_list = EntryList2},
    State#r_role{role_act_feast = RoleActFeast2}.


check_act_entry_reward(State, Entry) ->
    #r_role{role_act_feast = RoleActFeast} = State,
    #r_role_act_feast{entry_list = EntryList} = RoleActFeast,
    {value, #p_kv{val = Val}, Other} = lists:keytake(Entry, #p_kv.id, EntryList),
    ?IF(Val =:= ?ACT_REWARD_CAN_GET, ok, ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)),
    GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_FEAST_ENTRY, Entry),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_ACT_ENTRY_REWARD, GoodsList}],
    EntryList2 = [#p_kv{id = Entry, val = ?ACT_REWARD_GOT}|Other],
    RoleActFeast2 = RoleActFeast#r_role_act_feast{entry_list = EntryList2},
    State2 = State#r_role{role_act_feast = RoleActFeast2},
    {ok, BagDoings, State2}.

entry_config_list_change(#r_role{role_id = RoleID, role_act_feast = RoleFeast} = State, IsBc, EditTime, AddConfigList, DelConfigList, UpdateConfigList) ->
    #r_bg_act{start_date = StartDate} = world_bg_act_server:get_bg_act(?BG_ACT_FEAST_ENTRY),
    NowDay = time_tool:diff_date(time_tool:now(), StartDate) + 1,
    #r_role_act_feast{entry_list = RewardList} = RoleFeast,
    RewardList2 = lists:foldl(
        fun(DelID, AccList) ->
            lists:keydelete(DelID, #p_kv.id, AccList)
        end, RewardList, DelConfigList
    ),
    UpdateList = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, items = Items, title = Title}, AccUpdateList) ->
            case lists:keyfind(Sort, #p_kv.id, RewardList2) of
                false ->
                    AccUpdateList;
                RewardInfo ->
                    UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = RewardInfo#p_kv.val, num = -1},
                    [UpdateInfo|AccUpdateList]
            end
        end, [], UpdateConfigList
    ),
    {RewardList3, AddList} = lists:foldl(
        fun(#bg_act_config_info{sort = Sort, items = Items, title = Title}, {AccList, AccAddList}) ->
            NewRewardInfo = #p_kv{id = Sort, val = ?IF(NowDay >= Sort, ?ACT_REWARD_CAN_GET, ?ACT_REWARD_CANNOT_GET)},
            UpdateInfo = #p_bg_act_entry{sort = Sort, items = Items, title = Title, status = NewRewardInfo#p_kv.val, num = -1},
            {[NewRewardInfo|AccList], [UpdateInfo|AccAddList]}
        end, {RewardList2, []}, AddConfigList
    ),
    ?IF(IsBc, common_misc:unicast(RoleID, #m_bg_act_entry_update_toc{del_list = DelConfigList, add_list = AddList, update_list = UpdateList}), ok),
    RoleFeast2 = RoleFeast#r_role_act_feast{entry_list = RewardList3, entry_time = EditTime},
    State#r_role{role_act_feast = RoleFeast2}.
%%%===================================================================
%%% 登录有礼 end
%%%===================================================================


%%%===================================================================
%%% 充值有礼 start
%%%===================================================================
init_feast_recharge(#r_role{role_act_feast = RoleActFeast} = State, EditTime) ->
    RoleActFeast2 = RoleActFeast#r_role_act_feast{recharge_reward = ?ACT_REWARD_CANNOT_GET, recharge_reward_time = EditTime},
    State#r_role{role_act_feast = RoleActFeast2}.


feast_recharge_online_action(#r_role{role_id = RoleID, role_act_feast = RoleActFeast}, #r_bg_act{config = Config, explain_i = Explain} = Info) ->
    PBgAct = bg_act_misc:trans_r_bg_act_to_p_bg_act(Info),
    ModelId = proplists:get_value(model_id, Config),
    Power = proplists:get_value(power, Config),
    BackgroundImg = proplists:get_value(background_img, Config),
    EntryList2 = case lists:keyfind(1, #p_bg_act_entry.sort, PBgAct#p_bg_act.entry_list) of
                     false ->
                         [];
                     EntryInfo ->
                         [EntryInfo#p_bg_act_entry{status = RoleActFeast#r_role_act_feast.recharge_reward}]
                 end,
    PBgAct2 = PBgAct#p_bg_act{entry_list = EntryList2},
    common_misc:unicast(RoleID, #m_bg_recharge_toc{info = PBgAct2, fight = Power, model = ModelId, sigh_title = Explain, mod_img = BackgroundImg}),
    ok.

check_recharge_reward(#r_role{role_act_feast = RoleActFeast} = State) ->
    case RoleActFeast#r_role_act_feast.recharge_reward =:= ?ACT_REWARD_CAN_GET of
        true ->
            RoleActFeast2 = RoleActFeast#r_role_act_feast{recharge_reward = ?ACT_REWARD_GOT},
            GoodsList = world_bg_act_server:get_bg_act_reward(?BG_ACT_RECHARGE, 1),
            mod_role_bag:check_bag_empty_grid(GoodsList, State),
            BagDoings = [{create, ?ITEM_GAIN_BG_ACT_RECHARGE, GoodsList}],
            State2 = State#r_role{role_act_feast = RoleActFeast2},
            {ok, BagDoings, State2};
        _ ->
            ?THROW_ERR(?ERROR_BG_ACT_REWARD_002)
    end.

recharge(#r_role{role_act_feast = RoleActFeast, role_id = RoleID} = State) ->
    case RoleActFeast#r_role_act_feast.recharge_reward =:= ?ACT_REWARD_CANNOT_GET of
        true ->
            RoleActFeast2 = RoleActFeast#r_role_act_feast{recharge_reward = ?ACT_REWARD_CAN_GET},
            common_misc:unicast(RoleID, #m_bg_act_reward_condition_toc{id = ?BG_ACT_RECHARGE, list = [#p_kvt{id = 1, val = 1, type = ?ACT_REWARD_CAN_GET}]}),
            State#r_role{role_act_feast = RoleActFeast2};
        _ ->
            State
    end.


%%%===================================================================
%%% 充值有礼 end
%%%===================================================================