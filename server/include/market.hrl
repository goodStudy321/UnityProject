%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 六月 2018 10:16
%%%-------------------------------------------------------------------
-author("WZP").


-ifndef(MARKET_HRL).
-define(MARKET_HRL, market_hrl).


-define(MARKET_PAGE_NUM, 20).  %%每页物品数量


-define(MARKET_OPEN_LEVEL, 90).

-define(MARKET_SELL_MAPPING, market_sell_mapping).
-define(MARKET_DEMAND_MAPPING, market_demand_mapping).

%%时序映射列表
-define(MARKET_SELL_ITEM_MAPPING, market_sell_item_mapping).
-define(MARKET_DEMAND_ITEM_MAPPING, market_demand_item_mapping).

%%单价映射列表
-define(MARKET_SELL_UNIT_ITEM_MAPPING, market_sell_unit_item_mapping).
-define(MARKET_DEMAND_UNIT_ITEM_MAPPING, market_demand_unit_item_mapping).

%%总价映射列表
-define(MARKET_SELL_TOTAL_ITEM_MAPPING, market_sell_total_item_mapping).
-define(MARKET_DEMAND_TOTAL_ITEM_MAPPING, market_demand_total_item_mapping).

-record(market_mapping, {
    id,                     %% 种类ID
    list = [],              %% 主表ID
    num = 0
}).

-define(MARKET_ALL, 10490000).   %%全部

-define(MARKET_CLASS_LIST, [10490000, 10010000, 10320000, 10120000, 10200000, 10230000,
                            10030000, 10040000, 10050000, 10060000,
                            10021001, 10071001, 10081001, 10091001, 10101001, 10111001,
                            10021032, 10071032, 10081032, 10091032, 10101032, 10111032,
                            10131012, 10141012, 10151012, 10161012, 10171012, 10181012, 10191012,
                            10211020,
                            10241023, 10251023, 10261023, 10271023, 10281023, 10291023, 10301023, 10311023,10331023]).

-define(MARKET_MAX_PRICE, 999999).
-define(MARKET_MIN_PRICE, 2).

%%  用户市场摆拍数量
-define(MARKET_ROLE_SELL_GRID_NUM, 10).
%%  用户市场求购数量
-define(MARKET_ROLE_DEMAND_GRID_NUM, 10).

%%  用户商品密码长度
-define(MARKET_PASSWORD_LENGTH, 6).

%%  用户市场日志 20
-define(ROLE_MARKET_LOG_NUM, 20).

%%  type 1-销售市场 2-求购市场
-define(MARKET_SELL, 1).
-define(MARKET_DEMAND, 2).


-define(MARKET_SELL_LOG_BUY, 1).                %%市场购买
-define(MARKET_SELL_LOG_SELL, 2).               %%市场被购买
-define(MARKET_DEMAND_LOG_BUY, 3).              %%求购市场求购
-define(MARKET_DEMAND_LOG_SELL, 4).             %%求购市场被求购

%%  type 0-求购 1-出售
-define(MARKET_WANT, 0).


%%日志
-record(r_role_market_log, {role_id, log_id = 0, time = 0, price = 0, type, tax = 0, goods}).
-record(c_market_dic, {id, class, front_list, use_alone}).










-endif.
