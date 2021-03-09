%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 一月 2018 11:32
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(WORLD_BOSS_HRL).
-define(WORLD_BOSS_HRL, world_boss_hrl).

-define(ETS_FLOOR_ROLE, ets_floor_role).

-define(TIRED_BUFF, 203001).    %% 疲劳buff

-define(MAX_KILL_LOGS, 5).      %% 最多5条击杀日志
-define(MAX_DROP_LOGS, 20).     %% 最多20条拾取日志

-define(IS_WORLD_BOSS_TYPE(BossType), (BossType =:= 0 orelse BossType =:= 4)). %% 种类
-define(BOSS_TYPE_HIDDEN_BOSS, 3).      %% 隐藏boss类型

-define(BOSS_TYPE_WORLD_BOSS, 1).       %% 世界boss类型
-define(BOSS_TYPE_FAMILY, 2).           %% 洞天福地
-define(BOSS_TYPE_PERSONAL, 3).         %% 个人boss类型
-define(BOSS_TYPE_TIME, 4).             %% 幽冥禁地
-define(BOSS_TYPE_MYTHICAL, 5).         %% 神兽岛boss
-define(BOSS_TYPE_CROSS_MYTHICAL, 6).   %% 跨服神兽岛
-define(BOSS_TYPE_ANCIENTS, 7).         %% 远古遗迹

-define(DEAD_REDUCE_TIME, 10 * 60).     %% 死一次扣10分钟

-define(RANK_NORMAL_BOSS, 1).           %% 普通boss
-define(RANK_PEACE_BOSS, 2).            %% 和平boss
-define(RANK_FIRST_BOSS, 3).            %% 世界boss

%%  世界boss引导次数
-define(COPY_BOSS_GUIDE_ONE, 1).
-define(COPY_BOSS_GUIDE, 2).


-define(CARE_NOTICE_REFRESH, 0).    %% 关注刷新
-define(CARE_NOTICE_DEAD, 1).       %% 关注死亡


-record(r_floor_role, {
    key,            %% {BossType, Floor}
    role_num = 0,   %% 人数
    role_list = []  %% 角色ID
}).

%% 世界boss日志
-record(r_world_boss_log, {
    role_id = 0,
    map_id = 0,
    monster_type_id = 0,
    item_type_id = 0,
    time = 0
}).

%% 神兽岛刷新序列
-record(r_mythical_refresh, {
    map_id,                     %% 场景ID
    collect_type_id = 0,        %% T
    is_collect_remain = false,  %% 龙灵水晶关注提醒
    collect_refresh_time,       %% 龙灵水晶刷新时间
    is_monster_remain = false,  %% 怪物关注提醒
    monster_refresh_time        %% 怪物刷新时间
}).

%% 远古遗迹刷新序列
-record(r_ancients_refresh, {
    map_id,                     %% 场景ID
    is_collect_remain = false,  %% 龙灵水晶关注提醒
    collect_refresh_time,       %% 龙灵水晶刷新时间
    is_monster_remain = false,  %% 怪物关注提醒
    monster_refresh_time,       %% 怪物刷新时间
    hidden_boss                 %% 隐藏boss列表 #r_hidden_boss
}).

%% 远古移仓boss参数
-record(r_ancients_hidden_boss, {
    pos_list = [],              %% 已经刷新的点
    boss_list = []              %% [#p_kv{}|...]
}).

%% 世界boss地图结构
-record(r_map_world_boss, {
    exp_counter = 0,            %% 经验加成counter
    collect_type_id = 0,        %% 龙灵水晶TypeID
    collect_num = 0,            %% 龙灵水晶数量
    collect_refresh_time = 0,   %% 龙灵水晶刷新时间
    monster_type_id = 0,        %% 怪物ID
    monster_num = 0,            %% 怪物剩余数量
    monster_refresh_time = 0,   %% 怪物刷新时间
    monster_area_list = [],     %% 怪物区域刷新信息
    hidden_boss_list = []       %% 隐藏boss列表
}).

-record(c_world_boss, {
    type_id,            %% type_id
    boss_type,          %% 种类
    type,               %% 类型
    floor,              %% 层数
    map_id,             %% 地图ID
    pos,                %% 坐标
    refresh_interval,   %% 刷新间隔
    is_safe,            %% 安全区boss
    hidden_boss_rates,  %% 隐藏怪刷新概率
    hidden_boss_num,    %% 隐藏怪存在上限
    owner_reward,       %% 归属奖励
    first_day_interval, %% 首日刷新时间
    role_num1,          %% 人数判定1
    add_time_rate,      %% 增加时间幅度
    role_num2,          %% 人数判定2
    reduce_time_rate    %% 减少时间幅度
}).

%% 神兽岛
-record(c_mythical_refresh, {
    map_id,                 %% 场景ID
    collect_refresh_min,     %% 龙灵水晶刷新时间(分钟)
    collect_type_id,         %% 龙灵水晶ID
    collect_num,             %% 龙灵水晶刷新个数
    collect_pos,             %% 龙灵水晶刷新点
    monster_refresh_min,    %% 精英守卫刷新时间(分钟)
    monster_type_id,        %% 精英守卫ID
    monster_refresh_args    %% 精英守卫刷新参数
}).

%% 远古遗迹
-record(c_ancients_refresh, {
    map_id,                 %% 场景ID
    collect_type_id,        %% 采集物ID
    collect_num,            %% 采集物刷新个数
    collect_reduce_time,    %% 采集扣除停留时间
    collect_pos,            %% 采集物刷新点
    monster_type_id,        %% 精英守卫ID
    monster_refresh_args,   %% 精英守卫刷新参数
    refresh_hour_list,      %% 刷新时间
    hidden_boss_pos         %% 隐藏怪刷新点
}).
-endif.

