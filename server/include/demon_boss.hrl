%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. 五月 2019 10:19
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(DEMON_BOSS_HRL).
-define(DEMON_BOSS_HRL, demon_boss_hrl).

-define(ETS_DEMON_BOSS_REWARD, ets_demon_boss_reward).  %%
-define(DEMON_BOSS_ROOM_NUM, 3).        %% boss房间最大数量

-define(CLEAR_HURT_TIME, 20).    %% 20秒清空归属

-define(HP_REWARD_NOT_GET, 0).  %% 不能领取
-define(HP_REWARD_CAN_GET, 1).  %% 可以领取
-define(HP_REWARD_HAS_GOT, 2).  %% 已经领取

%% 控制进程用到的
-record(r_demon_boss_ctrl, {
    level = 0,      %% 世界等级
    next_level = 0, %% 下一次开启世界等级
    rooms = []      %% [#p_kb{}|...]
}).

%% 地图进程储存的状态
-record(r_map_demon_boss, {
    all_occupy_time = 0,    %% boss被占领的时间
    occupy_role,            %% p_demon_boss_role占领角色
    rank_list = [],         %% [#p_demon_boss_role{}|...] 前N名排行数据 有序列表
    time_list = [],         %% [#p_demon_boss_role{}|...]
    clear_time = 0          %% 移除占领的时间
}).

%% 地图用的demon_boss
-record(r_role_demon_boss, {
    is_enter = false,       %% 是否进入过
    cheer_times = 0,        %% 可以鼓舞次数
    add_buff_times = 0      %% 已经鼓舞的次数
}).

%% 活动玩法用，hp掉血奖励
-record(r_role_demon_boss_reward, {
    role_id,
    is_enter = false,       %% 之前有没有进入过
    status_list = []        %% 领取状态列表
}).

-record(c_demon_boss, {
    type_id,    %% 怪物ID
    pos,        %% 场景坐标
    drop_list   %% 掉落组
}).

%% 血量奖励配置
-record(c_demon_boss_hp_reward, {
    id,         %% ID
    hp_rate,    %% 血量比例
    rewards     %% 奖励
}).
-endif.
