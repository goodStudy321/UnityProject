%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. 四月 2018 10:35
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(ACT_HRL).
-define(ACT_HRL, act_hrl).

-define(ETS_ACT, ets_act).
-define(ETS_ACT_LIMITEDTIME_BUY, ets_act_limited_buy).

-define(ACT_STATUS_OPEN, 1).    %% 活动开启
-define(ACT_STATUS_CLOSE, 2).      %% 活动关闭

-define(ACT_YES, 1).       %% 是
-define(ACT_NO, 0).        %% 否

-define(ACT_ABOUT_DROP(Drop), Drop =:= ?ACT_IS_DROP).
-define(ACT_IS_DROP, 2).        %% 是否掉落类活动是
-define(ACT_NO_DROP, 1).        %% 否

-define(ONLINE_MIN_LEVEL, 0).       %% 在线奖励等级限制

%% 某些活动另外处理（1003,1022，1036）
-define(ID_LIST, [?ACT_ACCRECHARGE_ID, ?ACT_MARRY_THREE_LIFE, ?ACT_DAY_TARGET]).

-define(ACT_REPLENISH_SIGN_LIVENESS, 150).  %% 补签需要的活跃度

-define(ACT_OPEN_DAYS, 1).          %% 开服N天
-define(ACT_ANY_TIME, 2).           %% 配置特定时间
-define(ACT_CREATE_TIME, 4).        %% 玩家创角日期开启


-define(ACT_LEVEL_ID, 1001).                %% 冲级豪礼
-define(ACT_SEVEN_ID, 1002).                %% 七天
-define(ACT_ACCRECHARGE_ID, 1003).          %% 开服累充
-define(ACT_CLWORD_ID, 1005).               %% 集字
-define(ACT_DAYRECHARGE_ID, 1006).          %% 日冲
-define(ACT_RANK, 1007).                    %% 开服冲榜
-define(ACT_LOGIN, 1008).                   %% 回归豪礼
-define(ACT_ACC_PAY, 1009).                 %% 累充豪礼
-define(ACT_DOUBLE_EXP, 1010).              %% 双倍经验
-define(ACT_DOUBLE_COPY, 1011).             %% 副本双倍掉落
-define(ACT_FAIRY, 1012).                   %% 护送仙灵
-define(ACT_FRONT_FEAST, 1013).             %% 节日活动--前端占用ID
-define(ACT_FEAST_ENTRY, 1014).             %% 登录有礼
-define(ACT_FAMILY_CREATE, 1016).           %% 建帮立派
-define(ACT_FAMILY_BATTLE, 1017).           %% 仙盟争霸
-define(ACT_HUNT_BOSS_ID, 1019).            %% 猎杀BOSS
-define(ACT_LIMITED_TIME_BUY, 1020).        %% 限时云购
-define(ACT_MARRY_THREE_LIFE, 1022).        %% 活动三生三世
-define(ACT_OSS_WING, 1023).                %% 翅膀冲榜
-define(ACT_OSS_MAGIC_WEAPON, 1024).        %% 法宝冲榜
-define(ACT_OSS_HANDBOOK, 1025).            %% 图鉴冲榜
-define(ACT_OSS_SEVEN, 1026).               %% 七日投资
-define(ACT_OSS_PANIC_BUY, 1027).           %% 抢购
-define(ACT_OSS_TREVI_FOUNTAIN, 1028).      %% 许愿池
-define(ACT_OTF, 1029).                     %% 仙途
-define(ACT_OTF_BIG_GUARD, 1030).           %% 大精灵
-define(ACT_CAVE_BOSS_DOUBLE, 1031).        %% 洞天福地双倍掉落
-define(ACT_DROP, 1034).                    %% 掉落
-define(ACT_STORE, 1035).                   %% 商店
-define(ACT_DAY_TARGET, 1036).              %% 开服目标
%%-define(ACT_DAY_BOX, 1037).                 %% 每日宝箱
-define(ACT_FIRST_CHARGE, 1038).            %% 首充返元宝



-define(ACT_LIMITED_TIME_BUY_LOG, 30).    %% 云购日志数



-define(ACT_DAYRECHARGE_DAY_REWARD, 1).            %% 日冲日奖励
-define(ACT_DAYRECHARGE_COUNT_REWARD, 2).          %% 日冲计数奖励


%% 开服冲榜活动宏定义
-define(ACT_RANK_STATUS_NOT_OPEN, 0).   %% 未开启
-define(ACT_RANK_STATUS_RANKING, 1).    %% 正在进行排行
-define(ACT_RANK_STATUS_REWARD, 2).     %% 领取奖励阶段

-define(ACT_REWARD_RANK, 1).    %% 领取排行奖励
-define(ACT_REWARD_BASE, 2).    %% 领取基础奖励
-define(ACT_REWARD_BASE2, 3).   %% 领取基础奖励2
-define(ACT_REWARD_NOT, 4).     %% 不能领取奖励

