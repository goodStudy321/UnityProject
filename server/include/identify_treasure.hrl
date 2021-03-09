%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 鉴宝活动
%%% @end
%%% Created : 10. 九月 2019 11:14
%%%-------------------------------------------------------------------
-author("huangxiangrui").
-ifndef(IDENTIFY_TREASURE_HRL).
-define(IDENTIFY_TREASURE_HRL, identify_treasure_hrl).

-define(IS_RARE, 1). % 稀有

-define(VOLUNTARILY, 1). % 自动鉴宝

-define(LOOP_VOLUNTARILY, 3). % 系统自动鉴宝

-record(c_act_identify_treasure, {
    id,
    is_rare,        % 是否稀有
    reward,         % 奖励
    weight,         % 权重
    show,            % 大奖展示
    config_num
}).

-endif.