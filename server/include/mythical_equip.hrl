%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2019, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. 一月 2019 16:25
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(MYTHICAL_EQUIP_HRL).
-define(MYTHICAL_EQUIP_HRL, mythical_equip_hrl).

-define(MAX_MYTHICAL_EQUIP_NUM, 5).     %% 神兽装备最大数量

-define(MAX_MYTHICAL_BAG_NUM, 500).     %% 背包最大个数

-define(MYTHICAL_STATUS_NOT, 0).    %% 未激活
-define(MYTHICAL_STATUS_CAN, 1).    %% 可以激活
-define(MYTHICAL_STATUS_ACTIVE, 2). %% 已经激活

-define(PROP_TYPE_SELF, 1).     %% 自身加成
-define(PROP_TYPE_ALL, 2).      %% 所有加成

%% 神兽基础表
-record(c_mythical_equip_base, {
    soul_id,        %% 神兽ID
    soul_name,      %% 神兽名称
    level,          %% 显示等级
    props,          %% 基础属性
    base_add1,      %% 神兽基础加成技能1
    base_add2,      %% 神兽属性技能2
    skill_list,     %% 技能列表
    index_1,        %% 兽首装备
    index_2,        %% 旁肢装备
    index_3,        %% 元中装备
    index_4,        %% 定垂品质
    index_5         %% 偏足品质
}).

%% 神兽解锁表
-record(c_mythical_equip_unlock, {
    num,            %% 解锁数量
    level,          %% 解锁等级
    vip_level,      %% VIP等级
    item            %% 解锁消耗道具
}).

%% 神兽装备表
-record(c_mythical_equip_info, {
    type_id,            %% 装备ID
    name,               %% 装备名称
    index,              %% 部位
    quality,            %% 品质
    star,               %% 星级
    refine_num,         %% 强化次数
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    blue_props_num,     %% 蓝色属性数量
    blue_prop_id,       %% 蓝色属性组ID
    purple_props_num,   %% 紫色属性数量
    purple_prop_id,     %% 紫色属性组ID
    add_exp             %% 强化值
}).

%% 神兽极品属性表
-record(c_mythical_equip_excellent, {
    group_id,           %% 属性组ID
    desc,               %% 备注
    add_defence,        %% 防御加成
    add_hp,             %% 生命加成
    add_attack,         %% 攻击加成
    add_arp,            %% 破甲加成
    add_hit_rate,       %% 命中加成
    add_miss,           %% 闪避加成
    add_double,         %% 暴击加成
    add_double_anti,    %% 坚韧加成
    add_defence_rate,   %% 防御百分比
    add_hp_rate,        %% 生命百分比
    add_attack_rate,    %% 攻击百分比
    add_arp_rate,       %% 破甲加成
    add_hit_rate_rate,  %% 命中加成
    add_miss_rate,      %% 闪避加成
    add_double_rate,    %% 暴击加成
    add_double_anti_rate%% 坚韧加成
}).

%% 神兽强化表
-record(c_mythical_equip_refine, {
    refine_level,       %% 强化等级
    need_exp,           %% 强化经验
    all_exp,            %% 强化经验累计值
    add_hp,             %% 生命累计值
    add_attack,         %% 攻击累计值
    add_defence,        %% 防御累计值
    add_arp             %% 破甲累计值
}).
-endif.