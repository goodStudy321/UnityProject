%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 27. 六月 2017 10:39
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(COPY_HRL).
-define(COPY_HRL, copy_hrl).

-define(COPY_FRONT, 0).         %% 流程树副本（前端控制出怪）
-define(COPY_EXP, 1).           %% 经验副本
-define(COPY_SILVER,  2).       %% 金币副本
-define(COPY_EQUIP, 3).         %% 装备副本
-define(COPY_TOWER, 4).         %% 爬塔副本
-define(SPECIAL_COPY_FRONT, 5). %% 特殊流程树副本（白天黑夜地图）
-define(COPY_WORLD_BOSS, 6).    %% 个人boss副本
-define(COPY_SINGLE_TD, 7).     %% 单人TD副本（材料副本）
-define(COPY_OLD_OFFLINE_SOLO, 8).  %% 离线1v1副本
-define(COPY_EVIL, 9).          %% 心魔副本
-define(COPY_MISSION_TD, 10).   %% 守护副本 - 海源狂袭
-define(COPY_MISSION_1, 11).    %% 挑战副本1 - 妖魔岭
-define(COPY_MISSION_2, 12).    %% 挑战副本2 - 魔龙洞窟
-define(COPY_MISSION_3, 13).    %% 挑战副本3 - 鬼王殿
-define(COPY_RELIVE, 14).       %% 渡劫副本
-define(COPY_IMMORTAL, 15).     %% 仙魂副本
-define(COPY_MARRY, 16).        %% 仙侣副本
-define(COPY_CONFINE, 17).      %% 境界副本
-define(COPY_WAR_SPIRIT, 18).   %% 战灵副本
-define(COPY_FORGE_SOUL, 19).   %% 镇魂副本
-define(COPY_TREASURE_BOSS, 20).%% 藏宝图BOSS
-define(COPY_TREASURE_WAVE, 21).%% 藏宝图波数刷怪
-define(COPY_GUIDE_BOSS, 22).   %% 世界boss指引地图
-define(COPY_FIVE_ELEMENTS, 23).%% 五行秘境
-define(COPY_TREASURE_SECRET, 24).%% 宝藏秘境
-define(COPY_OFFLINE_SOLO, 25). %% 新离线1v1
-define(COPY_UNIVERSE, 26).     %% 太虚通天塔

-define(IS_COPY_FRONT(CopyType), (CopyType =:= ?COPY_FRONT orelse CopyType =:= ?SPECIAL_COPY_FRONT)).
-define(IS_COPY_EXP(CopyType), (CopyType =:= ?COPY_EXP)).
-define(IS_COPY_EQUIP(CopyType), (CopyType =:= ?COPY_EQUIP)).
-define(IS_COPY_TOWER(CopyType), (CopyType =:= ?COPY_TOWER)).
-define(IS_COPY_OLD_OFFLINE_SOLO(CopyType), (CopyType =:= ?COPY_OLD_OFFLINE_SOLO)).
-define(IS_COPY_OFFLINE_SOLO(CopyType), (CopyType =:= ?COPY_OFFLINE_SOLO)).
-define(IS_COPY_CONFINE(CopyType), (CopyType =:= ?COPY_CONFINE)).
-define(IS_COPY_TREASURE(CopyType), (CopyType =:= ?COPY_TREASURE_BOSS orelse CopyType =:= ?COPY_TREASURE_WAVE)).
-define(IS_COPY_GUIDE_BOSS(CopyType), (CopyType =:= ?COPY_GUIDE_BOSS)).
-define(IS_COPY_EVIL(CopyType), (CopyType =:= ?COPY_EVIL)).
-define(IS_COPY_FIVE_ELEMENTS(CopyType), (CopyType =:= ?COPY_FIVE_ELEMENTS)).
-define(IS_COPY_TREASURE_SECRET(CopyType), (CopyType =:= ?COPY_TREASURE_SECRET)).
-define(IS_COPY_UNIVERSE(CopyType), (CopyType =:= ?COPY_UNIVERSE)).

-define(COPY_FIRST_TOWER, 40001).       %% 爬塔第一层
-define(COPY_FIRST_UNIVERSE, 300001).   %% 太虚第一层
-define(GET_TOWER_FLOOR(TowerID), (TowerID rem 10000)).

