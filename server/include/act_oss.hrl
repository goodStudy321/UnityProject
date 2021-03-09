%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. 三月 2019 16:48
%%%-------------------------------------------------------------------
-author("WZP").
-ifndef(ACT_OSS).
-define(ACT_OSS_HRL, act_oss_hrl).

-define(ACT_OSS_REWARD_ONE, 1).             %% 1-排名奖励
-define(ACT_OSS_REWARD_TWO, 2).             %% 2-战力奖励
-define(ACT_OSS_REWARD_THREE, 3).           %% 3-灵力奖励
-define(ACT_OSS_REWARD_FOUR, 4).             %% 4-抢购
-define(ACT_OSS_REWARD_FIVE, 5).             %% 5-累充

-define(OSS_RECHARGE, 100101).                       %%充值    （条件参数 - 充值金额）
-define(OSS_WORLD_BOSS, 100117).                     %%击杀n个世界BOSS
-define(OSS_PERSON_BOSS, 100118).                    %%进入n次个人BOSS
-define(OSS_YMDJ, 100104).                           %%进入n次幽冥地界
-define(OSS_RUNE_TREASURE, 100105).                  %%完成n次符文寻宝
-define(OSS_RUNE_EQUIP, 100106).                     %%完成n次装备寻宝
-define(OSS_BLESS, 100107).                          %%完成n次祈福
-define(OSS_DAILY_TASK, 100108).                     %%完成n次日常任务
-define(OSS_QZY, 100109).                            %% 进入n次青竹园
-define(OSS_SLG, 100110).                            %%进入n次失落谷
-define(OSS_BJW, 100111).                            %%进入n次百角湾
-define(OSS_YHL, 100112).                            %%进入n次幽魂林
-define(OSS_TREVI_FOUNTAIN, 100116).                 %%完成n次许愿池
-define(OSS_USE_BIND_GOLD, 100103).                  %%消费绑宝 （条件参数 - 消费金额）
-define(OSS_USE_GOLD, 100102).                       %%消费元宝 （条件参数 - 消费金额
-define(OSS_HOME_BOSS, 100119).                      %%击杀n个洞天福地
-define(OSS_EQUIP_MAP, 100120).                      %%进入n次装备副本

-define(OSS_ENTER, 100121).                          %%进入登录      100121 - 100124只在act_otf实现
-define(OSS_LIMITEDTIME_BUY, 100122).                %%限时云购
-define(OSS_MARRY, 100123).                          %%结婚
-define(OSS_FAIRY, 100124).                          %%护送

-define(OSS_FAMILY_MISSION_SEVEN_START, 100125).                          %%道庭七星任务
-define(OSS_FAMILY_MISSION_SIX_START, 100126).                            %%道庭六星任务
-define(OSS_FAMILY_MISSION_FIVE_START, 100127).                           %%道庭五星任务
-define(OSS_FAMILY_MISSION_FOUR_START, 100128).                           %%道庭四星任务


-define(OSS_OFFLINE_SOLO, 100129).                            %%决斗场
-define(OSS_OFFLINE_BLESS, 100130).                           %%闭关修炼
-define(OSS_ORANGE_ESCORT, 100131).                           %%  品质4道庭护送
-define(OSS_PURPLE_ESCORT, 100132).                           %%  品质3道庭护送
-define(OSS_BLUE_ESCORT, 100133).                             %%  品质2色道庭护送
-define(OSS_WHITE_ESCORT, 100134).                            %%  品质1道庭护送





-define(OSS_TASK_LIST, [?OSS_RECHARGE, ?OSS_WORLD_BOSS, ?OSS_PERSON_BOSS, ?OSS_YMDJ, ?OSS_RUNE_TREASURE, ?OSS_RUNE_EQUIP, ?OSS_BLESS, ?OSS_DAILY_TASK, ?OSS_QZY, ?OSS_SLG, ?OSS_BJW, ?OSS_YHL, ?OSS_TREVI_FOUNTAIN,
                        ?OSS_USE_GOLD, ?OSS_USE_BIND_GOLD, ?OSS_HOME_BOSS, ?OSS_EQUIP_MAP]).


-define(OSS_TREVI_FOUNTAIN_GLOBAL, 112).



-record(c_oss_rank_reward, {
    id,
    type,       %%活动类型
    rank_region,%%排名区间
    arg,        %%条件
    arg_i,      %%条件参数
    reward      %%排行奖励
}).

-record(c_oss_mana, {
    rank_type,       %%活动类型
    mana,       %%奖励灵力
    arg,        %%条件参数
    type        %%任务类型
}).

-record(c_oss_mana_reward, {
    id,
    type,       %%活动类型
    mana,       %%灵力
    reward      %%奖励
}).

-record(c_oss_panic_buy, {
    id,
    type,               %%活动类型
    asset_type,         %%货币类型
    price,              %%价格
    buy_times,          %%购买次数
    reward              %%奖励
}).

-record(c_oss_power_reward, {
    id,
    type,               %%活动类型
    power,              %%货币类型
    reward              %%奖励
}).

-record(c_oss_recharge_reward, {
    id,
    type,               %%活动类型
    quota,              %%额度
    reward              %%奖励
}).

-record(c_oss_limited_panic_buy, {
    id,
    day,
    asset_type,         %%货币
    price,              %%价格
    buy_times,          %%购买次数，
    reward
}).

-record(c_oss_seven, {
    id,
    reward,         %%
    price
}).

-record(c_trevi_fountain, {
    id,
    is_rare,
    reward,
    weight,         %%
    open_days
}).

-record(c_trevi_fountain_reward, {
    id,
    score,
    reward         %%
}).

-endif.