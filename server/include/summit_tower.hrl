%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 四月 2018 10:38
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(SUMMIT_TOWER).
-include("map.hrl").
-define(SUMMIT_TOWER, summit_tower).

-define(ETS_ROLE_SUMMIT, ets_role_summit).

-define(NORMAL_SUMMIT_MAX_NUM, 30).     %% 普通层最多30人
-define(LAST_SUMMIT_MAX_NUM, 10).       %% 最后一层最多10人

-define(NORMAL_TOWER_TIME, 20 * 60).    %% 普通层数持续20分钟
-define(LAST_TOWER_TIME, 5 * 60).       %% 最后一层玩家第一个玩家进入时开始计时

-define(TOWER_MONSTER, 200126).     %% 普通层怪物

-define(MONSTER_ADD_SCORE, 1).  %% 击杀怪物增加积分
-define(ROLE_ADD_SCORE, 1).     %% 击杀角色增加积分

-define(TOWER_MAP_STATE_NORMAL, 1). %% 正常状态
-define(TOWER_MAP_STATE_CLOSE, 2).  %% 关闭状态

-define(SUMMIT_TOWER_SCORE, 1).     %% 积分更新
-define(SUMMIT_TOWER_RANK, 2).      %% 排行更新

-define(GET_SUMMIT_TOWER_FLOOR(MapID), ((MapID - ?MAP_FIRST_SUMMIT_TOWER) + 1)).
-define(SUMMIT_TOWER_RANK_NUM, 10). %% 只排10个人

%% 地图控制
-record(r_summit_ctrl, {
    map_id,
    cur_extra_id = 1,
    summit_extra_list = []  %% [#r_summit_extra{}|....]
}).

-record(r_summit_extra, {
    extra_id,    %% {MapID, ExtraID}
    num
}).

-record(r_role_summit, {
    role_id,
    map_id,
    extra_id,
    score = 0,
    is_end = false,
    is_rank_reward = false
}).

-record(r_summit_monster, {
    type_id,
    born_time,
    interval,
    born_pos
}).

-record(c_summit_tower, {
    map_id,         %% 地图ID
    need_score,     %% 上升需要的积分
    exp_rate,       %% 经验倍率
    add_item,       %% 完成道具奖励
    monster_args    %% 怪物参数
}).

-record(c_summit_tower_rank, {
    rank,           %% 排名
    add_item        %% 完成道具奖励
}).

-endif.