-define(SUCCESS_FRONT, 0).  %% 流程树副本，无限制
-define(SUCCESS_MONSTER, 1).%% 杀怪副本
-define(SUCCESS_WAVE, 2).   %% 坚持N波
-define(SUCCESS_TIME, 3).   %% 坚持N秒
-define(SUCCESS_DEFENCE, 4).%% 守护目标

-define(STARS_TIME, 1).     %% 星级-时间
-define(STARS_RUN_NUM, 2).  %% 星级-逃跑人数

-define(TIMES_TYPE_ENTER, 0).   %% 进入时扣除次数
-define(TIMES_TYPE_SUCC, 1).    %% 完成时扣除次数

-define(LEAVE_SHUTDOWN_TIME, 180 * 1000).       %% 下线或者离开180秒后关闭副本
-define(END_SHUTDOWN_TIME, 180).                %% 副本结束180秒后关闭副本
-define(FIRST_ENTER_SHUTDOWN_TIME, 10 * 1000).  %% 没有进入过地图的话 10分钟后销毁这个地图

-define(COPY_NOT_END, 0).   %% 副本-未结束
-define(COPY_SUCCESS, 1).   %% 副本-通关
-define(COPY_FAILED,  2).   %% 副本-失败

-define(COPY_STAR_1, 1).    %% 副本1星
-define(COPY_STAR_2, 2).    %% 副本2星
-define(COPY_STAR_3, 3).    %% 副本3星

-define(COPY_UPDATE_STATUS, 1).         %% 状态更新
-define(COPY_UPDATE_START_TIME, 2).     %% 开始时间
-define(COPY_UPDATE_END_TIME, 3).       %% 结束时间
-define(COPY_UPDATE_CUR, 4).            %% 当前进度
-define(COPY_UPDATE_SUB, 5).            %% 当前副进度

-define(HAVE_COPY_MARRY_TIMES, 0).   %% 仙侣副本还有次数
-define(NOT_HAVE_COPY_MARRY_TIMES, 1).   %% 仙侣副本没有次数

-define(COPY_DEGREE_NORMAL, 1). %% 简单难度

-define(IS_TEAM_MAP(IsTeamMap), (IsTeamMap > 0)).

-define(GET_MAP_BY_WAVE_ID(WaveID), (WaveID div 100)).
-define(GET_WAVE_ID_BY_MAP(MapID), (MapID * 100)).


-define(CHEER_SKILL_ID_1, 1).
-define(CHEER_SKILL_ID_2, 2).
-define(CHEER_BUFF_ID, 201001). %% 鼓舞buffID

-define(CAN_COPY_CLEAN(CanClean), (CanClean =:= 1)).
-define(IS_CLEAN_COST(IsCleanCost), (IsCleanCost =:= 1)).

%% 单人TD副本相关
-define(ROUND_1_POS_LIST, [
    [{1645,-1665},{737,-453},{82,173},{-695,936}],
    [{1645,-1665},{474,-493},{-230,171},{-840,805}],
    [{1645,-1665},{475,-759},{-322,10},{-901,761}]
]).
-define(ROUND_2_POS_LIST, [
    [{-899,-2753},{-671,-1292},{-670,364},{-774,738}],
    [{-899,-2753},{-916,-1292},{-918,-383},{-886,681}],
    [{-899,-2753},{-1144,-1345},{-1116,-355},{-1040,753}]
]).

-define(ROUND_3_POS_LIST, [
    [{-3446,-1654},{-2246,-755},{-1483,13},{-998,712}],
    [{-3446,-1654},{-2407,-573},{-1632,180},{-1070,853}],
    [{-3446,-1654},{-2571,-423},{-1834,289},{-1076,1054}]
]).


