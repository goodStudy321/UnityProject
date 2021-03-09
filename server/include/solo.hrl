%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 三月 2018 10:17
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(SOLO_HRL).
-define(SOLO_HRL, solo_hrl).

-define(SOLO_RESET_WEEK, common_misc:get_global_int(?GLOBAL_SOLO_CROSS_DOMAIN_SERVER)).    %% 13天一个赛季

-define(ROLE_INFO_SCORE, 1).                %% 积分更新
-define(ROLE_INFO_DAILY_REWARD, 2).         %% 段位奖励更新
-define(ROLE_INFO_ENTER_TIMES, 3).          %% 参与次数
-define(ROLE_INFO_ENTER_REWARDS, 4).        %% 已经领取参与奖励列表
-define(ROLE_INFO_IS_MATCHING, 5).          %% 是否在匹配中
-define(ROLE_INFO_SEASON_ENTER_TIMES, 6).   %% 赛季进入次数更新
-define(ROLE_INFO_SEASON_WIN_TIMES, 7).     %% 赛季胜利次数
-define(ROLE_INFO_EXP, 8).                  %% 经验
-define(ROLE_INFO_STEP_REWARD_LIST, 9).     %% 段位奖励更新

-define(SOLO_MATCH_START, 1).   %% 开始匹配
-define(SOLO_MATCH_STOP, 0).    %% 结束匹配

-define(MAP_PREPARE_TIME, 3).   %% 双方进入之后有3秒时间准备
-define(MAP_FIGHT_TIME, 120).   %% 战斗阶段120秒
-define(SOLO_MAP_START_TIME, 25).   %% 25秒后必出结果
-define(MAP_END_TIME, 60).      %% 结束之后60秒关闭副本

-define(MAP_SOLO_STATUS_PREPARE, 1). %% 准备进入阶段
-define(MAP_SOLO_STATUS_START, 2).   %% 战斗阶段
-define(MAP_SOLO_STATUS_END, 3).     %% 结束阶段
-define(MAP_SOLO_STATUS_SHUTDOWN, 4).%% 关闭阶段

-define(END_RESET_TIME, {23, 59, 0}). %% 结算时间

-define(LEFT_POS, {-2800, 10000}).
-define(RIGHT_POS, {3250, 10000}).

-define(SOLO_RANK_NUM, 50).     %% 取前50名排行

-define(SOLO_ADD_EXP_TIMES, 10).    %% 前10次有经验加成

-define(SINGLE_SERVER_TYPE, 1). %% 单服类型

-define(SINGLE_SERVER_SEND, 8). % 开服第8天跨服

-define(START_SATURDAY, 6).  %% 星期六开启赛季

%% @doc 准备匹配数据
-record(r_role_solo_match, {
    role_id,        %% 角色ID
    grade,          %% 段位
    wait_round=0    %% 等待轮次 5秒一轮
}).

-record(r_map_solo, {
    status,         %% 当前状态
    start_time,     %% 开始时间
    end_time,       %% 结束时间
    shutdown_time,  %% 关闭时间
    role_list=[]    %% 进入的玩家

}).

-record(c_solo_step_reward,{
    step,           %% 段位ID
    score,          %% 积分
    grade_name,     %% 段位名称
    add_honor,      %% 增加冗余
    win_add_score,  %% 获胜增加积分
    lose_add_score, %% 失败增加积分
    reward_string,  %% 道具奖励
    win_exp_rate,   %% 获胜经验奖励/前10场
    lose_exp_rate,  %% 失败经验奖励/前10场
    win_honor,      %% 获胜荣誉奖励/前10场
    lose_honor,     %% 失败荣誉奖励/前10场
    item_rewards    %% 获胜道具奖励/前10场
}).

-record(c_solo_enter_reward,{
    times,      %% 参与次数
    rewards     %% 奖励
}).

%% 排行奖励
-record(c_solo_rank_reward, {
    id,
    type,       % 类型
    region,     % 排名区间
    reward      % 奖励内容
}).

-endif.