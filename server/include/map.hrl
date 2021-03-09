-ifndef(MAP_HRL).
-define(MAP_HRL, map_hrl).


-define(SLICES_KEY, 1).
-define(ACTORS_KEY, 2).
-define(MISC_KEY, 3).
-define(ETS_LIST, [{?SLICES_KEY, #r_map_kv.key}, {?ACTORS_KEY, #r_map_actor.actor_id}, {?MISC_KEY, #r_map_kv.key}]).

-define(FRESH_LEVEL, 50).           %% 新手50级之前不会死

-define(MAP_TYPE_NORMAL, 1).    %% 普通地图
-define(MAP_TYPE_COPY, 2).     %% 副本地图

-define(SUB_TYPE_WORLD_BOSS_1, 1).      %% 世界boss
-define(SUB_TYPE_WORLD_BOSS_2, 2).      %% 洞天福地
-define(SUB_TYPE_WORLD_BOSS_3, 3).      %% 个人boss
-define(SUB_TYPE_WORLD_BOSS_4, 4).      %% 幽冥禁地
-define(SUB_TYPE_ANSWER, 5).            %% 答题副本地图
-define(SUB_TYPE_BATTLE, 6).            %% 多阵营对战地图
-define(SUB_TYPE_SOLO, 7).              %% 1v1对战地图
-define(SUB_TYPE_OFFLINE_SOLO, 8).      %% 离线1v1对战地图
-define(SUB_TYPE_FAMILY_TD, 9).         %% 守卫仙盟
-define(SUB_TYPE_FAMILY_BOSS, 10).      %% 仙盟boss
-define(SUB_TYPE_FAMILY_BATTLE, 11).    %% 帮派战
-define(SUB_TYPE_SUMMIT_TOWER, 12).     %% 青云之巅
-define(SUB_TYPE_MYTHICAL_BOSS, 16).    %% 神兽岛
-define(SUB_TYPE_ANCIENTS_BOSS, 17).    %% 远古遗迹
-define(SUB_TYPE_DEMON_BOSS, 18).       %% 魔域boss
-define(SUB_TYPE_FIVE_ELEMENTS, 20).    %% 五行秘境

-define(IS_WORLD_BOSS_SUB_TYPE(SubType), (lists:member(SubType, [?SUB_TYPE_WORLD_BOSS_1, ?SUB_TYPE_WORLD_BOSS_2, ?SUB_TYPE_WORLD_BOSS_4,
                                                                 ?SUB_TYPE_MYTHICAL_BOSS, ?SUB_TYPE_ANCIENTS_BOSS]))).

%% 非副本不能自动开启的地图
-define(WILD_CONDITION_SUB_TYPE, [?SUB_TYPE_WORLD_BOSS_1, ?SUB_TYPE_WORLD_BOSS_2, ?SUB_TYPE_WORLD_BOSS_3, ?SUB_TYPE_WORLD_BOSS_4, ?SUB_TYPE_ANSWER,
                                  ?SUB_TYPE_BATTLE, ?SUB_TYPE_SOLO, ?SUB_TYPE_FAMILY_TD, ?SUB_TYPE_FAMILY_BOSS, ?SUB_TYPE_FAMILY_BATTLE, ?SUB_TYPE_SUMMIT_TOWER,
                                  ?SUB_TYPE_MYTHICAL_BOSS, ?SUB_TYPE_ANCIENTS_BOSS]).

-define(IS_SPECIAL_OPEN(IsSpecialOpen), (IsSpecialOpen =:= 1)).

-define(DEFAULT_EXTRA_ID, 1).    %% 默认extra_id
-define(TRANSFER_ITEM, 31015).   %% 小飞鞋传送扣除道具

-define(MAP_SHUTDOWN_TIME, 5).  %% 一般5秒关闭地图
-define(MAP_MAX_ROLE_NUM, 500). %% 单张地图最多支持500人

%% 地图基础元素
-define(TILE_SIZE, 100). %% 单个格子的大小为100*100
-define(MAP_SLICE_WIDTH, 1000).  %%单位厘米
-define(MAP_SLICE_HEIGHT, 1000). %%单位厘米
-define(WILD_MAX_SLICE, 4000).  %%单位厘米

-define(DEFAULT_MDIR, 180).
-define(MAX_MDIR, 360).
-define(DEFAULT_DIR, 4). %% 默认朝向

-define(M2T(M), ((M) div ?TILE_SIZE)).
-define(T2M(T), ((T) * ?TILE_SIZE + ?TILE_SIZE div 2)).


%% actor类型
-define(ATTACK_LIST, [?ACTOR_TYPE_ROLE, ?ACTOR_TYPE_ROBOT, ?ACTOR_TYPE_MONSTER]).
-define(ACTOR_TYPE_ROLE, 1).        %% 角色
-define(ACTOR_TYPE_MONSTER, 2).     %% 怪物
-define(ACTOR_TYPE_COLLECTION, 3).  %% 采集物
-define(ACTOR_TYPE_TRAP, 6).        %% 陷阱、弹道类
-define(ACTOR_TYPE_DROP, 13).       %% 掉落物
-define(ACTOR_TYPE_ROBOT, 30).      %% 机器人

%% 状态相关
-define(MAP_STATUS_NORMAL, 0).  %% 正常状态
-define(MAP_STATUS_DEAD, 1).  %% 死亡状态
-define(MAP_STATUS_FIGHT, 2).  %% 战斗状态
-define(MAP_STATUS_RETURN, 20). %% 怪物回归状态

-define(MAP_WEAPON_STATE_NORMAL, 0).%% 正常状态
-define(MAP_WEAPON_STATE_SHINE, 1). %% 发光状态

%% 阵营
-define(DEFAULT_CAMP_MONSTER, 1).   %% 怪物默认阵营
-define(DEFAULT_CAMP_ROLE, 2).      %% 角色默认阵营

-define(BATTLE_CAMP_IMMORTAL, 1).   %% 仙
-define(BATTLE_CAMP_DEMON, 2).      %% 魔
-define(BATTLE_CAMP_BUDDHA, 3).     %% 佛
-define(BATTLE_CAMP_MONSTER, 4).    %% 怪物阵营
-define(BATTLE_CAMP_NORMAL, 5).     %% 中立阵营 不能被攻击

-define(CAMP_RED, 1).      %% 帮战红
-define(CAMP_BLUE, 2).     %% 帮战蓝

%% 跳转变化
-define(ACTOR_MOVE_NORMAL, 0). %% 普通传送
-define(ACTOR_MOVE_RUSH, 1). %% 冲刺
-define(ACTOR_MOVE_CATCH, 2). %% 抓取
-define(ACTOR_MOVE_JUMP, 3). %% 跳转

%% map_actor_attr的id值
-define(MAP_ATTR_STATUS, 2).        %% 状态变化
-define(MAP_ATTR_MOVE_SPEED, 3).    %% 移动速度变化
-define(MAP_ATTR_BUFF_UPDATE, 4).   %% BuffID 更新
-define(MAP_ATTR_BUFF_DEL, 5).      %% BuffID 减少
-define(MAP_ATTR_CAMP_ID, 6).       %% 阵营变化
-define(MAP_ATTR_PK_MODE, 7).       %% PK模式变化
-define(MAP_ATTR_NAME, 8).          %% 名字变化

-define(ROLE_LEVEL, 101).           %% 角色等级变化
-define(ROLE_WEAPON_STATE, 102).    %% 角色武器状态变化
-define(ROLE_SKIN_LIST, 103).       %% 角色皮肤变化
-define(ROLE_PK_VALUE, 104).        %% 角色pk值变化
-define(ROLE_FAMILY_ID, 105).       %% 角色帮派ID变化
-define(ROLE_FAMILY_NAME, 106).     %% 角色帮派名字变化
-define(ROLE_TEAM_ID, 107).         %% 角色队伍变化
-define(ROLE_POWER, 108).           %% 角色战斗力变化
-define(ROLE_CONFINE, 109).         %% 角色境界变化
-define(ROLE_TITLE_ID, 110).        %% 角色称号变化
-define(ROLE_FAMILY_TITLE, 111).    %% 角色帮派称号变化
-define(ROLE_COUPLE_ID, 112).       %% 角色仙侣ID变化
-define(ROLE_COUPLE_NAME, 113).     %% 角色仙侣名字变化
-define(ROLE_RELIVE_LEVEL, 114).    %% 角色转生等级变化
-define(ROLE_ORNAMENT_LIST, 115).   %% 角色装饰列表变化

-define(MONSTER_BATTLE_OWNER, 201). %% 战场归属
-define(MONSTER_WORLD_BOSS, 202).   %% 世界boss归属
-define(MONSTER_COUNTDOWN, 203).    %% 倒计时更新

%% PK模式
-define(PK_MODE_PEACE, 1).          %% 和平模式
-define(PK_MODE_FORCE, 2).          %% 强制模式
-define(PK_MODE_ALL, 3).            %% 全体模式
-define(PK_MODE_CAMP, 4).           %% 阵营模式
-define(PK_MODE_SERVER, 5).         %% 跨服模式
-define(PK_MODE_WORLD_BOSS, 6).     %% 世界boss专属模式

-define(PK_VALUE_TIME, 3600).       %% 1点PK值减少的时间
-define(ADD_PK_VALE, 1).            %% 该地图pk是会增加pk值

-define(IS_MISSION_SHARE(IsShare), (IsShare =:= 1)).    %% 任务是否区域共享

-define(RELIVE_TYPE_NORMAL, 0). %% 普通方式复活
-define(RELIVE_TYPE_FEE, 1).    %% 花钱原地复活
-define(IS_NORMAL_RELIVE(IsNormal), (IsNormal > 0)).    %% 是否可以普通复活
-define(IS_FEE_RELIVE(IsFee), (IsFee > 0)).           %% 是否可以花钱复活


%% monster 跟 trap用到
-define(ONE_COUNTER, 1).        %% 最小的counter = 100ms
-define(MIN_COUNTER, 2).        %% 小counter = 200ms
-define(NORMAL_COUNTER, 4).     %% 正常的counter = 400ms
-define(BLAME_COUNTER, 6).      %% 惩罚性的counter = 600ms
-define(ATTACK_COUNTER, 8).     %% 受到攻击后延迟的counter = 800ms
-define(SECOND_COUNTER, 10).    %% 1秒的counter

%% 地图相关定义
-define(ETS_MAP_BRANCH, ets_map_branch).
-define(CHECK_EXTRA_CD, 60 * 1000). %% 1分钟检查一次
-define(CLOSE_TIME, 30).    %% 分线地图为0时的关闭时间

-define(MAP_FRESH, 10101).                  %% 初始新手地图
-define(MAP_SINGLE_TD, 20301).              %% 单人TD副本
-define(MAP_OFFLINE_SOLO, 20901).           %% 单人离线1v1地图
-define(MAP_COPY_EXP, 20001).               %% 青竹院
-define(MAP_COPY_MARRY, 30018).             %% 仙侣副本

-define(MAP_ROB_ESCORT, 30022).                  %% 护送抢夺
-define(MAP_ROB_BACK_ESCORT, 30023).             %% 护送夺回
%%-define(MAP_ROB_BACK_ESCORT, 30023).             %% 护送夺回

-define(MAP_BATTLE, 30001).                 %% 战场地图ID
-define(MAP_SOLO, 30002).                   %% 1v1战场地图ID
-define(MAP_FAMILY_TD, 30003).              %% 守卫仙盟地图
-define(MAP_FAMILY_BOSS, 30004).            %% 仙盟boss地图  与  道庭神兽地图同一张
-define(MAP_FAMILY_AS, 30007).              %% 仙盟答题
-define(MAP_ANSWER, 30006).                 %% 答题地图
-define(MAP_FAMILY_BT, 30008).              %% 帮派战
-define(MAP_FIRST_SUMMIT_TOWER, 30009).     %% 巅峰爬塔第一层
-define(MAP_LAST_SUMMIT_TOWER, 30017).      %% 巅峰爬塔第九层
-define(MAP_MARRY_FEAST, 30019).            %% 婚礼场景
-define(MAP_DEMON_BOSS, 30021).             %% 魔域boss
-define(MAP_TREASURE_SECRET_MIN, 80001).    %% 宝藏秘境
-define(MAP_TREASURE_SECRET_MAX, 80008).    %% 宝藏秘境

-define(MAP_FIRST_COPY_TOWER, 40001).       %% 爬塔副本第一层
-define(MAP_FIRST_UNIVERSE, 300001).        %% 太虚通天塔第一层

%% 地图锁
-define(MAP_NO_LOCK, 0).                    %% 无地图锁
-define(MAP_FAIRY_LOCK, 1).                 %% 仙灵护送地图锁


-define(IS_CROSS_MAP(IsCrossMap), (IsCrossMap =:= 1)).  %% 是跨服地图
-define(IS_ADD_BOSS_TIMES(IsAddBossTimes), (IsAddBossTimes =:= 1)). %% 是世界boss疲劳地图
-define(IS_WORLD_BOSS_TIME(StayTime), (StayTime > 0)).

-define(IS_MAP_BATTLE(MapID), (MapID =:= ?MAP_BATTLE)).             %% 战场地图
-define(IS_MAP_SOLO(MapID), (MapID =:= ?MAP_SOLO)).                 %% 1v1地图
-define(IS_MAP_OFFLINE_SOLO(MapID), (MapID =:= ?MAP_OFFLINE_SOLO)). %% 离线1v1地图
-define(IS_MAP_TD(MapID), (MapID =:= ?MAP_SINGLE_TD orelse MapID =:= ?MAP_FAMILY_TD)).              %% TD副本
-define(IS_MAP_FAMILY_TD(MapID), (MapID =:= ?MAP_FAMILY_TD)).       %% 守卫仙盟地图
-define(IS_MAP_FAMILY_BOSS(MapID), (MapID =:= ?MAP_FAMILY_BOSS)).   %% 仙盟boss地图
-define(IS_MAP_FAMILY_GOD_BEAST(MapID), (MapID =:= ?MAP_FAMILY_BOSS)).   %% 道庭神兽地图
-define(IS_MAP_ANSWER(MapID), (MapID =:= ?MAP_ANSWER)).             %% 答题地图
-define(IS_MAP_FAMILY_AS(MapID), (MapID =:= ?MAP_FAMILY_AS)).       %% 仙盟晚宴答题
-define(IS_MAP_SUMMIT_TOWER(MapID), (?MAP_FIRST_SUMMIT_TOWER =< MapID andalso MapID =< ?MAP_LAST_SUMMIT_TOWER)).    %% 巅峰爬塔地图
-define(IS_MAP_LAST_SUMMIT_TOWER(MapID), (MapID =:= ?MAP_LAST_SUMMIT_TOWER)).   %% 巅峰爬塔最后一层
-define(IS_MAP_FAMILY_BT(MapID), (MapID =:= ?MAP_FAMILY_BT)).   %% 帮战
-define(IS_MAP_MARRY_FEAST(MapID), (MapID =:= ?MAP_MARRY_FEAST)).   %% 结婚场景
-define(IS_MAP_COPY_EXP(MapID), (MapID =:= ?MAP_COPY_EXP)).         %% 青竹院
-define(IS_MAP_COPY_MARRY(MapID), (MapID =:= ?MAP_COPY_MARRY)).     %% 仙侣副本
-define(IS_MAP_DEMON_BOSS(MapID), (MapID =:= ?MAP_DEMON_BOSS)).     %% 魔域boss
-define(IS_MAP_TREASURE_SECRET(MapID), (MapID >= ?MAP_TREASURE_SECRET_MIN andalso ?MAP_TREASURE_SECRET_MAX >= MapID)).%% 宝藏秘境

-define(IS_MAP_ROB_ESCORT(MapID), (MapID =:= ?MAP_ROB_ESCORT)).               %% 护送抢夺
-define(IS_MAP_ROB_BACK_ESCORT(MapID), (MapID =:= ?MAP_ROB_BACK_ESCORT)).     %% 护送夺回

-define(MAP_BUFF_IMPRISON, 102002). %% 定身buff
%% map ets
-record(r_map_kv, {key, val}).

%% 战斗相关设定
-record(r_map_fight, {actor_id, max_hp, attack, defence}).

%% 格子与九宫格
-record(r_pos, {mx, my, mdir, tx, ty, dir}).
-record(r_slice, {slice_x, slice_y}).

%% 野外地图分线管理
-record(r_map_branch, {map_id, cur_extra_id, max_extra_id, extra_list}).
-record(r_map_extra, {extra_id, fresh_enter_num = 0, role_num = 0, close_time = 0}).

%% 用于怪物寻路，拐点和所有路径
-record(r_path, {corner, path = []}).
-record(r_map_node, {key, tx, tz, dir, g, f, p_parent}).

%% 角色进入地图时的返回
-record(r_map_enter, {map_pid}).

%% 场景单元死亡附带参数
-record(r_actor_dead, {src_id, src_type, extra_args}).

%% 地图中锁定时actor需要的信息
-record(r_map_actor, {
    actor_id = 0,
    actor_type = 0,
    actor_name = "",

    hp = 0,
    shield = 0,           %% 护盾
    max_hp = 0,
    prop_effects = [],    %% [#r_map_prop_effect{}|...] 状态类效果
    fight_effects = [],   %% [{Type, [#r_fight_effect{}|..]}, {Type, [#r_fight_effect{}|..]}|....]  战斗结果触发效果
    buffs = [],           %% [ID|..]
    buff_status = 0,

    status = 0,
    move_speed = 0,
    pos = 0,
    target_pos = 0,
    camp_id = 0,
    reduce_hp_times = 0,
    pk_mode = ?PK_MODE_CAMP, %% 默认阵营模式
    role_extra,
    monster_extra,
    collection_extra,
    trap_extra,
    drop_extra
}).

%% 状态类效果
-record(r_map_prop_effect, {
    skill_sub_type,     %% 技能子类型
    id,
    rate,
    end_time_ms,        %% 技能生效结束时间
    last_time,          %% 持续时间
    cd,
    next_time_ms = 0
}).

%% 战斗触发类效果，无状态
-record(r_fight_effect, {
    id,                 %% 纹印ID
    type,               %% 类型fight.hrl
    rate = 0,           %% 概率
    condition = [],       %% 条件参数 list
    self_buffs = [],    %% 自身buff
    enemy_buffs = [],   %% 对方buff
    args,               %% 参数
    cd,                 %% CD时间
    time                %% 可以触发的时间
}).

%% 角色自己独有的数据
-record(r_map_role, {
    role_id,
    ref,
    attack_time = 0,        %% 最近一次受击时间
    attack_times = 0,       %% 被攻击次数

    gateway_pid,
    role_pid,
    is_guide = 0,       %% 世界boss副本引导字段
    cave_times = 0,           %% 剩余洞天福地挑战次数
    cave_assist_times = 0,    %% 剩余洞天福地援助次数
    mythical_times = 0,       %% 剩余神兽岛次数
    mythical_collect = 0,     %% 龙灵水晶采集次数
    mythical_collect2 = 0,    %% 凤血水晶采集次数
    missions = [],            %% 当前任务
    special_drops = [],     %% 特殊掉落列表
    item_drops = []         %% 道具掉落控制 [#r_item_control{}|....]
}).

-record(r_reduce_src, {
    actor_id,
    actor_type,
    actor_name = "",
    actor_level = 0,
    team_id = 0,
    family_id = 0}).

-record(r_marry_collect, {
    role_id,
    taste_times = 0,
    heat_collect_times = 0,     %% 当前采集次数
    heat_max_times = 0
}).

-record(c_map_base, {
    map_id = 0,           %% 场景ID
    map_name = "",        %% 名称
    map_type,           %% 场景类型
    sub_type,           %% 场景子类型
    is_special_open,    %% 特殊开启
    is_cross_map,       %% 是跨服地图 1是 其他否
    max_num,            %% 野外地图分线最大人数
    map_bc_size,        %% 地图广播
    data_id,            %% 地图数据ID
    seqs = [],            %% 刷新序列
    is_normal_relive,   %% 是否可以普通复活
    is_fee_relive,      %% 是否可以原地复活
    normal_times,       %% 普通复活次数
    normal_cd,          %% 普通复活CD
    times_cd,           %% 复活次数CD
    relive_gold,        %% 元宝
    act_drop,           %% 活动掉落
    pk_modes,           %% 可选择模式
    default_pk_mode,    %% 进入场景模式
    is_add_pk_value,    %% 是否增加pk值
    free_enter_times,   %% 免费进入次数
    vip_free_level,     %% 免费进入VIP等级
    vip_enter_level,    %% 进入VIP等级
    use_gold,           %% 花费元宝
    use_item_string,    %% 消耗道具
    min_level,          %% 最小进入等级
    stay_time,          %% 单次停留时间
    enter_times         %% 可进入次数
}).

-record(c_map_seq, {
    seq_id,             %% 序列ID
    monster_desc,       %% 怪物注释
    seq_desc,           %% 场景注释
    create_num,         %% 创建数量
    refresh_interval,   %% 刷新间隔
    is_mission_share,   %% 任务是否共享
    min_point = [],       %% 左下角点 [MX, MY]
    max_point = [],       %% 右上角点 [MX, MY]
    monster_type_id,    %% 怪物的TypeID
    collection_type_id, %% 采集物的TypeID
    min_level,          %% 最小等级
    max_level           %% 最大等级
}).


-endif.