%% 副本类型对应的模块
-define(COPY_MOD_LIST, [
    {?COPY_FRONT, copy_single},
    {?COPY_EXP, copy_exp},
    {?COPY_SILVER, copy_wave},
    {?COPY_EQUIP, copy_wave},
    {?COPY_TOWER, copy_tower},
    {?SPECIAL_COPY_FRONT, copy_single},
    {?COPY_WORLD_BOSS, copy_world_boss},
    {?COPY_SINGLE_TD, copy_single_td},
    {?COPY_OFFLINE_SOLO, copy_offline_solo},
    {?COPY_EVIL, copy_evil},
    {?COPY_MISSION_TD, copy_single_td},
    {?COPY_MISSION_1, copy_demon},
    {?COPY_MISSION_2, copy_dragon},
    {?COPY_MISSION_3, copy_ghost},
    {?COPY_RELIVE, copy_relive},
    {?COPY_IMMORTAL, copy_immortal},
    {?COPY_MARRY, copy_marry},
    {?COPY_CONFINE, copy_evil},
    {?COPY_WAR_SPIRIT, copy_wave},
    {?COPY_FORGE_SOUL, copy_wave},
    {?COPY_TREASURE_BOSS, copy_treasure_boss},
    {?COPY_TREASURE_WAVE, copy_treasure_wave},
    {?COPY_GUIDE_BOSS, copy_guide_boss},
    {?COPY_FIVE_ELEMENTS, copy_five_elements},
    {?COPY_TREASURE_SECRET, copy_treasure_secret},
    {?COPY_UNIVERSE, copy_universe}
]).

-record(r_clean_args, {
    copy_type,              %% 副本类型
    map_id,                 %% 副本ID
    role_level,             %% 角色等级
    star,                   %% 星级
    num,                    %% 次数
    boss_num                %% Boss数量
}).

%% 地图里存放的副本信息
-record(r_map_copy, {
    map_id,                 %% 地图ID
    status=?COPY_NOT_END,   %% 是否结束
    copy_mod,               %% 副本模块
    start_time,             %% 副本开始时间
    start_time_ms,          %% 副本开始时间(Ms)
    end_time,               %% 副本结束时间
    shutdown_time,          %% 副本关闭时间
    success_type,           %% 完成副本类型
    success_args,           %% 完成副本参数
    cur_progress,           %% 完成副本相关参数(跟完成任务参数相关)
    sub_progress,           %% 副本副进度
    all_wave,               %% 总波数
    mod_args,               %% 不同副本类型的参数
    copy_level,             %% 副本角色的平均等级
    enter_roles=[]          %% 进入过副本的玩家
}).

%% 经验副本刷怪r结构
-record(r_copy_exp, {
    born_num,               %% 第一波出生数量
    born_pos_list,          %% 坐标范围
    born_time = 0           %% 第一波出生的间隔
}).

%% 金币、装备副本刷怪r结构
-record(r_copy_wave, {
    type_id,                %% 怪物类型
    born_num,               %% 出生数量
    born_pos_list,          %% 坐标范围
    kill_num = 0,           %% 当前击杀的数量
    born_time = 0,          %% 这一波出生的间隔
    add_props = 0           %% 属性加成
}).

%% 单人TD副本刷怪r结构
-record(r_copy_single_td, {
    area_1,                 %% 1区域刷怪[{TypeID, Num}|..]
    area_2,                 %% 2区域刷怪[{TypeID, Num}|..]
    area_3,                 %% 3区域刷怪[{TypeID, Num}|..]
    remain_num,             %% 当前波次剩余怪物数量
    need_remain_num         %% 下一波出怪阈值
}).

%% 妖魔岭对应的r结构
-record(r_copy_demon, {
    buff_monster = []
}).

%% 鬼王岭对应的r结构
-record(r_copy_ghost, {
    ghost_type_id,          %% 鬼王ID
    monster_num,            %% 小弟怪物数量
    hp_list                 %% 低于XX血量召唤
}).

