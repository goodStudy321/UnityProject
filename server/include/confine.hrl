%%%-------------------------------------------------------------------
%%% @author WZP
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. 十二月 2018 16:38
%%%-------------------------------------------------------------------
-author("WZP").


-ifndef(CONFINE_HRL).
-define(CONFINE_HRL, confine_hrl).

-define(CONFINE_CLEAN, 1).       %%清除任务

-define(CONFINE_ACC_TYPE, 1).                %%正向累计计算类型  第二参数相等
-define(CONFINE_ACC_TYPE_I, 4).              %%正向累计计算类型  第二参数可以大可等
-define(CONFINE_MAX_TYPE, 2).                %%正向非累计计算类型 取最大值
-define(CONFINE_MAX_TYPE_I, 5).              %%正向非累计计算类型 第二参数可以大可等
-define(CONFINE_REVERSE_MAX_TYPE, 3).        %%反向非累计计算类型 取最大值


-define(CONFINE_UP_ITEM_ONE, 105).                %%飞仙
-define(CONFINE_UP_ITEM_TWO, 106).                %%升仙令牌
-define(CONFINE_UP_ITEM_THREE, 117).              %%渡劫丹   %% 19.5.10最新消耗


-define(CONFINE_CHECK_WHEN_NEW, 1).                %%创建任务时马上检查


-define(CONFINE_INIT_ID, 1000).

-define(WAR_SPIRIT_UP_ITEM, 30402).   %%战灵丹

%% 境界
-record(c_confine, {
    id,                    %% 境界ID
    name,                  %% 境界名称
    skill,                 %% 技能
    skill_book,            %% 技能书
    skill_book_show,       %% 技能展示
    item,                  %% 渡劫丹
    attack,                %% 攻击属性
    hp,                    %% 生命值
    defence,               %% 防御
    hurt_rate,             %% 对应伤害加深 - 加伤（万分比）
    hurt_derate,           %% 对应伤害减免 - 减伤（万分比）
    arp,                   %% 破甲
    open_war_spirit,
    map_id
}).


%% 渡劫任务
-record(c_confine_mission, {
    id,                     %% 任务ID
    check_type,             %% 任务进度检查类型
    acc_type,               %% 累计类型
    confine,                %% 开启境界
    complete_type,          %% 完成类型
    complete_param,         %% 完成参数
    reward                  %% 奖励
}).

-record(c_war_spirit_base, {
    war_spirit_id,          %% 战灵ID
    war_spirit_name,        %% 战灵名称
    equip_quality_limit_string,
%%    equip_quality_limit,    %% 灵饰品质上限
    armor_open_list,         %% 装备孔开启境界
    consume_goods        %% 装备孔开启道具
}).


%% 战灵升级
-record(c_war_spirit_up, {
    id,                     %% 序列ID
    war_spirit_id,          %% 战灵ID
    level,                  %% 等级
    exp,                    %% 升级经验
    hp,                     %% 生命
    attack,                 %% 攻击
    defence,                %% 防御
    arp,                    %% 破甲
    rate_attack,            %% 攻击加成
    skill,                  %% 技能
    open_confine            %% 解锁境界
}).

%%渡劫任务 开启触发
-define(CONFINE_BEFORE_OPEN_MISSION, 1).             %%前置任务完成开启
-define(CONFINE_SYSTEM_OPEN_MISSION, 2).             %%系统开启开启
-define(CONFINE_UP_OPEN_MISSION, 3).                 %%境界提升开启


%%渡劫任务 完成触发

