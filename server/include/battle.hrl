%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. 三月 2018 14:19
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(BATTLE_HRL).
-define(BATTLE_HRL, battle_hrl).
-include("map.hrl").

-define(MAX_BATTLE_ROLE_NUM, 45).           %% 一条线上只能有45个人
-define(ETS_MAP_BATTLE, ets_map_battle).    %% 战场地图数据
-define(ETS_ROLE_BATTLE, ets_role_battle).  %% 战场角色数据
-define(ETS_RANK_BATTLE, ets_rank_battle).  %% 战场排行数据

-define(ALL_RANK_KEY, 0).   %% all_rank的key

-define(BATTLE_ALL_RANK_NUM, 50).   %% 战场最终排行榜最大人数
-define(BATTLE_MONSTER, 200199).    %% 聚灵桩
-define(BATTLE_LOOP_SCORE, 30).     %% 每30秒加30积分

-define(BATTLE_MONSTER_REDUCE_HP, 1000).    %% 每次掉1000血

%% 怪物出生的坐标
-define(MONSTER_POS_LIST, [
    {?BATTLE_CAMP_MONSTER, 1280, 13, 270},
    {?BATTLE_CAMP_MONSTER, -623, -1089, 210},
    {?BATTLE_CAMP_MONSTER, -638, 1083, 145}
]).

-define(BATTLE_BUFF_UNBEATABLE, 205001).

-record(r_battle_ctrl, {cur_extra_id=0, cur_role_num=0, extra_id_list=[]}).
-record(r_map_battle, {extra_id, enter_role_ids=[], all_role_ids=[], power_list=[], tower_list=[]}).
-record(r_role_battle, {role_id, extra_id=0, camp_id=?DEFAULT_CAMP_ROLE, score=0, max_power=0, combo_kill=0}).
-record(r_rank_battle, {role_id, rank, camp_id, score, max_power}).


-record(c_battle_score_reward, {
    score,          %% 积分
    exp_rate,       %% 经验奖励
    item_reward     %% 道具奖励
}).

-record(c_battle_rank_reward, {
    min_rank,       %% 名次1
    max_rank,       %% 名次2
    item_rewards,   %% 道具奖励
    exp_rate        %% 经验倍率
}).

-record(c_battle_combo, {
    kill_num,
    kill_score,
    assist_score
}).

-endif.
