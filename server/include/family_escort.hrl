%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 六月 2019 14:37
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(FAMILY_ESCORT_HRL).
-define(FAMILY_ESCORT_HRL, family_escort_hrl).

-define(MAX_FAIRY, 1003).
-define(INIT_FAIRY, 1000).



%%1-提升品质 2-最高品质 3-开始护送
-define(ESCORT_UP_FAIRY, 1).
-define(ESCORT_MAX_FAIRY, 2).
-define(ESCORT_START, 3).

-define(ESCORT_LIST_NUM, 6).

-record(c_escort, {fairy_id, quality, need_item, max_num, exp_rate, reward, fairy_name, escort_time , rob_back_reward}).


%% 时间循环ID检测
-define(ETS_TIME_LOOP, ets_time_loop).
-record(r_time_loop, {time, check_list = []}).

-define(ESCORT_GLOBAL, 150).

-define(ESCORT_LOG_START, 1).
-define(ESCORT_LOG_END, 6).
-define(ESCORT_LOG_ROB_SUC, 7).
-define(ESCORT_LOG_ROB_FAIL, 8).
-define(ESCORT_LOG_HELP, 9).
-define(ESCORT_LOG_ROB_BACK, 10).


-define(MAX_FAIRY_LOG, 20).

-endif.


