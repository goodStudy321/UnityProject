%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 十月 2019 11:54
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(CYCLE_ACT_COUPLE_HRL).
-define(CYCLE_ACT_COUPLE_HRL, cycle_act_couple_hrl).

%% 一见钟情登录奖励领取Type
-define(CYCLE_ACT_COUPLE_LOGIN_TYPE_NORMAL, 1).    %% 登录奖励一
-define(CYCLE_ACT_COUPLE_LOGIN_TYPE_COUPLE, 2).    %% 登录奖励2

%% 告别单身状态
-define(CYCLE_ACT_COUPLE_PROPOSE_CAN_REWARD, 1).    %% 可以领奖
-define(CYCLE_ACT_COUPLE_PROPOSE_HAS_REWARD, 2).    %% 已经领奖

-define(CYCLE_ACT_COUPLE_PROPOSE_LEN, 3).

%% 月下情缘
-define(CYCLE_ACT_COUPLE_PRAY_ONE, 1).      %% 单抽
-define(CYCLE_ACT_COUPLE_PRAY_TEN, 10).     %% 10连抽

-define(CYCLE_ACT_COUPLE_PRAY_BIG_TYPE, 3). %% 月下情缘大奖类型

%% 魅力之王
-define(CYCLE_ACT_COUPLE_CHARM_LEN, 10).    %% 排行数量

-record(r_cycle_act_couple_charm, {
    role_id,
    date,
    charm
}).

-record(c_cycle_act_couple_login, {
    index_id,
    reward,
    type,
    config_num
}).

-record(c_cycle_act_couple_propose, {
    index_id,
    reward,
    type,
    config_num
}).

-record(c_cycle_act_couple_pray, {
    index_id,
    reward,
    weight,
    type,
    config_num
}).

-record(c_cycle_act_couple_pray_exchange, {
    index_id,
    need_score,
    reward,
    config_num
}).

-record(c_cycle_act_couple_charm, {
    index_id,
    reward,
    rank,
    config_num
}).

-endif.