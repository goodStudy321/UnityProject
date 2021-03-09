%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 十二月 2018 10:13
%%%-------------------------------------------------------------------
-author("WZP").

%% “是否”尽量用01代表  绑定除外

-ifndef(BG_ACT_HRL).
-define(BG_ACT_HRL, bg_act_hrl).

-define(REQUEST_BG_TYPE_NORMAL, 1).      %%   正常日期活动
-define(REQUEST_BG_TYPE_OPEN, 2).        %%   开服日期活动
-define(REQUEST_BG_TYPE_MERGE, 3).       %%   合服日期活动

-define(BG_CD, 15).      %%   后台活动开服期间CD  目前15天     目前CD无


-define(BG_ACT_FEAST_ENTRY, 1014).             %% 登录有礼
-define(BG_ACT_ACC_PAY, 1009).                 %% 累充豪礼
-define(BG_ACT_ACC_CONSUME, 1007).             %% 累消费
-define(BG_ACT_REGRESSION, 1008).              %% 回归豪礼
-define(BG_ACT_DOUBLE_EXP, 1010).              %% 双倍经验
-define(BG_ACT_DOUBLE_COPY, 1011).             %% 副本双倍掉落
-define(BG_ACT_BOSS_DROP, 1021).               %% 材料掉落
-define(BG_ACT_RECHARGE, 1000).                %% 充值有礼
-define(BG_ACT_MISSION, 1001).                 %% 任务类活动
-define(BG_ACT_STORE, 1002).                   %% 商店类活动
-define(BG_ACT_TREVI_FOUNTAIN, 1003).          %% 许愿池类活动
-define(BG_ACT_ALCHEMY, 1004).                 %% 炼丹炉类活动
-define(BG_ACT_RECHARGE_TURNTABLE, 1005).      %% 累充轮盘类活动
-define(BG_ACT_ACTIVE_TURNTABLE, 1006).        %% 活跃轮盘类活动
-define(BG_ACT_TREASURE_TROVE, 1015).          %% 神秘宝藏
-define(BG_ACT_SECRET_TERRITORY, 1016).        %% 秘密领地
-define(BG_ACT_ST_STORE, 1017).                %% 秘境商店
-define(BG_ACT_KING_GUARD, 1012).              %% 精灵王
-define(BG_ACT_ALCHEMY_ONE, 1018).             %% 仙品丹炉
-define(BG_ACT_ALCHEMY_TWO, 1019).             %% 凡品丹炉
-define(BG_ACT_TIME_STORE, 1020).              %% 仙人指路
-define(BG_ACT_RECHARGE_REWARD, 1022).              %% 充值大礼
-define(BG_ACT_CONSUME_RANK, 1023).                 %% 消费排行
-define(BG_ACT_DOUBLE_RECHARGE, 1024).              %% 充值双倍
-define(BG_ACT_RECHARGE_PACKET, 1026).              %% 单充大礼
-define(BG_ACT_QINGXIN, 1025).                      %% 一见倾心



-define(BG_ACT_ALL, 1999).                     %% 所有活动


-define(BG_ACT_STATUS_ONE, 1).          %% 活动开启期间，尚未真实开启
-define(BG_ACT_STATUS_TWO, 2).          %% 活动开启期间，并且已真实开启
-define(BG_ACT_STATUS_THREE, 3).        %% 不在活动开启期间
-define(BG_ACT_STATUS_FOUR, 4).         %% 处于开服CD时间

-define(BG_ACT_OPEN, 1).            %% 开启动作
-define(BG_ACT_CLOSE, 2).           %% 关闭动作
-define(BG_ACT_UNCHANGED, 3).       %% 不变

-define(BG_DOUBLE_EXP_ALL, 5004).       %% 所有玩家
-define(BG_DOUBLE_EXP_LOVERS, 5002).       %% 所有情侣


%%活动达成条件

-define(BG_LOGIN, 2001).                 %%登录触发
-define(BG_REGRESSION, 2002).            %%离线X秒触发
-define(BG_VIP, 2003).                   %%VIP，X触发
-define(BG_LOVING, 2004).                %%是否情侣触发
-define(BG_RECHARGE, 2005).              %%充值X触发
%%-define(BG_USE_ITEM, 2006).            %%使用道具触发


