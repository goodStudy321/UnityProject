%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 套装系统
%%% @end
%%% Created : 08. 五月 2019 16:21
%%%-------------------------------------------------------------------
-author("huangxiangrui").
-ifndef(SUIT_HRL).
-define(SUIT_HRL, suit_hrl).

%% 部件数
-define(PLACE_NUMBER, 5).

%% 最小阶级
-define(MIN_GRADATION, 0).

-define(BIG_TYPE_THUNDER, 1).   %% 神雷
-define(BIG_TYPE_SUN, 2).       %% 烈阳

-define(SUIT_SUB_TYPE_LEFT, 1). %% 左
-define(SUIT_SUB_TYPE_RIGHT, 2).%% 右

%% 套装属性表
-record(c_suit, {
    suit_id = 0,            %% 套装id
    type = 0,               %% 类型
    subtype = 0,            %% 小类
    gradation = 0,          %% 阶级
    attr = ""               %% 属性
}).

%% 部件升阶
-record(c_suit_star, {
    place_id,           %% 部位id
    place,              %% 部位
    suit_id,            %% 所属套装id
    gradation,          %% 阶级
    property,           %% 消耗材料
    restoration,        %% 消耗材料放回
    attr,               %% 属性
    pre_id,             %% 前置部位ID
    next_id,            %% 后置部位ID
    subtype = 0,        %% 小类
    type                %% 类型
}).

-endif.