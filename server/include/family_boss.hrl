%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 五月 2018 10:08
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(FAMILY_BOSS_HRL).
-define(FAMILY_BOSS_HRL, family_boss_hrl).

-define(FAMILY_BOSS_X, 2491).                        %%  Boss  坐标X
-define(FAMILY_BOSS_Y, 1503).                        %%  Boss  坐标Y

-define(FAMILY_BOSS_ONLINE_BC, 1).                       %%在线发送
-define(FAMILY_BOSS_LOGIN_BC, 0).                        %%上线通知

-define(FAMILY_BOSS_LIFE, 1).                        %%Boss存活
-define(FAMILY_BOSS_DEAD, 0).                        %%boss死了


-define(FAMILY_BOSS_OPEN, 1).                            %%活动状态开
-define(FAMILY_BOSS_CLOSE, 0).                           %%活动状态关


-define(FAMILY_BOSS_MAP_END_DELAY, 120).                           %%关闭地图延时


-record(r_family_boss_ctrl, {status = ?FAMILY_BOSS_CLOSE, family_list = []}).
-record(c_family_boss, {id, boss_id, level, point}).


-endif.
