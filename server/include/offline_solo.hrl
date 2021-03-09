%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. 四月 2018 10:43
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(OFFLINE_SOLO_HRL).
-define(OFFLINE_SOLO_HRL, offline_solo_hrl).

-define(ETS_RANK_OFFLINE_SOLO, ets_rank_offline_solo).

-define(OFFLINE_SOLO_MAX_ROBOT_NUM, 3000).   %% 初始创建3000个机器人

-define(DEFAULT_CHALLENGE_TIMES, 10).   %% 默认挑战次数
-define(DEFAULT_BUY_TIMES, 5).          %% 剩余购买次数
-define(BUY_CHALLENGE_GOLD, 10).        %% 10元宝购买挑战次数
-define(REWARD_RESET_HOUR, 22).         %% 每天10点重置奖励

-define(OFFLINE_SOLO_PANEL_OPEN, 1).    %% 打开面板
-define(OFFLINE_SOLO_PANEL_CLOSE, 0).   %% 关闭面板

-define(TEN_RANK, 10).
-define(FIFTY_RANK, 50).

-define(OFFLINE_SOLO_REFRESH_NUM, 5).   %% 一次刷新5个人
-define(OFFLINE_SOLO_WEAKER_NUM, 1).    %% 比自己弱的人数

%% 有排名且在一定范围内
-define(OFFLINE_SOLO_REFRESH_RANGE_1, [
    {0.8, 0.85},
    {0.86, 0.91},
    {0.92, 0.97},
    {0.98, 0.99},
    {1.05, 1.15}
]).

%% 没有排名或者处于最后一位
-define(OFFLINE_SOLO_REFRESH_RANGE_2, [
    {0.8, 0.85},
    {0.86, 0.91},
    {0.92, 0.95},
    {0.96, 0.98},
    {0.987, 0.999}
]).

%% 11-50名
-define(OFFLINE_SOLO_REFRESH_RANGE_3, [
    {0.4, 0.5},
    {0.6, 0.7},
    {0.8, 0.9},
    {1.0, 1.1},
    {1.2, 1.3}
]).

-record(r_offline_solo_dict, {
    is_panel_open = false,      %% 面板是否打开
    robot_args,
    my_bestir_times = 0,        %% 鼓舞次数
    dest_bestir_times = 0,      %% 对方鼓舞次数
    rank_list = []
}).

%% 挑战者参数
-record(r_challenge_args, {
    dest_role_id,
    robot_args
}).

-record(r_rank_offline_solo, {rank, role_id}).

-record(r_offline_solo_fight, {
    role_id,
    role_name,
    level,
    sex,
    category,
    hp,
    power,
    skin_list
}).

-record(c_robot_offline_solo, {
    min_rank,
    max_rank,
    prop_range,
    level,
    hp,
    min_power,
    max_power
}).

-record(c_offline_solo_reward, {
    min_rank,
    max_rank,
    add_honor,
    add_silver
}).

-endif.