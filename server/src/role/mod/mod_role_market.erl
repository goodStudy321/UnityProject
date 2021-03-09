%%%%%-------------------------------------------------------------------
%%%%% @author WZP
%%%%% @copyright (C) 2018, <COMPANY>
%%%%% @doc
%%%%%
%%%%% @end
%%%%% Created : 30. 六月 2018 11:36
%%%%%-------------------------------------------------------------------
-module(mod_role_market).
%%-author("WZP").
%%-include("role.hrl").
%%-include("market.hrl").
%%-include("proto/mod_role_market.hrl").
%%
%%
%%%% API
%%-export([
%%    init/1,
%%    handle/2,
%%    day_reset/1,
%%    online/1
%%]).
%%
%%-export([
%%    add_log/2,
%%    clean_overtime_goods/3,
%%    check_get_class_num/2,
%%    off_line_add_log/1,
%%    off_line_clean_overtime_goods/2
%%]).
%%
%%
%%-export([
%%    gm_up_market/2,
%%    get_search_ids/4
%%]).
%%
%%
%%
%%
%%add_log(RoleID, Log) ->
%%    case role_misc:is_online(RoleID) of
%%        true ->
%%            role_misc:info_role(RoleID, {mod, mod_role_market, {add_log, Log}});
%%        _ ->
%%            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_add_log, [Log]})
%%    end.
%%
%%clean_overtime_goods(RoleID, Market, ID) ->
%%    case role_misc:is_online(RoleID) of
%%        true ->
%%            role_misc:info_role(RoleID, {mod, mod_role_market, {clean_overtime_goods, Market, ID}});
%%        _ ->
%%            world_offline_event_server:add_event(RoleID, {?MODULE, off_line_clean_overtime_goods, [Market, ID]})
%%    end.
%%
%%
%%
%%init(#r_role{role_id = RoleID, role_market = undefined} = State) ->
%%    RoleMarket = #r_role_market{role_id = RoleID, prohibit_time = 0, demand_grid = [], sell_grid = [], log = []},
%%    State#r_role{role_market = RoleMarket};
%%init(State) ->
%%    State.
%%
%%
%%online(#r_role{role_market = RoleMarket, role_id = RoleID} = State) ->
%%    SellGrid = market_misc:trans_to_p_market_goods(RoleMarket#r_role_market.sell_grid),
%%    DemandGrid = market_misc:trans_to_p_market_goods(RoleMarket#r_role_market.demand_grid),
%%    common_misc:unicast(RoleID, #m_market_self_info_toc{prohibit_time = RoleMarket#r_role_market.prohibit_time, sell_grid = SellGrid, demand_grid = DemandGrid}),
%%    State.
%%
%%
%%day_reset(#r_role{role_market = RoleMarket} = State) ->
%%    State#r_role{role_market = RoleMarket#r_role_market{demand_bc = 0}}.
%%
%%
%%handle({#m_market_search_tos{type = Type, key_word = KeyWord, first_type = FirstType, second_type = SecondType, color = Color, order = Order,
%%                             password = PassWord, dic = Dic, search_type = SearchType, sort_type = SortType}, RoleID, _Pid}, State) ->
%%    do_market_search(RoleID, Type, KeyWord, FirstType, SecondType, Color, Order, PassWord, Dic, SearchType, SortType, State);
%%handle({#m_market_self_info_tos{}, RoleID, _Pid}, State) ->
%%    do_send_self_info(RoleID, State);
%%handle({#m_market_self_log_tos{}, RoleID, _Pid}, State) ->
%%    do_send_self_logs(RoleID, State);
%%%%handle({#m_market_on_shelf_tos{id = ID, num = GoodsNum, total_price = TotalPrice, unit_price = UnitPrice, password = Password}, RoleID, _Pid}, State) ->
%%%%    do_on_shelf(RoleID, State, ID, GoodsNum, TotalPrice, UnitPrice, Password);
%%handle({#m_market_buy_tos{id = ID, password = Password}, RoleID, _Pid}, State) ->
%%    do_buy_goods(RoleID, State, ID, Password);
%%handle({#m_market_demand_tos{info = DemandInfo}, RoleID, _Pid}, State) ->
%%    do_demand_goods(RoleID, State, DemandInfo);
%%handle({#m_market_sell_demand_tos{id = ID, demand_id = DemandID}, RoleID, _Pid}, State) ->
%%    do_sell_demand_goods(RoleID, State, ID, DemandID);
%%handle({#m_market_down_shelf_tos{id = ID, market_type = Market}, RoleID, _Pid}, State) ->
%%    do_down_shelf_goods(RoleID, State, ID, Market);
%%handle({#m_market_class_num_tos{class = Class, type = Type}, RoleID, _Pid}, State) ->
%%    do_get_class_num(RoleID, Class, Type, State);
%%handle({add_log, Log}, State) ->
%%    do_add_log(State, Log);
%%handle({clean_overtime_goods, Market, ID}, State) ->
%%    do_clean_overtime_goods(State, Market, ID);
%%handle(Info, State) ->
%%    ?ERROR_MSG("unknow Info:~w", [Info]),
%%    State.
%%
%%
%%off_line_add_log(Log) ->
%%    erlang:send(erlang:self(), {mod, ?MODULE, {add_log, Log}}).
%%
%%%%过期
%%off_line_clean_overtime_goods(Market, ID) ->
%%    erlang:send(erlang:self(), {mod, ?MODULE, {clean_overtime_goods, Market, ID}}).
%%
%%
%%
%%do_send_self_info(RoleID, #r_role{role_id = RoleID, role_market = RoleMarket} = State) ->
%%    SellGrid = market_misc:trans_to_p_market_goods(RoleMarket#r_role_market.sell_grid),
%%    DemandGrid = market_misc:trans_to_p_market_goods(RoleMarket#r_role_market.demand_grid),
%%    common_misc:unicast(RoleID, #m_market_self_info_toc{prohibit_time = RoleMarket#r_role_market.prohibit_time, sell_grid = SellGrid, demand_grid = DemandGrid}),
%%    State.
%%
%%do_send_self_logs(RoleID, #r_role{role_id = RoleID, role_market = RoleMarket} = State) ->
%%    common_misc:unicast(RoleID, #m_market_self_log_toc{logs = RoleMarket#r_role_market.log}),
%%    State.
%%
%%
%%%%上架销售市场
%%%%do_on_shelf(RoleID, State, ID, GoodsNum, TotalPrice, UnitPrice, Password) ->
%%%%    case catch check_can_on_shelf(State, ID, GoodsNum, TotalPrice, UnitPrice, Password) of
%%%%        {ok, BagDoing, MarketGoods, State2} ->
%%%%            SellGrid = market_misc:trans_to_p_market_goods(MarketGoods),
%%%%            State3 = mod_role_bag:do(BagDoing, State2),
%%%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_SELL, ?LOG_MARKET_ON_SHELF, MarketGoods)),
%%%%            common_misc:unicast(RoleID, #m_market_on_shelf_toc{sell_grid = SellGrid}),
%%%%            State3;
%%%%        {error, ErrCode} ->
%%%%            common_misc:unicast(RoleID, #m_market_on_shelf_toc{err_code = ErrCode}),
%%%%            State
%%%%    end.
%%
%%
%%%%check_can_on_shelf(#r_role{role_market = RoleMarket, role_id = RoleID, role_attr = RoleAttr} = State, ID, GoodsNum, TotalPrice, UnitPrice, Password) ->
%%%%    ?IF(RoleAttr#r_role_attr.level >= ?MARKET_OPEN_LEVEL, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_003)),
%%%%    ?IF(?MARKET_ROLE_SELL_GRID_NUM > erlang:length(RoleMarket#r_role_market.sell_grid), ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_004)),
%%%%    Goods = mod_role_bag:get_goods_by_bag_id(ID, State),
%%%%    ?IF(Goods =:= false, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_006), ok),
%%%%    ?IF(Goods#p_goods.bind =:= true, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_005), ok),
%%%%    ?IF(GoodsNum > Goods#p_goods.num, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_006), ok),
%%%%    ?IF(0 =:= Goods#p_goods.end_time, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_007)),
%%%%    [ItemConfig] = lib_config:find(cfg_item, Goods#p_goods.type_id),
%%%%    ?IF(ItemConfig#c_item.market_time =:= 0 orelse Goods#p_goods.market_end_time >= time_tool:now(), ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_007)),
%%%%    case string:tokens(ItemConfig#c_item.price_region, "|") of
%%%%        [MinPrice, MaxPrice] ->
%%%%            ?IF(lib_tool:to_integer(MinPrice) =< UnitPrice andalso UnitPrice =< lib_tool:to_integer(MaxPrice), ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_010));
%%%%        _ ->
%%%%            ok
%%%%    end,
%%%%    ?IF(0 =/= ItemConfig#c_item.market_type, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_007)),
%%%%    DecreaseList = [#r_goods_decrease_info{id = Goods#p_goods.id, num = GoodsNum}],
%%%%    BagDoing = [{decrease, ?ITEM_REDUCE_MARKET_ON_SHELF, DecreaseList}],
%%%%    case Password =:= [] of
%%%%        true ->
%%%%            ok;
%%%%        _ ->
%%%%            ?IF(mod_role_vip:get_vip_level(State) >= 4, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_008)),
%%%%            case re:run(Password, "^[0-9]*$") of
%%%%                nomatch ->
%%%%                    ?THROW_ERR(?ERROR_MARKET_ON_SHELF_009);
%%%%                _ ->
%%%%                    ?IF(erlang:length(Password) =/= ?MARKET_PASSWORD_LENGTH orelse Password =:= "", ?THROW_ERR(?ERROR_MARKET_ON_SHELF_009), ok)
%%%%            end
%%%%    end,
%%%%    MarketGoods = make_market_goods_info(Goods, GoodsNum, TotalPrice, UnitPrice, Password, RoleID),
%%%%    RoleMarket2 = RoleMarket#r_role_market{sell_grid = [MarketGoods|RoleMarket#r_role_market.sell_grid]},
%%%%    State2 = State#r_role{role_market = RoleMarket2},
%%%%    {ok, BagDoing, MarketGoods, State2}.
%%
%%
%%make_market_goods_info(Goods, GoodsNum, TotalPrice, UnitPrice, Password, RoleID) ->
%%    #p_goods{type_id = TypeID, excellent_list = ExcellentList} = Goods,
%%    TotalPrice2 = case TotalPrice < ?MARKET_MIN_PRICE of
%%                      true ->
%%                          ?MARKET_MIN_PRICE;
%%                      _ ->
%%                          TotalPrice
%%                  end,
%%    Data = #r_sell_market{time = time_tool:now(), role_id = RoleID, total_price = TotalPrice2, password = Password, num = GoodsNum, type_id = TypeID,
%%                          excellent_list = ExcellentList, unit_price = UnitPrice},
%%    case market_misc:up_shelf_sell_goods(Data) of
%%        {ok, BackID} ->
%%            Data#r_sell_market{id = BackID};
%%        {error, ErrCode} ->
%%            ?THROW_ERR(ErrCode)
%%    end.
%%
%%
%%%%购买销售商品
%%do_buy_goods(RoleID, State, ID, Password) ->
%%    case catch check_can_buy(RoleID, State, ID, Password) of
%%        {ok, AssetDoing, Data, State2} ->
%%            State3 = mod_role_asset:do(AssetDoing, State2),
%%            market_misc:send_buy_email(RoleID, Data),
%%            common_misc:unicast(RoleID, #m_market_buy_toc{id = ID}),
%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_SELL, ?LOG_MARKET_BUY, Data)),
%%            State3;
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_buy_toc{err_code = ErrCode}),
%%            State;
%%        {error, ErrCode, State2} ->
%%            common_misc:unicast(RoleID, #m_market_buy_toc{err_code = ErrCode}),
%%            State2;
%%        Res ->
%%            ?ERROR_MSG("------------do_buy_goods------------Res------------~w", [Res])
%%    end.
%%
%%
%%
%%check_can_buy(RoleID, #r_role{role_market = RoleMarket, role_attr = RoleAttr} = State, ID, Password) ->
%%    ?IF(RoleAttr#r_role_attr.level >= ?MARKET_OPEN_LEVEL, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_003)),
%%    case market_misc:get_sell_market_info_by_id(ID) of
%%        [Data] ->
%%            Data;
%%        _ ->
%%            Data = ?THROW_ERR(?ERROR_MARKET_ON_SHELF_001)
%%    end,
%%    ?IF(RoleID =/= Data#r_sell_market.role_id, ok, ?THROW_ERR(?ERROR_MARKET_BUY_001)),
%%    Now = time_tool:now(),
%%    ?IF(RoleMarket#r_role_market.prohibit_time >= Now andalso Data#r_sell_market.password =/= "", ?THROW_ERR(?ERROR_MARKET_BUY_003), ok),
%%    case Data#r_sell_market.password =/= "" andalso Password =/= Data#r_sell_market.password of
%%        true ->
%%            #r_role_market{error_times = ErrorTimes, error_goods = ErrorGoods, error_time = ErrorTime} = RoleMarket,
%%            NewRoleMarket = case Now - ErrorTime > 10 of
%%                                true ->
%%                                    RoleMarket#r_role_market{error_time = Now, error_goods = ID, error_times = 1};
%%                                _ ->
%%                                    case ID =:= ErrorGoods of
%%                                        true ->
%%                                            case ErrorTimes < 2 of
%%                                                true ->
%%                                                    RoleMarket#r_role_market{prohibit_time = Now + 1800, error_times = 0, error_goods = 0, error_time = 0};
%%                                                _ ->
%%                                                    RoleMarket#r_role_market{error_times = ErrorTimes + 1, error_time = Now}
%%                                            end;
%%                                        _ ->
%%                                            RoleMarket#r_role_market{error_time = Now, error_goods = ID, error_times = 1}
%%                                    end
%%                            end,
%%            {error, ?ERROR_MARKET_BUY_002, State#r_role{role_market = NewRoleMarket}};
%%        _ ->
%%            AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, Data#r_sell_market.total_price, ?ASSET_GOLD_REDUCE_FROM_MARKET_BUY, State),
%%            case market_misc:buy_goods(ID) of
%%                {ok, MyLog} ->
%%                    State2 = do_add_log(State, MyLog),
%%                    {ok, AssetDoing, Data, State2};
%%                {error, ErrCode} ->
%%                    {error, ErrCode}
%%            end
%%    end.
%%
%%
%%%%上架求购信息
%%do_demand_goods(RoleID, State, DemandInfo) ->
%%    case catch check_can_demand(RoleID, State, DemandInfo) of
%%        {ok, State2, DemandGoods, AssetDoing} ->
%%            DemandGrid = market_misc:trans_to_p_market_goods(DemandGoods),
%%            common_misc:unicast(RoleID, #m_market_demand_toc{demand_grid = DemandGrid}),
%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_DEMAND, ?LOG_MARKET_ON_SHELF, DemandGoods)),
%%            mod_role_asset:do(AssetDoing, State2);
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_demand_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%
%%check_can_demand(RoleID, State, DemandInfo) ->
%%    #r_role{role_market = RoleMarket, role_attr = RoleAttr} = State,
%%    ?IF(RoleAttr#r_role_attr.level >= ?MARKET_OPEN_LEVEL, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_003)),
%%    ?IF(?MARKET_ROLE_DEMAND_GRID_NUM > erlang:length(RoleMarket#r_role_market.demand_grid), ok, ?THROW_ERR(?ERROR_MARKET_DEMAND_001)),
%%    Config = mod_role_item:get_item_config(DemandInfo#p_market_goods.type_id),
%%    ?IF(Config#c_item.market_time =:= 0, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_007)),
%%    NewNum = case Config#c_item.cover_num =:= 1 of
%%                 true ->
%%                     1;
%%                 _ ->
%%                     ?IF(DemandInfo#p_market_goods.num > Config#c_item.cover_num, Config#c_item.cover_num, DemandInfo#p_market_goods.num)
%%             end,
%%    TotalPrice = case DemandInfo#p_market_goods.total_price < ?MARKET_MIN_PRICE of
%%                     true ->
%%                         ?THROW_ERR(?ERROR_MARKET_DEMAND_003);
%%                     _ ->
%%                         ?IF(DemandInfo#p_market_goods.total_price > ?MARKET_MAX_PRICE, ?MARKET_MAX_PRICE, DemandInfo#p_market_goods.total_price)
%%                 end,
%%    AssetDoing = mod_role_asset:check_asset_by_type(?CONSUME_UNBIND_GOLD, TotalPrice, ?ASSET_GOLD_REDUCE_FROM_MARKET_DEMAND, State),
%%    DemandGoods = #r_demand_market{time = time_tool:now(), role_id = RoleID, unit_price = DemandInfo#p_market_goods.unit_price,
%%                                   total_price = TotalPrice, num = NewNum, type_id = DemandInfo#p_market_goods.type_id, role_name = RoleAttr#r_role_attr.role_name},
%%    case market_misc:on_shelf_to_demand_market(DemandGoods) of
%%        {ok, BackID} ->
%%            DemandGoods2 = DemandGoods#r_demand_market{id = BackID},
%%            RoleMarket2 = RoleMarket#r_role_market{demand_grid = [DemandGoods2|RoleMarket#r_role_market.demand_grid]},
%%            RoleMarket3 = case RoleMarket2#r_role_market.demand_bc < 5 of
%%                              true ->
%%                                  NoticeRecord = #m_common_notice_toc{id = ?NOTICE_MARKET_DEMAND, text_string = [RoleAttr#r_role_attr.role_name, lib_tool:to_list(TotalPrice), lib_tool:to_list(NewNum)],
%%                                                                      goods_list = [#p_goods{type_id = DemandInfo#p_market_goods.type_id, num = NewNum}]},
%%                                  common_broadcast:bc_record_to_world(NoticeRecord),
%%                                  RoleMarket2#r_role_market{demand_bc = RoleMarket2#r_role_market.demand_bc + 1};
%%                              _ ->
%%                                  RoleMarket2
%%                          end,
%%            State2 = State#r_role{role_market = RoleMarket3},
%%            {ok, State2, DemandGoods2, AssetDoing};
%%        {error, ErrCode} ->
%%            ?THROW_ERR(ErrCode)
%%    end.
%%
%%
%%
%%do_sell_demand_goods(RoleID, State, ID, DemandID) ->
%%    case catch check_can_sell_demand(RoleID, State, ID, DemandID) of
%%        {ok, BagDoing, TotalPrice, DemandGoods, PTypeID} ->
%%            State2 = mod_role_bag:do(BagDoing, State),
%%            market_misc:send_demand_payment(State2, TotalPrice, PTypeID),
%%            common_misc:unicast(RoleID, #m_market_sell_demand_toc{id = DemandID}),
%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_DEMAND, ?LOG_MARKET_BUY, DemandGoods)),
%%            State2;
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_sell_demand_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_can_sell_demand(RoleID, #r_role{role_attr = RoleAttr} = State, ID, DemandID) ->
%%    ?IF(RoleAttr#r_role_attr.level >= ?MARKET_OPEN_LEVEL, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_003)),
%%    case market_misc:get_demand_market_info_by_id(DemandID) of
%%        [] ->
%%            ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_001);
%%        [#r_demand_market{role_id = DRoleID, type_id = DTypeID, num = GoodsNum, total_price = TotalPrice} = DemandGoods] ->
%%            Goods = mod_role_bag:get_goods_by_bag_id(ID, State),
%%            ?IF(Goods =:= false, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_002), ok),
%%            #p_goods{type_id = PTypeID, bind = Bind, end_time = EndTime, num = HaveNum} = Goods,
%%            ?IF(EndTime =:= 0, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_002)),
%%            ?IF(Bind =:= false, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_004)),
%%            ?IF(RoleID =/= DRoleID, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_003)),
%%            ?IF(DTypeID =:= PTypeID, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_002)),
%%            ?IF(HaveNum >= GoodsNum, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_002)),
%%            [ItemConfig] = lib_config:find(cfg_item, Goods#p_goods.type_id),
%%            ?IF(ItemConfig#c_item.market_time =:= 0, ok, ?THROW_ERR(?ERROR_MARKET_ON_SHELF_007)),
%%            ?IF(Goods#p_goods.market_end_time >= time_tool:now(), ok, ?THROW_ERR(?ERROR_MARKET_BUY_007)),
%%%%            ?IF(PExcellentList =:= DExcellentList, ok, ?THROW_ERR(?ERROR_MARKET_SELL_DEMAND_002)),  暂时不做卓越属性
%%            DecreaseList = [#r_goods_decrease_info{type = must_unbind, id = ID, num = GoodsNum}],
%%            BagDoing = [{decrease, ?ITEM_REDUCE_MARKET_SELL, DecreaseList}],
%%            case market_misc:sell_goods(DemandID) of
%%                ok ->
%%                    {ok, BagDoing, TotalPrice, DemandGoods, PTypeID};
%%                {error, ErrCode} ->
%%                    {error, ErrCode}
%%            end
%%    end.
%%
%%
%%%%下架
%%do_down_shelf_goods(RoleID, State, ID, Market) ->
%%    case Market of
%%        ?MARKET_SELL ->
%%            do_down_shelf_sell_goods(RoleID, State, ID, Market);
%%        _ ->
%%            do_down_shelf_demand_goods(RoleID, State, ID, Market)
%%    end.
%%
%%%%下架摆摊
%%do_down_shelf_sell_goods(RoleID, State, ID, Market) ->
%%    case catch check_down_shelf_sell_goods(RoleID, State, ID, Market) of
%%        {ok, State2, BagDoings, MarketGoods} ->
%%            common_misc:unicast(RoleID, #m_market_down_shelf_toc{grid_type = Market, grid_id = ID}),
%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_SELL, ?LOG_MARKET_DOWN, MarketGoods)),
%%            mod_role_bag:do(BagDoings, State2);
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_down_shelf_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_down_shelf_sell_goods(RoleID, #r_role{role_market = RoleMarket} = State, ID, Market) ->
%%    case Market of
%%        ?MARKET_SELL ->
%%            case lists:keytake(ID, #r_sell_market.id, RoleMarket#r_role_market.sell_grid) of
%%                {value, MarketGoods, NewSellGrid} ->
%%                    case market_misc:down_shelf_sell_goods(ID, RoleID, Market) of
%%                        ok ->
%%                            NewRoleMarket = RoleMarket#r_role_market{sell_grid = NewSellGrid},
%%                            GoodsList = [#p_goods{type_id = MarketGoods#r_sell_market.type_id, num = MarketGoods#r_sell_market.num, bind = true}],
%%                            BagDoings = [{create, ?ITEM_GAIN_MARKET_REVOKE, GoodsList}],
%%                            {ok, State#r_role{role_market = NewRoleMarket}, BagDoings, MarketGoods};
%%                        {error, ErrCode} ->
%%                            {error, ErrCode}
%%                    end;
%%                _ ->
%%                    ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_001)
%%            end
%%    end.
%%
%%%%下架求购
%%do_down_shelf_demand_goods(RoleID, State, ID, Market) ->
%%    case catch check_down_shelf_demand_goods(RoleID, State, ID, Market) of
%%        {ok, State2, AssetDoing, DemandGoods} ->
%%            common_misc:unicast(RoleID, #m_market_down_shelf_toc{grid_type = Market, grid_id = ID}),
%%            ?TRY_CATCH(log_market(RoleID, ?MARKET_DEMAND, ?LOG_MARKET_DOWN, DemandGoods)),
%%            mod_role_asset:do(AssetDoing, State2);
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_sell_demand_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_down_shelf_demand_goods(RoleID, #r_role{role_market = RoleMarket} = State, ID, Market) ->
%%    case lists:keytake(ID, #r_sell_market.id, RoleMarket#r_role_market.demand_grid) of
%%        {value, #r_demand_market{total_price = TotalPrice} = DemandGoods, NewDemandGrid} ->
%%            case market_misc:down_shelf_sell_goods(ID, RoleID, Market) of
%%                ok ->
%%                    AssetDoing = [{add_gold, ?ASSET_GOLD_ADD_FROM_MARKET_DOWN_SELF, TotalPrice, 0}],
%%                    NewRoleMarket = RoleMarket#r_role_market{demand_grid = NewDemandGrid},
%%                    {ok, State#r_role{role_market = NewRoleMarket}, AssetDoing, DemandGoods};
%%                {error, ErrCode} ->
%%                    {error, ErrCode}
%%            end;
%%        _ ->
%%            ?THROW_ERR(?ERROR_MARKET_DOWN_SHELF_001)
%%    end.
%%
%%
%%do_get_class_num(RoleID, Class, Type, State) ->
%%    case catch check_get_class_num(Class, Type) of
%%        {ok, List} ->
%%            common_misc:unicast(RoleID, #m_market_class_num_toc{list = List, type = Type}),
%%            State;
%%        {error, ErrCode} ->
%%            common_misc:unicast(RoleID, #m_market_class_num_toc{err_code = ErrCode}),
%%            State
%%    end.
%%
%%
%%check_get_class_num(Class, Type) ->
%%    TableName = ?IF(?MARKET_SELL =:= Type, ?MARKET_SELL_MAPPING, ?MARKET_DEMAND_MAPPING),
%%    case lib_config:find(cfg_market_dic, Class) of
%%        [#c_market_dic{class = 3, id = ID}] ->
%%            ClassList = check_get_class_num_i(ID),
%%            ResList = lists:foldl(
%%                fun(ClassID, Res) ->
%%                    case ets:lookup(TableName, ClassID) of
%%                        [] ->
%%                            Res;
%%                        [Info] ->
%%                            [#p_kv{id = ClassID div 10000, val = Info#market_mapping.num}|Res]
%%                    end
%%                end, [],
%%                ClassList),
%%            {ok, ResList};
%%        _ ->
%%            ?THROW_ERR(?ERROR_MARKET_CLASS_NUM_001)
%%    end.
%%
%%check_get_class_num_i(ID) ->
%%    List = lib_config:list(cfg_market_dic),
%%    List2 = check_get_class_num_i(ID, List, []),
%%    [ID * 10000|List2].
%%
%%check_get_class_num_i(_ID, [], List) ->
%%    List;
%%check_get_class_num_i(ID, [{_, Config}|T], List) ->
%%    case lists:member(ID, Config#c_market_dic.front_list) of
%%        true ->
%%            Type = case Config#c_market_dic.use_alone =:= 1 of
%%                       true ->
%%                           Config#c_market_dic.id * 10000 + ID;
%%                       _ ->
%%                           Config#c_market_dic.id * 10000
%%                   end,
%%            check_get_class_num_i(ID, T, [Type|List]);
%%        _ ->
%%            check_get_class_num_i(ID, T, List)
%%    end.
%%
%%
%%%%增加日志
%%do_add_log(#r_role{role_id = RoleID, role_market = RoleMarket, role_vip = RoleVip} = State, #p_market_log{log_type = Type, id = ID, total_price = TotalPrice, type_id = ItemType} = Log) ->
%%    RoleMarket2 = check_log_type(RoleID, Type, ID, RoleMarket, RoleVip, TotalPrice, ItemType, Log),
%%    State#r_role{role_market = RoleMarket2}.
%%
%%check_log_type(RoleID, Type, ID, RoleMarket, RoleVip, TotalPrice, ItemType, Log) ->
%%    case Type of
%%        ?MARKET_SELL_LOG_SELL ->
%%            %%发送自我收获金钱邮件
%%            TaxRate = market_misc:get_tax_rate(mod_role_vip:get_vip_level_by_role_vip(RoleVip)),
%%            Tax = lib_tool:ceil(TotalPrice * TaxRate / 10000),
%%            [ItemConfig] = lib_config:find(cfg_item, ItemType),
%%            GoodsList = [#p_goods{type_id = ?ASSET_GOLD, num = TotalPrice - Tax, bind = false}],
%%            LetterInfo = #r_letter_info{
%%                template_id = ?LETTER_TEMPLATE_MARKET_SELL,
%%                text_string = [lib_tool:to_list(ItemConfig#c_item.name), lib_tool:to_list(TotalPrice - Tax)],
%%                action = ?ITEM_GAIN_LETTER_MARKET_SELL,
%%                goods_list = GoodsList},
%%            common_letter:send_letter(RoleID, LetterInfo),
%%            %%删除对应上架物品
%%            common_misc:unicast(RoleID, #m_market_info_change_toc{type = Type, id = ID}),
%%            NewList = lists:keydelete(ID, #r_sell_market.id, RoleMarket#r_role_market.sell_grid),
%%            Log2 = Log#p_market_log{tax = Tax},
%%            common_misc:unicast(RoleID, #m_market_add_log_toc{log = Log2}),
%%            RoleMarket2 = RoleMarket#r_role_market{sell_grid = NewList},
%%            NewLogs = case erlang:length(RoleMarket2#r_role_market.log) >= ?ROLE_MARKET_LOG_NUM of
%%                          true ->
%%                              Logs1 = lists:droplast(RoleMarket2#r_role_market.log),
%%                              [Log2|Logs1];
%%                          _ ->
%%                              [Log2|RoleMarket2#r_role_market.log]
%%                      end,
%%            RoleMarket3 = RoleMarket2#r_role_market{log = NewLogs},
%%            RoleMarket3;
%%        ?MARKET_DEMAND_LOG_SELL ->
%%            common_misc:unicast(RoleID, #m_market_info_change_toc{type = Type, id = ID}),
%%            NewList = lists:keydelete(ID, #r_demand_market.id, RoleMarket#r_role_market.demand_grid),
%%            RoleMarket#r_role_market{demand_grid = NewList};
%%        ?MARKET_SELL_LOG_BUY ->
%%            NewLogs = case erlang:length(RoleMarket#r_role_market.log) >= ?ROLE_MARKET_LOG_NUM of
%%                          true ->
%%                              Logs1 = lists:droplast(RoleMarket#r_role_market.log),
%%                              [Log|Logs1];
%%                          _ ->
%%                              [Log|RoleMarket#r_role_market.log]
%%                      end,
%%            common_misc:unicast(RoleID, #m_market_add_log_toc{log = Log}),
%%            RoleMarket#r_role_market{log = NewLogs}
%%    end.
%%
%%
%%%%商品搜索
%%do_market_search(RoleID, Type, KeyWord, FirstType, SecondType, Color, Order, PassWord, Dic, SearchType, SortType, State) ->
%%    {MarketTable, MappingTable} = case Type =:= ?MARKET_SELL of
%%                                      true ->
%%                                          {?DB_SELL_MARKET_P, ?MARKET_SELL_MAPPING};
%%                                      _ ->
%%                                          {?DB_DEMAND_MARKET_P, ?MARKET_DEMAND_MAPPING}
%%                                  end,
%%    NewIDS = case SearchType of
%%                 true ->
%%                     IDS = get_search_ids(MappingTable, FirstType, SecondType, KeyWord),
%%                     market_sort(SortType, IDS);
%%                 _ ->
%%                     get_cache_all_list()
%%             end,
%%    {GoodList, OtherIDS} = get_search_goods(MarketTable, NewIDS, Color, Order, PassWord, ?MARKET_PAGE_NUM, []),
%%    set_cache_all_list(OtherIDS),
%%    IsNull = OtherIDS =:= [],
%%    common_misc:unicast(RoleID, #m_market_search_toc{goods = lists:reverse(GoodList), type = Type, dic_id = Dic, is_null = IsNull}),
%%    State.
%%
%%market_sort(#p_kv{id = SortType, val = SortType2}, IDS) ->
%%    IDS2 = lists:keysort(SortType, IDS),
%%    case SortType =:= 1 of
%%        true ->
%%            lists:reverse(IDS2);
%%        _ ->
%%            ?IF(SortType2 =:= 1, IDS2, lists:reverse(IDS2))
%%    end.
%%
%%
%%%% 获取搜索ID
%%get_search_ids(MappingTable, FirstType, SecondType, KeyWord) ->
%%    case KeyWord =:= [] of
%%        true ->
%%            MappingID = FirstType * 10000 + SecondType,
%%            case ets:lookup(MappingTable, MappingID) of
%%                [#market_mapping{list = List}] ->
%%                    List;
%%                _ ->
%%                    []
%%            end;
%%        _ ->
%%            ItemMappingTable = ?IF(MappingTable =:= ?MARKET_SELL_MAPPING, ?MARKET_SELL_ITEM_MAPPING, ?MARKET_DEMAND_ITEM_MAPPING),
%%            get_item_ids(ItemMappingTable, KeyWord, [])
%%    end.
%%
%%get_item_ids(_Table, [], List) ->
%%    List;
%%get_item_ids(Table, [ID|T], List) ->
%%    List2 = case ets:lookup(Table, ID) of
%%                [#market_mapping{list = MappingList}] ->
%%                    MappingList ++ List;
%%                _ ->
%%                    List
%%            end,
%%    get_item_ids(Table, T, List2).
%%
%%
%%
%%
%%get_search_goods(_MarketTable, IDS, _Color, _Order, _PassWord, Num, GoodList) when Num =:= 0 orelse IDS =:= [] ->
%%    {GoodList, IDS};
%%get_search_goods(MarketTable, [{ID, _, _}|T], Color, Order, PassWord, Num, GoodList) ->
%%    case ets:lookup(MarketTable, ID) of
%%        [] ->
%%            get_search_goods(MarketTable, T, Color, Order, PassWord, Num, GoodList);
%%        [Info] ->
%%            case catch check_is_right_goods(Info, Color, Order, PassWord) of
%%                ok ->
%%                    SendInfo = market_misc:trans_to_p_market_goods(Info),
%%                    get_search_goods(MarketTable, T, Color, Order, PassWord, Num - 1, [SendInfo|GoodList]);
%%                {error, _} ->
%%                    get_search_goods(MarketTable, T, Color, Order, PassWord, Num, GoodList)
%%            end
%%    end.
%%
%%
%%check_is_right_goods(Info, Color, Order, PassWord) ->
%%    {Type2, Password2} = case Info of
%%                             #r_sell_market{type_id = Type, password = Password1} ->
%%                                 {Type, Password1};
%%                             #r_demand_market{type_id = Type, password = Password1} ->
%%                                 {Type, Password1}
%%                         end,
%%    ?IF(PassWord =:= 1 orelse (PassWord =:= 2 andalso "" =:= Password2) orelse (PassWord =:= 3 andalso "" =/= Password2), ok, ?THROW_ERR(1)),
%%    [ItemConfig] = lib_config:find(cfg_item, Type2),
%%    ?IF(Color =/= 0 andalso Color =/= ItemConfig#c_item.quality, ?THROW_ERR(1), ok),
%%    case Order =:= 0 of
%%        true ->
%%            ok;
%%        _ ->
%%            case lib_config:find(cfg_equip, Type2) of
%%                [EquipConfig] ->
%%                    ?IF(EquipConfig#c_equip.step =/= Order, ?THROW_ERR(1), ok);
%%                _ ->
%%                    ?THROW_ERR(1)
%%            end
%%    end.
%%
%%
%%
%%
%%
%%get_cache_all_list() ->
%%    case erlang:get({?MODULE, cache_all_list}) of
%%        List when erlang:is_list(List) ->
%%            List;
%%        _ ->
%%            []
%%    end.
%%
%%set_cache_all_list(List) ->
%%    erlang:put({?MODULE, cache_all_list}, List).
%%
%%
%%gm_up_market(#r_role{role_bag = #r_role_bag{}} = State, Type) ->
%%    gm_up_market_i(State, 10, Type).
%%
%%gm_up_market_i(State, Num, _) when Num =:= 0 ->
%%    State;
%%gm_up_market_i(#r_role{role_id = RoleID} = State, Num, Type) ->
%%    case mod_role_bag:get_goods_by_type_id(Type, State) of
%%        #p_goods{id = ID} ->
%%            State2 = do_on_shelf(RoleID, State, ID, 1, 10, 10, ""),
%%            gm_up_market_i(#r_role{role_id = RoleID} = State2, Num - 1, Type);
%%        _ ->
%%            State
%%    end.
%%
%%log_market(FromRoleID, MarketType, ActionType, Data) ->
%%    case Data of
%%        #r_sell_market{} ->
%%            #r_sell_market{
%%                id = MarketID,
%%                time = SellTime,
%%                role_id = SellRoleID,
%%                total_price = TotalPrice,
%%                num = Num,
%%                type_id = TypeID} = Data;
%%        #r_demand_market{} ->
%%            #r_demand_market{
%%                id = MarketID,
%%                time = SellTime,
%%                role_id = SellRoleID,
%%                total_price = TotalPrice,
%%                num = Num,
%%                type_id = TypeID} = Data
%%    end,
%%    Log =
%%    #log_market{
%%        from_role_id = FromRoleID,
%%        market_type = MarketType,
%%        action_type = ActionType,
%%        market_id = MarketID,
%%        goods_type_id = TypeID,
%%        goods_num = Num,
%%        sell_role_id = SellRoleID,
%%        price = TotalPrice,
%%        sell_time = SellTime,
%%        expire_time = SellTime + ?ONE_DAY
%%    },
%%    mod_role_dict:add_background_logs(Log).
%%
%%
%%%%商品过期下架
%%do_clean_overtime_goods(#r_role{role_market = RoleMarket, role_id = RoleID} = State, Market, ID) ->
%%    case Market of
%%        ?MARKET_SELL ->
%%            case lists:keytake(ID, #r_sell_market.id, RoleMarket#r_role_market.sell_grid) of
%%                {value, _MarketGoods, NewSellGrid} ->
%%                    NewRoleMarket = RoleMarket#r_role_market{sell_grid = NewSellGrid},
%%                    common_misc:unicast(RoleID, #m_market_down_shelf_toc{grid_type = Market, grid_id = ID}),
%%                    State#r_role{role_market = NewRoleMarket};
%%                _ ->
%%                    State
%%            end;
%%        _ ->
%%            case lists:keytake(ID, #r_sell_market.id, RoleMarket#r_role_market.demand_grid) of
%%                {value, _DemandGoods, NewDemandGrid} ->
%%                    NewRoleMarket = RoleMarket#r_role_market{demand_grid = NewDemandGrid},
%%                    common_misc:unicast(RoleID, #m_market_down_shelf_toc{grid_type = Market, grid_id = ID}),
%%                    State#r_role{role_market = NewRoleMarket};
%%                _ ->
%%                    State
%%            end
%%    end.
