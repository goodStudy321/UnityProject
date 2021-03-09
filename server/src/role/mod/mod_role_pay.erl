%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 六月 2018 12:20
%%%-------------------------------------------------------------------
-module(mod_role_pay).
-author("laijichang").
-include("pay.hrl").
-include("role.hrl").
-include("bg_act.hrl").
-include("proto/mod_role_pay.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    zero/1,
    online/1,
    handle/2
]).

-export([
    role_pay/2,
    use_pay_item/2,
    gm_pay/2,
    gm_product_id/2,
    get_product_id_by_pay_fee/1
]).

init(#r_role{role_id = RoleID, role_pay = undefined} = State) ->
    RolePay = #r_role_pay{role_id = RoleID},
    State#r_role{role_pay = RolePay};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_pay = RolePay} = State,
    RolePay2 = RolePay#r_role_pay{today_pay_gold = 0, today_pay_list = []},
    State#r_role{role_pay = RolePay2}.

zero(State) ->
    online(State).

online(State) ->
    #r_role{role_id = RoleID, role_pay = RolePay} = State,
    #r_role_pay{
        first_pay_list = FirstPayList,
        package_time = PackageTime,
        package_days = PackageDays,
        today_pay_gold = TodayPayGold,
        total_pay_gold = TotalPayGold} = RolePay,
    Now = time_tool:now(),
    case PackageDays > 0 andalso (not time_tool:is_same_date(PackageTime, Now)) of
        true ->
            PackageDays2 = PackageDays - 1,
            RolePay2 = RolePay#r_role_pay{package_days = PackageDays2, package_time = Now},
            [#c_pay{package_goods = PackageGoods}] = lib_config:find(cfg_pay, ?PACKAGE_PRODUCT_ID),
            GoodsList = [#p_goods{type_id = TypeID, num = Num} || {TypeID, Num} <- common_misc:get_item_reward(PackageGoods)],
            LetterInfo = #r_letter_info{
                template_id = ?LETTER_PAY_PACKAGE,
                action = ?ITEM_GAIN_LETTER_PAY_GIFT,
                text_string = [lib_tool:to_list(PackageDays2)],
                goods_list = GoodsList},
            common_letter:send_letter(RoleID, LetterInfo);
        _ ->
            PackageDays2 = PackageDays,
            RolePay2 = RolePay
    end,
    DataRecord = #m_role_pay_info_toc{
        first_pay_list = FirstPayList,
        package_days = PackageDays2,
        today_pay_gold = TodayPayGold,
        total_pay_gold = TotalPayGold},
    common_misc:unicast(RoleID, DataRecord),
    State#r_role{role_pay = RolePay2}.


role_pay(RoleID, OrderID) ->
    role_misc:info_role(RoleID, {mod, ?MODULE, {role_pay, RoleID, OrderID}}).

use_pay_item(AddGold, State) ->
    AssetDoings = [{add_gold, ?ASSET_GOLD_ADD_FROM_BACK_SEND, AddGold, 0}],
    State2 = mod_role_asset:do(AssetDoings, State),
    PayFee = AddGold * 10,
    ProductID = get_product_id_by_pay_fee(PayFee),
    hook_role:role_pay(AddGold, ProductID, PayFee, State, State2).


gm_pay(AddGold, State) ->
    AssetDoings = [{add_gold, ?ASSET_GOLD_ADD_FROM_PAY_GOLD_ITEM, AddGold, 0}],
    PayFee = AddGold * 10,
    ProductID = get_product_id_by_pay_fee(PayFee),
    State2 = mod_role_asset:do(AssetDoings, State),
    State3 = hook_role:role_pay(AddGold, ProductID, PayFee, State, State2),
    State3.

