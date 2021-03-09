%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. 三月 2018 19:32
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(FAMILY_TD_HRL).
-define(FAMILY_TD_HRL, family_td_hrl).

-define(ETS_FAMILY_TD, ets_family_td).
-define(ETS_FAMILY_TD_REWARD, ets_family_td_reward).

-define(FAMILY_TD_STATUS_NORMAL, 1).        %% 正常状态
-define(FAMILY_TD_STATUS_FAILED_END, 2).    %% 失败结束
-define(FAMILY_TD_STATUS_SUCCESS_END, 3).   %% 成功结束

-define(FAMILY_TD_EXP_BUFF, 207001).   %% 守卫仙盟经验buff

-define(AREA_1, 1).
-define(AREA_2, 2).
-define(AREA_3, 3).

-define(AREA_POS_1, 1).
-define(AREA_EXTRA_POS_1, 2).
-define(AREA_POS_2, 3).
-define(AREA_EXTRA_POS_2, 4).
-define(AREA_POS_3, 5).

-define(FAMILY_TD_UPDATE_WAVE, 1).          %% 波数更新
-define(FAMILY_TD_UPDATE_KILL_NUM, 2).      %% 击杀数量更新
-define(FAMILY_TD_UPDATE_ASSAULT_TIME, 4).  %% 更新突袭时间
-define(FAMILY_TD_UPDATE_NEXT_TIME, 5).     %% 更新下波时间

-define(FAMILY_TD_ALL_STAR, 5).     %% 初始5星
-define(BASE_STAR_REDUCE, 2).       %% 前2个雕像死亡每个扣除2星

-record(r_family_td, {
    family_id,
    is_map_open = false,    %% 地图是否开启
    is_end = false          %% 本仙盟的活动是否结束
}).

-record(r_map_family_td, {
    status = 0,                 %% 当前状态
    shutdown_time = 0,          %% 关闭时间
    cur_wave = 0,               %% 当前波数
    all_wave = 0,               %% 总波数
    all_num = 0,                %% 总怪物数
    kill_num = 0,               %% 当前杀怪数
    kill_exp = 0,               %% 杀怪经验
    star = 0,                   %% 星级
    buff_multi = 0,             %% buff叠加次数
    assault_time_list = [],     %% 怪物突袭时间列表
    normal_refresh_list = [],   %% 普通刷怪列表
    assault_refresh_list = [],  %% 突袭刷新列表
    area_pos_list = []          %% [{AreaID, PosList}|.....]
}).

-record(r_td_monster_fresh, {
    time,
    monster_refresh = []    %% [{Index, [{TypeID, Num}....]} |.....]
}).

-record(r_family_td_end, {
    is_succ,
    kill_num,
    kill_exp,
    star,
    star_exp,
    rank_list
}).

-record(c_family_td_refresh, {
    bron_time,  %% 出生时间
    area_1,     %% 区域刷怪
    area_2,
    area_3
}).

-record(c_family_td_rank_exp, {
    min_rank,   %% 名次1
    max_rank,   %% 名次2
    rate        %% 倍率
}).

-record(c_family_td_pos, {
    id,
    desc,
    pos_string
}).
-endif.