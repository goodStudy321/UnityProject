%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 八月 2017 11:14
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(ACTIVITY_HRL).
-define(ACTIVITY_HRL, activity_hrl).
-include("map.hrl").

-define(ETS_ACTIVITY, ets_activity).

-define(STATUS_BEFORE_MINUTES, 0). %% 活动开启X分钟前
-define(STATUS_PREPARE, 1). %% 活动准备
-define(STATUS_OPEN, 2).    %% 活动开启
-define(STATUS_CLOSE, 3).   %% 活动关闭

-define(PREPARE_TIME, 10).  %% 准备时间现在是默认开始前的10秒

-define(ACTIVITY_BATTLE, 10001).              %% 三界战场
-define(ACTIVITY_SOLO, 10002).                %% 1v1PK
-define(ACTIVITY_FAMILY_TD, 10003).           %% 守卫仙盟
-define(ACTIVITY_ANSWER, 10004).              %% 答题活动
-define(ACTIVITY_FAMILY_AS, 10006).           %% 仙盟晚宴答题
-define(ACTIVITY_FAMILY_BS, 10007).           %% 仙盟BOSS
-define(ACTIVITY_SUMMIT_TOWER, 10008).        %% 巅峰爬塔
-define(ACTIVITY_FAMILY_BATTLE, 10010).       %% 帮派(仙盟)战
-define(ACTIVITY_DEMON_BOSS, 10011).          %% 魔域boss
-define(ACTIVITY_FAMILY_GOD_BEAST, 10012).    %% 道庭神兽
-define(ACTIVITY_LATTICE_MINING, 10013).      %% 秘境探索（挖矿）
-define(ACTIVITY_FAMILY_ESCORT, 90001).       %% 护送

%% 活动对应的模块
-define(ACTIVITY_MOD_LIST, [
    #c_activity_mod{activity_id = ?ACTIVITY_BATTLE, mod = mod_battle, map_id = ?MAP_BATTLE},
    #c_activity_mod{activity_id = ?ACTIVITY_SOLO, mod = mod_solo, map_id = ?MAP_SOLO},
    #c_activity_mod{activity_id = ?ACTIVITY_FAMILY_TD, mod = mod_family_td, map_id = ?MAP_FAMILY_TD},
    #c_activity_mod{activity_id = ?ACTIVITY_ANSWER, mod = mod_answer, map_id = ?MAP_ANSWER},
    #c_activity_mod{activity_id = ?ACTIVITY_FAMILY_AS, mod = mod_family_as, map_id = ?MAP_FAMILY_AS},
    #c_activity_mod{activity_id = ?ACTIVITY_FAMILY_BS, mod = mod_family_bs, map_id = ?MAP_FAMILY_BOSS},
    #c_activity_mod{activity_id = ?ACTIVITY_SUMMIT_TOWER, mod = mod_summit_tower, map_id = ?MAP_FIRST_SUMMIT_TOWER},
    #c_activity_mod{activity_id = ?ACTIVITY_FAMILY_BATTLE, mod = mod_family_bt, map_id = ?MAP_FAMILY_BT},
    #c_activity_mod{activity_id = ?ACTIVITY_DEMON_BOSS, mod = mod_demon_boss, map_id = ?MAP_DEMON_BOSS},
    #c_activity_mod{activity_id = ?ACTIVITY_FAMILY_GOD_BEAST, mod = mod_family_god_beast, map_id = ?MAP_FAMILY_BOSS},
    #c_activity_mod{activity_id = ?ACTIVITY_LATTICE_MINING, mod = mod_mining}
]).

%%开始前X分钟发协议给客户端显示活动图标 的活动列表
-define(ACTIVITY_LIST, [?ACTIVITY_BATTLE, ?ACTIVITY_SOLO, ?ACTIVITY_FAMILY_TD, ?ACTIVITY_ANSWER, ?ACTIVITY_FAMILY_AS,
    ?ACTIVITY_SUMMIT_TOWER, ?ACTIVITY_FAMILY_BATTLE, ?ACTIVITY_DEMON_BOSS, ?ACTIVITY_FAMILY_GOD_BEAST]).

-record(r_activity, {
    id,                     %% 活动id
    status = ?STATUS_CLOSE, %% 活动状态
    prepare_time,           %% 准备时间
    start_time,             %% 开始时间
    end_time,               %% 结束时间
    broadcast_time,         %% 开始前广播的时间
    broadcast_min,          %% 开始前广播的分钟数
    is_cross = false        %% 跨服是否开启
}).

-record(c_activity, {
    id,                     %% 活动ID
    name,                   %% 活动名称
    min_level,              %% 参与最小等级
    day_list,               %% 星期
    time_list,              %% 开启时间
    last_time,              %% 持续时间
    broadcast_list,         %% 活动开始前广播
    broadcast_id,           %% 开始前广播ID
    is_cross                %% 是否本服转跨服
}).

-record(c_activity_mod, {
    activity_id,
    mod,
    map_id
}).

-endif.
