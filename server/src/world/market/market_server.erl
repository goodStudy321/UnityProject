%%%%%-------------------------------------------------------------------
%%%%% @author WZP
%%%%% @copyright (C) 2018, <COMPANY>
%%%%% @doc
%%%%%
%%%%% @end
%%%%% Created : 28. 六月 2018 10:05
%%%%%-------------------------------------------------------------------
-module(market_server).
%%-author("WZP").
%%-behaviour(gen_server).
%%-include("common.hrl").
%%-include("market.hrl").
%%-include("db.hrl").
%%-include("role.hrl").
%%
%%%% API
%%-export([
%%    start/0,
%%    start_link/0
%%]).
%%
%%
%%%% gen_server callbacks
%%-export([
%%    init/1,
%%    handle_call/3,
%%    handle_cast/2,
%%    handle_info/2,
%%    terminate/2,
%%    code_change/3
%%]).
%%
%%-export([
%%    info/1,
%%    call/1
%%]).
%%
%%info(Info) ->
%%    pname_server:send(?MODULE, Info).
%%
%%call(Info) ->
%%    pname_server:call(?MODULE, Info).
%%
%%start() ->
%%    world_sup:start_child(?MODULE).
%%
%%start_link() ->
%%    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
%%
%%
%%%%%===================================================================
%%%%% gen_server callbacks
%%%%%===================================================================
%%init([]) ->
%%    erlang:process_flag(trap_exit, true),
%%    world_data:init_demand_market_goods_id(),
%%    world_data:init_sell_market_goods_id(),
%%    init_mapping_ets(),
%%    do_clean_overtime_info(),
%%    {ok, []}.
%%
%%handle_call(Info, _From, State) ->
%%    Reply = ?DO_HANDLE_CALL(Info, State),
%%    {reply, Reply, State}.
%%
%%handle_cast(Info, State) ->
%%    ?DO_HANDLE_INFO(Info, State),
%%    {noreply, State}.
%%
%%handle_info(Info, State) ->
%%    ?DO_HANDLE_INFO(Info, State),
%%    {noreply, State}.
%%
%%terminate(_Reason, _State) ->
%%    time_tool:dereg(world, [0, 60000]),
%%    ok.
%%
%%code_change(_OldVsn, State, _Extra) ->
%%    {ok, State}.
%%
%%
%%do_handle({mod, Mod, Info}) ->
%%    Mod:handle(Info);
%%do_handle(loop_clean_goods) ->
%%    do_clean_overtime_info();
%%do_handle(Info) ->
%%    ?ERROR_MSG("unknow info :~w", [Info]).
%%
%%
%%
%%
%%do_clean_overtime_info() ->
%%    erlang:send_after(600000, erlang:self(), loop_clean_goods),
%%    Now = time_tool:now(),
%%    Time = Now - 86400,
%%    [case db:table_all(MarketDB) of
%%         [] ->
%%             ok;
%%         List ->
%%             lists:foreach(
%%                 fun(Data) ->
%%                     do_clean_overtime_info_i(Data, Time)
%%                 end, List)
%%     end || MarketDB <- [?DB_SELL_MARKET_P, ?DB_DEMAND_MARKET_P]].
%%
%%
%%do_clean_overtime_info_i(#r_sell_market{time = SellTime} = Data, Time) ->
%%    if
%%        Time >= SellTime ->
%%            market_misc:do_clean_overtime_goods(Data),
%%            market_misc:down_shelf_to_sell_market(Data);
%%        true ->
%%            ok
%%    end;
%%
%%do_clean_overtime_info_i(#r_demand_market{time = SellTime} = Data, Time) ->
%%    if
%%        Time >= SellTime ->
%%            market_misc:do_clean_overtime_goods(Data),
%%            market_misc:down_shelf_to_demand_market(Data);
%%        true ->
%%            ok
%%    end.
%%
%%
%%
%%init_mapping_ets() ->
%%    ets:new(?MARKET_SELL_MAPPING, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #market_mapping.id}]),
%%    ets:new(?MARKET_DEMAND_MAPPING, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #market_mapping.id}]),
%%    ets:new(?MARKET_SELL_ITEM_MAPPING, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #market_mapping.id}]),
%%    ets:new(?MARKET_DEMAND_ITEM_MAPPING, [named_table, set, public, {read_concurrency, true}, {write_concurrency, true}, {keypos, #market_mapping.id}]),
%%    ItemList = cfg_item:list(),
%%    lists:foreach(
%%        fun(TypeID) ->
%%            ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = TypeID}),
%%            ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = TypeID})
%%        end, ?MARKET_CLASS_LIST),
%%    lists:foreach(
%%        fun({_, Item}) ->
%%            case Item#c_item.market_type =:= 0 of
%%                true ->
%%                    ets:insert(?MARKET_SELL_ITEM_MAPPING, #market_mapping{id = Item#c_item.type_id}),
%%                    ets:insert(?MARKET_DEMAND_ITEM_MAPPING, #market_mapping{id = Item#c_item.type_id});
%%                _ ->
%%                    ok
%%            end
%%        end, ItemList),
%%    SellGoods = ets:tab2list(?DB_SELL_MARKET_P),
%%    DemandGoods = ets:tab2list(?DB_DEMAND_MARKET_P),
%%    init_mapping_ets_i(SellGoods, ?MARKET_SELL_MAPPING),
%%    init_mapping_ets_i(DemandGoods, ?MARKET_DEMAND_MAPPING).
%%
%%init_mapping_ets_i([], _Table) ->
%%    ok;
%%init_mapping_ets_i([Goods|T], Table) ->
%%    case Table of
%%        ?MARKET_SELL_MAPPING ->
%%            Info = market_misc:get_sell_item_mapping(Goods#r_sell_market.type_id),
%%            ets:insert(?MARKET_SELL_ITEM_MAPPING, #market_mapping{id = Goods#r_sell_market.type_id, list = [{Goods#r_sell_market.id, Goods#r_sell_market.unit_price, Goods#r_sell_market.total_price}|Info#market_mapping.list], num = Info#market_mapping.num + 1}),
%%            {AloneClass, WholeClass} = market_misc:get_market_class(Goods#r_sell_market.type_id),
%%            Info2 = market_misc:get_sell_mapping(AloneClass),
%%            ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = AloneClass, list = [{Goods#r_sell_market.id, Goods#r_sell_market.unit_price, Goods#r_sell_market.total_price}|Info2#market_mapping.list], num = Info2#market_mapping.num + 1}),
%%            Info3 = market_misc:get_sell_mapping(WholeClass),
%%            ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = WholeClass, list = [{Goods#r_sell_market.id, Goods#r_sell_market.unit_price, Goods#r_sell_market.total_price}|Info3#market_mapping.list], num = Info3#market_mapping.num + 1}),
%%            Info4 = market_misc:get_sell_mapping(?MARKET_ALL),
%%            ets:insert(?MARKET_SELL_MAPPING, #market_mapping{id = ?MARKET_ALL, list = [{Goods#r_sell_market.id, Goods#r_sell_market.unit_price, Goods#r_sell_market.total_price}|Info4#market_mapping.list], num = Info4#market_mapping.num + 1});
%%        ?MARKET_DEMAND_MAPPING ->
%%            Info = market_misc:get_demand_item_mapping(Goods#r_demand_market.type_id),
%%            ets:insert(?MARKET_DEMAND_ITEM_MAPPING, #market_mapping{id = Goods#r_demand_market.type_id, list = [{Goods#r_demand_market.id, Goods#r_demand_market.unit_price, Goods#r_demand_market.total_price}|Info#market_mapping.list], num = Info#market_mapping.num + 1}),
%%            {AloneClass, WholeClass} = market_misc:get_market_class(Goods#r_demand_market.type_id),
%%            Info2 = market_misc:get_demand_mapping(AloneClass),
%%            ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = AloneClass, list = [{Goods#r_demand_market.id, Goods#r_demand_market.unit_price, Goods#r_demand_market.total_price}|Info2#market_mapping.list], num = Info2#market_mapping.num + 1}),
%%            Info3 = market_misc:get_demand_mapping(WholeClass),
%%            ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = WholeClass, list = [{Goods#r_demand_market.id, Goods#r_demand_market.unit_price, Goods#r_demand_market.total_price}|Info3#market_mapping.list], num = Info3#market_mapping.num + 1}),
%%            Info4 = market_misc:get_demand_mapping(?MARKET_ALL),
%%            ets:insert(?MARKET_DEMAND_MAPPING, #market_mapping{id = ?MARKET_ALL, list = [{Goods#r_demand_market.id, Goods#r_demand_market.unit_price, Goods#r_demand_market.total_price}|Info4#market_mapping.list], num = Info4#market_mapping.num + 1});
%%        _ ->
%%            ok
%%    end,
%%    init_mapping_ets_i(T, Table).