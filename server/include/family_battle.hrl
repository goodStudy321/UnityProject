%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. 七月 2018 11:11
%%%-------------------------------------------------------------------
-author("WZP").

-ifndef(FAMILY_BATTLE_HRL).
-define(FAMILY_BATTLE_HRL, family_battle_hrl).

%%region


-define(FAMILY_BATTLE_MAP_BUFF, 202002).    %%地图buff

-define(FAMILY_BATTLE_FIRST_TITLE, 220021).             %%第一称号
-define(FAMILY_BATTLE_SECOND_TITLE, 220022).            %%第二称号
-define(FAMILY_BATTLE_THIRD_TITLE, 220023).             %%第三称号



-define(FAMILY_BATTLE_ROUND_ONE_MAP, [13, 24, 57, 68]).
-define(FAMILY_BATTLE_ROUND_TWO_MAP, [12, 34, 56, 78]).

-define(ETS_FAMILY_BATTLE_RANK, ets_family_battle_rank).    %% 排行数据

-define(FAMILY_BATTLE_REGION1, 1).
-define(FAMILY_BATTLE_REGION2, 2).
-define(FAMILY_BATTLE_REGION3, 3).
-define(FAMILY_BATTLE_REGION4, 4).
-define(FAMILY_BATTLE_REGION5, 5).

-define(FAMILY_BATTLE_GLOBAL, 36).   %%全局表配置
-define(FAMILY_BATTLE_GLOBAL_TWO, 40).   %%全局表击杀积分配置

-define(FAMILY_BATTLE_ROUND_ING, 1).   %%正在比赛
-define(FAMILY_BATTLE_ROUND_FINISH, 0).   %%正在比赛结束


-define(FAMILY_BATTLE_ROUND_ONE, 1).     %%第一回合
-define(FAMILY_BATTLE_ROUND_SLEEP, 2).   %%休息回合
-define(FAMILY_BATTLE_ROUND_TWO, 3).     %%第二回合
-define(FAMILY_BATTLE_ROUND_END, 4).     %%结束

-define(FAMILY_BATTLE_RED, 1).       %%红
-define(FAMILY_BATTLE_BLUE, 2).      %%蓝
-define(FAMILY_BATTLE_BLANK, 3).     %%空白


-define(FAMILY_BATTLE_IN, 1).
-define(FAMILY_BATTLE_OUT, 0).


-define(FAMILY_BATTLE_CANNOT_IN, 0).            %%地图不能进入
-define(FAMILY_BATTLE_CAN_IN, 1).            %%地图能进入

-define(FAMILY_BATTLE_ADD, 1).            %%占领增加
-define(FAMILY_BATTLE_REDUCE, 0).


-record(r_family_battle_status, {round, start_time, end_time}).

%% red_rate,blue_rate,rate   这一秒到下一秒变化速率
-record(r_family_battle_region, {owner = ?FAMILY_BATTLE_BLANK, red_percent = 0, blue_percent = 0, blank_percent = 100, red_roles = [], blue_roles = [], red_rate = 0, blue_rate = 0, red_trend, blue_trend}).

-record(r_family_battle_info, {max_score, red_region_list = [], blue_region_list = [], red_score = 0, blue_score = 0, red_time = 0, blue_time = 0, red_power, blue_power, red_rank, blue_rank,
                               red_family_id, blue_family_id, red_family_name, blue_family_name}).


%%修改结构要修改   mod_map_family_bt get_settlement_list 里面的MS
-record(r_family_battle_rank, {role_id, map_extra, rank = 0, family_name, camp_id = 0, role_name, score = 0, region = 0}).

%%  cv_time 连胜次数
-record(r_family_battle_temple, {role_id, role_name, skin = [], rank = 0, family_name, family_id, sex, level = 0, category, cv_time = 0}).


-record(c_fbt_region, {id, pos, radius, add_score,role_add_score}).
-record(c_fbt_occupy, {id, rate}).
-record(c_fbt_rank_reward, {rank, reward}).
-record(c_fbt_round_reward, {rank, reward, word}).
-record(c_fbt_cv_reward, {id, rank, cv_times, world_level, vc_reward}).
-record(c_fbt_end, {id, buff, reward}).
-record(c_fbt_temple, {rank, reward, buff, title}).

-record(c_family_battle_rank, {
    rank,           %% 排名
    family_name,    %% 名字
    family_id,      %% ID
    power           %% 战力
}).

-endif.