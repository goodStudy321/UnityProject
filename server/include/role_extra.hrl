%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%% 角色零碎数据
%%% @end
%%% Created : 07. 五月 2018 15:56
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(ROLE_EXTRA_HRL).
-define(ROLE_EXTRA_HRL, role_extra_hrl).

-define(MAX_FEEDBACK_TIMES, 5).     %% 一天最多反馈5次
-define(MAX_TITLE_LEN, 10).         %% 标题最大长度
-define(MAX_TEXT_LEN, 250).         %% 内容最大长度

-define(FEEDBACK_TIMES, 1).                 %% 玩家意见回馈次数
-define(SURVEY_ID, 2).                      %% 问卷调查的id
-define(KEY_ACT_RANK, 3).                   %% 开服冲榜
-define(EXTRA_KEY_FIRST_DROP, 4).           %% 新手首次掉落
-define(EXTRA_KEY_EXP_EFFICIENCY, 5).       %% 离线挂机效率
-define(EXTRA_KEY_ACT_RANK_PAY, 6).         %% 活动每日充值数据
-define(EXTRA_KEY_IMMORTAL_GUARD, 7).       %% 仙魂副本守卫信息
-define(EXTRA_KEY_COMMENT_STATUS, 8).       %% 引导好评状态
-define(EXTRA_KEY_ACTIVITY_MAP, 9).         %% 活动地图信息保存
-define(EXTRA_KEY_RESOURCE_LIST, 10).       %% 资源找回
-define(EXTRA_KEY_DOWNLOAD_STATUS, 11).     %% 下载领取奖励状态
-define(EXTRA_KEY_CHAT_AREA_BAN, 12).       %% 屏蔽玩家的信息
-define(EXTRA_KEY_COPY_EXP_AUTO, 13).       %% 经验副本自动鼓舞
-define(EXTRA_KEY_IS_FIRST_WORLD_BOSS, 14). %% 是否首次击杀世界boss
-define(EXTRA_KEY_SPECIAL_DROP_LIST, 15).   %% 特殊掉落
-define(EXTRA_KEY_COPY_FIRST_LIST, 16).     %% 首次通关
-define(EXTRA_KEY_WIND_OPEN_LIST, 17).      %% 窗口打开记录
-define(EXTRA_KEY_ITEM_DROP_LIST, 18).      %% 道具掉落控制
-define(EXTRA_KEY_FAMILY_ASM_INSPIRE, 19).  %% 道庭任务求助加速次数
-define(EXTRA_KEY_CHAT_MSG, 20).            %% 个人最近聊天信息
-define(EXTRA_KEY_RUNE_TREASURE_FIRST, 21). %% 首次寻宝固定奖励
-define(EXTRA_KEY_RESOURCE_TIMES, 22).      %% 资源找回-部分玩法次数
-define(EXTRA_KEY_BG_SUMMER, 23).           %% 夏日活动  周日活动(后台活动  结构定义于 bg_act)
-define(EXTRA_KEY_IS_V4_REWARD, 24).        %% v4奖励
-define(EXTRA_KEY_BG_WEEK_TWO, 25).         %% 第二周活动   活动(后台活动  结构定义于 bg_act)
-define(EXTRA_KEY_EXP_GOLD, 26).            %% 经验副本价格
-define(EXTRA_KEY_MERGE_SERVER, 27).        %% 合服相关
-define(EXTRA_KEY_PACKAGE_FLOOR, 28).       %% 礼包保底
-define(EXTRA_KEY_FIRST_CHARGE, 29).       %% 首充返元宝
-define(EXTRA_KEY_UNIVERSE_ADMIRE, 30).     %% 太虚通天塔膜拜次数
-define(EXTRA_KEY_TRENCH_CEREMONY, 31).     %% 绝版壕礼
-define(EXTRA_KEY_UNIVERSE_POWER_SET, 32).  %% 太虚通天塔是否直接设置了
-define(EXTRA_KEY_ACR_ESOTERICA_LAST_OFFLINE_TIME, 33).  %% 修炼秘籍的离线时间/最后找回时间
-define(EXTRA_KEY_ENTER_PERSONAL_BOSS, 36). %% 新号是否已经进入过个人boss
-define(EXTRA_KEY_SECOND_OPEN_ACT, 37).     %% 第二阶段开服活动（优化）
-define(EXTRA_KEY_COPY_GAIN, 38).           %% 完成副本获得的荣誉
-define(EXTRA_KEY_COPY_MARRY_TIMES, 39).    %% 是否剩余仙侣副本次数
-define(EXTRA_KEY_CYCLE_ACT_LIMITED_PANIC_BUY, 40).    %% 限时抢购修改
-define(EXTRA_KEY_SUMMER_EXTRA, 41).        %% 后台活动累充大礼新增

-define(NOT_ENTER_PERSONAL_BOSS, 0). %% 没有进入过个人boss
-define(ENTER_PERSONAL_BOSS, 1). %% 进入过个人boss



-define(EXTRA_KEY_WORLD_LEVEL_ADD, 100).    %% GM指令 世界等级不影响
-define(EXTRA_KEY_GM_PROPS, 101).           %% GM指令 调整属性

-define(CONFINE_ADD_ATTACK, 2).     %% 攻击
-define(CONFINE_ADD_HP, 3).         %% 生命


-define(COMMENT_STATUS_NOT, 0).     %% 没有评论
-define(COMMENT_STATUS_HAS, 1).     %% 评论了没有领取奖励
-define(COMMENT_STATUS_REWARD, 2).  %% 已经领取奖励

%% 需要每天重置的key
-define(RESET_KEY_LIST,
    [
        ?FEEDBACK_TIMES,
        ?EXTRA_KEY_UNIVERSE_ADMIRE
    ]).


-define(MAX_CHAT_LEN, 150).     %% 检测最近150条发言信息

-record(r_ban_chat_text, {
    time,       %% 时间
    type,       %% 类型
    msg         %% 信息
}).

-record(r_act_rank_reward, {
    id,                         %% ID
    reward_type,                %% 奖励类型
    is_reward = false,          %% 是否领取奖励
    base_list = [],             %% [#r_act_rank_base{}|...]
    buy_list = []               %% 购买列表 [#p_kv{}|....]
}).

-record(r_act_rank_base, {
    id,                     %% ID
    is_condition = false,   %% 是否满足
    is_reward = false       %% 是否领取奖励
}).

-record(r_act_trench_ceremony, {
    role_id,
    status = 0,            %% 状态
    accrecharge = 0,       %% 累计充值数
    open_time = 0
}).

-record(r_role_act_limited_panic_buy, {
    role_id,
    limited_panic_buy = [],          %% 限时抢购
    open_time = 0
}).


-record(r_role_second_open_act, {
    role_id,                        %% 用户id
    second_open_act = []          %% [#r_second_open_act{}]
}).


-record(r_second_open_act, {
    oss_rank_type = 0,            %% 冲榜活动类型
    rank_reward = [],               %% 榜单奖励
    rank = 0,                       %% 最终排名s
    power_reward = [],              %% 战力奖励
    panic_buy = [],                 %% 抢购
    mana = 0,                       %% 灵力
    mana_reward = [],               %% 灵力奖励表
    recharge_reward = [],           %% 累充
    task_list = [],                 %% 任务进度
    recharge = 0                    %% 充值总额
}).


-endif.