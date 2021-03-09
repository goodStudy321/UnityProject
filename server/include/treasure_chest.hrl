%%%-------------------------------------------------------------------
%%% @author chenqinyong
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. 十月 2019 11:04
%%%-------------------------------------------------------------------
-author("chenqinyong").

-record(c_act_treasure_chest, {
    id,
    name,
    config_num,  %%套序号
    need_recharge,
    reward_list
}).

-define(TREASURE_CHEST_CANNOT_REWARD, 0).     %% 不可领取奖励
-define(TREASURE_CHEST_CAN_REWARD, 1).     %% 可领取奖励
-define(TREASURE_CHEST_HAS_REWARD, 2).     %% 已经领取奖励