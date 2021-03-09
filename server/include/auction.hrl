%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 六月 2019 19:58
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(AUCTION_HRL).
-define(AUCTION_HRL, auction_hrl).

-define(AUCTION_BUY_BUYOUT, 1).     %% 一口价
-define(AUCTION_BUY_AUCTION, 2).    %% 竞价

-define(AUCTION_FROM_ROLE, 0).      %% 拍品来自玩家
-define(AUCTION_FROM_FAMILY, 1).    %% 拍品来自道庭

-define(AUCTION_CARE, 0).           %% 关注
-define(AUCTION_CANCEL_CARE, 1).    %% 取消关注

-define(AUCTION_LOG_ROLE_SELL, 1).  %% 玩家拍品记录
-define(AUCTION_LOG_ROLE_BUY, 2).   %% 玩家竞拍记录
-define(AUCTION_LOG_FAMILY_SELL, 3).%% 道庭拍品记录

-define(AUCTION_ALL_CLASS, 1000).   %% 所有ID

-define(ETS_AUCTION_CLASS_HASH, ets_auction_class_hash).    %% 根据分类做hash
-define(ETS_AUCTION_TIME_HASH, ets_auction_time_hash).      %% 根据时间获取
-define(ETS_AUCTION_TYPE_ID_HASH, ets_auction_type_id_hash).%% TypeID Hash

%% key = {分类ID, 品质(0表示全部)} key里不再加等阶
-record(r_auction_class_hash, {key, ids = [], len=0}).

%% end_time 过期时间
-record(r_auction_time_hash, {end_time, ids = []}).

%% 类型ID Hash
-record(r_auction_type_id_hash, {type_id, ids = [], care_role_ids=[]}).

-record(c_auction_major_class, {
    major_id,       %% 大ID
    name,           %% 名称
    sub_list,       %% 子类
    is_equip        %% 装备搜索
}).
-endif.