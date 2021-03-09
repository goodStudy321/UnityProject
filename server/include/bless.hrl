%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 一月 2019 14:46
%%%-------------------------------------------------------------------
-author("WZP").
-ifndef(BLESS_HRL).
-define(BLESS_HRL, bless_hrl).

-define(ROLE_BLESS_BASE_TIMES, 8).
-define(BLESS_GLOBAL, 139).
-define(BLESS_EXP, 2).
-define(BLESS_COPPER, 1).
-define(BLESS_FREE_CD, 28800).

-record(c_bless, {
    times,                    %% 祈福次数
    exp_need                  %% 经验祈福消耗元宝

}).

-record(c_bless_rate, {
    id = 0,
    type = 0,
    value = 0,
    rate = 0
}).

-endif.
