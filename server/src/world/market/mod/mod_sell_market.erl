%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 七月 2018 19:50
%%%-------------------------------------------------------------------
-module(mod_sell_market).
-author("WZP").
-include("role.hrl").
-include("common.hrl").
-include("market.hrl").
-include("proto/mod_role_market.hrl").

%% API
-export([
    handle/1
]).

handle({buy_goods, ID}) ->
    do_buy_goods(ID);
handle({down_shelf, ID, RoleID}) ->
    do_down_shelf(ID, RoleID);
handle({up_shelf, Data}) ->
    do_up_shelf(Data);
handle(Info) ->
    ?ERROR_MSG("unknow info :~w", [Info]).

do_buy_goods(ID) ->
    case catch check_can_buy(ID) of
        {ok, MyLog} ->
            {ok, MyLog};
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_buy(ID) ->
    case market_misc:get_sell_market_info_by_id(ID) of
        [] ->
            ?THROW_ERR(?ERROR_MARKET_BUY_004);
        [Data] ->
            MyLog = do_seller_log(Data),
            market_misc:down_shelf_to_sell_market(Data),
            {ok, MyLog}
    end.

do_seller_log(Data) ->
    Log = #p_market_log{id = Data#r_sell_market.id, type_id = Data#r_sell_market.type_id, num = Data#r_sell_market.num, excellent_list = Data#r_sell_market.excellent_list,
                        unit_price = Data#r_sell_market.unit_price, total_price = Data#r_sell_market.total_price, time = time_tool:now(), log_type = ?MARKET_SELL_LOG_SELL},
    mod_role_market:add_log(Data#r_sell_market.role_id, Log),
    Log#p_market_log{log_type = ?MARKET_SELL_LOG_BUY}.



do_down_shelf(ID, RoleID) ->
    case catch check_can_down(ID, RoleID) of
        ok ->
            ok;
        {error, ErrCode} ->
            {error, ErrCode}
    end.

check_can_down(ID, RoleID) ->
    case market_misc:get_sell_market_info_by_id(ID) of
        [] ->
            ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_002);
        [Data] ->
            ?IF(Data#r_sell_market.role_id =:= RoleID, ok, ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_001)),
            market_misc:down_shelf_to_sell_market(Data),
            ok
    end.


do_up_shelf(Data) ->
    case catch market_misc:on_shelf_to_sell_market(Data) of
        {error, ErrCode} ->
            {error, ErrCode};
        {ok, MarketId} ->
            {ok, MarketId}
    end.