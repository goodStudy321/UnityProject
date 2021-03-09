%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. 五月 2017 10:00
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(MONSTER_HRL).
-define(MONSTER_HRL, monster_hrl).
-include("global.hrl").

-define(MONSTER_RETURN(Counter, MonsterData), erlang:throw({ok, Counter, MonsterData})).
-define(MONSTER_BORN_ONCE, 1). %% 只存在一次
-define(MONSTER_REBORN, 2). %% 死后会复活

-define(FIGHT_TYPE_PASSIVE, 1). %% 被动怪
-define(FIGHT_TYPE_ACTIVE,  2). %% 主动怪
-define(FIGHT_TYPE_PATROL,  3). %% 巡逻怪

-define(MONSTER_STATE_BORN, 1).     %% 怪物出生状态
-define(MONSTER_STATE_GUARD, 2).    %% 怪物守护状态
-define(MONSTER_STATE_PATROL, 3).   %% 怪物巡逻状态
-define(MONSTER_STATE_FIGHT, 4).    %% 怪物战斗状态
-define(MONSTER_STATE_RETURN, 5).   %% 怪物回归状态
-define(MONSTER_STATE_TD, 6).       %% 怪物TD前进状态

%%怪物珍惜度类型  1普通怪，2精英，3普通Boss 4世界Boss 5仙盟Boss 6 个人BOSS
-define(MONSTER_RARITY_NORMAL, 1).
-define(MONSTER_RARITY_ELITE, 2).
-define(MONSTER_RARITY_BOSS, 3).
-define(MONSTER_RARITY_WORLD_BOSS, 4).
-define(MONSTER_RARITY_FAMILY_GOD_BEAST, 5).
-define(MONSTER_RARITY_PERSON_BOSS, 6).

-define(MONSTER_SINGLE_COPY, 1). %% 单人副本类型的怪物

-define(SINGLE_AI_STOP, 1).     %% 停止loop
-define(SINGLE_AI_START, 2).    %% 继续loop
-define(SINGLE_AI_MOVE, 3).     %% 移动AI
-define(SINGLE_AI_DEAD, 4).     %% 死亡
-define(SINGLE_AI_ATTACK, 5).   %% 攻击锁定

-define(DROP_OWNER_FIRST, 1).       %% 首刀
-define(DROP_OWNER_SHARE, 2).       %% 共享
-define(DROP_OWNER_WORLD_BOSS, 3).  %% 世界boss掉落

-define(HURT_OWNER_ROLE, 1).        %% 归属于个人
-define(HURT_OWNER_TEAM, 2).        %% 归属于队伍
-define(HURT_OWNER_ROLES, 3).       %% 归属于特定人群

-define(WORLD_BOSS_INTERVAL, 10).   %% 10秒后清空伤害
-define(WORLD_BOSS_RECOVER_MS, 10 * 1000).      %% 10秒恢复一次hp

-define(IS_HATRED(IsHatred), (IsHatred > 0)).   %% 是嘲讽怪
-define(IS_SILVER(IsSilver), (IsSilver > 0)).   %% 金钱怪

-define(SILVER_DROP_TIME, 3).   %% 3秒掉落一次
-define(SILVER_DROP_PIECES, 20).%% 掉落分20份


%% 动态刷怪相关
-define(IS_COPY_EXP_MONSTER(IsCopyExp), (IsCopyExp =:= 1)).

