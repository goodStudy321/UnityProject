%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 六月 2018 14:43
%%%-------------------------------------------------------------------
-author("WZP").


-ifndef(FAIRY_HRL).
-define(FAIRY_HRL, fairy_hrl).

-define(FAIRY_BEFORE, 1).                                      %%  任务前
-define(FAIRY_FAILED, 0).                                      %%  任务失败



-define(FAIRY_LEVEL, 130).                                      %%  参加等级限制
-define(FAIRY_TIMES, 3).                                        %%  每日次数
-define(FAIRY_OFF_LINE_FAIL_TIME, 120).                         %%  离线后任务失败
-define(FAIRY_DOUBLE_GLOBAL_ID, 1012).                          %%  双倍时间活动系统配置ID
-define(FAIRY_IS_BC, 1).                                        %%  广播
-define(FAIRY_MAP_LOCK_GLOBAL, 29).                             %%  护送地图锁

-record(c_fairy, {id, fairy_item_num, exp_percent, silver, fairy_name,is_bc}).

-record(c_fairy_reward, {level, exp}).

-endif.



