gm_product_id(ProductID, State) ->
    [#c_pay{pay_money = PayMoney} = Config] = lib_config:find(cfg_pay, ProductID),
    case mod_role_addict:is_pay_ban(State, PayMoney) of
        {ok, NewState} ->
            do_role_pay2(Config, PayMoney * 100, State#r_role.role_id, NewState);
        false ->
            do_role_pay2(Config, PayMoney * 100, State#r_role.role_id, State);
        _ ->
            State
    end.

handle({role_pay, RoleID, OrderID}, State) ->
    do_role_pay(RoleID, OrderID, State);
handle({#m_role_pay_order_tos{product_id = ProductID}, RoleID, _PID}, State) ->
    do_get_order(RoleID, ProductID, State).

do_role_pay(RoleID, OrderID, State) ->
    case catch world_pay_server:role_pay(RoleID, OrderID) of
        {ok, _PFOrderID, ProductID, PayFee} ->
            case lib_config:find(cfg_pay, ProductID) of
                [Config] ->
                    do_role_pay2(Config, PayFee, RoleID, State);
                _ ->
                    ?ERROR_MSG("ProductID not found:~w", [ProductID, PayFee]),
                    State
            end;
        _ ->
            State
    end.

do_role_pay2(Config, PayFee, RoleID, State) ->
    #r_role{role_pay = RolePay, role_attr = RoleAttr, role_addict = RoleAddict} = State,
    #c_pay{
        product_id = ProductID,
        package_type = PackageType,
        pay_money = PayMoney,
        add_gold = AddGold,
        first_add_bind_gold = FirstAddBindGold,
        other_add_bind_gold = OtherAddBindGold,
        package_days = PackageDays} = Config,
    #r_role_pay{
        today_pay_gold = TodayPayGold,
        total_pay_gold = PayGold,
        total_pay_fee = TotalPayFee,
        package_days = OldPackageDays,
        first_pay_list = FirstPayList,
        today_pay_list = TodayPayList
    } = RolePay,
    RoleAddict2 = RoleAddict#r_role_addict{
        pay_money = RoleAddict#r_role_addict.pay_money + PayMoney
    },
    TodayPayList2 = add_today_pay_list(ProductID, TodayPayList),
    if
        PackageType =:= ?PACKAGE_PRODUCT_ID -> %% 每日礼包
            RolePay2 = RolePay#r_role_pay{
                today_pay_gold = TodayPayGold + AddGold,
                total_pay_gold = AddGold + PayGold,
                total_pay_fee = TotalPayFee + PayFee,
                package_days = OldPackageDays + PackageDays,
                today_pay_list = TodayPayList2
            },
            AssetDoings = [];
        PackageType =:= ?PACKAGE_TYPE_GOLD orelse PackageType =:= ?OTHER_PAY_GOLD -> %% 元宝充值
            case lists:member(ProductID, FirstPayList) of
                true ->
                    FirstPayList2 = FirstPayList,
                    AddBindGold = OtherAddBindGold;
                _ ->
                    FirstPayList2 = [ProductID|FirstPayList],
                    AddBindGold = FirstAddBindGold
            end,
            RolePay2 = RolePay#r_role_pay{
                today_pay_gold = TodayPayGold + AddGold,
                total_pay_gold = AddGold + PayGold,
                total_pay_fee = TotalPayFee + PayFee,
                first_pay_list = FirstPayList2,
                today_pay_list = TodayPayList2
            },
            Rate = get_pay_rate(),
            AssetDoings = [{add_gold, ?ASSET_GOLD_ADD_FROM_PAY, AddGold * Rate, AddBindGold}],
            LetterInfo =
            case AddBindGold > 0 of
                true ->
                    #r_letter_info{template_id = ?LETTER_PAY_GOLD, text_string = [lib_tool:to_list(AddGold), lib_tool:to_list(AddBindGold)]};
                _ ->
                    #r_letter_info{template_id = ?LETTER_PAY_GOLD2, text_string = [lib_tool:to_list(AddGold)]}
            end,
            common_letter:send_letter(RoleID, LetterInfo);
        true -> %% 其他
            RolePay2 = RolePay#r_role_pay{
                today_pay_gold = TodayPayGold + AddGold,
                total_pay_gold = AddGold + PayGold,
                total_pay_fee = TotalPayFee + PayFee,
                today_pay_list = TodayPayList2
            },
            AssetDoings = []
    end,
    family_server:add_box(?GLOBAL_FAMILY_BOX_PAY, PayMoney, RoleAttr#r_role_attr.family_id, State#r_role.role_id),
    State2 = State#r_role{role_pay = RolePay2, role_addict = RoleAddict2},
    State3 = mod_role_asset:do(AssetDoings, State2),
    State4 = hook_role:role_pay(AddGold, ProductID, PayFee, State, State3),
    State5 = do_package_pay(PackageType, ProductID, State4),
    common_misc:unicast(RoleID, #m_role_pay_succ_toc{product_id = ProductID}),
    State6 = online(State5),
    State6.



get_pay_rate() ->
    case world_bg_act_server:get_bg_act(?BG_ACT_DOUBLE_RECHARGE) of
        #r_bg_act{status = ?BG_ACT_STATUS_TWO} ->
            2;
        _ ->
            1
    end.


%% 礼包接口回调
do_package_pay(PackageType, ProductID, State) ->
    FunList = [
        fun(StateAcc) ->
            if
                PackageType =:= ?PAY_PACKAGE_DISCOUNT ->
                    mod_role_discount_pay:pay(ProductID, StateAcc);
                PackageType =:= ?KING_GUARD ->
                    mod_role_guard:activate_king_guard(StateAcc);
                PackageType =:= ?OPEN_ACT_ESOTERICA ->
                    mod_role_act_esoterica:purchase_celestial(StateAcc);
                true ->
                    StateAcc
            end
        end],
    role_server:execute_state_fun(FunList, State).

do_get_order(RoleID, ProductID, State) ->
    case catch check_get_order(ProductID, State) of
        {ok, State2} ->
            mod_role_dict:add_key_time(?MODULE, ?SECOND_MS),
            case catch world_pay_server:get_order_id() of
                {ok, OrderID} ->
                    Url = mod_role_pf:get_pf_pay_url(),
                    PFArgs = mod_role_pf:get_pf_pay_args(OrderID, ProductID, State),
                    common_misc:unicast(RoleID, #m_role_pay_order_toc{order_id = OrderID, product_id = ProductID, notify_url = Url, pf_args = PFArgs}),
                    State2;
                _ ->
                    ?ERROR_MSG("获取订单失败！！"),
                    common_misc:unicast(RoleID, #m_role_pay_order_toc{err_code = ?ERROR_COMMON_SYSTEM_ERROR}),
                    State2
            end;
        {error, ?ERROR_ROLE_PAY_ORDER_002} ->
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_role_pay_order_toc{err_code = ErrCode}),
            State
    end.

check_get_order(ProductID, State) ->
    Config =
    case lib_config:find(cfg_pay, ProductID) of
        [ConfigT] ->
            ConfigT;
        _ ->
            ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)
    end,
    case lib_config:find(cfg_warning, pay_ban_product_ids) of
        [List] ->
            ?IF(lists:member(ProductID, List), ?THROW_ERR(?ERROR_COMMON_FUNCTION_BAN), ok);
        _ ->
            ok
    end,
    #c_pay{
        pay_money = PayMoney,
        package_type = PackageType,
        game_channel_id_list = GameChannelIDList
    } = Config,
    State2 = case mod_role_addict:is_pay_ban(State, PayMoney) of
                 {ok, NewState} ->
                     NewState;
                 Res ->
                     ?IF(Res, ?THROW_ERR(?ERROR_ROLE_PAY_ORDER_002), ok),
                     State
             end,
    mod_role_dict:is_time_able(?MODULE),
    ?IF(is_game_channel_match(GameChannelIDList), ok, ?THROW_ERR(?ERROR_ROLE_PAY_ORDER_005)),
    mod_role_pf:check_pay_order(ProductID, State2),
    State3 =
    if
        PackageType =:= ?PAY_PACKAGE_DISCOUNT -> %% 特惠礼包在充值时，要判断一下。
            mod_role_discount_pay:check_pay(ProductID, State2);
        true ->
            State2
    end,
    {ok, State3}.

get_product_id_by_pay_fee(PayFee) ->
    get_product_id_by_pay_fee2(lib_config:list(cfg_pay), PayFee).

get_product_id_by_pay_fee2([], PayFee) ->
    ?ERROR_MSG("Unknow PayFee:~w", [PayFee]),
    0;
get_product_id_by_pay_fee2([{ProductID, #c_pay{pay_money = PayMoney}}|R], PayFee) ->
    case PayMoney * 100 =:= PayFee of
        true ->
            ProductID;
        _ ->
            get_product_id_by_pay_fee2(R, PayFee)
    end.

add_today_pay_list(ProductID, TodayPayList) ->
    case lists:keytake(ProductID, #p_kv.id, TodayPayList) of
        {value, #p_kv{val = OldVal} = KV, TodayPayList2} ->
            [KV#p_kv{val = OldVal + 1}|TodayPayList2];
        _ ->
            [#p_kv{id = ProductID, val = 1}|TodayPayList]
    end.

is_game_channel_match(GameChannelIDList) ->
    case GameChannelIDList =:= [] of
        true ->
            true;
        _ ->
            {_ChannelID, GameChannelID} = mod_role_dict:get_game_chanel_id(),
            lists:member(GameChannelID, GameChannelIDList)
    end.