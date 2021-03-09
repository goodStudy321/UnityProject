%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%     拍卖行misc
%%% @end
%%% Created : 17. 六月 2019 20:31
%%%-------------------------------------------------------------------
-module(auction_misc).
-author("laijichang").
-include("auction.hrl").
-include("global.hrl").
-include("proto/mod_role_auction.hrl").

%% API
-export([
    get_class_hash/1,
    get_class_hash/2,
    get_auction_goods/1
]).

-export([
    check_auction_buy/3
]).

-export([
    auction_update/1,
    auction_del/2,
    broadcast_add/1,
    broadcast_update/1,
    broadcast_del/1
]).

-export([
    log_auction_exchange/4,
    log_auction_buy/3
]).

-export([
    trans_to_p_auction_goods/1,
    trans_to_p_auction_log/1
]).

get_class_hash(Class) ->
    get_class_hash(Class, 0).
get_class_hash(Class, Quality) ->
    mod_auction_data:get_class_hash({Class, Quality}).

get_auction_goods(ID) ->
    case mod_auction_data:get_auction_goods(ID) of
        [AuctionGoods] ->
            AuctionGoods;
        _ ->
            undefined
    end.

%% 角色进程跟拍卖行进程都会调用
check_auction_buy(RoleID, Type, ID) ->
    AuctionGoods =
        case get_auction_goods(ID) of
            #r_auction_goods{} = AuctionGoodsT ->
                AuctionGoodsT;
            _ ->
                ?THROW_ERR(?ERROR_AUCTION_BUY_001)
        end,
    #r_auction_goods{
        type_id = TypeID,
        num = Num,
        auction_time = AuctionTime,
        auction_role_id = AuctionRoleID,
        cur_gold = CurGold,
        from_id = FromID} = AuctionGoods,
    ?IF(RoleID =:= FromID, ?THROW_ERR(?ERROR_AUCTION_BUY_002), ok),
    ?IF(RoleID =:= AuctionRoleID, ?THROW_ERR(?ERROR_AUCTION_BUY_004), ok),
    ?IF(time_tool:now() >= AuctionTime, ok, ?THROW_ERR(?ERROR_AUCTION_BUY_005)),
    #c_item{
        auction_buyout = AuctionBuyOut
    } = mod_role_item:get_item_config(TypeID),
    AuctionBuyOut2 = AuctionBuyOut * Num,
    NeedGold =
        case Type of
            ?AUCTION_BUY_BUYOUT ->
                ?IF(AuctionBuyOut2 > 0, ok, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM)),
                AuctionBuyOut2;
            ?AUCTION_BUY_AUCTION ->
                NeedGoldT = ?IF(AuctionRoleID > 0, lib_tool:ceil(CurGold * erlang:max(11000, common_misc:get_global_int(?GLOBAL_AUCTION_ARGS))/?RATE_10000), CurGold),
                ?IF(NeedGoldT >= AuctionBuyOut2, erlang:throw({goods_update, AuctionGoods}), ok),
                NeedGoldT
        end,
    {AuctionGoods, NeedGold}.

auction_update(AuctionGoods) ->
    #r_auction_goods{from_id = FromID} = AuctionGoods,
    common_misc:unicast(FromID, #m_auction_goods_update_toc{update_goods = trans_to_p_auction_goods(AuctionGoods)}).

auction_del(FromID, DelID) ->
    common_misc:unicast(FromID, #m_auction_goods_update_toc{del_goods_id = DelID}).

broadcast_add(AuctionGoods) ->
    DataRecord = #m_auction_panel_add_toc{add_goods = trans_to_p_auction_goods(AuctionGoods)},
    common_broadcast:bc_record_to_roles(mod_auction_data:get_panel_roles(), DataRecord).

broadcast_update(AuctionGoods) ->
    DataRecord = #m_auction_panel_update_toc{update_goods = trans_to_p_auction_goods(AuctionGoods)},
    common_broadcast:bc_record_to_roles(mod_auction_data:get_panel_roles(), DataRecord).

broadcast_del(DelID) ->
    DataRecord = #m_auction_panel_del_toc{del_goods_id = DelID},
    common_broadcast:bc_record_to_roles(mod_auction_data:get_panel_roles(), DataRecord).

trans_to_p_auction_goods(List) when erlang:is_list(List) ->
    [ trans_to_p_auction_goods2(AuctionGoods) || #r_auction_goods{} = AuctionGoods <- List];
trans_to_p_auction_goods(#r_auction_goods{} = AuctionGoods) ->
    trans_to_p_auction_goods2(AuctionGoods).

trans_to_p_auction_goods2(AuctionGoods) ->
    #r_auction_goods{
        id = ID,
        type_id = TypeID,
        num = Num,
        auction_time = AuctionTime,
        end_time = EndTime,
        cur_gold = CurGold,
        auction_role_id = AuctionRoleID,
        from_type = FromType,
        from_id = FromID} = AuctionGoods,
    #p_auction_goods{
        id = ID,
        type_id = TypeID,
        num = Num,
        auction_time = AuctionTime,
        end_time = EndTime,
        auction_role_id = AuctionRoleID,
        cur_gold = CurGold,
        from_type = FromType,
        from_id = FromID
    }.

log_auction_exchange(FromType, FromID, Action, AuctionGoods) ->
    #r_auction_goods{
        id = GoodsID,
        type_id = TypeID,
        num = Num,
        cur_gold = CurGold
    } = AuctionGoods,
    {ChannelID, GameChannelID} =
        case FromType of
            ?AUCTION_FROM_ROLE ->
                #r_role_attr{channel_id = ChannelIDT, game_channel_id = GameChannelIDT} = common_role_data:get_role_attr(FromID),
                {ChannelIDT, GameChannelIDT};
            _ ->
                {0, 0}
        end,
    Log =
        #log_auction_exchange{
            action = Action,
            goods_id = GoodsID,
            from_type = FromType,
            from_id = FromID,
            type_id = TypeID,
            num = Num,
            gold = CurGold,
            channel_id = ChannelID,
            game_channel_id = GameChannelID},
    background_misc:log(Log).

log_auction_buy(RoleID, AuctionType, AuctionGoods) ->
    #r_auction_goods{
        id = GoodsID,
        type_id = TypeID,
        num = Num,
        cur_gold = CurGold
    } = AuctionGoods,
    #r_role_attr{channel_id = ChannelID, game_channel_id = GameChannelID} = common_role_data:get_role_attr(RoleID),
    Log =
        #log_auction_buy{
            role_id = RoleID,
            goods_id = GoodsID,
            type_id = TypeID,
            num = Num,
            auction_type = AuctionType,
            gold = CurGold,
            channel_id = ChannelID,
            game_channel_id = GameChannelID},
    background_misc:log(Log).

trans_to_p_auction_log(List) when erlang:is_list(List) ->
    [ trans_to_p_auction_log2(AuctionLog) || #r_auction_log{} = AuctionLog <- List];
trans_to_p_auction_log(#r_auction_log{} = AuctionLog) ->
    trans_to_p_auction_log2(AuctionLog).

trans_to_p_auction_log2(AuctionLog) ->
    #r_auction_log{
        time = Time,
        type_id = TypeID,
        num = Num,
        gold = Gold} = AuctionLog,
    #p_auction_log{
        time = Time,
        type_id = TypeID,
        num = Num,
        gold = Gold
    }.
