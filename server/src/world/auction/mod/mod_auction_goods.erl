%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 六月 2019 15:06
%%%-------------------------------------------------------------------
-module(mod_auction_goods).
-author("laijichang").
-include("auction.hrl").
-include("global.hrl").
-include("role.hrl").
-include("vip.hrl").
-include("family.hrl").
-include("proto/mod_role_auction.hrl").
-include("proto/mod_role_family.hrl").

%% API
-export([
    goods_end_time/1,
    goods_be_bought/1,

    add_goods_hash/1,
    del_goods_hash/1,

    add_end_time_hash/2,
    del_end_time_hash/2
]).

-export([
    auction_role_buy_log/2,
    auction_role_sell_log/2
]).

%% 达到截止时间，做各种处理
goods_end_time(AuctionGoods) ->
    #r_auction_goods{auction_role_id = AuctionRoleID} = AuctionGoods,
    case AuctionRoleID > 0 of
        true ->
            goods_be_bought(AuctionGoods);
        _ ->
            goods_unsold(AuctionGoods)
    end.

%% 道具被卖出
goods_be_bought(AuctionGoods) ->
    #r_auction_goods{
        id = ID,
        type_id = TypeID,
        num = Num,
        excellent_list = ExcellentList,
        cur_gold = CurGold,
        auction_role_id = AuctionRoleID,
        from_type = FromType,
        from_id = FromID,
        from_args = FromArgs
    } = AuctionGoods,
    del_goods_hash(AuctionGoods),
    mod_auction_data:del_auction_goods(ID),
    Log = #r_auction_log{
        time = time_tool:now(),
        type_id = TypeID,
        num = Num,
        gold = CurGold},
    #c_item{name = ItemName, protect_time = ProtectTime} = mod_role_item:get_item_config(TypeID),
    Now = time_tool:now(),
    AuctionGoodsList = [#p_goods{type_id = TypeID, num = Num, bind = false, excellent_list = ExcellentList, market_end_time = Now + ProtectTime}],
    #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
    CurGoldString = lib_tool:to_list(CurGold),
    AuctionLetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_AUCTION_BUY_SUCC,
        text_string = [CurGoldString, ItemName],
        goods_list = AuctionGoodsList,
        action = ?ITEM_GAIN_AUCTION_BUY
    },
    common_letter:send_letter(AuctionRoleID, AuctionLetterInfo),
    auction_role_buy_log(AuctionRoleID, Log),
    case FromType =:= ?AUCTION_FROM_FAMILY of
        true ->
            auction_family_sell_log(FromID, Log),
            RedPacket = get_red_packet(CurGold, FromArgs, ItemName),
            mod_family_red_packet:family_auction_red_packet(FromID, RedPacket);
        _ ->
            VipLevel = common_role_data:get_role_vip_level(FromID),
            [#c_vip_level{market_tax_rate = TaxRate}] = lib_config:find(cfg_vip_level, VipLevel),
            TaxGold = lib_tool:floor(CurGold * TaxRate/?RATE_10000),
            GainGold = CurGold - TaxGold,
            FromGoodsList = [#p_goods{type_id = ?ITEM_GOLD, num = GainGold}],
            FromLetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_AUCTION_SELL_SUCC,
                text_string = [ItemName, CurGoldString, lib_tool:to_list(TaxGold), lib_tool:to_list(GainGold)],
                goods_list = FromGoodsList,
                action = ?ITEM_GAIN_AUCTION_REWARD
            },
            common_letter:send_letter(FromID, FromLetterInfo),
            auction_role_sell_log(FromID, Log),
            del_role_auction_id(FromID, ID),
            auction_misc:auction_del(FromID, ID)
    end,
    auction_misc:broadcast_del(ID),
    ?TRY_CATCH(auction_misc:log_auction_exchange(?AUCTION_FROM_ROLE, AuctionRoleID, ?ACTION_AUCTION_BUY, AuctionGoods)).

%% 没卖出去
goods_unsold(AuctionGoods) ->
    #r_auction_goods{
        id = ID,
        type_id = TypeID,
        num = Num,
        from_type = FromType,
        from_id = FromID
    } = AuctionGoods,
    del_goods_hash(AuctionGoods),
    mod_auction_data:del_auction_goods(ID),
    Log = #r_auction_log{
        time = time_tool:now(),
        type_id = TypeID,
        num = Num,
        gold = 0},
    case FromType =:= ?AUCTION_FROM_FAMILY of
        true ->
            auction_family_sell_log(FromID, Log);
        _ ->
            #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
            FromGoodsList = [#p_goods{type_id = TypeID, num = Num, bind = false}],
            FromLetterInfo = #r_letter_info{
                template_id = ?LETTER_TEMPLATE_AUCTION_SELL_FAILED,
                text_string = [ItemName],
                goods_list = FromGoodsList,
                action = ?ITEM_GAIN_AUCTION_RETURN
            },
            common_letter:send_letter(FromID, FromLetterInfo),
            auction_role_sell_log(FromID, Log),
            del_role_auction_id(FromID, ID),
            auction_misc:auction_del(FromID, ID)
    end,
    auction_misc:broadcast_del(ID),
    ?TRY_CATCH(auction_misc:log_auction_exchange(FromType, FromID, ?ACTION_AUCTION_UNSOLD, AuctionGoods)).

