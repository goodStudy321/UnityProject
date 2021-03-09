%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. 七月 2019 14:33
%%%-------------------------------------------------------------------
-module(mod_role_daily_buy).
-author("laijichang").
-include("role.hrl").
-include("discount_pay.hrl").
-include("proto/mod_role_daily_buy.hrl").

%% API
-export([
    init/1,
    online/1,
    day_reset/1,
    zero/1,
    handle/2
]).

-export([
    gm_clear/1,
    condition_update/1
]).

init(#r_role{role_id = RoleID, role_daily_buy = undefined} = State) ->
    RoleDailyBuy = #r_role_daily_buy{role_id = RoleID},
    State#r_role{role_daily_buy = RoleDailyBuy};
init(State) ->
    State.

online(State) ->
    State2 = online_modify_time(State),
    {_IsChange, State3} = condition_update2(State2),
    notice_info(State3),
    State3.

zero(State) ->
    {_IsChange, State2} = condition_update2(State),
    notice_info(State2),
    State2.

day_reset(State) ->
    #r_role{role_daily_buy = RoleDailyBuy} = State,
    RoleDailyBuy2 = RoleDailyBuy#r_role_daily_buy{buy_list = [], finish_ids = []},
    State2 = State#r_role{role_daily_buy = RoleDailyBuy2},
    State2.

handle({#m_role_daily_buy_tos{id = ID}, RoleID, _PID}, State) ->
    do_daily_buy(RoleID, ID, State);
handle(condition_update, State) ->
    do_condition_update(State).

gm_clear(State) ->
    #r_role{role_daily_buy = RoleDailyBuy} = State,
    RoleDailyBuy2 = RoleDailyBuy#r_role_daily_buy{buy_list = [], finish_ids = []},
    State2 = State#r_role{role_daily_buy = RoleDailyBuy2},
    {_IsChange, State3} = condition_update2(State2),
    online(State3).

%% 外部接口调用
condition_update(State) ->
    role_misc:info_role(State#r_role.role_id, ?MODULE, condition_update),
    State.

do_condition_update(State) ->
    {IsChange, State2} = condition_update2(State),
    ?IF(IsChange, notice_info(State2), ok),
    State2.

condition_update2(State) ->
    case mod_role_data:get_role_level(State) >= common_misc:get_global_int(?GLOBAL_DAILY_BUY) of
        true -> %% 达到特定等级才开启
            #r_role{role_daily_buy = RoleDailyBuy} = State,
            #r_role_daily_buy{buy_list = BuyList, finish_ids = FinishIDs} = RoleDailyBuy,
            OpenDays = common_config:get_open_days(),
            Level = mod_role_data:get_role_level(State),
            VIPLevel = mod_role_vip:get_vip_level(State),
            IsFirstPay = mod_role_act_firstrecharge:is_first_pay(State),
            HasIDs = [ NowID || #p_kv{id = NowID} <- BuyList] ++ FinishIDs,
            Now = time_tool:now(),
            Date = time_tool:date(),
            MidNight = time_tool:midnight(Now) + ?ONE_DAY,
            AddList = condition_update3(lib_config:list(cfg_daily_buy), OpenDays, Date, Level, VIPLevel, IsFirstPay, HasIDs, Now, MidNight, []),
            case AddList =/= [] of
                true ->
                    RoleDailyBuy2 = RoleDailyBuy#r_role_daily_buy{buy_list = AddList ++ BuyList},
                    {true, State#r_role{role_daily_buy = RoleDailyBuy2}};
                _ ->
                    {false, State}
            end;
        _ ->
            {false, State}
    end.

condition_update3([], _OpenDays, _Date, _Level, _VIPLevel, _IsFirstPay, _HasIDs, _Now, _MidNight, AddAcc) ->
    AddAcc;
condition_update3([{ID, Config}|R], OpenDays, Date, Level, VIPLevel, IsFirstPay, HasIDs, Now, MidNight, AddAcc) ->
    #c_daily_buy{
        days = ConfigDays,
        date = ConfigDate,
        condition_type = ConditionType,
        condition_args = ConditionArgs,
        limit_time = LimitTime} = Config,
    case not lists:member(ID, HasIDs) andalso mod_role_discount_pay:is_days_fit(ConfigDays, ConfigDate, OpenDays, Date) of
        true ->
            IsFit =
                if
                    ConditionType =:= ?DISCOUNT_CONDITION_HAS_FIRST_CHARGE ->
                        IsFirstPay;
                    ConditionType =:= ?DISCOUNT_CONDITION_NOT_FIRST_CHARGE ->
                        not IsFirstPay;
                    ConditionType =:= ?DISCOUNT_CONDITION_ABOVE_LEVEL ->
                        Level >= ConditionArgs;
                    ConditionType =:= ?DISCOUNT_CONDITION_BELOW_LEVEL ->
                        Level =< ConditionArgs;
                    ConditionType =:= ?DISCOUNT_CONDITION_ABOVE_VIP_LEVEL ->
                        VIPLevel >= ConditionArgs;
                    ConditionType =:= ?DISCOUNT_CONDITION_BELOW_VIP_LEVEL ->
                        VIPLevel =< ConditionArgs;
                    true ->
                        true
                end,
            AddAcc2 = ?IF(IsFit, [#p_kv{id = ID, val = erlang:min(Now + LimitTime * ?ONE_MINUTE, MidNight)}|AddAcc], AddAcc),
            condition_update3(R, OpenDays, Date, Level, VIPLevel, IsFirstPay, HasIDs, Now, MidNight, AddAcc2);
        _ ->
            condition_update3(R, OpenDays, Date, Level, VIPLevel, IsFirstPay, HasIDs, Now, MidNight, AddAcc)
    end.

do_daily_buy(RoleID, ID, State) ->
    case catch check_can_buy(ID, State) of
        {ok, AssetDoing, BagDoing, Log, State2} ->
            State3 = mod_role_asset:do(AssetDoing, State2),
            State4 = mod_role_bag:do(BagDoing, State3),
            mod_role_dict:add_background_logs(Log),
            common_misc:unicast(RoleID, #m_role_daily_buy_toc{id = ID}),
            State4;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_daily_buy_toc{err_code = ErrCode}),
            State
    end.

check_can_buy(ID, State) ->
    #r_role{role_daily_buy = RoleDailyBuy} = State,
    #r_role_daily_buy{buy_list = BuyList, finish_ids = FinishIDs} = RoleDailyBuy,
    {KV, BuyList2} =
        case lists:keytake(ID, #p_kv.id, BuyList) of
            {value, #p_kv{} = KVT, BuyListT} ->
                {KVT, BuyListT};
            _ ->
                ?THROW_ERR(?ERROR_ROLE_DAILY_BUY_001)
        end,
    #p_kv{val = EndTime} = KV,
    ?IF(EndTime >= time_tool:now(), ok, ?THROW_ERR(?ERROR_ROLE_DAILY_BUY_001)),
    [#c_daily_buy{
        reward = Reward,
        asset_type = AssetType,
        asset_value = AssetValue}] = lib_config:find(cfg_daily_buy, ID),
    GoodsList = common_misc:get_reward_p_goods(common_misc:get_item_reward(Reward)),
    AssetDoing = mod_role_asset:check_asset_by_type(AssetType, AssetValue, ?ASSET_GOLD_REDUCE_FROM_DAILY_PANIC_BUY, State),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    BagDoings = [{create, ?ITEM_GAIN_DAILY_PANIC_BUY, GoodsList}],
    FinishIDs2 = [ID|FinishIDs],
    RoleDailyBuy2 = RoleDailyBuy#r_role_daily_buy{buy_list = BuyList2, finish_ids = FinishIDs2},
    State2 = State#r_role{role_daily_buy = RoleDailyBuy2},
    Log = get_daily_buy_log(ID, GoodsList, AssetType, AssetValue, State),
    {ok, AssetDoing, BagDoings, Log, State2}.


online_modify_time(State) ->
    #r_role{role_attr = RoleAttr, role_private_attr = RolePrivateAttr, role_daily_buy = RoleDailyBuy} = State,
    #r_role_attr{last_offline_time = LastOfflineTime} = RoleAttr,
    #r_role_private_attr{last_login_time = LastLoginTime} = RolePrivateAttr,
    #r_role_daily_buy{buy_list = BuyList} = RoleDailyBuy,
    TodayMidnight = time_tool:midnight(),
    BuyList2 =
        [ begin
              EndTime2 = erlang:min(EndTime + LastLoginTime - LastOfflineTime, TodayMidnight + ?ONE_DAY),
              KV#p_kv{val = EndTime2}
          end|| #p_kv{val = EndTime} = KV <- BuyList, EndTime > TodayMidnight],
    RoleDailyBuy2 = RoleDailyBuy#r_role_daily_buy{buy_list = BuyList2},
    State#r_role{role_daily_buy = RoleDailyBuy2}.

notice_info(State) ->
    case mod_role_data:get_role_level(State) >= common_misc:get_global_int(?GLOBAL_DAILY_BUY) of
        true ->
            #r_role{role_id = RoleID, role_daily_buy = RoleDailyBuy} = State,
            #r_role_daily_buy{buy_list = BuyList} = RoleDailyBuy,
            Now = time_tool:now(),
            PList =
                [ begin
                      [#c_daily_buy{
                          reward = Reward,
                          asset_type = AssetType,
                          old_asset_value = OldPrice,
                          asset_value = NowPrice,
                          discount = Discount
                      }] = lib_config:find(cfg_daily_buy, ID),
                      #p_daily_buy{
                          id = ID,
                          end_time = EndTime,
                          goods_list = [ #p_kv{id = TypeID, val = Num}|| {TypeID, Num, _Bind} <- common_misc:get_item_reward(Reward)],
                          asset_type = AssetType,
                          old_price = OldPrice,
                          now_price = NowPrice,
                          discount = Discount
                      }
                  end|| #p_kv{id = ID, val = EndTime} <- BuyList, EndTime >= Now],
            ?IF(PList =/= [], common_misc:unicast(RoleID,  #m_role_daily_buy_info_toc{list = PList}), ok);
        _ ->
            ok
    end.

get_daily_buy_log(BuyID, GoodsList, AssetType, AssetValue, State) ->
    #r_role{role_attr = RoleAttr} = State,
    #r_role_attr{
        role_id = RoleID,
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #log_daily_buy{
        role_id = RoleID,
        buy_id = BuyID,
        goods_string = common_misc:to_goods_string(GoodsList),
        asset_type = AssetType,
        asset_value = AssetValue,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.