%%  extra














%%后台活动单条条目信息结构
-record(bg_act_config_info, {
    sort = 0,
    title = "",
    condition = "",
    items = "",
    status = 0
}).

%%后台活动单条条目信息结构
-record(bg_act_mission, {
    sort = 0,
    type = 0,
    schedule = 0,       %%当前进度
    target = 0,         %%任务目标
    title = "",         %%任务描述
    reward = 0,         %%奖励任务点数
    now_times = 0,      %%当前完成次数
    all_times = 0       %%全部完成次数
}).

%%回归好礼奖励结构
-record(bg_regression, {
    id = 0,
    type = 0,           %% 完成条件
    param = 0,          %% 奖励完成参数
    schedule = 0,       %% 进度
    status = 0          %% 奖励状态
}).


%%回归好礼奖励结构
-record(bg_active_turntable_mission, {
    id = 0,
    type = 0,           %%完成条件
    param = 0,          %%奖励完成参数
    status = 0          %%奖励状态
}).


%%神秘宝藏
-record(c_treasure_trove, {id, layer, item, weight}).


%%-------------------------   每周活动  -------------------- begin

-record(r_bg_summer, {
    recharge_reward_list = [],
    recharge_edit_time = 0,

    rank_edit_time = 0,
    my_use = 0     %%消费元宝
}).

-record(r_summer_extra, {
    recharge_reward_list = [],
    recharge_edit_time = 0,
    pay_gold = 0
}).

-record(r_bg_rank, {
        role_id = 0,
        rank = 0,
        consume = 0,
        role_name = ""
}).


%%后台单冲大礼
-record(r_role_bg_recharge_package, {role_id, edit_time = 0, list = []}).



%%-------------------------   每周活动  -------------------- end




-define(BG_ATURNTABLE_MISSION_ONE, 1).       %%每天登陆
-define(BG_ATURNTABLE_MISSION_TWO, 2).       %%在线时长
-define(BG_ATURNTABLE_MISSION_THREE, 3).     %%日常活跃


-define(BG_ACT_YES, 1).       %% 是
-define(BG_ACT_NO, 0).        %% 否



-define(BG_MISSION_RECHARGE, 100101).                        %%充值
-define(BG_MISSION_KILL_WORLD_BOSS, 100102).                 %%击杀世界BOSS
-define(BG_MISSION_KILL_PERSON_BOSS, 100103).                %%击杀个人BOSS
-define(BG_MISSION_YOUMING, 100104).                         %%幽冥地界
-define(BG_MISSION_RUNE_TREASURE, 100105).                   %%符文寻宝
-define(BG_MISSION_EQUIP_TREASURE, 100106).                  %%装备寻宝
-define(BG_MISSION_BLESS, 100107).                           %%祈福
-define(BG_MISSION_DAILY, 100108).                           %%日常任务
-define(BG_MISSION_YARD, 100109).                         %%青竹园
-define(BG_MISSION_RUINS, 100110).                        %%失落谷
-define(BG_MISSION_VAULT, 100111).                        %%白角湾
-define(BG_MISSION_FOREST, 100112).                       %%幽魂林
-define(BG_MISSION_SUMMIT_TOWER, 100113).                 %%逍遥神坛
-define(BG_MISSION_BATTLE, 100114).                       %%主线战场
-define(BG_MISSION_SOLE, 100115).                         %%仙峰论剑
-define(BG_MISSION_TREVI_FOUNTAIN, 100116).               %%许愿池
-define(BG_MISSION_KILL_MYTHICAL_BOSS, 100117).            %%击杀神兽岛BOSS
-define(BG_MISSION_KILL_FUDI_BOSS, 100118).                %%击杀福地洞天BOSS
-define(BG_MISSION_KILL_ANCIENT_BOSS, 100119).             %%击杀远古BOSS
-define(BG_MISSION_EQUIP_COPY, 100120).                    %%进入装备副本
-define(BG_MISSION_WAR_SPIRIT, 100121).                    %%战魂副本

-endif.
