%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 六月 2019 20:30
%%%-------------------------------------------------------------------
-module(mod_role_auction).
-author("laijichang").
-include("auction.hrl").
-include("role.hrl").
-include("proto/mod_role_auction.hrl").

%% API
-export([
    online/1,
    offline/1,
    handle/2
]).

online(State) ->
    #r_role{role_id = RoleID, role_attr = #r_role_attr{family_id = FamilyID}} = State,
    #r_role_auction{
        auction_goods_ids = AuctionGoodsIDs,
        sell_logs = SellLogs,
        buy_logs = BuyLogs,
        care_type_ids = CareTypeIDs
    } = mod_auction_data:get_role_auction(RoleID),
    AuctionGoodsList = [auction_misc:get_auction_goods(ID) || ID <- AuctionGoodsIDs],
    #r_family_auction{sell_logs = FamilySellLogs} = mod_auction_data:get_family_auction(FamilyID),
    DataRecord = #m_auction_person_info_toc{
        care_type_ids = CareTypeIDs,
        auction_goods = [auction_misc:trans_to_p_auction_goods(AuctionGoods) || #r_auction_goods{} = AuctionGoods <- AuctionGoodsList],
        sell_logs = auction_misc:trans_to_p_auction_log(SellLogs),
        buy_logs = auction_misc:trans_to_p_auction_log(BuyLogs),
        family_sell_logs = auction_misc:trans_to_p_auction_log(FamilySellLogs)
    },
    common_misc:unicast(RoleID, DataRecord),
    State.

