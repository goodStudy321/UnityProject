%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 24. 五月 2017 15:30
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(MISSION_HRL).
-define(MISSION_HRL, mission_hrl).

%%任务类型：
-define(MISSION_TYPE_MAIN, 1).      %% 主线
-define(MISSION_TYPE_BRANCH, 2).    %% 支线
%% 3以上都是循环任务
-define(MISSION_TYPE_RING, 3).      %% 跑环任务
-define(MISSION_TYPE_FAMILY, 4).    %% 帮派日常任务
-define(MISSION_TYPE_DAILY, 6).     %% 日常活跃任务
-define(MISSION_TYPE_FAIRY, 909).   %% 护送仙女任务
-define(IS_MISSION_LOOP(Type), (Type >= ?MISSION_TYPE_RING)).  %% 是否循环任务

-define(MISSION_COPY_TIMES, 1).     %% 一轮副本最多1次副本任务

-define(MISSION_KILL_MONSTER, 0).           %% 杀怪任务
-define(MISSION_SPEAK, 1).                  %% 对话任务
-define(MISSION_COLLECT, 2).                %% 采集任务
-define(MISSION_MOVE, 4).                   %% 抵达目标点配置
-define(MISSION_RATE, 5).                   %% 概率增加计数器
-define(MISSION_FRONT, 6).                  %% 流程树id
-define(MISSION_FINISH_COPY, 7).            %% 通关副本
-define(MISSION_POWER, 8).                  %% 战斗力
-define(MISSION_REFINE, 9).                 %% 强化
-define(MISSION_GAIN_EXP, 10).              %% 获得经验
-define(MISSION_ACTIVE, 11).                %% 活跃度
-define(MISSION_FRIEND_NUM, 12).            %% 好友数量
-define(MISSION_WORLD_BOSS, 13).            %% 世界boss
-define(MISSION_COMPOSE, 15).               %% 合成
-define(MISSION_OFFLINE_SOLO, 16).          %% 离线竞技场
-define(MISSION_ALL_REFINE_LEVEL, 17).      %% 全身装备强化等级
-define(MISSION_FINISH_DAILY_MISSION, 18).  %% 完成日常任务
-define(MISSION_LISTEN_ITEM, 19).           %% 收集道具
-define(MISSION_CONFINE, 20).               %% 达到特定境界
-define(MISSION_FAMILY_MISSION, 21).        %% 完成X次道庭任务
-define(MISSION_FAMILY_ESCORT, 22).         %% 完成X次道庭护送
-define(MISSION_FAMILY_ROB_ESCORT, 23).     %% 参与X次道庭劫镖
-define(MISSION_KILL_FIVE_ELEMENT_BOSS, 24).%% 击杀五行秘境X只

-define(MISSION_STATUS_ACCEPT, 1).  %% 未接取
-define(MISSION_STATUS_DOING, 2).   %% 未完成
-define(MISSION_STATUS_REWARD, 3).  %% 未领取

-define(DAILY_RESET_DAY, 1).    %% 每日0点重置
-define(DAILY_RESET_WEEK, 2).   %% 每周重置

-define(IS_AUTO_ACCEPT(AutoAccept), (AutoAccept =:= 1)).
-define(IS_AUTO_COMPLETE(AutoComplete), (AutoComplete =:= 1)).

-define(CONDITION_LEVEL, 1).        %% 任务等级限制
-define(CONDITION_FAMILY, 2).       %% 任务帮派限制
-define(CONDITION_RELIVE_ARGS, 3).  %% 转生限制
-define(CONDITION_FAIRY, 4).        %% 护送任务限制
-define(CONDITION_FUNCTION, 5).     %% 功能开启限制

-define(NEED_FAMILY(NeedFamily), (NeedFamily =:= 1)).   %% 是否需要帮派

-define(MAX_MISSION_ID, 100000).

%% 过滤的任务ID
-define(FLIER_MISSION_ID_LIST, [301303]).

-define(DEL_DAILY_MISSION_IDS, [103008, 103009, 103010, 103011, 103012]).

-define(SPECIAL_ITEM_REWARD, "0").  %% 道具奖励特殊格式，直接过滤
-record(r_mission_item_monster, {
    mission_id,
    item_type_id,
    item_rate
}).

-record(c_mission, {
    id=0,
    name="",
    type=0,
    sub_type=0,
    max_times=0,
    pre_mission=0,
    next_mission=0,
    min_level=0,
    conditions=[],
    auto_accept=0,
    auto_complete=0,
    listeners=[],
    exp_type=0,
    exp=0,
    item=[],
    add_buffs=[]
}).

-record(c_mission_excel, {
    id=0,
    name="",
    chapter = 0,
    type=0,
    sub_type=0,
    quality=0,
    times=0,
    rounds=0,
    pre_mission=0,
    next_mission=0,
    min_level=0,
    max_level=0,
    need_family=0,
    need_relive_args=[],
    auto_accept=0,
    auto_complete=0,
    listener_type=0,
    listener_value=[],
    exp_type=0,
    exp=0,
    item=[],
    add_buffs=[],
    need_function_id=0
}).

-record(c_daily_mission, {
    type = 0,           %% 组ID
    type_desc,          %% 备注
    reward_times,       %% 轮数
    rewards             %% 循环任务额外奖励
}).

-endif.
