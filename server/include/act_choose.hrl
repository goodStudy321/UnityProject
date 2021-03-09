%%%-------------------------------------------------------------------
%%% @author huangxiangrui
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%% 黑市鉴宝
%%% @end
%%% Created : 11. 九月 2019 10:37
%%%-------------------------------------------------------------------
-author("huangxiangrui").

-ifndef(ACT_CHOOSE_HRL).
-define(ACT_CHOOSE_HRL, act_choose_hrl).

-record(c_act_choose, {
    id,
    reward_gear,    % 奖励
    drop,           % 掉落组
    upper_limit,    % 刷新上限
    weight,          % 权重,
    config_num
}).

-endif.