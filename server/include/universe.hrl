%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 九月 2019 11:33
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(UNIVERSE_HRL).
-define(UNIVERSE_HRL, universe_hrl).

-define(ETS_UNIVERSE, ets_universe).        %% 游戏服太虚通天塔数据缓存

-define(UNIVERSE_KEY_FLOOR, universe_key_floor).                %% 最快通关玩家
-define(UNIVERSE_BEST_THREE_INFO, universe_best_three_info).    %% 总层数三强
-define(UNIVERSE_FLOOR_RANK, universe_floor_rank).              %% 总层数排行

-define(UNIVERSE_GET_CENTER_DATA, universe_get_center_data).    %% 是否获取了中央服数据

-define(UNIVERSE_UPDATE_KEY_FLOOR, universe_update_key_floor).
-define(UNIVERSE_UPDATE_FLOOR_RANK, universe_update_floor_rank).

-define(BEST_RANK_NUM, 3).              %% 至尊三强
-define(UNIVERSE_RANK_NUM, 100).        %% 100

-define(UNIVERSE_ROLE_MIN_POWER, 1).    %% 最低战力
-define(UNIVERSE_ROLE_FAST, 2).         %% 最快速度
-define(UNIVERSE_ROLE_BOTH, 3).         %% 最低战力 + 最快速度

-record(universe_info, {
    role_id,
    role_name,
    server_name,
    copy_id,
    confine_id,
    category,
    sex,
    level,
    skin_list,
    use_time,
    power,
    update_list = []
}).

-record(universe_role_info, {
    role_id,
    role_name,
    confine_id,
    category,
    sex,
    level,
    skin_list
}).

-endif.