-define(REWARD_STATUS_NOT, 1).  %% 不能领取奖励
-define(REWARD_STATUS_OK, 2).   %% 可以领取奖励
-define(REWARD_STATUS_GET, 3).  %% 已领取奖励

-define(ACT_FIVE_ELEMENTS, 7).  %% 五行秘境
-define(ACT_RANK_LEVEL, 1).     %% 冲级活动
-define(ACT_RANK_MOUNT, 2).     %% 坐骑进阶
-define(ACT_RANK_SUIT, 3).      %% 套装榜单
-define(ACT_RANK_PET, 4).       %% 训宠达人
-define(ACT_RANK_NATURE, 5).    %% 天机榜
-define(ACT_RANK_POWER, 6).     %% 战力排行

%% 建帮立派各个宏定义
-define(ACT_FAMILY_CREATE_CREATE, 1).           %% 创建仙盟
-define(ACT_FAMILY_CREATE_VICE, 2).             %% 任命X名副庭主
-define(ACT_FAMILY_CREATE_MEMBER, 3).           %% 仙盟成员达到X人
-define(ACT_FAMILY_CREATE_MEMBER2, 4).          %% 仙盟成员达到X人
-define(ACT_FAMILY_CREATE_LEVEL, 5).            %% 仙盟等级达到X级
-define(ACT_FAMILY_CREATE_LEVEL2, 6).           %% 仙盟等级达到X级
-define(ACT_FAMILY_CREATE_JOIN, 7).             %% 加入仙盟
-define(ACT_FAMILY_CREATE_TITLE_ELDER, 8).      %% 担任长老
-define(ACT_FAMILY_CREATE_TITLE_VICE, 9).       %% 担任副庭主

-define(ACT_FAMILY_MAX_VICE, 1).                %% 最大庭主Key
-define(ACT_FAMILY_MAX_MEMBER, 2).              %% 最大成员key

-define(ACT_FAMILY_BATTLE_FIRST_OWNER, 1).      %% 第一名庭主
-define(ACT_FAMILY_BATTLE_FIRST_MEMBER, 2).     %% 第一名成员
-define(ACT_FAMILY_BATTLE_SECOND_OWNER, 3).     %% 第二名庭主
-define(ACT_FAMILY_BATTLE_SECOND_MEMBER, 4).    %% 第二名成员
-define(ACT_FAMILY_BATTLE_THIRD_OWNER, 5).      %% 第三名庭主
-define(ACT_FAMILY_BATTLE_THIRD_MEMBER, 6).     %% 第三名成员
-define(ACT_FAMILY_BATTLE_OTHER_MEMBER, 7).     %% 其他成员

%% 节日活动宏定义
-define(RETURN_REWARD_DAYS, 5). %% 5天未登录

-define(LOGIN_REWARD_TYPE_RETURN, 0).   %% 领取回归玩家奖励
-define(LOGIN_REWARD_TYPE_NORMAL, 1).   %% 领取正常奖励

-define(LOGIN_ACT_STATUS_NOT, 0).   %% 不能领取
-define(LOGIN_ACT_STATUS_OK, 1).    %% 可以领取（活动状态限制）
-define(LOGIN_ACT_STATUS_GET, 2).   %% 已经领取

-define(ACT_HUNT_BOSS_40_REWARD, 7).    %%猎杀boss40积分奖励
-define(ACT_HUNT_BOSS_60_REWARD, 8).    %%猎杀boss60积分奖励

%%集字
-define(ACT_CLWORD_ROLE, 1).   %% 个人数量限制
-define(ACT_CLWORD_SERVER, 2).   %% 全服数量限制

%% 活动的r结构
-record(r_act, {
    id,                           %% 活动ID
    is_gm_set = false,           %% GM设置活动状态
    start_time = 0,               %% 开始时间
    end_time = 0,                 %% 结束时间
    start_date = 0,               %% 开始日期
    end_date = 0,                 %% 结束日期
    status = ?ACT_STATUS_CLOSE,   %% 状态
    is_visible = false,          %% 是否显示
    bc_pid = []                   %% 活动状态变化时需通知PID列表
}).

-record(r_act_rank, {
    role_id,        %%
    rank,           %% 排名
    condition,      %% 当前进度
    time            %% 时间
}).