%% 新增物品，加索引
add_goods_hash(AuctionGoods) ->
    #r_auction_goods{
        id = ID,
        type_id = TypeID,
        end_time = EndTime
    } = AuctionGoods,
    #c_item{quality = Quality, auction_sub_class = SubClass} = mod_role_item:get_item_config(TypeID),
    add_end_time_hash(EndTime, ID),
    add_type_id_hash(TypeID, ID),
    IndexList = mod_auction_data:get_sub_class_index_list(SubClass),
    IndexList2 = modify_index_list(SubClass, IndexList),
    QualityList = get_quality_list(Quality),
    KeyList = get_goods_hash_key(IndexList2, QualityList),
    add_goods_hash2(KeyList, ID).

add_goods_hash2([], _ID) ->
    ok;
add_goods_hash2([Key|R], ID) ->
    #r_auction_class_hash{ids = IDs} = ClassHash = mod_auction_data:get_class_hash(Key),
    IDs2 = IDs ++ [ID],
    mod_auction_data:set_class_hash(ClassHash#r_auction_class_hash{ids = IDs2, len = erlang:length(IDs2)}),
    add_goods_hash2(R, ID).

%% 拍卖行物品移除，移除对应索引
del_goods_hash(AuctionGoods) ->
    #r_auction_goods{
        id = ID,
        type_id = TypeID,
        end_time = EndTime
    } = AuctionGoods,
    #c_item{quality = Quality, auction_sub_class = SubClass} = mod_role_item:get_item_config(TypeID),
    del_end_time_hash(EndTime, ID),
    del_type_id_hash(TypeID, ID),
    IndexList = mod_auction_data:get_sub_class_index_list(SubClass),
    IndexList2 = modify_index_list(SubClass, IndexList),
    QualityList = get_quality_list(Quality),
    KeyList = get_goods_hash_key(IndexList2, QualityList),
    del_goods_hash2(KeyList, ID).

del_goods_hash2([], _ID) ->
    ok;