-define(CONFINE_COMPLETE_GOD_WEAPON, 101001).            %%101001 神兵等级
-define(CONFINE_COMPLETE_MAGIC_WEAPON, 102001).          %%102001 宝物等级
-define(CONFINE_COMPLETE_WING, 103001).                  %%103001 翅膀等级
-define(CONFINE_COMPLETE_MOUNT, 104001).                 %%104001 坐骑阶数
-define(CONFINE_COMPLETE_PET, 105001).                   %%105001 宠物阶数
-define(CONFINE_COMPLETE_PET_I, 106001).                 %%105001 宠物等级
-define(CONFINE_COMPLETE_EQUIP_REFINE, 201001).          %%201001 装备强化总等级
-define(CONFINE_COMPLETE_EQUIP_STONE1, 202001).          %%202001 攻击宝石总等级
-define(CONFINE_COMPLETE_EQUIP_STONE2, 203001).          %%203001 生命宝石总等级
-define(CONFINE_COMPLETE_EQUIP_STONE_LEVEL, 204001).     %%204001 X  Y级
-define(CONFINE_COMPLETE_ZHUXIAN, 23213104001).          %%204001 穿戴 X 件诛仙套装
-define(CONFINE_COMPLETE_ZHUSHENG, 205001).              %%205001 穿戴 X 件诛神套装
-define(CONFINE_COMPLETE_PAGODA, 401001).                %%401001 通天塔通过 X 层
-define(CONFINE_COMPLETE_YARD, 402001).                  %%402001 完成青竹庭院 X 次
-define(CONFINE_COMPLETE_RUINS, 403001).                 %%403001 完成失落遗迹 X 次
-define(CONFINE_COMPLETE_VAULT, 405001).                 %%405001 完成邪龙金库 X 次
-define(CONFINE_COMPLETE_FOREST, 407001).                %%407001 完成幽魂石林 X 次
-define(CONFINE_COMPLETE_EQUIP_COPY, 408001).            %%408001 完成装备副本 X 次
-define(CONFINE_COMPLETE_RUNE_LEVEL, 301001).            %%301001 符文总等级
-define(CONFINE_COMPLETE_RUNE, 302001).                  %%302001 镶嵌 X 颗 Y 品质符文
-define(CONFINE_COMPLETE_EQUIP_COPY_FIRST, 409001).      %%409001 甲级通过 X 装备（副本ID）副本
-define(CONFINE_COMPLETE_RUINS_FIRST, 404001).           %%404001 甲级通过第 X 星的失落遗迹副本
-define(CONFINE_COMPLETE_VAULT_FIRST, 406001).           %%406001 甲级通过第 X 星的邪龙金库副本
-define(CONFINE_COMPLETE_BOSS, 601001).                  %%601001 消灭 X 级以上Boss Y
-define(CONFINE_COMPLETE_MONSTER, 602001).               %%602001 消灭 X 只以上怪物 Y
-define(CONFINE_COMPLETE_OFFLINE_SOLO, 501001).          %%501001 完成决战瑶台 X 次
-define(CONFINE_COMPLETE_OFFLINE_SOLO_RANK, 502001).     %%502001 决战瑶台进入前 X 名
-define(CONFINE_COMPLETE_SOLE, 503001).                  %%503001 仙峰论剑达到 X 段位
-define(CONFINE_COMPLETE_SOLE_RANK, 504001).             %%504001 参加仙峰论剑 X 次
-define(CONFINE_COMPLETE_ANSWER_RANK, 505001).           %%505001 仙峰论道达到 X 名
-define(CONFINE_COMPLETE_BATTLE, 506001).                %%506001 参与诛仙战场 X 次
-define(CONFINE_COMPLETE_FAMILY_TD, 701001).             %%701001 参与守卫仙盟 X 次
-define(CONFINE_COMPLETE_FAMILY_ANSWER, 702001).         %%702001 参与仙盟宴会 X 次
-define(CONFINE_COMPLETE_FAMILY_BOSS, 703001).           %%703001 参与讨伐仙盟Boss X 次
-define(CONFINE_COMPLETE_FAMILY_BT, 704001).             %%704001 参与仙盟战 X 次
-define(CONFINE_COMPLETE_LEVEL, 801001).                 %%801001 等级
-define(CONFINE_COMPLETE_POWER, 802001).                 %%802001 战力
%%-define(CONFINE_COMPLETE_CHAPTER, 803001).             %%803001 章节任务

-define(CONFINE_COMPLETE_MAIN_MISSION, 507001).              %%507001 主线任务
-define(CONFINE_COMPLETE_LEARN_SKILL, 508001).               %%508001 学X个技能
-define(CONFINE_COMPLETE_UP_SKILL, 509001).                  %%508002 升级X个技能
-define(CONFINE_COMPLETE_OFFLINE_SOLO_WIN, 510001).          %%502001 决战瑶台进入赢 X 次

-define(CONFINE_COMPLETE_EQUIP_ONE, 206001).                 %%穿戴X件Y阶蓝色以上装备
-define(CONFINE_COMPLETE_EQUIP_TWO, 207001).                 %%穿戴X件Y阶紫色以上装备
-define(CONFINE_COMPLETE_EQUIP_THREE, 208001).               %%穿戴X件Y阶橙色以上装备
-define(CONFINE_COMPLETE_EQUIP_FOUR, 209001).                %%穿戴X件Y阶橙色2星以上装备
-define(CONFINE_COMPLETE_EQUIP_FIVE, 210001).                %%穿戴X件Y阶红色以上装备
-define(CONFINE_COMPLETE_EQUIP_SIX, 211001).                 %%穿戴X件Y阶红色2星以上装备

