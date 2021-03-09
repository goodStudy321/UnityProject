%%%-------------------------------------------------------------------
%%% @author yaolun
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 图鉴
%%% @end
%%% Created : 14. 二月 2019 19:33
%%%-------------------------------------------------------------------
-author("yaolun").

-ifndef(HANDBOOK_HRL).
-define(HANDBOOK_HRL, handbook_hrl).


%% 图鉴养成配置表结构
-record(c_handbook_cultivate, {
    card_id,            %% 卡片Id
    name,               %% 名称
    type,               %% 类型
    group,              %% 卡组的id
    quality,            %% 品质
    star_lv,            %% 星级
    grade,              %% 等级
    upgrade_consume,    %% 升级消耗
    essence_consume,    %% 精华消耗
    property1,          %% 属性1
    property2,          %% 属性2
    property3,          %% 属性3
    property4           %% 属性4
}).


%% 图鉴卡片道具表结构
-record(c_handbook_prop, {
    item_id,        %% 道具id
    essence         %% 分解精华
}).


%% 图鉴卡片组表结构
-record(c_handbook_group, {
    card_group_id,          %% 卡组id
    card_list,              %% 卡片id列表
    act_num,                %% 激活数量
    star_num,               %% 星级数量
    act_pro                 %% 激活属性
}).


-endif.