del_goods_hash2([Key|R], ID) ->
    #r_auction_class_hash{ids = IDs} = ClassHash = mod_auction_data:get_class_hash(Key),
    IDs2 = lists:delete(ID, IDs),
    mod_auction_data:set_class_hash(ClassHash#r_auction_class_hash{ids = IDs2, len = erlang:length(IDs2)}),
    del_goods_hash2(R, ID).

%% 结束时间的hash
add_end_time_hash(EndTime, ID) ->
    #r_auction_time_hash{ids = IDs} = TimeHash = mod_auction_data:get_end_time_hash(EndTime),
    IDs2 = [ID|IDs],
    mod_auction_data:set_end_time_hash(TimeHash#r_auction_time_hash{ids = IDs2}).

del_end_time_hash(EndTime, ID) ->
    #r_auction_time_hash{ids = IDs} = TimeHash = mod_auction_data:get_end_time_hash(EndTime),
    IDs2 = lists:delete(ID, IDs),
    mod_auction_data:set_end_time_hash(TimeHash#r_auction_time_hash{ids = IDs2}).

%% 道具ID Hash
add_type_id_hash(TypeID, ID) ->
    #r_auction_type_id_hash{ids = IDs, care_role_ids = CareRoleIDs} = TypeIDHash = mod_auction_data:get_type_id_hash(TypeID),
    IDs2 = [ID|IDs],
    mod_auction_data:set_type_id_hash(TypeIDHash#r_auction_type_id_hash{ids = IDs2}),
    common_broadcast:bc_record_to_roles(CareRoleIDs, #m_auction_notice_toc{type_id = TypeID}).

del_type_id_hash(TypeID, ID) ->
    #r_auction_type_id_hash{ids = IDs} = TypeIDHash = mod_auction_data:get_type_id_hash(TypeID),
    IDs2 = lists:delete(ID, IDs),
    mod_auction_data:set_type_id_hash(TypeIDHash#r_auction_type_id_hash{ids = IDs2}).

%% 日志
auction_role_buy_log(RoleID, Log) ->
    [_ShowTime, _AuctionTime, LogLen|_] = common_misc:get_global_list(?GLOBAL_AUCTION_ARGS),
    #r_role_auction{buy_logs = BuyLogs} = RoleAuction = mod_auction_data:get_role_auction(RoleID),
    BuyLogs2 = lists:sublist([Log|BuyLogs], LogLen),
    DataRecord = #m_auction_log_update_toc{type = ?AUCTION_LOG_ROLE_BUY, log = auction_misc:trans_to_p_auction_log(Log)},
    common_misc:unicast(RoleID, DataRecord),
    mod_auction_data:set_role_auction(RoleAuction#r_role_auction{buy_logs = BuyLogs2}).

auction_role_sell_log(RoleID, Log) ->
    [_ShowTime, _AuctionTime, LogLen|_] = common_misc:get_global_list(?GLOBAL_AUCTION_ARGS),
    #r_role_auction{sell_logs = SellLogs} = RoleAuction = mod_auction_data:get_role_auction(RoleID),
    SellLogs2 = lists:sublist([Log|SellLogs], LogLen),
    DataRecord = #m_auction_log_update_toc{type = ?AUCTION_LOG_ROLE_SELL, log = auction_misc:trans_to_p_auction_log(Log)},
    common_misc:unicast(RoleID, DataRecord),
    mod_auction_data:set_role_auction(RoleAuction#r_role_auction{sell_logs = SellLogs2}).

auction_family_sell_log(FamilyID, Log) ->
    [_ShowTime, _AuctionTime, LogLen|_] = common_misc:get_global_list(?GLOBAL_AUCTION_ARGS),
    #r_family_auction{sell_logs = SellLogs} = FamilyAuction = mod_auction_data:get_family_auction(FamilyID),
    SellLogs2 = lists:sublist([Log|SellLogs], LogLen),
    DataRecord = #m_auction_log_update_toc{type = ?AUCTION_LOG_FAMILY_SELL, log = auction_misc:trans_to_p_auction_log(Log)},
    common_broadcast:bc_record_to_family(FamilyID, DataRecord),
    mod_auction_data:set_family_auction(FamilyAuction#r_family_auction{sell_logs = SellLogs2}).

del_role_auction_id(RoleID, ID) ->
    #r_role_auction{auction_goods_ids = AuctionGoodsIDs} = RoleAuction = mod_auction_data:get_role_auction(RoleID),
    RoleAuction2 = RoleAuction#r_role_auction{auction_goods_ids = lists:delete(ID, AuctionGoodsIDs)},
    mod_auction_data:set_role_auction(RoleAuction2).

get_quality_list(0) ->
    [];
get_quality_list(Quality) ->
    [0, Quality].

modify_index_list(SubClass, IndexList) ->
    case IndexList of
        [_|_] ->
            IndexList;
        _ ->
            ?ERROR_MSG("unknow SubClass:~w", [{SubClass, IndexList}]),
            [?AUCTION_ALL_CLASS]
    end.

get_goods_hash_key(IndexList, QualityList) ->
    get_goods_hash_key2(IndexList, QualityList, []).

get_goods_hash_key2([], _QualityList, Acc) ->
    Acc;
get_goods_hash_key2([Index|R], QualityList, Acc) ->
    Acc2 = [ {Index, Quality} || Quality <- QualityList] ++ Acc,
    get_goods_hash_key2(R, QualityList, Acc2).

get_red_packet(Gold, RoleList, ItemName) ->
    RoleLen = erlang:length(RoleList),
    RoleNum = ?IF(RoleLen >= 5, RoleLen, 5),
    RoleNum2 = ?IF(Gold > RoleNum, RoleNum, Gold),
    #p_red_packet{
        icon = 0,
        sender_name = ?AUCTION_NAME_LANG,
        content = ItemName,
        time = time_tool:now(),
        amount = Gold,
        piece = RoleNum2,
        bind = ?BAG_ASSET_GOLD,
        role_list = RoleList}.