-define(CONFINE_COMPLETE_EQUIP_SEVEN, 212001).                 %%激活x件y阶以上雷劫套装
-define(CONFINE_COMPLETE_EQUIP_EIGHT, 213001).                 %%激活x件y阶以上雷霆套装
-define(CONFINE_COMPLETE_EQUIP_NINE, 214001).                  %%激活x件y阶以上阳炎套装
-define(CONFINE_COMPLETE_EQUIP_TEM, 215001).                   %%激活x件y阶以上阳元套装
-define(CONFINE_COMPLETE_FRIEND, 803001).                      %% X个朋友

-define(CONFINE_COMPLETE_IMMORTAL_SOUL_O, 216001).                      %% 装备x个橙色及以上仙魂
-define(CONFINE_COMPLETE_IMMORTAL_SOUL_R, 217001).                      %% 装备x个红色及以上仙魂
-define(CONFINE_COMPLETE_LOOK_XLFB, 804001).                            %% 查看仙侣副本

-define(CONFINE_COMPLETE_FAMILY_MISSION, 706001).                       %% 完成X道庭任务
-define(CONFINE_COMPLETE_FAMILY_ESCORT, 705001).                        %% 完成X次道庭护送
-define(CONFINE_COMPLETE_BOX_COLOR, 707001).                            %%  X宝箱Y颜色

-define(CONFINE_COMPLETE_XILIAN, 805001).                               %% 装备洗连
-define(CONFINE_FIVE_ELEMENTS, 410001).                               %% 通关五行幻境X


%%辅助列表
-define(CONFINE_COMPLETE_EQUIP_LIST, [{5, 2, ?CONFINE_COMPLETE_EQUIP_SIX}, {5, 0, ?CONFINE_COMPLETE_EQUIP_FIVE}, {4, 2, ?CONFINE_COMPLETE_EQUIP_FOUR},
                                      {4, 0, ?CONFINE_COMPLETE_EQUIP_THREE}, {3, 0, ?CONFINE_COMPLETE_EQUIP_TWO}, {2, 0, ?CONFINE_COMPLETE_EQUIP_ONE}]).


%% 战灵灵饰表
-record(c_war_spirit_equip_info, {
    type_id,                %% 装备ID
    name,                   %% 装备名称
    index,                  %% 部位
    quality,                %% 品质
    step,                   %% 阶级
    star,                   %% 星级
    refine_num,             %% 强化上限
    step_item,              %% 升阶消耗
    decompose_exp,          %% 分解经验
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_defence,            %% 防御
    add_arp,                %% 破甲
    blue_props_num,         %% 蓝色属性数量
    blue_prop_id,           %% 蓝色属性组ID
    purple_props_num,       %% 紫色属性数量
    purple_prop_id,         %% 紫色属性组ID
    high_purple_props_num,  %% 高级紫色属性数量
    high_purple_prop_id,    %% 紫色属性组ID
    suit_id_list            %% 套装组id列表
}).

%% 战灵灵饰极品属性表
-record(c_war_spirit_equip_excellent, {
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

%% 战灵灵饰极强化表
-record(c_war_spirit_equip_refine, {
    refine_level,       %% 强化等级
    reduce_exp,         %% 扣除exp
    need_exp,           %% 强化经验
    all_exp,            %% 强化经验累计值
    add_hp,             %% 生命累计值
    add_attack,         %% 攻击累计值
    add_defence,        %% 防御累计值
    add_arp             %% 破甲累计值
}).

%% 战灵灵饰极套装表
-record(c_war_spirit_equip_suit, {
    suit_id,            %% 套装分类
    spirit_list,        %% 战灵归属
    desc,               %% 备注
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp             %% 破甲
}).

%% 战神套装基础表
-record(c_war_god_base, {
    war_god_id,         %% 战神套装ID
    war_god_name,       %% 战神套装明朝
    equip_1,            %% 武器部件ID
    equip_1_condition,  %% 武器激活条件
    equip_2,            %% 背饰部件ID
    equip_2_condition,  %% 背饰激活条件
    equip_3,            %% 上衣部件ID
    equip_3_condition,  %% 上衣激活条件
    equip_4,            %% 下衣部件ID
    equip_4_condition,  %% 下衣激活条件
    add_hp,             %% 生命累计值
    add_attack,         %% 攻击累计值
    add_defence,        %% 防御累计值
    add_arp,            %% 破甲累计值
    replace_skill_id    %% 替换技能ID
}).

%% 战神套装开光表
-record(c_war_god_refine, {
    equip_id,           %% 部件ID
    refine_level,       %% 开光品阶
    need_exp,           %% 开光次数
    need_score,         %% 开光消耗
    refine_multi,       %% 开光暴击
    add_hp,             %% 生命累计值
    add_attack,         %% 攻击累计值
    add_defence,        %% 防御累计值
    add_arp             %% 破甲累计值
}).
-endif.


