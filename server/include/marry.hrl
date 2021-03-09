%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 15:13
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(MARRY_HRL).
-define(MARRY_HRL, marry_hrl).

-define(MARRY_MIN_LEVEL, 213).      %% 结婚最低等级
-define(HAS_COUPLE(CoupleID), (CoupleID > 0)).      %% 是否已经有仙侣
-define(HAS_PROPOSE(ProposeID), (ProposeID > 0)).   %% 是否有提亲对象

-define(MARRY_TREE_REWARD, 1).  %% 种树立即获取
-define(MARRY_TREE_DAILY, 2).   %% 每日奖励

%% 求婚宏定义
-define(MARRY_PROPOSE_END_TIME, 60 * 10).   %% 求婚10分钟后结束时间

-define(MARRY_PROPOSE_ACCEPT, 1).   %% 同意
-define(MARRY_PROPOSE_REFUSE, 2).   %% 拒绝

%% 婚宴相关宏定义
-define(MIN_FEAST_HOUR, 1).     %% 每天预约是从1点场开始
-define(MAX_FEAST_HOUR, 24).    %% 每天最后一场是24点

-define(FEAST_APPOINT_MIN, 50).         %% 50分之后不能再预约婚礼
-define(FEAST_PREPARE_TIME, 5 * 60).    %% 5分钟的准备时间
-define(FEAST_BOW_TIME, 3 * 60).        %% 开始3分钟后进行拜堂
-define(FEAST_TIME, 15 * 60).           %% 开始15分钟的举办时间

-define(FEAST_END, 0).          %% 结束
-define(FEAST_PREPARE, 1).      %% 准备
-define(FEAST_START, 2).        %% 开始

-define(FEAST_MIN_LEVEL, 100).  %% 100级的玩家才能

-define(FEAST_GUEST_REFUSE, 0). %% 拒绝
-define(FEAST_GUEST_ACCEPT, 1). %% 同意

%% 婚礼结构
-record(r_marry_feast, {
    date,           %% 日期
    hour_list = []
}).

-record(r_feast_hour, {
    hour,               %% 小时
    share_id            %% ShareID
}).

%% 婚礼状态机
-record(r_feast_state,{
    status = ?FEAST_END,
    share_id,
    prepare_time = 0,
    start_time = 0,
    end_time = 0
}).

%% 结婚地图r结构
-record(r_map_feast, {
    is_end = false,     %% 是否结束
    owners = [],        %% 结婚主角
    bow_time = 0,       %% 拜堂时间
    end_time = 0,       %% 结束时间
    wish_logs = [],     %% 祝福记录
    heat = 0,           %% 热度
    index_id = 0,       %% 采集ID
    exp_counter = 0,    %% 增加经验的counter
    collect_counter = 0,%% 采集物的counter
    feast_monster,      %% 怪物掉落
    feast_collects = [] %% 采集次数更新相关 #r_feast_collect{}
}).

%% 婚礼场景-采集物
-record(r_feast_collect, {
    index_id = 0,
    end_time = 0,
    role_add_list = []
}).

%% 婚礼场景-怪物
-record(r_feast_monster, {
    end_time = 0,
    pos,
    drop_list = []
}).

%% 求婚
-record(c_marry_propose, {
    type,               %% 档次
    need_friendly,      %% 需要的亲密度
    guild_need_friendly,%% 公会需要的亲密度
    consume_type,       %% 花费元宝类型
    consume_fee,        %% 花费元宝
    title_id,           %% 称号id
    add_feast_times,    %% 婚礼次数
    reward              %% 道具奖励
}).

%% 同心结
-record(c_marry_knot, {
    id,             %% id
    step,           %% 等阶
    level,          %% 等级
    need_exp,       %% 升级需要经验
    base_props,     %% 基础属性加成
    extra_props     %% 额外属性加成
}).

%% 祝福
-record(c_marry_wish, {
    index_id,       %% index_id
    type,           %% 类型
    val             %% 参数
}).

%% 仙侣-称号
-record(c_marry_title, {
    id,             %% id
    title_id,       %% 获得的称号id
    friendly,       %% 需要的好感度
    knot_id,        %% 同心结id
    baby_id         %% 仙娃id
}).

-endif.