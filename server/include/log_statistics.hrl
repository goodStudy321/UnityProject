%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. 十一月 2018 16:09
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(LOG_STATISTICS_HRL).
-define(LOG_STATISTICS_HRL, log_statistics_hrl).
-include("activity.hrl").

-define(ETS_ROLE_STATISTICS, ets_role_statistics).

-define(LOG_STAT_RING_MISSION, 1).          %% 悬赏
-define(LOG_STAT_OFFLINE_SOLO, 2).          %% 竞技场
-define(LOG_STAT_WORLD_BOSS_1, 11).         %% 野外BOSS
-define(LOG_STAT_WORLD_BOSS_2, 12).         %% 洞天福地
-define(LOG_STAT_WORLD_BOSS_4, 13).         %% 幽冥地界
-define(LOG_STAT_MYTHICAL_BOSS, 14).        %% 神兽岛
-define(LOG_STAT_ANCIENTS_BOSS, 15).        %% 远古遗迹
-define(LOG_STAT_FAMILY_MISSION, 16).       %% 道庭任务

-define(LOG_STAT_BATTLE, 30).           %% 三界战场
-define(LOG_STAT_SOLO, 31).             %% 仙峰论剑
-define(LOG_STAT_FAMILY_TD, 32).        %% 守卫仙盟
-define(LOG_STAT_ANSWER, 33).           %% 答题
-define(LOG_STAT_FAMILY_ANSWER, 34).    %% 仙盟晚宴
-define(LOG_STAT_FAMILY_BOSS, 35).      %% 仙盟BOSS
-define(LOG_STAT_SUMMIT_TOWER, 36).     %% 逍遥神坛
-define(LOG_STAT_FAMILY_BATTLE, 37).    %% 仙盟战
-define(LOG_STAT_DEMON_BOSS, 38).       %% 魔域boss参与度
-define(LOG_STAT_FAMILY_ESCORT, 39).    %% 道庭护送
-define(LOG_STAT_FAMILY_ROB, 40).       %% 道庭拦截

-define(LOG_STAT_COPY_EXP, 60).         %% 经验副本
-define(LOG_STAT_COPY_SILVER, 61).      %% 金币副本
-define(LOG_STAT_COPY_EQUIP, 62).       %% 装备副本
-define(LOG_STAT_COPY_TOWER, 63).       %% 爬塔副本
-define(LOG_STAT_COPY_WORLD_BOSS, 64).  %% 个人boss副本
-define(LOG_STAT_COPY_SINGLE_TD, 65).   %% 宠物副本
-define(LOG_STAT_COPY_IMMORTAL, 66).    %% 仙魂副本

-define(LOG_STAT_LIST, [
    #c_log_stat{type = ?LOG_STAT_RING_MISSION, level_args = 95, sub_list = [10]},
    #c_log_stat{type = ?LOG_STAT_OFFLINE_SOLO, level_args = 90, sub_list = [10]},
    #c_log_stat{type = ?LOG_STAT_WORLD_BOSS_1, level_args = 34, sub_list = [8, 11]},
    #c_log_stat{type = ?LOG_STAT_WORLD_BOSS_2, level_args = 160},
    #c_log_stat{type = ?LOG_STAT_WORLD_BOSS_4, level_args = 270},
    #c_log_stat{type = ?LOG_STAT_MYTHICAL_BOSS, level_args = 330},
    #c_log_stat{type = ?LOG_STAT_ANCIENTS_BOSS, level_args = 380},
    #c_log_stat{type = ?LOG_STAT_FAMILY_MISSION, level_args = {mfa, mod_role_log_statistics, get_family_task_level, []}},

    #c_log_stat{type = ?LOG_STAT_BATTLE, level_args = {activity, ?ACTIVITY_BATTLE}},
    #c_log_stat{type = ?LOG_STAT_SOLO, level_args = {activity, ?ACTIVITY_SOLO}},
    #c_log_stat{type = ?LOG_STAT_FAMILY_TD, level_args = {activity, ?ACTIVITY_FAMILY_TD}},
    #c_log_stat{type = ?LOG_STAT_ANSWER, level_args = {activity, ?ACTIVITY_ANSWER}},
    #c_log_stat{type = ?LOG_STAT_FAMILY_ANSWER, level_args = {activity, ?ACTIVITY_FAMILY_AS}},
    #c_log_stat{type = ?LOG_STAT_FAMILY_BOSS, level_args = {activity, ?ACTIVITY_FAMILY_BS}},
    #c_log_stat{type = ?LOG_STAT_SUMMIT_TOWER, level_args = {activity, ?ACTIVITY_SUMMIT_TOWER}},
    #c_log_stat{type = ?LOG_STAT_FAMILY_BATTLE, level_args = {activity, ?ACTIVITY_FAMILY_BATTLE}},
    #c_log_stat{type = ?LOG_STAT_DEMON_BOSS, level_args = {activity, ?ACTIVITY_DEMON_BOSS}, sub_list = [1, 3]},
    #c_log_stat{type = ?LOG_STAT_FAMILY_ESCORT, level_args = {activity, ?ACTIVITY_FAMILY_ESCORT}, sub_list = [1, 5]},
    #c_log_stat{type = ?LOG_STAT_FAMILY_ROB, level_args = {activity, ?ACTIVITY_FAMILY_ESCORT}, sub_list = [1, 5]},

    #c_log_stat{type = ?LOG_STAT_COPY_EXP, level_args = {copy, 20001}, sub_list = [2, 4]},
    #c_log_stat{type = ?LOG_STAT_COPY_SILVER, level_args = {copy, 20101}},
    #c_log_stat{type = ?LOG_STAT_COPY_EQUIP, level_args = {copy, 20201}, sub_list = [2]},
    #c_log_stat{type = ?LOG_STAT_COPY_TOWER, level_args = {copy, 40001}},
    #c_log_stat{type = ?LOG_STAT_COPY_WORLD_BOSS, level_args = {copy, 90031}, sub_list = [3]},
    #c_log_stat{type = ?LOG_STAT_COPY_SINGLE_TD, level_args = {copy, 20301}},
    #c_log_stat{type = ?LOG_STAT_COPY_IMMORTAL, level_args = {copy, 20701}}
]).

-record(c_log_stat, {type, level_args, sub_list = []}).

-record(r_role_statistics, {
    role_id,
    log_list = []
}).

-record(r_statistics_log, {
    type,           %% 类型
    times,          %% 参与次数
    sub_times       %% 子次数
}).
-endif.
