%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 二月 2019 11:09
%%%-------------------------------------------------------------------
-author("WZP").
-ifndef(WEEK_CARD_HRL).
-define(WEEK_CARD, week_card).


-define(WEEK_CARD_REPLACE,1).     %%替换
-define(WEEK_CARD_ADD,2).         %%增加


-define(WEEK_CARD_TYPE_ONE,1).     %%单次限时
-define(WEEK_CARD_TYPE_TWO,2).     %%单次不限时
-define(WEEK_CARD_TYPE_THREE,3).   %%循环不限时

-define(WEEK_CARD_OPEN_TYPE_ONE,1).   %%正常时间开启
-define(WEEK_CARD_OPEN_TYPE_TWO,2).   %%开服时间开启


-define(WEEK_CARD_BUY,1).        %%购买
-define(WEEK_CARD_RECHARGE,2).   %%充值顺带激活
-define(WEEK_CARD_FIRST_RECHARGE,3).   %%充值顺带激活

-record(r_week_card, {
    id,
    open_time,     %%  时间为0时未激活
    end_time,      %%  消失时间，消失前未激活则周卡丢失   0为永久存在
    buy_times,     %%  周卡激活次数
    reward = []    %%  已领奖励
}).


-record(c_week_card, {
    id,                     %%ID卡
    type,                   %%类型
    time_type,              %%开启类型
    level,                  %%开启等级
    open_time,              %%开启时间
    end_time,               %%结束时间
    start_args,             %%开服开启时间
    end_args,               %%开服结束时间
    loop_times,             %%循环次数
    open_type,              %%激活条件
    open_args               %%激活条件参数
}).

-record(c_week_card_reward, {
    id,
    card_id,
    day,
    reward
}).

-endif.