%% 活动仙盟相关结构
-record(r_act_family, {
    family_id = 0,  %%
    max_list = []   %% [#p_kv{}|..] 活动用到的一个最大key值
}).

%% 仙盟战相关结构
-record(r_act_family_battle, {
    is_end = false,
    condition_list = []
}).


%% 限时云购
-record(r_act_limitedtime_buy, {
    role_id,                    %% role_id
    name,                       %% 名字
    buy_times = 0               %% 购买次数
}).



-record(c_act_online, {
    minute,            %% 分
    reward             %% 奖励
}).

-record(c_act_sign_daily, {
    day,            %% 日期
    item_reward,    %% 奖励
    vip_level,      %% VIP等级
    multi           %% 倍率
}).

-record(c_act_sign_reward, {
    times,          %% 次数
    item_rewards    %% 奖励
}).

-record(c_act_level, {
    level,          %% 等级
    item_rewards,   %% 奖励
    limit_num       %% 限制数量
}).

%%
-record(c_act_rank, {
    id,
    name,           %% 活动名称
    open_days,      %% 开启天数
    rank_time,      %% 排行时间[天,小时]
    rank_num,       %% 排行人数
    rank_condition, %% 排行条件
    rank_1,         %% 排行1
    rank_1_reward,  %% 排行奖励1
    rank_2,         %% 排行2
    rank_2_reward,  %% 排行奖励2
    rank_3,         %% 排行3
    rank_3_reward,  %% 排行奖励3
    rank_4,         %% 排行4
    rank_4_reward,  %% 排行奖励4
    base_condition, %% 基础奖励条件
    base_reward,    %% 基础奖励
    base_condition2,%% 基础奖励条件2
    base_reward2,   %% 基础奖励2
    base_condition3,%% 基础奖励条件3
    base_reward3,   %% 基础奖励3
    base_condition4,%% 基础奖励条件4
    base_reward4,   %% 基础奖励4
    base_condition5,%% 基础奖励条件5
    base_reward5,   %% 基础奖励5
    buy_goods       %% 购买道具
}).

-record(c_act, {
    id,                 %% 活动ID
    merge_effect,       %% 合服影响
    type,               %% 活动类型
    name,               %% 活动名称
    desc,               %% 活动描述
    min_level,          %% 最低等级
    start_date,         %% 开启日期
    end_date,           %% 结束日期
    time_string,        %% 时间段
    create_args,        %% 创角时间开启
    terminate_args,     %% 创角时间结束
    start_args,         %% 开服开启
    end_args,           %% 开服结束
    drop,               %% 掉落相关
    game_channel_list,  %%       ,
    merge_start_args,   %% 合服开始天数
    merge_end_args      %% 合服结束天数
}).

-record(c_act_time, {
    id,                 %% 活动ID
    type,               %% 活动类型
    start_date,         %% 开启日期
    end_date,           %% 结束日期
    time_string,        %% 时间段
    start_args,         %% 开服开启
    end_args            %% 开服结束
}).

%% 回归豪礼
-record(c_act_login, {
    days,           %% 天数
    login_rewards,  %% 登录奖励
    return_rewards  %% 回归奖励
}).

%% 登录豪礼
-record(c_act_entry, {
    days,           %% 天数
    login_rewards   %% 登录奖励
}).


%% 累计充值
-record(c_act_acc_pay, {
    gold,           %% 充值元宝数
    rewards         %% 奖励
}).

%% 副本双倍
-record(c_act_double_copy, {
    days,           %% 天数
    copy_type_list, %% 副本类型
    multi           %% 经验倍数
}).

-record(c_act_dayrecharge_count, {
    day,          %% 次数
    reward,         %% 奖励
    quota           %% 额度
}).

-record(c_act_dayrecharge, {
    quota,          %% 额度
    reward,          %% 奖励
    reward_one,
    reward_two,
    reward_three,
    reward_four,
    reward_five,
    reward_six,
    reward_seven
}).

-record(c_act_accrecharge, {
    quota,          %% 额度
    reward          %% 奖励
}).

-record(c_act_firstrecharge, {
    day,            %% 天数
    quota,          %% 额度
    reward          %% 奖励
}).

-record(c_act_clword, {
    id,                  %% 兑换ID
    need_item,           %% 需要物品
    get_item,            %% 拿到物品
    num,                 %% 每日数量,
    type,                %% 类型
    merge_need_item,     %% 需要物品
    merge_get_item,      %% 拿到物品
    merge_num,           %% 每日数量,
    merge_type           %% 类型
}).


-record(c_act_zeropanicbuy, {
    id,              %% 兑换ID
    fight,           %% 战力
    type,            %% 货币类型
    price,           %% 金额
    day              %% 日
}).

%% 开宗立派配置
-record(c_act_family_create, {
    id,         %% id
    desc,       %% 描述
    args,       %% 参数
    num,        %% 数量
    reward      %% 奖励
}).

%% 仙盟争霸配置
-record(c_act_family_battle, {
    id,         %% id
    desc,       %% 描述
    reward      %% 奖励
}).

%% 限时云购
-record(c_act_limitedtime_buy, {
    id,                 %% id
    big_reward,         %% 描述
    reward,             %% 奖励
    merge_big_reward,
    merge_reward
}).

-record(c_act_hunt_boss, {
    id,             %% id
    type,           %% 类型
    args1,          %% 参数1
    args2,          %% 参数2
    num,            %% 数量
    reward          %% 奖励
}).

-record(c_act_store, {
    id,             %% id
    item,           %%
    need_item,      %%
    need_num,       %%
    all_num
}).


-endif.