%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 七月 2017 10:52
%%%-------------------------------------------------------------------
-module(mod_role_shop).
-author("laijichang").
-include("role.hrl").
-include("family.hrl").
-include("proto/mod_role_shop.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    init/1,
    day_reset/1,
    online/1,
    zero/1,
    handle/2
]).

-export([
    check_can_buy/4,
    get_shop_log/7
]).

init(#r_role{role_id = RoleID, role_shop = undefined} = State) ->
    RoleShop = #r_role_shop{role_id = RoleID},
    State#r_role{role_shop = RoleShop};
init(State) ->
    State.

day_reset(State) ->
    #r_role{role_shop = RoleShop} = State,
    #r_role_shop{buy_limit = BuyLimit} = RoleShop,
    IsWeekReset = role_misc:is_reset_week(State),
    BuyLimit2 =
    lists:foldl(fun(#p_kv{id = ID} = KV, Acc) ->
        case lib_config:find(cfg_shop, ID) of
            [#c_shop{limit_type = ShopLimit}] ->
                if
                    ShopLimit =:= 1 -> %% 每周重置
                        ?IF(IsWeekReset, Acc, [KV|Acc]);
                    true ->
                        Acc
                end;
            _ ->
                Acc
        end
                end, [], BuyLimit),
    RoleShop2 = RoleShop#r_role_shop{buy_limit = BuyLimit2},
    State#r_role{role_shop = RoleShop2}.

online(State) ->
    #r_role{role_id = RoleID, role_shop = RoleShop} = State,
    common_misc:unicast(RoleID, #m_shop_buy_limit_toc{buy_limit = RoleShop#r_role_shop.buy_limit}),
    State.

zero(State) ->
    online(State).

handle({#m_shop_buy_goods_tos{shop_id = ShopID, num = Num, type_id = TypeID}, RoleID, _PID}, State) ->
    do_buy_good(RoleID, ShopID, Num, TypeID, State).

do_buy_good(RoleID, ShopID, Num, TypeID, State) ->
    case catch check_can_buy(ShopID, Num, TypeID, State) of
        {ok, ItemID, GoodsList, AssetDoing, LogList, State2, IsUpdate} ->
            BagDoing = [{create, ?ITEM_GAIN_SHOP_BUY, GoodsList}],
            State3 = mod_role_asset:do(AssetDoing, State2),
            case lists:member(ItemID, ?GUARD_LIST) of
                false ->
                    State4 = mod_role_bag:do(BagDoing, State3);
                _ ->
                    State4 = mod_role_guard:buy_guard(ItemID, Num, State3)
            end,
            common_misc:unicast(RoleID, #m_shop_buy_goods_toc{type_id = ItemID}),
            case mod_role_item:get_item_config(ItemID) of
                #c_item{name = ItemName, effect_type = ?ITEM_USE_GUARD} ->
                    common_broadcast:send_world_common_notice(?NOTICE_GUARD_GOT, [mod_role_data:get_role_name(State), ItemName]);
                _ ->
                    ok
            end,
            ?IF(IsUpdate, online(State4), ok),
            mod_role_dict:add_background_logs(LogList),
            State5 = mod_role_day_target:buy_shop_item(ShopID, Num, State4),
            State5;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_shop_buy_goods_toc{err_code = ErrCode}),
            State
    end.

check_can_buy(ShopID, Num, FrontTypeID, State) ->
    #r_role{role_shop = RoleShop, role_attr = #r_role_attr{level = RoleLevel, family_id = FamilyID}} = State,
    #r_role_shop{buy_limit = BuyLimit} = RoleShop,
    [ShopConfig] = lib_config:find(cfg_shop, ShopID),
    #c_shop{
        item_id = ItemID,
        is_bind = IsBind,
        shop_type = ShopType,
        asset_type = AssetType,
        asset_value = AssetValue,
        limit_num = LimitNum,
        limit_level = LimitLevel,
        limit_vip_level = LimitVipLevel,
        need_family_level = NeedFamilyLevel
    } = ShopConfig,
    ?IF(FrontTypeID =:= ItemID orelse FrontTypeID =:= 0, ok, ?THROW_ERR(?ERROR_SHOP_BUY_GOODS_003)),
    case ?ASSET_FAMILY_CON =:= AssetType of
        true ->
            ?IF(?HAS_FAMILY(FamilyID), ok, ?THROW_ERR(?ERROR_FAMILY_APPLY_REPLY_001)),
            #p_family{level = FamilyLevel} = mod_family_data:get_family(FamilyID),
            ?IF(NeedFamilyLevel =< FamilyLevel, ok, ?THROW_ERR(?ERROR_SHOP_BUY_GOODS_002));
        _ ->
            ok
    end,
    ?IF(Num > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
    ?IF(RoleLevel >= LimitLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_LEVEL)),
    ?IF(mod_role_vip:get_vip_level(State) >= LimitVipLevel, ok, ?THROW_ERR(?ERROR_COMMON_NO_ENOUGH_VIP_LEVEL)),
    case LimitNum > 0 of
        true ->
            case lists:keyfind(ShopID, #p_kv.id, BuyLimit) of
                #p_kv{val = Val} = KV ->
                    Val2 = Val + Num,
                    KV2 = ?IF(Val2 =< LimitNum, KV#p_kv{val = Val2}, ?THROW_ERR(?ERROR_SHOP_BUY_GOODS_001)),
                    BuyLimit2 = lists:keyreplace(ShopID, #p_kv.id, BuyLimit, KV2);
                _ ->
                    ?IF(Num =< LimitNum, ok, ?THROW_ERR(?ERROR_SHOP_BUY_GOODS_001)),
                    BuyLimit2 = [#p_kv{id = ShopID, val = Num}|BuyLimit]
            end,
            IsUpdate = true,
            RoleShop2 = RoleShop#r_role_shop{buy_limit = BuyLimit2};
        _ ->
            IsUpdate = false,
            RoleShop2 = RoleShop
    end,
    TypeID = mod_map_drop:get_item_by_equip_drop_id(ItemID),
    GoodsList = mod_role_bag:get_create_list([#p_goods{type_id = TypeID, num = Num, bind = ?IS_BIND(IsBind)}]),
    mod_role_bag:check_bag_empty_grid(GoodsList, State),
    AssetValue2 = AssetValue * Num,
    case AssetType of
        ?CONSUME_SILVER ->
            AssetDoing = mod_role_asset:check_asset_by_type(AssetType, AssetValue2, ?CONSUME_SILVER, State),
            LogList = [get_shop_log(AssetType, AssetValue2, 0, ShopType, TypeID, Num, State)];
        ?CONSUME_UNBIND_GOLD -> %% 不绑定元宝 这里的购买日志在mod_role_asset里写
            Action = ?ASSET_GOLD_REDUCE_FROM_SHOP_BUY,
            mod_role_asset:check_asset_by_type(AssetType, AssetValue2, Action, State),
            AssetDoing = [{buy_item_reduce_unbind_gold, Action, ShopType, ItemID, Num, AssetValue2}],
            LogList = [];
        ?CONSUME_ANY_GOLD -> %% 任意元宝 这里的购买日志在mod_role_asset里写
            Action = ?ASSET_GOLD_REDUCE_FROM_SHOP_BUY,
            mod_role_asset:check_asset_by_type(AssetType, AssetValue2, Action, State),
            AssetDoing = [{buy_item_reduce_any_gold, Action, ShopType, ItemID, Num, AssetValue2}],
            LogList = [];
        ?CONSUME_BIND_GOLD -> %% 绑定元宝 这里的购买日志在mod_role_asset里写
            Action = ?ASSET_GOLD_REDUCE_FROM_SHOP_BUY,
            mod_role_asset:check_asset_by_type(AssetType, AssetValue2, Action, State),
            AssetDoing = [{buy_item_reduce_bind_gold, Action, ShopType, ItemID, Num, AssetValue2}],
            LogList = [];
        _ -> %% 其他积分
            Action = ?ASSET_SCORE_REDUCE_FROM_SHOP,
            AssetDoing = mod_role_asset:check_asset_by_type(AssetType, AssetValue2, Action, State),
            LogList = [get_shop_log(AssetType, AssetValue2, 0, ShopType, TypeID, Num, State)]
    end,
    State2 = State#r_role{role_shop = RoleShop2},
    {ok, ItemID, GoodsList, AssetDoing, LogList, State2, IsUpdate}.

get_shop_log(AssetType, AssetValue, AssetBindValue, ShopType, TypeID, Num, State) ->
    #r_role{role_id = RoleID, role_attr = RoleAttr} = State,
    #r_role_attr{
        channel_id = ChannelID,
        game_channel_id = GameChannelID} = RoleAttr,
    #log_shop{
        role_id = RoleID,
        shop_type = ShopType,
        type_id = TypeID,
        buy_num = Num,
        asset_type = AssetType,
        asset_value = AssetValue,
        asset_bind_value = AssetBindValue,
        channel_id = ChannelID,
        game_channel_id = GameChannelID}.
