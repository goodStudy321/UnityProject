%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 三月 2019 20:29
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(HUNT_TREASURE_HRL).
-define(HUNT_TREASURE_HRL, hunt_treasure_hrl).

-define(ITEM_EVENT_ID, 101).

%% 藏宝图道具
-record(c_hunt_treasure_item, {
    type_id,            %% 道具ID
    desc,               %% 备注
    event_string,       %% 事件权重
    pos_string,         %% 挖宝坐标
    hunt_treasure_score %% 宝珠
}).

-record(c_hunt_treasure_event, {
    event_id,           %% 事件ID
    desc,               %% 备注
    time,               %% 持续时间
    boss_string,        %% boss挑战抽取ID
    wave_string,        %% 组队挑战抽取ID
    map_id,             %% 场景ID
    boss_pos,           %% boss挑战坐标
    captain_reward,     %% 队长固定奖励
    member_reward       %% 队员奖励
}).

-endif.