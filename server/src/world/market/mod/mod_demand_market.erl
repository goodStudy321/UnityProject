%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 七月 2018 14:56
%%%-------------------------------------------------------------------
-module(mod_demand_market).
-author("WZP").
-include("role.hrl").
-include("common.hrl").
-include("market.hrl").
-include("proto/mod_role_market.hrl").

%% API
-export([
    handle/1
]).

handle({sell_goods, ID}) ->
    do_sell_goods(ID);
handle({down_shelf, ID, RoleID}) ->
    do_down_shelf(ID, RoleID);
handle({up_shelf, Data}) ->
    do_up_shelf(Data);
handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_sell_goods(ID) ->
    case market_misc:get_demand_market_info_by_id(ID) of
        [] ->
            {error, ?ERROR_MARKET_SELL_DEMAND_001};
        [Data] ->
            market_misc:down_shelf_to_demand_market(Data),
            do_send_goods_email(Data),
            do_log(Data),
            ok
    end.

do_log(Data) ->
    Log = #p_market_log{id = Data#r_demand_market.id, type_id = Data#r_demand_market.type_id, num = Data#r_demand_market.num, excellent_list = Data#r_demand_market.excellent_list,
                        unit_price = Data#r_demand_market.unit_price, total_price = Data#r_demand_market.total_price, time = time_tool:now(), log_type = ?MARKET_DEMAND_LOG_SELL},
    mod_role_market:add_log(Data#r_demand_market.role_id, Log).

do_send_goods_email(#r_demand_market{role_id = RoleID, type_id = TypeID, num = Num, excellent_list = ExcellentList}) ->
    GoodsList = [#p_goods{type_id = TypeID, num = Num, excellent_list = ExcellentList, bind = true}],
    [ItemConfig] = lib_config:find(cfg_item, TypeID),
    LetterInfo = #r_letter_info{
        template_id = ?LETTER_TEMPLATE_MARKET_DEMAND,
        action = ?ITEM_GAIN_LETTER_MARKET_SELL,
        text_string = [lib_tool:to_list(Num), lib_tool:to_list(ItemConfig#c_item.name)],
        goods_list = GoodsList},
    common_letter:send_letter(RoleID, LetterInfo).

do_down_shelf(ID, RoleID) ->
    case check_can_down(ID, RoleID) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_down(ID, RoleID) ->
    case market_misc:get_demand_market_info_by_id(ID) of
        [] ->
            ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_002);
        [Data] ->
            ?IF(Data#r_demand_market.role_id =:= RoleID, ok, ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_001)),
            market_misc:down_shelf_to_demand_market(Data),
            ok
    end.


do_up_shelf(Data) ->
    case catch market_misc:on_shelf_to_demand_market(Data) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, MarketId} ->
            {ok, MarketId}
    end.