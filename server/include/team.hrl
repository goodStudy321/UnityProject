%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. 十月 2017 10:00
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(TEAM_HRL).
-define(TEAM_HRL, team_hrl).

-define(ETS_TEAM_DATA, ets_team_data).
-define(ETS_ROLE_TEAM, ets_role_team).

-define(HAS_TEAM(TeamID), (TeamID > 0)).
-define(MAX_TEAM_NUM, 3).   %% 最大人数
-define(COPY_READY_TIME, 11).       %% 队伍准备时间
-define(TEAM_ROBOT_NUM, 3000).      %% 机器人ID

-define(TEAM_INVITE_REPLY_ACCEPT, 1).      %% 同意加入队伍
-define(TEAM_INVITE_REPLY_REFUSE, 2).      %% 拒绝加入队伍

-define(TEAM_APPLY_REPLY_ACCEPT, 1).       %% 同意某人加入队伍
-define(TEAM_APPLY_REPLY_REFUSE, 2).       %% 拒绝某人加入队伍

-define(LEVEL_LIMIT, level_limit).          %% 等级限制
-define(COPY_DEGREE_LIMIT, copy_limit).     %% 难度限制
-define(COPY_TIMES_LIMIT, copy_times_limit).%% 次数限制
-define(COPY_TIMES_ALL_LIMITS, copy_times_all_limits).%% 所有人次数为0限制

-define(CONDITION_TYPE_LEVEL, 1).           %% 等级不足
-define(CONDITION_TYPE_DEGREE, 2).          %% 该难度未开启
-define(CONDITION_TYPE_IN_COPY, 3).         %% 在副本中
-define(CONDITION_TYPE_OFFLINE, 4).         %% 不在线
-define(CONDITION_TYPE_REFUSE, 5).          %% 拒绝进入副本
-define(CONDITION_TYPE_TIMES_NOT_ENOUGH, 6).%% 次数不足
-define(CONDITION_TYPE_MARRY, 7).           %% 异性二人组队方可进入
-define(CONDITION_TYPE_TIMEOUT, 8).         %% 超时

-define(COPY_EQUIP_GUIDE, 20201).           %% 装备副本引导ID

-record(team_create_args, {
    min_level = 0,
    max_level = 1000
}).

%% 队伍r结构
-record(r_team, {
    team_id = 0,
    copy_id = 0,            %% 目标ID
    min_level = 0,
    max_level = 1000,
    enter_copy_id = 0,      %% 准备进入副本的ID
    captain_role_id = 0,    %% 队长ID
    is_start = false,
    add_friendly_time = 0,  %% 可增加亲密度的时间
    dissolve_time = 0,      %% 解散时间
    start_copy_time = 0,    %% 副本开始时间
    role_list = []          %% role_id List
}).

-record(r_role_team, {
    role_id = 0,            %% 角色ID
    team_id = 0,            %% 队伍ID
    match_copy_id = 0,      %% 正在匹配的
    map_id = 0,             %% 当前地图ID
    role_name = "",         %% 玩家名
    role_level = 0,         %% 等级
    category = 0,           %% 职业
    sex = 0,                %% 性别
    skin_list = [],         %% 皮肤列表
    ornament_list = [],     %% 装饰列表
    is_online = false,      %% 是否在线
    is_ready = false,       %% 是否准备
    copy_list = []          %% 组队副本的完成列表[#p_kv{}|..]
}).

%% 场景中用到的map_team
-record(r_map_team, {
    team_id = 0,
    captain_role_id = 0,
    role_id_list = [],      %% RoleID
    role_list = [],          %% [#r_role_team{}|....]
    extra_role_id_list = []     %% 发其他奖励的role_id
}).

-endif.