offline(State) ->
    mod_auction_operation:close_panel(State#r_role.role_id),
    State.

handle({#m_auction_class_tos{class = Class}, RoleID, _PID}, State) ->
    do_auction_class(RoleID, Class, State);
handle({#m_auction_detail_tos{class = Class, quality = Quality, step = Step}, RoleID, _PID}, State) ->
    do_auction_detail(RoleID, Class, Quality, Step),
    State;
handle({#m_auction_search_tos{type_id_list = TypeIDList}, RoleID, _PID}, State) ->
    do_auction_search(RoleID, TypeIDList),
    State;
handle({#m_auction_buy_tos{type = Type, id = ID, gold = Gold}, RoleID, _PID}, State) ->
    do_auction_buy(RoleID, Type, ID, Gold, State);
handle({#m_auction_sell_tos{sell_goods = SellGoods}, RoleID, _PID}, State) ->
    do_auction_sell(RoleID, SellGoods, State);
handle({#m_auction_obtain_tos{id = ID}, RoleID, _PID}, State) ->
    do_auction_obtain(RoleID, ID, State);
handle({#m_auction_care_tos{type = Type, type_id = TypeID}, RoleID, _PID}, State) ->
    do_auction_care(RoleID, Type, TypeID),
    State;
handle({#m_auction_close_panel_tos{}, RoleID, _PID}, State) ->
    mod_auction_operation:close_panel(RoleID),
    State.

do_auction_class(RoleID, Class, State) ->
    [#c_auction_major_class{sub_list = SubList}] = lib_config:find(cfg_auction_major_class, Class),
    KVList = do_auction_class2(SubList, Class, []),
    common_misc:unicast(RoleID, #m_auction_class_toc{class_list = KVList}),
    State.

do_auction_class2([], _Class, Acc) ->
    Acc;
do_auction_class2([SubClass|R], Class, Acc) ->
    Index = ?IF(SubClass =:= 0, Class, SubClass),
    #r_auction_class_hash{len = Len} = auction_misc:get_class_hash(Index),
    do_auction_class2(R, Class, [#p_kv{id = SubClass, val = Len}|Acc]).

%% 根据道具ID搜索
do_auction_search(RoleID, TypeIDList) ->
    PAuctionGoods = do_auction_search2(TypeIDList, common_misc:get_global_int(?GLOBAL_AUCTION_NUM), []),
    mod_auction_operation:open_panel(RoleID),
    DataRecord = #m_auction_search_toc{auction_goods = PAuctionGoods},
    common_misc:unicast(RoleID, DataRecord).

do_auction_search2([], _RemainNum, AuctionGoodsAcc) ->
    AuctionGoodsAcc;
do_auction_search2(_IDs, 0, AuctionGoodsAcc) ->
    AuctionGoodsAcc;
do_auction_search2([TypeID|R], RemainNum, AuctionGoodsAcc) ->
    #r_auction_type_id_hash{ids = IDs} = mod_auction_data:get_type_id_hash(TypeID),
    {RemainNum2, AddAcc} = do_auction_search3(IDs, RemainNum, []),
    do_auction_search2(R, RemainNum2, AddAcc ++ AuctionGoodsAcc).

do_auction_search3([], RemainNum, AddAcc) ->
    {RemainNum, AddAcc};
do_auction_search3(_IDs, 0, AddAcc) ->
    {0, AddAcc};
do_auction_search3([ID|R], RemainNum, Acc) ->
    case auction_misc:get_auction_goods(ID) of
        #r_auction_goods{} = AuctionGoods ->
            Acc2 = [auction_misc:trans_to_p_auction_goods(AuctionGoods)|Acc],
            do_auction_search3(R, RemainNum - 1, Acc2);
        _ ->
            do_auction_search3(R, RemainNum, Acc)
    end.

%% 某个分类
do_auction_detail(RoleID, Class, Quality, Step) ->
    #r_auction_class_hash{ids = IDs} = auction_misc:get_class_hash(Class, Quality),
    PAuctionGoods = do_auction_detail2(IDs, common_misc:get_global_int(?GLOBAL_AUCTION_NUM), Step, []),
    mod_auction_operation:open_panel(RoleID),
    DataRecord = #m_auction_detail_toc{auction_goods = PAuctionGoods},
    common_misc:unicast(RoleID, DataRecord).

do_auction_detail2([], _RemainNum, _Step, AuctionGoodsAcc) ->
    AuctionGoodsAcc;
do_auction_detail2(_IDs, 0, _Step, AuctionGoodsAcc) ->
    AuctionGoodsAcc;
do_auction_detail2([ID|R], RemainNum, Step, AuctionGoodsAcc) ->
    case auction_misc:get_auction_goods(ID) of
        #r_auction_goods{type_id = TypeID} = AuctionGoods ->
            IsAdd =
                case Step > 0 of
                    true ->
                        case lib_config:find(cfg_equip, TypeID) of
                            [#c_equip{step = ConfigStep}] when ConfigStep =:= Step ->
                                true;
                            _ ->
                                false
                        end;
                    _ ->
                        true
                end,
            {RemainNum2, AuctionGoodsAcc2} = ?IF(IsAdd,
                {RemainNum - 1, [auction_misc:trans_to_p_auction_goods(AuctionGoods)|AuctionGoodsAcc]},
                {RemainNum, AuctionGoodsAcc}),
            do_auction_detail2(R, RemainNum2, Step, AuctionGoodsAcc2);
        _ ->
            do_auction_detail2(R, RemainNum, Step, AuctionGoodsAcc)
    end.

%% 竞拍商品
do_auction_buy(RoleID, Type, ID, Gold, State) ->
    case catch check_auction_buy(RoleID, Type, ID, Gold, State) of
        {ok, NeedGold, AssetDoings} ->
            case catch mod_auction_operation:buy_goods(RoleID, Type, ID, NeedGold) of
                {ok, AuctionGoods} ->
                    common_misc:unicast(RoleID, #m_auction_buy_toc{type = Type, auction_goods = auction_misc:trans_to_p_auction_goods(AuctionGoods)}),
                    State2 = mod_role_asset:do(AssetDoings, State),
                    FunList = [
                        fun(StateAcc) -> mod_role_day_target:auction_buy(StateAcc) end
                    ],
                    role_server:execute_state_fun(FunList, State2);
                {goods_update, AuctionGoods} ->
                    common_misc:unicast(RoleID, #m_auction_buy_toc{err_code = ?ERROR_AUCTION_BUY_003, auction_goods = auction_misc:trans_to_p_auction_goods(AuctionGoods)}),
                    State;
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_auction_buy_toc{err_code = ErrCode}),
                    State
            end;
        {goods_update, AuctionGoods} ->
            common_misc:unicast(RoleID, #m_auction_buy_toc{err_code = ?ERROR_AUCTION_BUY_003, auction_goods = auction_misc:trans_to_p_auction_goods(AuctionGoods)}),
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_auction_buy_toc{err_code = ErrCode}),
            State
    end.

check_auction_buy(RoleID, Type, ID, Gold, State) ->
    {AuctionGoods, NeedGold} = auction_misc:check_auction_buy(RoleID, Type, ID),
    #r_auction_goods{cur_gold = CurGold} = AuctionGoods,
    ?IF(Type =:= ?AUCTION_BUY_BUYOUT orelse CurGold =:= Gold, ok, erlang:throw({goods_update, AuctionGoods})),
    ?IF(mod_role_insider:is_insider(State), ?IF(NeedGold > 20, ?THROW_ERR(?ERROR_AUCTION_BUY_006), ok), ok),
    AssetDoings = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, NeedGold, ?ASSET_GOLD_REDUCE_FROM_AUCTION_BUY, State),
    {ok, NeedGold, AssetDoings}.

%% 拍卖品上架
do_auction_sell(RoleID, SellGoods, State) ->
    case catch check_auction_sell(RoleID, SellGoods, State) of
        {ok, BagDoings, GoodsList} ->
            common_misc:unicast(RoleID, #m_auction_sell_toc{}),
            State2 = mod_role_bag:do(BagDoings, State),
            SellNum = get_sell_num(GoodsList, 0),
            State3 = hook_role:auction_sell(State2, SellNum),
            mod_auction_operation:sell_goods(RoleID, GoodsList),
            State3;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_auction_sell_toc{err_code = ErrCode}),
            State
    end.

check_auction_sell(RoleID, SellGoods, State) ->
    #r_role_auction{auction_goods_ids = AuctionGoodsID} = mod_auction_data:get_role_auction(RoleID),
    ?IF(erlang:length(AuctionGoodsID) >= common_misc:get_global_int(?GLOBAL_AUCTION_NUM), ?THROW_ERR(?ERROR_AUCTION_SELL_001), ok),
    {ok, DecreaseList, GoodsList} = mod_role_bag:check_bag_by_kv_list(SellGoods, State),
    [begin
         #c_item{auction_gold = AuctionGold} = mod_role_item:get_item_config(TypeID),
         ?IF(Bind, ?THROW_ERR(?ERROR_COMMON_CLIENT_PARAM), ok),
         ?IF(AuctionGold > 0, ok, ?THROW_ERR(?ERROR_COMMON_CONFIG_ERROR)),
         ?IF(MarketEndTime >= ?MARKET_ALLOW_SELL, ok, ?THROW_ERR(?ERROR_AUCTION_SELL_001)),
         Now = time_tool:now(),
         ?IF(MarketEndTime >= ?MARKET_ALLOW_SELL andalso Now >= MarketEndTime, ok, ?THROW_ERR(?ERROR_AUCTION_SELL_004)) %% 保护时间内不可二次上架
     end || #p_goods{bind = Bind, type_id = TypeID, market_end_time = MarketEndTime} <- GoodsList],
    BagDoings = [{decrease, ?ITEM_REDUCE_AUCTION_SELL, DecreaseList}],
    {ok, BagDoings, GoodsList}.

%% 拍卖品下架
do_auction_obtain(RoleID, ID, State) ->
    case catch check_auction_obtain(ID, State) of
        {ok, FromID, FromLetterInfo, State} ->
            case mod_auction_operation:obtain_goods(RoleID, ID) of
                ok ->
                    common_letter:send_letter(FromID, FromLetterInfo),
                    common_misc:unicast(RoleID, #m_auction_obtain_toc{});
                {error, ErrCode} ->
                    common_misc:unicast(RoleID, #m_auction_obtain_toc{err_code = ErrCode})
            end,
            State;
        {error, ErrCode} ->
            common_misc:unicast(RoleID, #m_auction_obtain_toc{err_code = ErrCode}),
            State
    end.

check_auction_obtain(ID, State) ->
    AuctionGoods = auction_misc:get_auction_goods(ID),
    #r_auction_goods{from_id = FromID, type_id = TypeID, num = Num, auction_role_id = AuctionRoleID, from_type = FromType} = AuctionGoods,
    #c_item{name = ItemName} = mod_role_item:get_item_config(TypeID),
    ?IF(AuctionRoleID =:= 0, ok, ?THROW_ERR(?ERROR_AUCTION_OBTAIN_001)),
    ?IF(FromType =/= ?AUCTION_FROM_FAMILY, ok, ?THROW_ERR(?ERROR_AUCTION_OBTAIN_002)),
    FromGoodsList = [#p_goods{type_id = TypeID, num = Num, bind = true}],
    FromLetterInfo = #r_letter_info{
        template_id = ?LETTER_AUCTION_OBTAIN_GAIN,
        text_string = [ItemName],
        goods_list = FromGoodsList,
        action = ?ITEM_GAIN_ACT_OBTAIN
    },
    {ok, FromID, FromLetterInfo, State}.

do_auction_care(RoleID, Type, TypeID) ->
    case mod_role_item:get_item_config(TypeID) of
        #c_item{auction_sub_class = SubClass} when SubClass > 0 ->
            mod_auction_operation:auction_care(RoleID, Type, TypeID);
        _ ->
            ok
    end.

get_sell_num([], Num) ->
    Num;
get_sell_num([#p_goods{num = Num2}|T], Num) ->
    get_sell_num(T, Num + Num2).