%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. 九月 2019 16:27
%%%-------------------------------------------------------------------
-author("WZP").


-ifndef(CYCLE_ACT_HRL).
-define(CYCLE_ACT_HRL, cycle_act_hrl).

-define(CYCLE_ACT_STATUS_OPEN, 1).      %% 活动开启
-define(CYCLE_ACT_STATUS_CLOSE, 2).     %% 活动关闭





-define(CYCLE_ACT_NO_OPEN, 0).            %%活动开启方式   没开启
-define(CYCLE_ACT_FIRST_OPEN, 1).         %%活动开启方式  开服开启
-define(CYCLE_ACT_SECOND_OPEN, 2).        %%月循环开启
-define(CYCLE_ACT_THIRD_OPEN, 3).         %%日期开启
-define(CYCLE_ACT_GM_OPEN, 4).            %%GM开启

-define(TRENCH_CEREMONY_NONE, 0).           %% 没有达到条件
-define(TRENCH_CEREMONY_CAN_REWARD, 1).     %% 可以领取奖励
-define(TRENCH_CEREMONY_HAS_REWARD, 2).     %% 已经领取奖励


%%
-record(c_cycle_act, {
    id,                                  %% 活动ID
    level = 0,                           %% 等级
    open_day = 0,                        %% 活动时长
    server_open_day = 0,                 %% 开服天数
    open_time = "",                      %% 开启日期
    limited_time = 0,                    %% 开服几天后进入月循环
    month_loop = ""                      %% 月循环
}).


-record(c_egg, {
    id,                                  %% 活动ID
    egg_type = 0,                        %%
    egg_weight = 0,                      %% 权重
    inevitable = 0,                      %% 必出
    reward = "",                         %% 奖励
    config_num = 1
}).

-record(c_egg_reward, {
    id,                                  %% 活动ID
    need_num = 0,                        %%
    reward = "",                         %% 奖励
    config_num = 1
}).


-record(c_cycle_config, {
    id,                                  %% 活动ID
    cycle_act = 0,                       %%
    world_level = [1,9999],              %% 奖励
    week  =  []
}).

-record(c_day_box, {
    day,             %% id
    times,           %%
    reward,
    config_num
}).


-record(c_cycle_tower, {
    id,             %% id
    type,           %% 奖励类型
    pool_id,        %% 奖池ID
    layer,          %% 层
    item,
    num,
    weight,         %% 权重
    config_num
}).

-record(c_act_red_packet, {
    hour,           %% 时间
    red_packet_1,   %% 红包1
    red_packet_2,   %% 红包2
    red_packet_3,   %% 红包3
    red_packet_4,   %% 红包4
    red_packet_5    %% 红包5
}).


-record(c_cycle_mission_reward, {
    id,          %%
    money,       %% 所需兑换点数
    reward,      %%
    config_num   %%
}).

-record(c_cycle_mission, {
    id,                 %%
    type,               %% 任务类型
    param,              %%
    money,
    complete_times,     %% 可完成次数
    config_num          %%
}).

-record(r_cycle_mission, {
    id = 0,
    type = 0,
    schedule = 0,       %%当前进度
    remaining_times
}).


%%       对于活动半小时一小时监测有可能发现跳秒而不一定运行到        如需严格执行再另行处理
-define(CYCLE_ACT_CHOOSE, 2003).            %% 黑市鉴宝
-define(CYCLE_ACT_LUCKY_TOKEN, 2004).       %% 幸运上上签
-define(CYCLE_ACT_IDENTIFY_TREASURE, 2005). %% 幸运鉴宝
-define(CYCLE_ACT_EGG, 2002).               %% 砸蛋
-define(CYCLE_ACT_LUCKY_CAT, 2001).         %% 招财猫
-define(CYCLE_ACT_CHARGE, 2000).            %% 首充倍送
-define(CYCLE_ACT_TRENCH_CEREMONY, 2006).   %% 绝版壕礼
-define(CYCLE_ACT_DAY_CYCLE, 2007).         %% 每日宝箱
-define(CYCLE_ACT_TREASURE_CHEST, 2008).   %% 欢乐宝箱
-define(CYCLE_ACT_TOWER, 2009).             %% 通天宝塔
-define(CYCLE_ACT_ESOTERICA, 2010).         %% 修炼秘籍
-define(CYCLE_ACT_RED_PACKET, 2011).        %% 全服红包
-define(CYCLE_ACT_COUPLE, 2012).            %% 天道情缘活动
-define(CYCLE_ACT_MISSION, 2013).           %% 任务
-define(CYCLE_ACT_DROP, 2014).              %% 掉落
-define(CYCLE_ACT_LIMITED_PANIC_BUY, 2015). %% 限时抢购

-define(GLOBAL_EGG, 184).                   %%砸蛋全局表
-define(C_ACT_BEST_EGG_TYPE, 3).            %%最好的蛋
-define(C_ACT_BETTER_EGG_TYPE, 2).          %%次好的蛋
-define(GLOBAL_CYCLE_TOWER, 190).           %%通天宝塔全局表









%%    cycle_act_misc key
-define(CYCLE_MISC_TOWER,1).





-endif.