-record(r_monster, {
    monster_id,
    monster_name,       %% monster_name
    type_id,            %% type_id
    seq_id,             %% 序列id
    state,              %% 状态
    buff_status=0,      %% buff状态
    next_counter=0,     %% 下一次可执行的counter
    level=0,            %% 等级
    add_exp=0,          %% 杀死后获得的经验
    attack_speed,       %% 攻击速度
    attacked_counter=0, %% 上次被攻击的counter
    camp_id=0,          %% 阵营ID
    born_pos,           %% #r_pos{}出生位置
    last_patrol_time=0, %% 上次巡逻时间
    last_skill=0,       %% 上次释放的技能
    last_skill_time=0,  %% 上次释放技能的时间 ms
    last_attack_time=0, %% 上次攻击的时间 ms
    add_props = 0,      %% 基础属性加强百分比
    last_dest_pos,      %% 上次要抵达的目标点
    patrol_pos,         %% 下一个巡逻的目标点 #r_pos{}
    action_string="",   %% 前端用到的动画参数
    attack_pos=#r_pos{},%% 攻击的位置
    fight_args = [],    %% [Fight|...]
    base_attr,          %% 基础属性
    attr,               %% #actor_fight_attr{}
    owner,              %% 怪物归属r_hurt_owner
    battle_owner=0,     %% 出生时怪物归属于的阵营
    td_index=0,         %% TD的位置信息 (各个场景用到的这个index不一样，仙魂里是守卫index，神兽岛是精英怪物的Index)
    world_boss,         %% 世界boss怪用到的字段 记录恢复时间 与 伤害列表用来计算归属
    attack_list=[],     %% 部分场景的怪物，用来记录谁攻击过
    skill_list=[],      %% [#p_skill{}]
    return_list=[],     %% 回归列表[#r_monster_path{}|...]
    td_pos_list=[],     %% td副本的坐标列表
    walk_path=[],       %% 走路路径
    first_enemies=[],   %% 一级仇恨列表
    second_enemies=[],  %% 二级仇恨列表
    born_time=0,        %% 出生时间
    buffs=[],           %% buff
    debuffs=[]          %% debuff
}).

%% 配置表结构
-record(c_monster,{
    type_id,                %% 怪物类型ID
    monster_name,           %% 怪物名字
    fight_type,             %% 战斗类型
    level=0,                %% 等级
    skill_list=[],          %% 技能列表
    rarity=0,               %% 怪物类型
    drop_type=0,            %% 掉落类型
    first_drop=0,           %% 首次掉落
    camp_id=0,              %% 阵营
    single_type,            %% 单人剧情怪 0不是 1是
    guard_radius,           %% 警戒范围 cm
    active_radius,          %% 活动范围 cm
    patrol_range=0,         %% 巡逻半径 cm
    patrol_cd,              %% 巡逻cd时间(单位：秒）
    owner_type,             %% 怪物归属
    special_drop_id = 0,    %% 特殊掉落组
    drop_id_list,           %% 死亡掉落
    add_exp,                %% 增加经验
    born_delay,             %% 出生时间
    is_hatred = 0,          %% 是否吸引怪物仇恨
    silver_drop = 0,        %% 伤害掉落铜钱
    not_around = 0,         %% 不包围目标
    cost_time = 0,          %% 扣除停留时间

%% 下面这些需要保存在r_monster（可能会发生变化）
    move_speed,             %% 移动速度
    attack_speed,           %% 攻击速度
    max_hp = 0,             %% 最大血量
    attack = 0,             %% 攻击
    defence = 0,            %% 防御
    arp = 0,                %% 破甲
    hit_rate = 0,           %% 命中
    miss = 0,               %% 闪避
    double = 0,             %% 暴击
    double_anti = 0,        %% 韧性
    double_multi = 0,       %% 暴击伤害
    double_multi_anti,      %% 暴伤减免
    hurt_rate = 0,          %% 伤害加深（万分比）
    hurt_derate = 0,        %% 伤害减免（万分比）
    strike = 0,             %% 会心一击（万分比）
    strike_anti = 0,        %% 会心抵抗（万分比）
    block = 0,              %% 格挡几率（万分比）
    block_anti = 0,         %% 抵抗格挡（万分比）
    defy_defence = 0,       %% 无视防御
    defy_defence_anti = 0,  %% 无视防御抵抗
    metal_anti = 0,         %%
    wood_anti = 0,
    water_anti = 0,
    fire_anti = 0,
    earth_anti = 0,
    min_reduce_rate,        %% 扣血下限
    max_reduce_rate,        %% 扣血上限
    attack_limit_level,     %% 攻击等级上限
    level_suppress,         %% 等级压制
    power_suppress          %% 战力压制
}).

%% 怪物动态计算
-record(c_dynamic_calc, {
    type_id,        %% 怪物ID
    desc,           %% 描述
    is_copy_exp,    %% 是否九幽
    start_level,    %% 开始等级
    end_level,      %% 结束等级
    hp_args,        %% 怪物生命参数
    life_time,      %% 怪物生存时间
    attack_args,    %% 怪物攻击参数
    dps_multi,      %% 怪物dps倍数
    attack_time,    %% 怪物攻击时间
    exp_multi       %% 经验倍数
}).


-record(c_monster_path, {id, path_list}).

-record(r_monster_enemy, {actor_id = 0, total_hurt = 0, last_att_time=0, is_hatred = false}).

-record(r_monster_path, {pos, use_time, delay_counter}).

-record(r_monster_skill, {skill_id=0, skill_type=0, time=0}).

%% type         --- 归属者类型 个人、队伍
%% type_args    --- 归属者参数 个人ID、队伍ID
%% world_boss_owner --- 世界boss专用
-record(r_hurt_owner, {type, type_args, world_boss_owner}).

%% 世界boss归属与角色伤害集合
-record(r_monster_world_boss, {recover_time=0, role_hurt_list = []}).
-record(r_role_hurt, {role_id, role_name="", role_level=0, hurt_hp = 0, last_attack_time = 0, team_id = 0, family_id = 0}).

-record(r_monster_silver, {monster_id, drop_time, drop_silver}).

%% 怪物死亡时回调的参数
-record(r_monster_dead, {td_index}).

%% 怪物被攻击时参数
-record(r_monster_attack, {src_id, src_type, last_attack_time=0, attack_hp=0}).

-endif.