%% 仙魂副本对应的r结构
-record(r_copy_immortal, {
    max_wave = 0,           %% 最大波数
    monster_list = [],      %% 刷怪相关 [{TypeID, Num}|...]
    guard_list = [],        %% 守卫列表 [#p_kv{}|...]
    skill_list = [],        %% 技能列表[#p_kv{}|...]
    remain_num = 0,         %% 剩余怪物数量
    next_remain_num = 0,    %% 下一波生成的阈值
    run_num = 0,            %% 逃跑数量
    summon_boss_round = 0,  %% 上一次召唤boss的回合
    is_auto_summon = false  %% 是否自动召唤
}).

%% 仙侣副本对应的r结构
-record(r_copy_marry, {
    refresh_list = [],
    select_list = [],       %% [#p_dkv{}]
    icon_end_time = 0,
    icon_list = [],         %% [#p_dkl{}...]
    sweet_percent = 0,      %% 甜蜜度进度 达到100时加buff
    buff_end_time = 0       %% buff结束时间 为0时表示不衰减
}).

%% 仙侣副本刷怪r结构
-record(r_copy_marry_monster, {
    type_id,                %% 怪物类型
    born_num,               %%
    born_list=[],           %% [{Num1, 坐标1}, {Num2, 坐标2}]
    kill_num = 0            %% 当前击杀的数量
}).

%% 角色副本r结构
-record(r_copy_role, {
    role_id,                %% 角色ID
    cheer_list = []         %% 鼓舞列表
}).

%% 鼓舞相关参数
-record(r_cheer_args, {
    cost_list,
    silver_times,
    all_times,
    add_buff_id
}).

%% cfg_copy结构
-record(c_copy, {
    map_id,             %% 副本地图ID
    copy_name,          %% 副本名称
    copy_type,          %% 副本类型,
    copy_degree,        %% 副本难度
    start_countdown=0,  %% 副本开始倒计时
    success_type,       %% 完成副本类型
    success_args,       %% 完成副本参数
    stars_type,         %% 星级类型
    stars_args,         %% 星级参数
    exist_time,         %% 副本存在时间
    enter_time,         %% 副本可进入时间
    times_type,         %% 副本扣除次数类型
    times,              %% 每日副本进入次数
    cd,                 %% 副本CD
    cd_cost,            %% 清除CD需要的条件
    use_item,           %% 消耗道具[TypeID, Num]
    buy_times,          %% 可购买次数
    buy_gold_list,      %% 购买单价
    succ_end_time,      %% 跳结算间隔时间
    count_down,         %% 结束倒计时(秒)
    leave_map_id,       %% 离开地图ID
    leave_map_pos,      %% 离开地图坐标
    can_use_mount,      %% 是否可使用坐骑
    can_pk,             %% 是否可PK
    enter_level,        %% 进入等级
    need_props,         %% 需要属性
    need_confine_id,    %% 需要境界ID
    five_elements_reward,%% 五行副本奖励
    is_team_map,        %% 是否可组队
    role_num_limit,     %% 人数限制
    mission_limit,      %% 任务限制
    can_clean,          %% 是否可扫荡,
    clean_condition,    %% 扫荡条件
    clean_cost_item,    %% 扫荡消耗道具[TypeID, Num]
    base_rewards,       %% 基础奖励
    star_1_rewards,     %% 1星奖励
    star_1_drops,       %% 1星掉落奖励
    star_2_rewards,     %% 2星奖励
    star_2_drops,       %% 2星掉落奖励
    star_3_rewards,     %% 3星奖励
    star_3_drops,       %% 3星掉落奖励
    resource_reward     %% 资源找回奖励
}).

%% 经验副本刷怪
-record(c_copy_exp, {
    map_id,             %% 副本ID
    monster_num,        %% 每波刷怪数量
    interval,           %% 间隔时间
    pos                 %% 怪物坐标
}).

%% 心魔副本
-record(c_copy_evil, {
    map_id,             %% 副本ID
    monster_type_id,    %% 怪物ID
    pos,                %% 坐标
    mdir                %% 朝向
}).

%% 副本指引boss
-record(c_copy_guide_boss, {
    index_id,           %% IndexID
    monster_type_id,    %% 怪物ID
    pos,                %% 坐标
    drop_list,          %% 掉落组
    owner_reward        %% 归属奖励
}).

%% 怪物属性结构
-record(c_monster_wave, {
    level,              %% 等级
    monsters,           %% 怪物库
    max_hp = 0,         %% 生命
    attack = 0,         %% 攻击
    defence = 0,        %% 防御
    hit_rate = 0,       %% 命中
    miss = 0,           %% 闪避
    double = 0,         %% 暴击
    double_anti = 0,    %% 韧性
    min_exp = 0,        %% 最小经验
    max_exp = 0         %% 最大经验
}).

-record(c_copy_exp_cheer, {
    cheer_times,        %% 鼓舞次数
    asset_type,         %% 消耗货币类型
    asset_value         %% 消耗货币
}).

%% 按波次刷怪
-record(c_copy_wave, {
    wave_id,            %% 副本刷怪ID
    monster_type,       %% 怪物ID
    num,                %% 刷怪数量
    interval,           %% 出生间隔
    add_props,          %% 怪物强度
    pos                 %% 怪物坐标,string
}).

%% 爬塔副本刷怪表
-record(c_copy_tower, {
    map_id,             %% 副本ID
    monster_type,       %% 怪物ID
    num,                %% 刷怪数量
    pos,                %% 怪物坐标
    accept_rewards,     %% 领取奖励
    finish_rewards,     %% 通关奖励
    finish_box,         %% 爬塔通关宝箱ID
    daily_rewards,      %% 日常奖励
    box_id,             %% 宝箱ID
    rune_essence,       %% 寻宝【魂晶】获得
    activity_box_id     %% 活动符文宝箱
}).

%% 单人副本TD刷怪表
-record(c_copy_single_td, {
    wave_id,            %% 副本刷怪ID
    area_1,             %% 区域1
    area_2,             %% 区域2
    area_3,             %% 区域3
    target_pos,         %% 目标坐标
    need_remain_num,    %% 下一波出怪阈值
    defenders           %% 护卫
}).

%% 妖魔岭刷怪
-record(c_copy_demon, {
    id,                 %% ID
    type_id,            %% 怪物ID
    num,                %% 怪物数量
    pos,                %% 怪物坐标
    buff_list           %% 加成的buff
}).

%% 鬼王殿刷怪
-record(c_copy_ghost, {
    map_id,             %% 地图ID
    ghost_id,           %% 鬼王ID
    pos,                %% 鬼王坐标
    hp_list,            %% 低于血量召唤
    summon_monsters     %% 召唤怪物
}).

%% 个人boss
-record(c_copy_world_boss, {
    map_id,             %% 副本刷怪ID
    monster_type,       %% 怪物ID
    num,                %% 刷怪数量
    pos                 %% 怪物坐标,string
}).

%% 仙魂副本刷怪
-record(c_copy_immortal_wave, {
    wave,               %% 波数
    min_level,          %% 最小等级
    max_level,          %% 最大等级
    monster,            %% 怪物
    boss_type_id,       %% boss
    summon_boss,        %% 召唤boss
    interval,           %% 间隔
    need_remain_num     %% 下一波出怪阈值
}).

%% 仙魂技能表
-record(c_copy_immortal_skill, {
    skill_id,           %% 技能ID
    buff_id,            %% buffID
    use_times,          %% 使用次数
    cd                  %% 使用CD时间
}).

%% 仙魂技能表
-record(c_copy_immortal_star, {
    level,              %% 等级
    base_rewards,       %% 基础奖励
    star_1_rewards,     %% 1星奖励
    star_2_rewards,     %% 2星奖励
    star_3_rewards      %% 3星奖励
}).

%% 仙侣副本刷怪
-record(c_copy_marry_monster, {
    id,         %% 波次ID
    type_id,    %% 怪物ID
    num,        %% 数量
    pos_1,      %% 坐标1
    pos_2       %% 坐标2
}).

%% 副本复活
-record(c_copy_relive, {
    copy_type,          %% 副本类型
    times,              %% 原地复活次数
    is_normal_relive,   %% 回起点复活
    relive_fee_cd,      %% 原地复活时间
    relive_fee          %% 原地复活消耗元宝
}).

%% 五行幻境
-record(c_five_elements_floor, {
    floor,              %% 层数
    name,               %% 名称
    need_list,          %% 突破幻境需求
    max_illusion,       %% 幻力上限
    illusion_min,       %% 幻力获得速度
    max_nat_intensify,  %% 勾玉上限
    nat_intensify_min   %% 勾玉获得速度
}).

%% 五行幻境关卡
-record(c_five_elements_detail, {
    copy_id,            %% 副本ID
    floor,              %% 副本层数
    name,               %% 关卡名称
    first_reward,       %% 首通奖励
    fist_drop_list,     %% 首通概率奖励
    need_world_level,   %% 世界等级
    normal_reward1,     %% 普通奖励1
    normal_reward2,     %% 普通奖励2
    need_illusion,      %% 挑战消耗幻力
    is_big_floor,       %% 是否大关
    step_num,           %% 关数
    monster_type_id,    %% 怪物Id
    monster_pos,        %% 怪物坐标
    monster_num         %% 怪物数量
}).

%% 太虚通天塔
-record(c_copy_universe, {
    copy_id,            %% 副本ID
    monster_type_id,    %% 怪物ID
    monster_num,        %% 刷怪数量
    monster_pos,        %% 怪物坐标
    monster_dir,        %% 怪物角度
    power               %% 战力
}).
-endif.
