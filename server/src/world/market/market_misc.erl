%%%%%-------------------------------------------------------------------
%%%%% @author WZP
%%%%% @copyright (C) 2018, <COMPANY>
%%%%% @doc
%%%%%
%%%%% @end
%%%%% Created : 29. 六月 2018 9:59
%%%%%-------------------------------------------------------------------
-module(market_misc).
%%-author("WZP").
%%
%%
%%-include("common.hrl").
%%-include("market.hrl").
%%-include("db.hrl").
%%-include("role.hrl").
%%-include("vip.hrl").
%%
%%%% API
%%-export([
%%    on_shelf_to_sell_market/1,
%%    on_shelf_to_demand_market/1,
%%    down_shelf_to_sell_market/1,
%%    down_shelf_to_demand_market/1,
%%    do_clean_overtime_goods/1,
%%    get_sell_market_info_by_id/1,
%%    get_demand_market_info_by_id/1,
%%    buy_goods/1,
%%    sell_goods/1,
%%    send_buy_email/2,
%%    get_market_class/1,
%%    send_demand_payment/3,
%%    trans_to_p_market_goods/1,
%%    down_shelf_sell_goods/3,
%%    get_tax_rate/1,
%%    get_demand_mapping/1,
%%    get_sell_mapping/1,
%%    up_shelf_sell_goods/1,
%%    get_demand_item_mapping/1,
%%    get_sell_item_mapping/1
%%]).
%%
%%-export([
%%    insert_list/2
%%]).
%%
%%
%%
%%on_shelf_to_sell_market(#r_sell_market{type_id = TypeID, unit_price = UnitPrice, total_price = TotalPrice} = Data) ->
%%    MarketId = world_data:get_sell_market_goods_new_id(),
%%    Data2 = Data#r_sell_market{id = MarketId},
%%    db:insert(?DB_SELL_MARKET_P, Data2),
%%    {AloneClass, WholeClass} = get_market_class(TypeID),
%%    Info = get_sell_mapping(AloneClass),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = AloneClass, list = [{MarketId, UnitPrice, TotalPrice}|Info#market_mapping.list], num = Info#market_mapping.num + 1}),
%%    Info4 = get_sell_mapping(WholeClass),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = WholeClass, list = [{MarketId, UnitPrice, TotalPrice}|Info4#market_mapping.list], num = Info4#market_mapping.num + 1}),
%%    Info2 = get_sell_item_mapping(TypeID),
%%    ets:insert(?MARKET_SELL_ITEM_MAPPING, #market_mapping{id = TypeID, list = [{MarketId, UnitPrice, TotalPrice}|Info2#market_mapping.list], num = Info2#market_mapping.num + 1}),
%%    Info3 = get_sell_mapping(?MARKET_ALL),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = ?MARKET_ALL, list = [{MarketId, UnitPrice, TotalPrice}|Info3#market_mapping.list], num = Info3#market_mapping.num + 1}),
%%    {ok, MarketId}.
%%
%%on_shelf_to_demand_market(#r_demand_market{type_id = TypeID, unit_price = UnitPrice, total_price = TotalPrice} = Data) ->
%%    MarketId = world_data:get_demand_market_goods_new_id(),
%%    Data2 = Data#r_demand_market{id = MarketId},
%%    db:insert(?DB_DEMAND_MARKET_P, Data2),
%%    {AloneClass, WholeClass} = get_market_class(TypeID),
%%    Info = get_demand_mapping(AloneClass),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = AloneClass, list = [{MarketId, UnitPrice, TotalPrice}|Info#market_mapping.list], num = Info#market_mapping.num + 1}),
%%    Info4 = get_demand_mapping(WholeClass),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = WholeClass, list = [{MarketId, UnitPrice, TotalPrice}|Info4#market_mapping.list], num = Info4#market_mapping.num + 1}),
%%    Info2 = get_demand_item_mapping(TypeID),
%%    ets:insert(?MARKET_DEMAND_ITEM_MAPPING, #market_mapping{id = TypeID, list = [{MarketId, UnitPrice, TotalPrice}|Info2#market_mapping.list], num = Info2#market_mapping.num + 1}),
%%    Info3 = get_demand_mapping(?MARKET_ALL),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = ?MARKET_ALL, list = [{MarketId, UnitPrice, TotalPrice}|Info3#market_mapping.list], num = Info3#market_mapping.num + 1}),
%%    {ok, MarketId}.
%%
%%down_shelf_to_sell_market(#r_sell_market{id = ID, type_id = TypeID}) ->
%%    db:delete(?DB_SELL_MARKET_P, ID),
%%    {AloneClass, WholeClass} = get_market_class(TypeID),
%%    Info = get_sell_mapping(AloneClass),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = AloneClass, list = lists:keydelete(ID, 1, Info#market_mapping.list), num = Info#market_mapping.num - 1}),
%%    Info4 = get_sell_mapping(WholeClass),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = WholeClass, list = lists:keydelete(ID, 1, Info4#market_mapping.list), num = Info4#market_mapping.num - 1}),
%%    Info2 = get_sell_item_mapping(TypeID),
%%    ets:insert(?MARKET_SELL_ITEM_MAPPING, #market_mapping{id = TypeID, list = lists:keydelete(ID, 1, Info2#market_mapping.list), num = Info2#market_mapping.num - 1}),
%%    Info3 = get_sell_mapping(?MARKET_ALL),
%%    ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = ?MARKET_ALL, list = lists:keydelete(ID, 1, Info3#market_mapping.list), num = Info3#market_mapping.num - 1}).
%%
%%down_shelf_to_demand_market(#r_demand_market{id = ID, type_id = TypeID}) ->
%%    db:delete(?DB_DEMAND_MARKET_P, ID),
%%    {AloneClass, WholeClass} = get_market_class(TypeID),
%%    Info = get_demand_mapping(AloneClass),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = AloneClass, list = lists:keydelete(ID, 1, Info#market_mapping.list), num = Info#market_mapping.num - 1}),
%%    Info4 = get_demand_mapping(WholeClass),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = WholeClass, list = lists:keydelete(ID, 1, Info4#market_mapping.list), num = Info4#market_mapping.num - 1}),
%%    Info2 = get_demand_item_mapping(TypeID),
%%    ets:insert(?MARKET_DEMAND_ITEM_MAPPING, #market_mapping{id = TypeID, list = lists:keydelete(ID, 1, Info2#market_mapping.list), num = Info2#market_mapping.num - 1}),
%%    Info3 = get_demand_mapping(?MARKET_ALL),
%%    ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = ?MARKET_ALL, list = lists:keydelete(ID, 1, Info3#market_mapping.list), num = Info3#market_mapping.num - 1}).
%%
%%
%%get_sell_market_info_by_id(ID) ->
%%    ets:lookup(?DB_SELL_MARKET_P, ID).
%%
%%get_demand_market_info_by_id(ID) ->
%%    ets:lookup(?DB_DEMAND_MARKET_P, ID).
%%
%%%%拿到映射
%%get_demand_mapping(ID) ->
%%    case ets:lookup(?MARKET_DEMAND_MAPPING, ID) of
%%        [#market_mapping{} = Info] ->
%%            Info;
%%        _ ->
%%            #market_mapping{id = ID}
%%    end.
%%
%%get_sell_mapping(ID) ->
%%    case ets:lookup(?MARKET_SELL_MAPPING, ID) of
%%        [#market_mapping{} = Info] ->
%%            Info;
%%        _ ->
%%            #market_mapping{id = ID}
%%    end.
%%
%%get_demand_item_mapping(ID) ->
%%    case ets:lookup(?MARKET_DEMAND_ITEM_MAPPING, ID) of
%%        [#market_mapping{} = Info] ->
%%            Info;
%%        _ ->
%%            #market_mapping{id = ID}
%%    end.
%%
%%get_sell_item_mapping(ID) ->
%%    case ets:lookup(?MARKET_SELL_ITEM_MAPPING, ID) of
%%        [#market_mapping{} = Info] ->
%%            Info;
%%        _ ->
%%            #market_mapping{id = ID}
%%    end.
%%
%%
%%
%%
%%buy_goods(ID) ->
%%    market_server:call({mod, mod_sell_market, {buy_goods, ID}}).
%%
%%sell_goods(ID) ->
%%    market_server:call({mod, mod_demand_market, {sell_goods, ID}}).
%%
%%
%%
%%send_buy_email(RoleID, #r_sell_market{type_id = TypeID, num = Num, excellent_list = ExcellentList}) ->
%%    GoodsList = [#p_goods{type_id = TypeID, num = Num, excellent_list = ExcellentList, bind = true}],
%%    [ItemConfig] = lib_config:find(cfg_item, TypeID),
%%    LetterInfo = #r_letter_info{
%%        text_string = [lib_tool:to_list(Num), lib_tool:to_list(ItemConfig#c_item.name)],
%%        template_id = ?LETTER_TEMPLATE_MARKET_BUY,
%%        action = ?ITEM_GAIN_LETTER_MARKET_BUY,
%%        goods_list = GoodsList},
%%    common_letter:send_letter(RoleID, LetterInfo).
%%
%%%%上架物品超时
%%do_clean_overtime_goods(#r_sell_market{id = ID, type_id = TypeID, num = Num, excellent_list = ExcellentList, role_id = RoleID}) ->
%%    mod_role_market:clean_overtime_goods(RoleID, ?MARKET_SELL, ID),
%%    GoodsList = [#p_goods{type_id = TypeID, num = Num, excellent_list = ExcellentList, bind = true}],
%%    LetterInfo = #r_letter_info{
%%        template_id = ?LETTER_TEMPLATE_MARKET_OVER_TIME,
%%        action = ?ITEM_GAIN_LETTER_MARKET_TIMEOUT,
%%        goods_list = GoodsList},
%%    common_letter:send_letter(RoleID, LetterInfo);
%%
%%do_clean_overtime_goods(#r_demand_market{id = ID, total_price = TotalPrice, role_id = RoleID}) ->
%%    mod_role_market:clean_overtime_goods(RoleID, ?MARKET_DEMAND, ID),
%%    GoodsList = [#p_goods{type_id = ?BAG_ASSET_GOLD, num = TotalPrice, bind = true}],
%%    LetterInfo = #r_letter_info{
%%        template_id = ?LETTER_TEMPLATE_MARKET_OVER_TIME,
%%        action = ?ITEM_GAIN_LETTER_MARKET_TIMEOUT,
%%        goods_list = GoodsList},
%%    common_letter:send_letter(RoleID, LetterInfo).
%%
%%
%%%%
%%send_demand_payment(#r_role{role_id = RoleID} = State, TotalPrice,Type) ->
%%    TaxRate = market_misc:get_tax_rate(mod_role_vip:get_vip_level(State)),
%%    Tax = lib_tool:ceil(TotalPrice * TaxRate / 10000),
%%    GoodsList = [#p_goods{type_id = ?ASSET_GOLD, num = TotalPrice - Tax}],
%%    [ItemConfig] = lib_config:find(cfg_item, Type),
%%    LetterInfo = #r_letter_info{
%%        template_id = ?LETTER_TEMPLATE_MARKET_SELL,
%%        action = ?ITEM_GAIN_LETTER_MARKET_SELL,
%%        text_string = [lib_tool:to_list(ItemConfig#c_item.name), lib_tool:to_list(TotalPrice - Tax)],
%%        goods_list = GoodsList},
%%    common_letter:send_letter(RoleID, LetterInfo).
%%
%%
%%%%市场物品
%%trans_to_p_market_goods(List) when erlang:is_list(List) ->
%%    [trans_to_p_market_goods(Info) || Info <- List];
%%trans_to_p_market_goods(#r_demand_market{} = Info) ->
%%    #r_demand_market{id = ID, role_id = RoleID, unit_price = UnitPrice, total_price = TotalPrice, num = Num, password = Password, type_id = TypeID, excellent_list = ExcellentList, role_name = Name} = Info,
%%    Password2 = ?IF(Password =:= "", Password, "1"),
%%    #p_market_goods{id = ID, role_name = Name, role_id = RoleID, type_id = TypeID, num = Num, excellent_list = ExcellentList, unit_price = UnitPrice, total_price = TotalPrice, password = Password2};
%%trans_to_p_market_goods(#r_sell_market{} = Info) ->
%%    #r_sell_market{id = ID, role_id = RoleID, unit_price = UnitPrice, total_price = TotalPrice, num = Num, password = Password, type_id = TypeID, excellent_list = ExcellentList} = Info,
%%    Password2 = ?IF(Password =:= "", Password, "1"),
%%    #p_market_goods{id = ID, role_id = RoleID, type_id = TypeID, num = Num, excellent_list = ExcellentList, unit_price = UnitPrice, total_price = TotalPrice, password = Password2}.
%%
%%
%%%%下架
%%down_shelf_sell_goods(ID, RoleID, Market) ->
%%    case Market of
%%        ?MARKET_SELL ->
%%            market_server:call({mod, mod_sell_market, {down_shelf, ID, RoleID}});
%%        _ ->
%%            market_server:call({mod, mod_demand_market, {down_shelf, ID, RoleID}})
%%    end.
%%
%%%%上架
%%up_shelf_sell_goods(#r_sell_market{} = Data) ->
%%    market_server:call({mod, mod_sell_market, {up_shelf, Data}});
%%up_shelf_sell_goods(#r_demand_market{} = Data) ->
%%    market_server:call({mod, mod_demand_market, {up_shelf, Data}}).
%%
%%%%税率
%%get_tax_rate(Level) ->
%%    case lib_config:find(cfg_vip_level, Level) of
%%        [] ->
%%            3000;
%%        [Config] ->
%%            Config#c_vip_level.market_tax_rate
%%    end.
%%
%%
%%%%拿物品类别ID
%%get_market_class(#c_item{type_id = TypeID}) ->
%%    get_market_class(TypeID);
%%get_market_class(#r_demand_market{type_id = TypeID}) ->
%%    get_market_class(TypeID);
%%get_market_class(#r_sell_market{type_id = TypeID}) ->
%%    get_market_class(TypeID);
%%get_market_class(TypeID) when erlang:is_integer(TypeID) ->
%%    [Config] = lib_config:find(cfg_item, TypeID),
%%    case lib_config:find(cfg_market_dic, Config#c_item.market_type) of
%%        [] ->
%%            {10200000, 10500000};
%%        [DicConfig] ->
%%            case Config#c_item.item_type =:= ?IS_TYPE_OF_EQUIP of
%%                true ->
%%                    case Config#c_item.category =:= ?CATEGORY_1 of
%%                        true ->
%%                            {DicConfig#c_market_dic.id * 10000 + 1032, 10320000};
%%                        _ ->
%%                            {DicConfig#c_market_dic.id * 10000 + 1001, 10010000}
%%                    end;
%%                _ ->
%%                    [FrontID] = DicConfig#c_market_dic.front_list,
%%                    {DicConfig#c_market_dic.id * 10000 + FrontID, FrontID * 10000}
%%            end
%%    end.
%%
%%
%%
%%insert_list([], {Price, ID}) ->
%%    [{Price, ID}];
%%insert_list(List, {NowPrice, NowID}) ->
%%    insert_list(List, {NowPrice, NowID}, []).
%%
%%insert_list([{Price, ID}|T], {NowPrice, NowID}, OtherList) ->
%%    case NowPrice =< Price of
%%        false ->
%%            insert_list(T, {NowPrice, NowID}, [{Price, ID}|OtherList]);
%%        _ ->
%%            insert_list(T, {NowPrice, NowID}, OtherList)
%%    end.
%%
