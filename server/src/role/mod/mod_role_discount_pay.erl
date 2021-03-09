%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 六月 2019 14:41
%%%-------------------------------------------------------------------
-module(mod_role_discount_pay).
-author("laijichang").
-include("role.hrl").
-include("discount_pay.hrl").
-include("pay.hrl").
-include("proto/mod_role_discount_pay.hrl").
-include("proto/mod_role_pay.hrl").

%% API
-export([
    init/1,
    online/1,
    day_reset/1,
    zero/1,
    loop_min/2,
    handle/2
]).

-export([
    gm_clear/1,
    gm_generate/2,
    check_pay/2,
    pay/2,
    condition_update/1
]).

-export([
    is_days_fit/4,
    trigger_condition/2
]).

init(#r_role{role_id = RoleID, role_discount_pay = undefined} = State) ->
    RoleDiscountPay = #r_role_discount_pay{role_id = RoleID},
    State#r_role{role_discount_pay = RoleDiscountPay};
init(State) ->
    State.

online(State) ->
    State2 = online_modify_time(State),
    {_IsChange, State3} = condition_update2(State2),
    Now = time_tool:now(),
    #r_role{role_discount_pay = RoleDiscountPay} = State3,
    #r_role_discount_pay{today_discounts = TodayDiscounts} = RoleDiscountPay,
    TodayDiscountIDList = [ NowID || #r_discount_pay{id = NowID} <- TodayDiscounts],
    TodayDiscountIDList2 = [ ID || #r_discount_pay{id = ID, end_time = EndTime} <- TodayDiscounts, EndTime >=  Now],
    State4 =
    case TodayDiscountIDList =/= TodayDiscountIDList2 of
        true ->
            ConfirmIDList = get_confirm_id_list3(?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, State3),
            lists:foldl(fun(ID, StateAcc) ->
                case lists:member(ID, TodayDiscountIDList) of
                    true ->
                        StateAcc;
                    _ ->
                        StateAcc2 = trigger_condition(?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, StateAcc),
                        condition_update(StateAcc2)
                end
                        end, State3, ConfirmIDList);
        _ ->
            State3
    end,
    notice_info(State4),
    State4.

zero(State) ->
    {_IsChange, State2} = condition_update2(State),
    notice_info(State2),
    State2.

day_reset(State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_discounts = [], event_list = [], today_daily_gifts = [], finish_ids = []},
    State2 = State#r_role{role_discount_pay = RoleDiscountPay2},
    State2.

loop_min(Now, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{today_discounts = TodayDiscounts} = RoleDiscountPay,
    TodayDiscountIDList = [ NowID || #r_discount_pay{id = NowID} <- TodayDiscounts],
    TodayDiscountIDList2 = [ NowID || #r_discount_pay{id = NowID, end_time = EndTime} <- TodayDiscounts, EndTime >= Now],
    case TodayDiscountIDList =/= TodayDiscountIDList2 of
        true ->
            ConfirmIDList = get_confirm_id_list3(?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, State),
            lists:foldl(fun(ID, StateAcc) ->
                case lists:member(ID, TodayDiscountIDList) of
                    true ->
                        StateAcc;
                    _ ->
                        StateAcc2 = trigger_condition(?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, StateAcc),
                        condition_update(StateAcc2)
                end
                end, State, ConfirmIDList);
        _ ->
            State
    end.

handle(condition_update, State) ->
    do_condition_update(State);
handle({#m_discount_pay_daily_reward_tos{daily_gift_id = DailyID}, RoleID, _PID}, State) ->
    do_daily_reward(RoleID, DailyID, State).

gm_clear(State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_discounts = [], finish_ids = []},
    State2 = State#r_role{role_discount_pay = RoleDiscountPay2},
    {_IsChange, State3} = condition_update2(State2),
    online(State3).

gm_generate(ID, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    TodayDiscounts = RoleDiscountPay#r_role_discount_pay.today_discounts,
    [#c_discount_pay{limit_time = LimitTime}] = lib_config:find(cfg_discount_pay, ID),
    Now = time_tool:now(),
    MidNight = time_tool:midnight(Now) + ?ONE_DAY,
    TodayDiscounts2 = [#r_discount_pay{id = ID, buy_num = 0, end_time = erlang:min(Now + LimitTime * ?ONE_MINUTE, MidNight)}|TodayDiscounts],
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_discounts = TodayDiscounts2},
    State2 = State#r_role{role_discount_pay = RoleDiscountPay2},
    {_IsChange, State3} = condition_update2(State2),
    online(State3).

%% 检查能否获取订单
check_pay(ProductID, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{today_discounts = TodayDiscounts} = RoleDiscountPay,
    Now = time_tool:now(),
    PayID = check_pay2(ProductID, Now, TodayDiscounts),
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{cur_pay_id = PayID},
    State#r_role{role_discount_pay = RoleDiscountPay2}.

check_pay2(_ProductID, _Now, []) ->
    ?THROW_ERR(?ERROR_ROLE_PAY_ORDER_003);
check_pay2(ProductID, Now, [#r_discount_pay{id = ID, end_time = EndTime}|R]) ->
    [#c_discount_pay{product_id = ConfigProductID}] = lib_config:find(cfg_discount_pay, ID),
    case EndTime >= Now andalso ConfigProductID =:= ProductID of
        true ->
            ID;
        _ ->
            check_pay2(ProductID, Now, R)
    end.

pay(ProductID, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{
        cur_pay_id = CurPayID,
        today_discounts = TodayDiscounts,

        finish_ids = FinishIDs} = RoleDiscountPay,
    PayID = get_pay_id(ProductID, CurPayID, TodayDiscounts),
    [#c_discount_pay{
        reward = Reward,
        package_name = PackageName,
        limit_num = LimitNum}] = lib_config:find(cfg_discount_pay, PayID),
    {TodayDiscounts2, FinishIDs2} =
        case lists:keytake(PayID, #r_discount_pay.id, TodayDiscounts) of
            {value, DiscountPayT, TodayDiscountsT} ->
                #r_discount_pay{buy_num = BuyNum} = DiscountPayT,
                BuyNum2 = BuyNum + 1,
                ?IF(BuyNum2 < LimitNum, {[DiscountPayT#r_discount_pay{buy_num = BuyNum2}|TodayDiscountsT], FinishIDs},
                    {TodayDiscountsT, [PayID|FinishIDs]});
            _ ->
                {TodayDiscounts, [PayID|FinishIDs]}
        end,

    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{cur_pay_id = 0, today_discounts = TodayDiscounts2, finish_ids = FinishIDs2},
    State2 = State#r_role{role_discount_pay = RoleDiscountPay2},
    notice_info(State2),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    ?TRY_CATCH(log_discount_pay(PayID, ProductID, PackageName, GoodsList, State)),
    State3 = trigger_condition2(?DISCOUNT_CONDITION_BUY_DISCOUNT, PayID, State2),
    State4 = condition_update(State3),
    role_misc:create_goods(State4, ?ITEM_GAIN_DISCOUNT_PAY, GoodsList).

%% 获取充值的订单ID，兼容凌晨12点前充值，12点后到账的情况
get_pay_id(ProductID, CurPayID, TodayDiscounts) ->
    case CurPayID > 0 of
        true ->
            [#c_discount_pay{product_id = ConfigProductID}] = lib_config:find(cfg_discount_pay, CurPayID),
            case ProductID =:= ConfigProductID of
                true ->
                    CurPayID;
                _ ->
                    get_pay_id2(ProductID, TodayDiscounts)
            end;
        _ ->
            get_pay_id2(ProductID, TodayDiscounts)
    end.

get_pay_id2(ProductID, []) ->
    ?ERROR_MSG("未识别的ProductID :~w", [ProductID]),
    0;
get_pay_id2(ProductID, [#r_discount_pay{id = PayID}|R]) ->
    [#c_discount_pay{product_id = ConfigProductID}] = lib_config:find(cfg_discount_pay, PayID),
    case ConfigProductID =:= ProductID of
        true ->
            PayID;
        _ ->
            get_pay_id2(ProductID, R)
    end.

%% 外部接口调用
condition_update(State) ->
    role_misc:info_role(State#r_role.role_id, ?MODULE, condition_update),
    State.

do_condition_update(State) ->
    {IsChange, State2} = condition_update2(State),
    ?IF(IsChange, notice_info(State2), ok),
    State2.

condition_update2(State) ->
    case mod_role_data:get_role_level(State) >= common_misc:get_global_int(?GLOBAL_DISCOUNT_PAY_LEVEL) of
        true -> %% 达到特定等级才开启
            #r_role{role_discount_pay = RoleDiscountPay} = State,
            #r_role_discount_pay{
                today_discounts = TodayDiscounts,
                today_daily_gifts = TodayDailyGifts,
                condition_list = ConditionList,
                event_list = EventList,
                finish_ids = FinishIDs} = RoleDiscountPay,
            OpenDays = common_config:get_open_days(),
            Level = mod_role_data:get_role_level(State),
            VIPLevel = mod_role_vip:get_vip_level(State),
            IsFirstPay = mod_role_act_firstrecharge:is_first_pay(State),
            PayHasIDs = [ NowID || #r_discount_pay{id = NowID} <- TodayDiscounts] ++ FinishIDs,
            DailyHasIDs = [ ID || #r_daily_gift{id = ID} <- TodayDailyGifts] ++ FinishIDs,
            Now = time_tool:now(),
            Date = time_tool:date(),
            MidNight = time_tool:midnight(Now) + ?ONE_DAY,
            ConfigList = lib_config:list(cfg_discount_pay),
            ConfirmIDList = get_confirm_id_list3(?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE, State),
            { {AddPayList, ConditionList2, EventList2}, AddDailyList} = condition_update3(ConfigList, OpenDays, Date, Level, VIPLevel, IsFirstPay, PayHasIDs, DailyHasIDs, Now, MidNight, ConfirmIDList, ConditionList, EventList, [], []),
            case AddPayList =/= [] orelse AddDailyList =/= [] of
                true ->
                    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_discounts = AddPayList ++ TodayDiscounts, today_daily_gifts = AddDailyList ++ TodayDailyGifts, condition_list = ConditionList2, event_list = EventList2},
                    {true, State#r_role{role_discount_pay = RoleDiscountPay2}};
                _ ->
                    {false, State}
            end;
        _ ->
            {false, State}
    end.

condition_update3([], _OpenDays, _Date, _Level, _VIPLevel, _IsFirstPay, _PayHasIDs, _DailyHasIDs, _Now, _MidNight, _ConfirmIDList, ConditionListAcc, EventListAcc, AddPayAcc, AddDailyAcc) ->
    { {AddPayAcc, ConditionListAcc, EventListAcc}, AddDailyAcc};
condition_update3([{ID, Config}|R], OpenDays, Date, Level, VIPLevel, IsFirstPay, PayHasIDs, DailyHasIDs, Now, MidNight, ConfirmIDList, ConditionListAcc, EventListAcc, AddPayAcc, AddDailyAcc) ->
    #c_discount_pay{id = ID, days = Days, date = ConfigDate, week_day = ConfigWeek} = Config,
    {{ AddPayAcc2, ConditionListAcc2, EventListAcc2}, AddDailyAcc2} =
        case lists:member(ID, ?DAILY_GIFT_LIST) of
            true -> %% 每日活跃礼包
                { {AddPayAcc, ConditionListAcc, EventListAcc}, get_condition_daily_gift(ID, DailyHasIDs, AddDailyAcc)};
            _ -> %% 特惠充值礼包
                case Days =:= 0 andalso ConfigDate =:= [] andalso ConfigWeek =:= [] of
                    true ->
                        {get_extra_condition_discount_pay(ID, Config, Now, MidNight, ConfirmIDList, ConditionListAcc, EventListAcc, AddPayAcc), AddDailyAcc};
                    _ ->
                        {get_condition_discount_pay(ID, Config, OpenDays, Date, Level, VIPLevel, IsFirstPay, PayHasIDs, Now, MidNight, ConditionListAcc, EventListAcc, AddPayAcc), AddDailyAcc}
                end
        end,
    condition_update3(R, OpenDays, Date, Level, VIPLevel, IsFirstPay, PayHasIDs, DailyHasIDs, Now, MidNight, ConfirmIDList, ConditionListAcc2, EventListAcc2, AddPayAcc2, AddDailyAcc2).

get_condition_daily_gift(ID, DailyHasIDs, AddDailyAcc) ->
    case lists:member(ID, DailyHasIDs) of
        true ->
            AddDailyAcc;
        _ ->
            [#r_daily_gift{id = ID, is_reward = false}|AddDailyAcc]
    end.

get_condition_discount_pay(ID, Config, OpenDays, Date, Level, VIPLevel, IsFirstPay, PayHasIDs, Now, MidNight, ConditionListAcc, EventListAcc, AddPayAcc) ->
    #c_discount_pay{
        days = ConfigDays,
        date = ConfigDate,
        limit_time = LimitTime,
        week_day = WeekDay
        } = Config,
    case not lists:member(ID, PayHasIDs) andalso is_days_fit2(ConfigDays, ConfigDate, OpenDays, Date, WeekDay) of
        true ->
            IsFit = is_fit(Config, IsFirstPay, Level, VIPLevel),
            ?IF(IsFit, {[#r_discount_pay{id = ID, buy_num = 0, end_time = erlang:min(Now + LimitTime * ?ONE_MINUTE, MidNight)}|AddPayAcc], ConditionListAcc, EventListAcc}, {AddPayAcc, ConditionListAcc, EventListAcc});
        _ ->
            {AddPayAcc, ConditionListAcc, EventListAcc}
    end.

is_days_fit(ConfigDays, ConfigDate, OpenDays, Date) ->
    case ConfigDate of
        [] ->
            ConfigDays =:= OpenDays;
        [Year, Month, Day] ->
            OpenDays >= ConfigDays andalso Date =:= {Year, Month, Day}
    end.

is_days_fit2(ConfigDays, ConfigDate, OpenDays, Date, WeekDay) ->
    case ConfigDate of
        [] ->
            case WeekDay of
                [] ->
                    ConfigDays =:= OpenDays;
                _ ->
                    CurWeekDay = time_tool:weekday(),
                    OpenDays >= ConfigDays andalso lists:member(CurWeekDay, WeekDay)
            end;
        [Year, Month, Day] ->
            OpenDays >= ConfigDays andalso Date =:= {Year, Month, Day}
    end.

is_fit(Config, IsFirstPay, Level, VIPLevel) ->
    #c_discount_pay{
        condition_type = ConditionType, condition_args = ConditionArgs, condition_type2 = ConditionType2, condition_args2 = ConditionArgs2,
        condition_type3 = ConditionType3, condition_args3 = ConditionArgs3} = Config,
    ConditionArgsList = lib_tool:string_to_integer_list(ConditionArgs,";"),
    ConditionArgsList2 = lib_tool:string_to_integer_list(ConditionArgs2,";"),
    ConditionArgsList3 = lib_tool:string_to_integer_list(ConditionArgs3,";"),
    IsFit = is_fit2(IsFirstPay, Level, VIPLevel, ConditionType, ConditionArgsList),
    IsFit2 = is_fit2(IsFirstPay, Level, VIPLevel, ConditionType2, ConditionArgsList2),
    IsFit3 = is_fit2(IsFirstPay, Level, VIPLevel, ConditionType3, ConditionArgsList3),
    case ConditionArgsList =:= [] of
        true ->
            case ConditionArgsList2 =:= [] of
                true ->
                    case ConditionArgsList3 =:= [] of
                        true -> IsFit orelse IsFit2 orelse IsFit3;
                        _ -> IsFit3
                    end;
                _ -> ?IF(ConditionArgsList3 =:= [], IsFit2, IsFit3 orelse IsFit2)
            end;
        _ ->
            case ConditionArgsList2 =:= [] of
                true ->
                    case ConditionArgsList3 =:= [] of
                        true -> IsFit;
                        _ -> IsFit3 orelse IsFit
                    end;
                _ -> ?IF(ConditionArgsList3 =:= [], IsFit orelse IsFit2, IsFit orelse IsFit2 orelse IsFit3)
            end
    end.

is_fit2(IsFirstPay, Level, VIPLevel, ConditionType, ConditionArgs) ->
    case lists:member(ConditionType, ?DISCOUNT_CONDITION_LIST) of
        true -> false;
        _ ->
            if
                ConditionType =:= ?DISCOUNT_CONDITION_HAS_FIRST_CHARGE ->
                    IsFirstPay;
                ConditionType =:= ?DISCOUNT_CONDITION_NOT_FIRST_CHARGE ->
                    not IsFirstPay;
                ConditionType =:= ?DISCOUNT_CONDITION_ABOVE_LEVEL ->
                    ConditionArgs =/= [] andalso Level >= lists:nth(1, ConditionArgs);
                ConditionType =:= ?DISCOUNT_CONDITION_BELOW_LEVEL ->
                    ConditionArgs =/= [] andalso Level =< lists:nth(1, ConditionArgs);
                ConditionType =:= ?DISCOUNT_CONDITION_ABOVE_VIP_LEVEL ->
                    ConditionArgs =/= [] andalso VIPLevel >= lists:nth(1, ConditionArgs);
                ConditionType =:= ?DISCOUNT_CONDITION_BELOW_VIP_LEVEL ->
                    ConditionArgs =/= [] andalso VIPLevel =< lists:nth(1, ConditionArgs);
                true ->
                    true
            end
    end.

get_extra_condition_discount_pay(ID, Config, Now, MidNight, ConfirmIDList, ConditionListAcc, EventListAcc, AddPayAcc) ->
    #c_discount_pay{cd_time = CDTime, limit_time = LimitTime} = Config,
    lists:foldl(fun(#r_event{type = Type, trigger_list = TriggerList}, {Acc1, Acc2, Acc3}) ->
        case Type =:= ?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE of
            true ->
                case lists:member(ID, ConfirmIDList) andalso not lists:member(ID, TriggerList) of
                    true ->
                        StartTime = case lists:keyfind(ID, #p_kv.id, ConditionListAcc) of
                                        #p_kv{id = ID, val = Time} -> Time;
                                        _ -> 0
                                    end,
                        %% 触发完把id从trigger_list添加
                        case Now > (CDTime * ?AN_HOUR + StartTime)  of
                            true ->
                                AddPayAcc2 = [#r_discount_pay{id = ID, buy_num = 0, end_time = erlang:min(Now + LimitTime * ?ONE_MINUTE, MidNight)}| Acc1],
                                ConditionListAcc2 = lists:keystore(ID, #p_kv.id, Acc2, #p_kv{id = ID, val = Now}),
                                EventListAcc2 = lists:keystore(Type, #r_event.type, Acc3, #r_event{type = Type, trigger_list = lib_tool:list_filter_repeat([ID | TriggerList])}),
                                {AddPayAcc2, ConditionListAcc2, EventListAcc2};
                            _ ->
                                {Acc1, Acc2, Acc3}
                        end;
                    _ ->
                        {Acc1, Acc2, Acc3}
                end;
            _ ->
                case lists:member(ID, TriggerList) of
                    true ->
                        StartTime = case lists:keyfind(ID, #p_kv.id, ConditionListAcc) of
                                        #p_kv{id = ID, val = Time} -> Time;
                                        _ -> 0
                                    end,
                        %% 触发完把id从trigger_list删除
                        case Now > (CDTime * ?AN_HOUR + StartTime)  of
                            true ->
                                AddPayAcc2 = [#r_discount_pay{id = ID, buy_num = 0, end_time = erlang:min(Now + LimitTime * ?ONE_MINUTE, MidNight)}| Acc1],
                                ConditionListAcc2 = lists:keystore(ID, #p_kv.id, Acc2, #p_kv{id = ID, val = Now}),
                                EventListAcc2 = lists:keystore(Type, #r_event.type, Acc3, #r_event{type = Type, trigger_list = (lists:delete(ID, TriggerList))}),
                                {AddPayAcc2, ConditionListAcc2, EventListAcc2};
                            _ ->
                                EventListAcc2 = lists:keystore(Type, #r_event.type, Acc3, #r_event{type = Type, trigger_list = (lists:delete(ID, TriggerList))}),
                                {Acc1, Acc2, EventListAcc2}
                        end;
                    _ ->
                        {Acc1, Acc2, Acc3}
        end end end, {AddPayAcc, ConditionListAcc, EventListAcc}, EventListAcc).

%% 开启条件 101- 106 109 判断
is_confirm_condition(Type, Level, MapID, ConditionArgsList) ->
    if
        Type =:= ?DISCOUNT_CONDITION_FIVE_ELEMENT_FAILED ->
            (ConditionArgsList =/= [] andalso MapID >= lists:nth(1, ConditionArgsList) andalso MapID =< lists:nth(2, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_FAMILY_ESCORT_FAILED ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_ENTER_COPY_EXP ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_STRENGTH_COIN_NOT_ENOUGH ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_EQUIP_CONCISE ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_STONE_HONE ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        Type =:= ?DISCOUNT_CONDITION_BUY_CONFINE_CROSSOVER ->
            (ConditionArgsList =/= [] andalso Level > lists:nth(1, ConditionArgsList));
        true ->
            false
    end.

get_config(Config) ->
    #c_discount_pay{condition_type = ConditionType, condition_type2 = ConditionType2, condition_type3 = ConditionType3,
        condition_args = ConditionArgs, condition_args2 = ConditionArgs2, condition_args3 = ConditionArgs3} = Config,
    ConditionArgsList = lib_tool:string_to_integer_list(ConditionArgs,";"),
    ConditionArgsList2 = lib_tool:string_to_integer_list(ConditionArgs2,";"),
    ConditionArgsList3 = lib_tool:string_to_integer_list(ConditionArgs3,";"),
    {ConditionType, ConditionType2, ConditionType3, ConditionArgsList, ConditionArgsList2, ConditionArgsList3}.

%% 获取符合条件的id 开启条件107
get_confirm_id_list2(Type, PayID) ->
    ConfirmIDList =
        lists:foldl(fun({ID, Config}, Acc) ->
            {ConditionType, ConditionType2, ConditionType3, ConditionArgsList, ConditionArgsList2, ConditionArgsList3} = get_config(Config),
            case lists:member(Type, [ConditionType, ConditionType2, ConditionType3]) of
                true ->
                    Result = case ConditionType =:= Type of
                                 true -> PayID =:= lists:nth(1, ConditionArgsList);
                                 _ ->
                                     ?IF(ConditionType2 =:= Type, PayID =:= lists:nth(1, ConditionArgsList2),
                                         PayID =:= lists:nth(1, ConditionArgsList3))
                             end,
                    ?IF(Result, [ID | Acc], Acc);
                _ ->  Acc
            end end, [], lib_config:list(cfg_discount_pay)),
    ConfirmIDList.

%% 开启条件 108 判断
is_confirm_condition2(Type, TodayDiscounts, ConditionArgsList) ->
    if
        Type =:= ?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE ->
            Now = time_tool:now(),
            EndTimeList = [{BuyNum, EndTime} || #r_discount_pay{id = ID, buy_num = BuyNum, end_time = EndTime} <- TodayDiscounts, ConditionArgsList =/= [], ID =:= lists:nth(1, ConditionArgsList)],
            ConditionArgsList =/= [] andalso EndTimeList =/= [] andalso ((Now - erlang:element(2, lists:nth(1, EndTimeList))) >= lists:nth(2, ConditionArgsList) * ?ONE_MINUTE)
                andalso erlang:element(1, lists:nth(1, EndTimeList)) =:= 0;
        true ->
            false
    end.

%% 获取符合条件的id 开启条件101 - 106
get_confirm_id_list(Type, State) ->
    Level = mod_role_data:get_role_level(State),
    MapID = mod_role_data:get_role_map_id(State),
    lists:foldl(fun({ID, Config}, Acc) ->
        {ConditionType, ConditionType2, ConditionType3, ConditionArgsList, ConditionArgsList2, ConditionArgsList3} = get_config(Config),
        case lists:member(Type, [ConditionType, ConditionType2, ConditionType3]) of
            true ->
                Result =
                    case ConditionType =:= Type of
                        true ->
                            is_confirm_condition(Type, Level, MapID, ConditionArgsList);
                        _ ->
                            ?IF(ConditionType2 =:= Type,  is_confirm_condition(Type, Level, MapID, ConditionArgsList2),
                                is_confirm_condition(Type, Level, MapID, ConditionArgsList3))
                    end,
                ?IF(Result, [ID | Acc], Acc);
            _ ->
                Acc
        end end, [], lib_config:list(cfg_discount_pay)).

%% 获取符合条件的id 开启条件108
get_confirm_id_list3(Type, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{today_discounts = TodayDiscounts} = RoleDiscountPay,
    lists:foldl(fun({ID, Config}, Acc) ->
        {ConditionType, ConditionType2, ConditionType3, ConditionArgsList, ConditionArgsList2, ConditionArgsList3} = get_config(Config),
        case lists:member(Type, [ConditionType, ConditionType2, ConditionType3]) of
            true ->
                Result = case ConditionType =:= Type of
                             true ->
                                 is_confirm_condition2(Type, TodayDiscounts, ConditionArgsList);
                             _ ->
                                 ?IF(ConditionType2 =:= Type, is_confirm_condition2(Type, TodayDiscounts, ConditionArgsList2),
                                     is_confirm_condition2(Type, TodayDiscounts, ConditionArgsList3))
                         end,
                ?IF(Result, [ID | Acc], Acc);
            _ -> Acc
        end end, [], lib_config:list(cfg_discount_pay)).


%% 触发之后把符合条件的id写进event_list  开启条件（除了107） 开启条件108不把id写进event_list
trigger_condition(Type, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{event_list = EventList} = RoleDiscountPay,
    ConfirmIDList = get_confirm_id_list(Type, State),
    EventList2 =
    case Type =:= ?DISCOUNT_CONDITION_BUY_DISCOUNT_EXPIRE  of
        true ->
            Event2 =
                case lists:keyfind(Type, #r_event.type, EventList) of
                    #r_event{} = Event ->
                        Event;
                    _ ->
                        #r_event{type = Type, trigger_list = []}
                end,
            lists:keystore(Type, #r_event.type, EventList, Event2);
        _ ->
            lists:keystore(Type, #r_event.type, EventList, #r_event{type = Type, trigger_list = ConfirmIDList})
    end,
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{event_list = EventList2},
    State#r_role{role_discount_pay = RoleDiscountPay2}.

%% 触发之后把符合条件的id写进event_list  开启条件107
trigger_condition2(Type, PayID, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{event_list = EventList} = RoleDiscountPay,
    ConfirmIDList = get_confirm_id_list2(Type, PayID),
    EventList2 = lists:keystore(Type, #r_event.type, EventList, #r_event{type = Type, trigger_list = ConfirmIDList}),
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{event_list = EventList2},
    State#r_role{role_discount_pay = RoleDiscountPay2}.

%% 活跃礼包领取
do_daily_reward(RoleID, DailyID, State) ->
    case catch check_daily_reward(DailyID, State) of
        {ok, DailyGift, BagDoings, State2} ->
            common_misc:unicast(RoleID, #m_discount_pay_daily_reward_toc{daily_gift = get_p_daily_gift(DailyGift)}),
            mod_role_bag:do(BagDoings, State2);
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_discount_pay_daily_reward_toc{err_code = ErrCode}),
            State
    end.

check_daily_reward(DailyID, State) ->
    #r_role{role_discount_pay = RoleDiscountPay} = State,
    #r_role_discount_pay{today_daily_gifts = TodayDailyGifts} = RoleDiscountPay,
    {DailyGift, TodayDailyGifts2} =
        case lists:keytake(DailyID, #r_daily_gift.id, TodayDailyGifts) of
            {value, TodayDailyT, TodayDailyGifts2T} ->
                {TodayDailyT, TodayDailyGifts2T};
            _ ->
                ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)
        end,
    #r_daily_gift{is_reward = IsReward} = DailyGift,
    ?IF(IsReward, ?THROW_ERR(?ERROR_DISCOUNT_PAY_DAILY_REWARD_001), ok),
    [#c_discount_pay{condition_args = ConditionArgs, condition_args2 = ConditionArgs2, condition_args3 = ConditionArgs3, reward = Reward}] = lib_config:find(cfg_discount_pay, DailyID),
    ?IF(mod_role_daily_liveness:get_daily_liveness(State) >= get_need_active(ConditionArgs, ConditionArgs2, ConditionArgs3), ok, ?THROW_ERR(?ERROR_DISCOUNT_PAY_DAILY_REWARD_002)),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_DISCOUNT_DAILY, GoodsList}],
    DailyGift2 = DailyGift#r_daily_gift{is_reward = true},
    TodayDailyGifts3 = [DailyGift2|TodayDailyGifts2],
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_daily_gifts = TodayDailyGifts3},
    State2 = State#r_role{role_discount_pay = RoleDiscountPay2},
    {ok, DailyGift2, BagDoings, State2}.

online_modify_time(State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = RolePrivateAttr, role_discount_pay = RoleDiscountPay} = State,
    #r_role_attr{last_offline_time = LastOfflineTime} = RoleAttr,
    #r_role_private_attr{last_login_time = LastLoginTime} = RolePrivateAttr,
    #r_role_discount_pay{today_discounts = TodayDiscounts} = RoleDiscountPay,
    TodayMidnight = time_tool:midnight(),
    TodayDiscounts2 =
        [ begin
              EndTime2 = erlang:min(EndTime + LastLoginTime - LastOfflineTime, TodayMidnight + ?ONE_DAY),
              DisCountPay#r_discount_pay{end_time = EndTime2}
          end|| #r_discount_pay{end_time = EndTime} = DisCountPay <- TodayDiscounts, EndTime > TodayMidnight],
    RoleDiscountPay2 = RoleDiscountPay#r_role_discount_pay{today_discounts = TodayDiscounts2},
    State#r_role{role_discount_pay = RoleDiscountPay2}.

notice_info(State2) ->
    #r_role{role_id = RoleID, role_discount_pay = RoleDiscountPay} = State2,
    #r_role_discount_pay{today_discounts = TodayDiscounts, today_daily_gifts = TodayDailyGifts} = RoleDiscountPay,
    DiscountPayPList = get_p_discount_pay(TodayDiscounts),
    DailyPList = get_p_daily_list(TodayDailyGifts),
    DataRecord = #m_discount_pay_info_toc{pay_list = DiscountPayPList, daily_gift = DailyPList},
    common_misc:unicast(RoleID, DataRecord).

log_discount_pay(BuyID, ProductID, PackageName, GoodsList, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    [#c_pay{pay_money = PayMoney}] = lib_config:find(cfg_pay, ProductID),
    Log = #log_discount_pay{
        role_id = RoleID,
        buy_id = BuyID,
        package_name = unicode:characters_to_binary(PackageName),
        goods_string = common_misc:to_goods_string(GoodsList),
        pay_money = PayMoney,
        channel_id = ChannelID,
        game_channel_id = GameChannelID},
    mod_role_dict:add_background_logs(Log).

get_p_discount_pay(TodayDiscounts) ->
    Now = time_tool:now(),
    [ begin
          [#c_discount_pay{
              product_id = ProductID,
              reward = Reward,
              old_price = OldPrice,
              now_price = NowPrice,
              limit_num = LimitNum,
              package_name = PackageName
          }] = lib_config:find(cfg_discount_pay, ID),
          #p_discount_pay{
              id = ID,
              buy_num = BuyNum,
              end_time = EndTime,
              product_id = ProductID,
              goods_list = get_front_goods(common_misc:get_item_reward(Reward), []),
              old_price = OldPrice,
              now_price = NowPrice,
              limit_num = LimitNum,
              package_name = PackageName}
      end|| #r_discount_pay{id = ID, buy_num = BuyNum, end_time = EndTime} <- TodayDiscounts, EndTime >= Now].

get_front_goods([], Acc) ->
    lists:reverse(Acc);
get_front_goods([Item|R], Acc) ->
    KV =
        case Item of
            {TypeID, Num, _Bind} ->
                #p_kv{id = TypeID, val = Num};
            {TypeID, Num} ->
                #p_kv{id = TypeID, val = Num}
        end,
    get_front_goods(R, [KV|Acc]).

get_p_daily_list(TodayDailyGifts) ->
    [ get_p_daily_gift(TodayDaily) || TodayDaily<- TodayDailyGifts].

get_p_daily_gift(TodayDaily) ->
    #r_daily_gift{id = ID, is_reward = IsReward} = TodayDaily,
    [#c_discount_pay{
        reward = Reward,
        condition_args = ConditionArgs,
        condition_args2 = ConditionArgs2,
        condition_args3 = ConditionArgs3,
        old_price = OldPrice,
        package_name = PackageName
    }] = lib_config:find(cfg_discount_pay, ID),
    #p_daily_gift{
        id = ID,
        is_reward = IsReward,
        need_active = get_need_active(ConditionArgs, ConditionArgs2, ConditionArgs3),
        goods_list = get_front_goods(common_misc:get_item_reward(Reward), []),
        old_price = OldPrice,
        package_name = PackageName}.

get_need_active(ConditionArgs, ConditionArgs2, ConditionArgs3) ->
    case ConditionArgs =/= [] of
        true -> lists:nth(1, lib_tool:string_to_integer_list(ConditionArgs,";"));
        _ ->
            case ConditionArgs2 =/= [] of
                true -> lists:nth(1, lib_tool:string_to_integer_list(ConditionArgs2,";"));
                _ -> lists:nth(1, lib_tool:string_to_integer_list(ConditionArgs3,";"))
            end
    end.