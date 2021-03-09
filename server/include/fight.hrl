%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. 四月 2017 14:30
%%%-------------------------------------------------------------------
-author("laijichang").

-ifndef(FIGHT_HRL).
-define(FIGHT_HRL, fight_hrl).

%% 战斗相关宏定义
-define(MAX_TARGET_NUM, 20).

-define(TARGET_TYPE_ENEMY, 0).      %% 目标类型-敌方
-define(TARGET_TYPE_FRIEND, 1).     %% 目标类型-自己或者友方
-define(TARGET_TYPE_SELF, 2).       %% 目标类型-自己（只能是自己）
-define(TARGET_TYPE_ENEMY_ROLE, 4). %% 目标类型-敌方玩家

-define(EFFECT_TYPE_NORMAL_HIT, 1).         %% 普通攻击
-define(EFFECT_TYPE_CATCH, 2).              %% 拉取效果
-define(EFFECT_TYPE_BUFF, 3).               %% 加buff
-define(EFFECT_TYPE_SUMMON_TRAP, 4).        %% 召唤陷阱
-define(EFFECT_TYPE_PET_HIT, 5).            %% 宠物攻击
-define(EFFECT_TYPE_MAGIC_WEAPON_HIT, 6).   %% 法宝攻击
-define(EFFECT_TYPE_HIT_AGAIN, 7).          %% 再次攻击

-define(PROP_TYPE_NORMAL_HIT, 1).           %% 玩家攻击
-define(PROP_TYPE_NORMAL_BE_ATTACKED, 2).   %% 被玩家攻击
-define(PROP_TYPE_PET_HIT, 3).              %% 宠物攻击
-define(PROP_TYPE_DOUBLE_DIZZY_ROLE, 4).    %% 暴击时晕眩玩家
-define(PROP_TYPE_MAGIC_WEAPON_HIT, 5).     %% 法宝攻击
-define(PROP_TYPE_CONFINE_HIT, 6).          %% 战灵攻击
-define(PROP_TYPE_SELF_HP_BELOW, 7).        %% 玩家血量低于xx百分比
-define(PROP_TYPE_ADD_ROLE_ATTACK, 8).      %% 玩家普通攻击伤害技能伤害系数增加
-define(PROP_TYPE_REDUCE_HP_ONCE, 9).       %% 玩家单次受到伤害超过xx
-define(PROP_TYPE_SELF_HP_UP, 10).          %% 玩家血量高于

%%
-define(MAP_PROP_EFFECT_UNDEAD, 1).         %% 不死
-define(MAP_PROP_FIVE_REDUCE, 2).           %% 5次攻击，下一次伤害降低35%
-define(MAP_PROP_FIVE_ATTACK, 3).           %% 5次攻击，下一次攻击有10%*lv几率暴击

-define(ATTACK_RESULT_MISS, 1).             %% 闪避
-define(ATTACK_RESULT_ATTACK, 2).           %% 受到攻击
-define(ATTACK_RESULT_ATTACK_FROM_ROLE, 3). %% 受到玩家攻击
-define(ATTACK_RESULT_ATTACK_ROLE, 4).      %% 攻击玩家

-define(DOUBLE_BASE_RATE, 2).   %% 暴击基本系数
-define(PET_ATTR_RATE, 0.1).    %% 宠物属性系数
-define(STRIKE_RATE, 5).        %% 会心系数
-define(BLOCK_RATE, 0.5).       %% 格挡系数

-define(MIN_LEVEL_RATE_REDUCE, -7000).  %% 最低伤害减免
-define(MAX_LEVEL_RATE_ADD, 7000).      %% 伤害加成

-define(SET_RESULT_REDUCE_HP(Result), (1 bor Result)).          %% 扣血
-define(SET_RESULT_MISS(Result), ((1 bsl 1) bor Result)).       %% 闪避
-define(SET_RESULT_DOUBLE(Result), ((1 bsl 2) bor Result)).     %% 暴击
-define(SET_RESULT_STRIKE(Result), ((1 bsl 3) bor Result)).     %% 会心
-define(SET_RESULT_BLOCK(Result), ((1 bsl 4) bor Result)).      %% 格挡
-define(SET_RESULT_ADD_HP(Result), ((1 bsl 5) bor Result)).     %% 加血
-define(SET_RESULT_SHIELD(Result), ((1 bsl 6) bor Result)).     %% 吸收


%% 技能相关宏定义
-define(SKILL_INFO_ONLINE, 0).  %% 上线推送
-define(SKILL_INFO_OPEN, 1).    %% 开启推送

-define(SKILL_ONE, 0).          %% 单体
-define(SKILL_SELF_RECT, 1).    %% 前方矩形
-define(SKILL_SELF_ROUND, 2).   %% 自身圆形
-define(SKILL_ENEMY_ROUND, 3).  %% 目标圆形

-define(SKILL_ATTACK, 0).           %% 普通攻击
-define(SKILL_NORMAL, 1).           %% 技能攻击
-define(SKILL_PASSIVE, 2).          %% 被动技能

%% 被动技能列表
-define(SKILL_PASSIVE_LIST, [?SKILL_PASSIVE_PROP, ?SKILL_PASSIVE_HIT_BUFF, ?SKILL_PASSIVE_ADD_BUFF,
    ?SKILL_PASSIVE_TEAM_BUFF, ?SKILL_PASSIVE_HIT_AGAIN, ?SKILL_PASSIVE_HP_BUFFS, ?SKILL_PASSIVE_HIT_PROP, ?SKILL_PASSIVE_ATTACK_RESULT,
    ?SKILL_PASSIVE_ATTACK_AGAIN, ?SKILL_PASSIVE_ADD_HIT_PROP, ?SKILL_PASSIVE_ADD_OTHER_PROP, ?SKILL_PASSIVE_MAP_PROP_EFFECT, ?SKILL_PASSIVE_HP_RATE_PROP,
    ?SKILL_PASSIVE_WAR_SPIRIT_BUFF, ?SKILL_PASSIVE_FIGHT_BUFF, ?SKILL_PASSIVE_ADD_HURT, ?SKILL_PASSIVE_ADD_TARGET_NUM, ?SKILL_PASSIVE_REDUCE_CD, ?SKILL_PASSIVE_BUFF_TRIGGER,
    ?SKILL_PASSIVE_ONLY_PROP]).
-define(SKILL_OTHER_PROP_LIST, [?ATTR_PET_ADD, ?ATTR_MOUNT_ADD, ?ATTR_WING_ADD, ?ATTR_MAGIC_WEAPON_ADD, ?ATTR_GOD_WEAPON_ADD]).

-define(SKILL_PASSIVE_PROP, 2).             %% 被动技能 -- 增加属性
-define(SKILL_PASSIVE_HIT_BUFF, 3).         %% 被动技能 -- 攻击触发buff
-define(SKILL_PASSIVE_ADD_BUFF, 4).         %% 被动技能 -- 循环触发buff
-define(SKILL_PASSIVE_TEAM_BUFF, 5).        %% 被动技能 -- 组队触发buff
-define(SKILL_PASSIVE_HIT_AGAIN, 6).        %% 被动技能 -- 再次攻击
-define(SKILL_PASSIVE_HP_BUFFS, 7).         %% 被动技能 -- 生命buff加成
-define(SKILL_PASSIVE_HIT_PROP, 8).         %% 被动技能 -- 攻击时根据条件加成属性
-define(SKILL_PASSIVE_ATTACK_RESULT, 9).    %% 被动技能 -- 攻击结果根据条件加buff
-define(SKILL_PASSIVE_ATTACK_AGAIN, 10).    %% 被动技能 -- 有特效的再次攻击
-define(SKILL_PASSIVE_ADD_HIT_PROP, 11).    %% 被动技能 -- 增强8技能的效果
-define(SKILL_PASSIVE_ADD_OTHER_PROP, 12).  %% 被动技能 -- 影响其他功能的属性
-define(SKILL_PASSIVE_MAP_PROP_EFFECT, 13). %% 被动技能 -- 场景特殊效果
-define(SKILL_PASSIVE_HP_RATE_PROP, 14).    %% 被动技能 -- 血量比例增加属性
-define(SKILL_PASSIVE_WAR_SPIRIT_BUFF, 15). %% 被动技能 -- 战灵召唤触发buff
-define(SKILL_PASSIVE_FIGHT_BUFF, 16).      %% 被动技能 -- 战斗触发buff
-define(SKILL_PASSIVE_ADD_HURT, 17).        %% 被动技能 -- 技能伤害增加
-define(SKILL_PASSIVE_ADD_TARGET_NUM, 18).  %% 被动技能 -- 攻击目标改变
-define(SKILL_PASSIVE_REDUCE_CD, 19).       %% 被动技能 -- 技能cd冷却
-define(SKILL_PASSIVE_BUFF_TRIGGER, 20).    %% 被动技能 -- buff触发
-define(SKILL_PASSIVE_ONLY_PROP, 21).       %% 被动技能 -- 只加属性，不加战力

-define(ADD_BUFF_HP, 1).            %% 生命低于一定条件
-define(ADD_BUFF_MONSTER_ATTACK, 2).%% 受到N个怪物攻击时触发

-define(GET_SKILL_FUN(SkillID), (SkillID div 1000000)).
-define(GET_SKILL_TYPE_ID(SkillID), (SkillID div 1000)).
-define(GET_SKILL_LEVEL(SkillID), (SkillID rem 1000)).

-define(SKILL_FUN_ROLE, 1).         %% 角色技能
-define(SKILL_FUN_MONSTER, 2).      %% 怪物技能
-define(SKILL_FUN_PET, 3).          %% 宠物技能
-define(SKILL_FUN_MOUNT, 4).        %% 坐骑技能
-define(SKILL_FUN_MAGIC, 5).        %% 法宝技能
-define(SKILL_FUN_WING, 6).         %% 翅膀技能
-define(SKILL_FUN_TRAP, 7).         %% 召唤体技能
-define(SKILL_FUN_GOD, 8).          %% 神兵技能
-define(SKILL_FUN_WAR_SPIRIT, 9).   %% 战灵攻击
-define(SKILL_FUN_MYTHICAL, 10).    %% 神兽技能
-define(SKILL_FUN_TALENT, 11).      %% 天赋技能
-define(SKILL_FUN_THRONE, 12).      %% 宝座技能
-define(SKILL_FUN_FASHION, 13).     %% 时装技能
-define(SKILL_FUN_NATURE, 14).      %% 天机技能
-define(SKILL_FUN_EQUIP_COLLECT, 15).      %% 装备收集技能

-define(SKILL_POWER_NOT, 0).            %% 不额外增加战力
-define(SKILL_POWER_NORMAL, 1).         %% 固定增加
-define(SKILL_POWER_DPS_RATE, 2).       %% 输出战力万分比
-define(SKILL_POWER_EHP_RATE, 3).       %% 生存战力万分比

%% 技能铭文相关
-define(SEAL_TYPE_POSITIVE, 1).     %% 纹印主动效果类型
-define(SEAL_TYPE_PASSIVE, 2).      %% 纹印被动效果类型

-define(GET_SEAL_BASE_ID(SealID), (SealID div 100)).    %% 获取纹印基础ID
-define(SEAL_BASE_DOUBLE, 10042).   %% 必定暴击的铭文

%% 铭文被动类型参数
-define(SEAL_PASSIVE_ATTACK, 1).        %% 被动子类型-攻击时有概率释放buff(跟下面攻击触发buff一致，预留扩展）
-define(SEAL_PASSIVE_BE_ATTACKED, 2).   %% 被动子类型-被攻击时有概率释放buff(跟下面攻击触发buff一致，预留扩展）
-define(SEAL_PASSIVE_INTERVAL_ADD, 3).  %% 被动子类型-间隔触发buff
-define(SEAL_PASSIVE_SKILL_PROP_ADD, 4).%% 风卷残云-属性加成
-define(SEAL_PASSIVE_REBOUND, 5).       %% 反伤

%% 技能战斗触发buff
-define(SKILL_FIGHT_BUFF_ROLE_DOUBLE, 1).       %% 对玩家造成暴击
-define(SKILL_FIGHT_BUFF_BE_ROLE_DOUBLE, 2).    %% 被玩家暴击
-define(SKILL_FIGHT_BUFF_BLOCK_RATE, 3).        %% 格挡，概率触发
-define(SKILL_FIGHT_BUFF_ROLE_BLOCK, 4).        %% 格挡玩家
-define(SKILL_FIGHT_BUFF_BLOCK_MONSTER, 5).     %% 格挡怪物
-define(SKILL_FIGHT_BUFF_SKILL_RELEASE, 6).     %% 对玩家释放技能
-define(SKILL_FIGHT_REDUCE_MAX_HP, 7).          %% 扣除生命上限
-define(SKILL_FIGHT_HIT_ENEMY, 8).              %% 命中敌人触发buff
-define(SKILL_FIGHT_BUFF_HP_BELOW, 9).          %% 生命低于特定万分比
-define(SKILL_FIGHT_BUFF_DIZZY_BE_ATTACKED, 10).%% 自身眩晕时触发

%% 攻击结果相关
-define(FIGHT_EFFECT_ATTACK, 1).        %% 攻击触发buff
-define(FIGHT_EFFECT_BE_ATTACKED, 2).   %% 受到攻击触发buff
-define(FIGHT_EFFECT_REBOUND, 3).       %% 反击
-define(FIGHT_EFFECT_MAX_HP, 4).        %% 扣除生命上限

-define(FIGHT_EFFECT_ATTACK_POISON, 1). %% 击中中毒敌人
-define(FIGHT_EFFECT_ATTACK_BURN, 2).   %% 击中燃烧敌人
-define(FIGHT_EFFECT_DOUBLE, 3).        %% 暴击
-define(FIGHT_EFFECT_ROLE_DOUBLE, 4).   %% 对玩家造成暴击
-define(FIGHT_EFFECT_RELEASE_SKILL, 5). %% 释放技能
-define(FIGHT_EFFECT_HIT_ENEMY, 6).     %% 命中敌人触发buff
-define(FIGHT_EFFECT_HP_BELOW, 7).      %% 生命低于特定万分比

-define(FIGHT_EFFECT_BE_ATTACKED_HP_RATE, 1).   %% 受到的单次伤害超过生命上限15%
-define(FIGHT_EFFECT_BE_ROLE_DOUBLE, 2).        %% 被玩家暴击
-define(FIGHT_EFFECT_BLOCK_RATE, 3).            %% 格挡，概率触发
-define(FIGHT_EFFECT_BLOCK_ROLE, 4).            %% 格挡玩家
-define(FIGHT_EFFECT_BLOCK_MONSTER, 5).         %% 格挡怪物
-define(FIGHT_EFFECT_DIZZY_BE_ATTACKED, 6).     %% 自身眩晕时触发

-define(FIGHT_EFFECT_ROLE_MAX_HP_REDUCE, 1).    %% 扣除玩家上限生命

-define(SEAL_PASSIVE_INTERVAL_BELOW_HP_RATE, 1).    %% 血量低于一定百分比

%% 被加buff触发参数
-define(BE_BUFF_DIZZY_RATE, 1).     %% 被加晕眩buff

-define(IS_BUFF(BuffType), (BuffType =:= 1)).  %% 增益buff
-define(IS_DEBUFF(BuffType), (BuffType =:= 2)). %% 减益buff
-define(IS_COEXIST(CoExist), (CoExist =:= 2)).  %% 同类型的buff是否可以共存

-define(MAX_BUFF_NUM, 50).      %% 最大增益buff数量
-define(MAX_DEBUFF_NUM, 10).    %% 最大减益buff数量

-define(ROLE_FIGHT_COMMON_CD, 50).  %% 2段攻击之间间隔最少50ms

%% 需要进行属性重算的buff
-define(BUFF_CALC_LIST, [?BUFF_PROP_CHANGE, ?BUFF_STEAL_PROP, ?BUFF_LIMIT_PROP]).
%% 需要进行状态重算的buff
-define(BUFF_STATUS_LIST, [?BUFF_UNBEATABLE, ?BUFF_IMPRISON, ?BUFF_DIZZY, ?BUFF_LIMIT_N_A, ?BUFF_LIMIT_S_A, ?BUFF_LIMIT_U_S,
    ?BUFF_LIMIT_ITEM, ?BUFF_LIMIT_MONSTER, ?BUFF_POISON, ?BUFF_BURN, ?BUFF_BE_ATTACKED_BUFF, ?BUFF_SLOW]).

%% 以buff配置里的buff类型为准
-define(BUFF_UNBEATABLE, 4).        %% 无敌
-define(BUFF_IMMUNE, 8).            %% 免疫特定类型的buff
-define(BUFF_POISON, 9).            %% 中毒
-define(BUFF_ADD_HP, 10).           %% 治疗
-define(BUFF_PROP_CHANGE, 11).      %% buff修改属性
-define(BUFF_DISPEL_BUFF, 13).      %% 驱除增益buff
-define(BUFF_DISPEL_DEBUFF, 14).    %% 驱除减益buff
-define(BUFF_SHIELD, 15).           %% 护盾buff
-define(BUFF_BURN, 17).             %% 燃烧
-define(BUFF_ATTACK_HEAL, 19).      %% 生命恢复（攻击力万分比）
-define(BUFF_BE_ATTACKED_BUFF, 20). %% 被击中是反击的buff
-define(BUFF_STEAL_PROP, 21).       %% 偷取属性
-define(BUFF_LEVEL_HP_BUFF, 22).    %% 按照等级恢复生命
-define(BUFF_LIMIT_PROP, 23).       %% 加属性加到特定上限
-define(BUFF_SLOW, 24).             %% 减速属性

-define(BUFF_IMPRISON, 30).      %% 禁锢
-define(BUFF_DIZZY, 31).         %% 眩晕
-define(BUFF_LIMIT_N_A, 32).     %% 限制普通攻击
-define(BUFF_LIMIT_S_A, 33).     %% 限制技能攻击
-define(BUFF_LIMIT_U_S, 34).     %% 限制必杀技
-define(BUFF_LIMIT_ITEM, 35).    %% 限制使用道具
-define(BUFF_LIMIT_MONSTER, 36). %% 不能攻击怪物

-define(BUFF_DOUBLE_DIZZY, 101002).     %% 暴击晕眩玩家
-define(BUFF_DIZZY_RATE, 101003).       %% 概率晕眩

%% buff移除方式
-define(IS_BUFF_REMOVE_DEAD(RemoveType), (RemoveType band 16#1 > 0)).                   %% 死亡解除
-define(IS_BUFF_REMOVE_MAP(RemoveType), ((RemoveType bsr 1) band 16#1 > 0)).            %% 切换场景解除(包括下线)
-define(IS_BUFF_REMOVE_FIGHT_STATUS(RemoveType), ((RemoveType bsr 2) band 16#1 > 0)).   %% 脱离战斗状态移除
-define(IS_BUFF_REMOVE_TEAM(RemoveType), ((RemoveType bsr 3) band 16#1 > 0)).           %% 脱离队伍移除
-define(IS_BUFF_SHIELD_REMOVE(RemoveType), ((RemoveType bsr 4) band 16#1 > 0)).         %% 护盾消失移除


-define(BUFF_OFFLINE_CLEAR, 1).     %% 下线就清除
-define(BUFF_OFFLINE_NOT_COUNT, 2). %% 下线不计时
-define(BUFF_OFFLINE_COUNT, 3).     %% 下线计时

-define(BUFF_PELLET_EXP, 204).      %% 经验药buff

%% Buff的简化数据,在场景中广播让别人看到的状态的BUF
-define(IS_BUFF_IMPRISON(BuffStatus), (BuffStatus band 16#1 > 0)).                           %% 定身
-define(IS_BUFF_DIZZY(BuffStatus), ((BuffStatus bsr 1) band 16#1 > 0)).                      %% 眩晕
-define(IS_BUFF_LIMIT_NORMAL_ATTACK(BuffStatus), ((BuffStatus bsr 2) band 16#1 > 0)).        %% 限制普通攻击
-define(IS_BUFF_LIMIT_SKILL_ATTACK(BuffStatus), ((BuffStatus bsr 3) band 16#1 > 0)).         %% 限制技能攻击
-define(IS_BUFF_LIMIT_UNIQUE_SKILL(BuffStatus), ((BuffStatus bsr 4) band 16#1 > 0)).         %% 限制必杀技
-define(IS_BUFF_LIMIT_USE_ITEM(BuffStatus), ((BuffStatus bsr 5) band 16#1 > 0)).             %% 限制使用道具
-define(IS_BUFF_LIMIT_ATTACK_MONSTER(BuffStatus), ((BuffStatus bsr 6) band 16#1 > 0)).       %% 不能攻击世界boss
-define(IS_BUFF_LIMIT_UNBEATABLE(BuffStatus), ((BuffStatus bsr 7) band 16#1 > 0)).           %% 无敌
-define(IS_BUFF_UNDEAD(BuffStatus), ((BuffStatus bsr 8) band 16#1 > 0)).                     %% 不死
-define(IS_BUFF_POISON(BuffStatus), ((BuffStatus bsr 9) band 16#1 > 0)).                     %% 中毒
-define(IS_BUFF_BURN(BuffStatus), ((BuffStatus bsr 10) band 16#1 > 0)).                      %% 燃烧
-define(IS_BUFF_BE_ATTACKED_BUFF(BuffStatus), ((BuffStatus bsr 11) band 16#1 > 0)).          %% 收到伤害反弹buff
-define(IS_BUFF_SLOW(BuffStatus), ((BuffStatus bsr 12) band 16#1 > 0)).                      %% 减速

%% 广播给前端的buff
-define(SET_BUFF_IMPRISON(BuffStatus), (1 bor BuffStatus)).                                   %% 定身
-define(SET_BUFF_DIZZY(BuffStatus), ((1 bsl 1) bor BuffStatus)).                              %% 眩晕
-define(SET_BUFF_LIMIT_NORMAL_ATTACK(BuffStatus), ((1 bsl 2) bor BuffStatus)).                %% 限制普通攻击
-define(SET_BUFF_LIMIT_SKILL_ATTACK(BuffStatus), ((1 bsl 3) bor BuffStatus)).                 %% 限制技能攻击
-define(SET_BUFF_LIMIT_UNIQUE_SKILL(BuffStatus), ((1 bsl 4) bor BuffStatus)).                 %% 限制必杀技
-define(SET_BUFF_LIMIT_USE_ITEM(BuffStatus), ((1 bsl 5) bor BuffStatus)).                     %% 限制使用道具
-define(SET_BUFF_LIMIT_ATTACK_MONSTER(BuffStatus), ((1 bsl 6) bor BuffStatus)).               %% 不能攻击怪物
-define(SET_BUFF_LIMIT_UNBEATABLE(BuffStatus), ((1 bsl 7) bor BuffStatus)).                   %% 无敌
-define(SET_BUFF_UNDEAD(BuffStatus), ((1 bsl 8) bor BuffStatus)).                             %% 不死
-define(SET_BUFF_POISON(BuffStatus), ((1 bsl 9) bor BuffStatus)).                             %% 中毒
-define(SET_BUFF_BURN(BuffStatus), ((1 bsl 10) bor BuffStatus)).                              %% 燃烧
-define(SET_BUFF_BE_ATTACKED_BUFF(BuffStatus), ((1 bsl 11) bor BuffStatus)).                  %% 受到伤害反弹buff
-define(SET_BUFF_SLOW(BuffStatus), ((1 bsl 12) bor BuffStatus)).                              %% 减速

%% 符文二级属性，依赖其他属性
-define(IS_RUNE_SECOND_PROP(PropID), (?ATTR_EQUIP_ARMOR_HP_RATE =< PropID andalso PropID =< ?ATTR_BASE_DEF_RATE)).

%% 属性编码
-define(ATTR_HP, 1).                        %% 生命
-define(ATTR_ATTACK, 2).                    %% 攻击
-define(ATTR_DEFENCE, 3).                   %% 防御
-define(ATTR_ARP, 4).                       %% 破甲
-define(ATTR_HIT_RATE, 5).                  %% 命中
-define(ATTR_MISS, 6).                      %% 闪避
-define(ATTR_DOUBLE, 7).                    %% 暴击
-define(ATTR_DOUBLE_ANTI, 8).               %% 韧性
-define(ATTR_DOUBLE_MULTI, 9).              %% 暴伤（万分比）
-define(ATTR_DOUBLE_MULTI_ANTI, 10).        %% 暴免（万分比）
-define(ATTR_HURT_RATE, 11).                %% 加伤（万分比）
-define(ATTR_HURT_DERATE, 12).              %% 减伤（万分比）
-define(ATTR_DOUBLE_RATE, 13).              %% 暴击几率
-define(ATTR_MISS_RATE, 14).                %% 闪避几率
-define(ATTR_DOUBLE_ANTI_RATE, 15).         %% 暴击抵抗
-define(ATTR_SKILL_HURT, 16).               %% 技能伤害增加
-define(ATTR_SKILL_HURT_ANTI, 17).          %% 技能伤害减少
-define(ATTR_RATE_ADD_HP, 18).              %% 生命增加万分比
-define(ATTR_RATE_ADD_ATTACK, 19).          %% 攻击增加万分比
-define(ATTR_RATE_ADD_DEFENCE, 20).         %% 防御增加万分比
-define(ATTR_RATE_ADD_ARP, 21).             %% 破甲增加万分比
-define(ATTR_RATE_ADD_HIT, 22).             %% 命中增加万分比
-define(ATTR_RATE_ADD_MISS, 23).            %% 闪避增加万分比
-define(ATTR_RATE_ADD_DOUBLE, 24).          %% 暴击增加万分比
-define(ATTR_RATE_ADD_DOUBLE_A, 25).        %% 韧性增加万分比
-define(ATTR_MONSTER_EXP, 26).              %% 怪物经验加成
-define(ATTR_MOVE_SPEED, 27).               %% 移动速度加成
-define(ATTR_ARMOR, 28).                    %% 护甲
-define(ATTR_EVERY_THREE_ATTACK, 29).       %% 每3级加攻击
-define(ATTR_EVERY_THREE_ARP, 30).          %% 每3级加破甲
-define(ATTR_EVERY_THREE_HP, 31).           %% 每3级加生命
-define(ATTR_EVERY_THREE_DEFENCE, 32).      %% 每3级加防御
-define(ATTR_SILVER_DROP, 33).              %% 铜钱掉落
-define(ATTR_ITEM_DROP, 34).                %% 物品掉落
-define(ATTR_PET_ADD, 35).                  %% 宠物总属性增加
-define(ATTR_MOUNT_ADD, 36).                %% 坐骑总属性增加
-define(ATTR_WING_ADD, 37).                 %% 翅膀总属性增加
-define(ATTR_MAGIC_WEAPON_ADD, 38).         %% 法宝总属性增加
-define(ATTR_GOD_WEAPON_ADD, 39).           %% 神兵总属性增加
-define(ATTR_EQUIP_ARMOR_HP_RATE, 40).      %% 防具生命万分比
-define(ATTR_EQUIP_ARMOR_DEF_RATE, 41).     %% 防具防御万分比
-define(ATTR_EQUIP_WEAPON_ATTACK_RATE, 42). %% 武器攻击万分比
-define(ATTR_EQUIP_WEAPON_ARP_RATE, 43).    %% 武器破甲万分比
-define(ATTR_EQUIP_GOD_ATTACK_RATE, 44).    %% 仙器攻击万分比
-define(ATTR_BASE_ATTACK_RATE, 45).         %% 基础攻击万分比
-define(ATTR_BASE_HP_RATE, 46).             %% 基础生命万分比
-define(ATTR_BASE_ARP_RATE, 47).            %% 基础破甲万分比
-define(ATTR_BASE_DEF_RATE, 48).            %% 基础防御万分比
-define(ATTR_ROLE_HURT_REDUCE, 49).         %% pvp伤害减免
-define(ATTR_BOSS_HURT_ADD, 50).            %% boss伤害加深
-define(ATTR_EVERY_TEN_ATTACK, 51).         %% 每级加N点攻击
-define(ATTR_EVERY_FIFTY_BOSS_HURT, 52).    %% 每50级boss伤害增加1%
-define(ATTR_REBOUND, 53).                  %% 伤害反弹属性
-define(ATTR_MONSTER_HURT_ADD, 54).         %% 怪物伤害增加
-define(ATTR_MOVE_SPEED_RATE, 55).          %% 移动速度万分比加成
-define(ATTR_IMPRISON_HURT_ADD, 56).        %% 定身 + 晕眩伤害加成
-define(ATTR_SILENT_HURT_ADD, 57).          %% 沉默 + 晕眩伤害加成
-define(ATTR_DIZZY_RATE, 58).               %% 眩晕万分比
-define(ATTR_EQUIP_REFINE_ADD, 59).         %% 装备强化加成
-define(ATTR_LEVEL_RECOVER_HP, 60).         %% 每秒回血
-define(ATTR_LEVEL_RECOVER_HP_RATE, 61).    %% 回血最大血量万分比
-define(ATTR_EQUIP_BASE_RATE, 62).          %% 装备基础属性万分比
-define(ATTR_WAR_GOD_SUIT, 63).             %% 战神套装属性万分比
-define(ATTR_DOUBLE_MISS_RATE, 64).         %% 二次闪避概率
-define(ATTR_DOUBLE_DAMAGE_RATE, 65).       %% 二次伤害概率
-define(ATTR_POISON_HURT_ADD, 66).          %% 中毒伤害加成
-define(ATTR_BURN_HURT_ADD, 67).            %% 燃烧伤害加成
-define(ATTR_BOSS_HURT_REDUCE, 68).         %% Boss伤害降低
-define(ATTR_DRAIN, 69).                    %% 攻击力吸血
-define(ATTR_WAR_SPIRIT_TIME, 70).          %% 战灵持续时长（毫秒）
-define(ATTR_METAL, 71).                    %% 金攻
-define(ATTR_WOOD, 72).                     %% 木攻
-define(ATTR_WATER, 73).                    %% 水攻
-define(ATTR_FIRE, 74).                     %% 火攻
-define(ATTR_EARTH, 75).                    %% 土攻
-define(ATTR_METAL_ANTI, 76).               %% 金抗
-define(ATTR_WOOD_ANTI, 77).                %% 木抗
-define(ATTR_WATER_ANTI, 78).               %% 水抗
-define(ATTR_FIRE_ANTI, 79).                %% 火抗
-define(ATTR_EARTH_ANTI, 80).               %% 土抗
-define(ATTR_LEVEL_HP, 81).                 %% 角色等级提升生命
-define(ATTR_LEVEL_ATTACK, 82).             %% 角色等级提升攻击
-define(ATTR_LEVEL_DEFENCE, 83).            %% 角色等级提升防御
-define(ATTR_LEVEL_ARP, 84).                %% 角色等级提高破甲
-define(ATTR_LEVEL_HIT_RATE, 85).           %% 角色等级提高命中
-define(ATTR_LEVEL_MISS, 86).               %% 角色等级提高闪避
-define(ATTR_LEVEL200_HURT_DERATE, 87).     %% 每200级伤害减免
-define(ATTR_CONFINE_HP, 88).               %% 大境界提升生命
-define(ATTR_CONFINE_ATTACK, 89).           %% 大境界提升攻击
-define(ATTR_CONFINE_SKILL_HURT_ANTI, 90).  %% 大境界技能伤害减免
-define(ATTR_CONFINE_SKILL_HURT, 91).       %% 大境界技能伤害加成
-define(ATTR_EQUIP_HURT_DERATE, 92).        %% 穿戴状态受到玩家伤害降低
-define(ATTR_CONFINE_HURT_DERATE, 93).      %% 大境界伤害减免
-define(ATTR_CONFINE_HURT_RATE, 94).        %% 大境界伤害加成
-define(ATTR_BLOCK_RATE, 95).               %% 格挡几率
-define(ATTR_BLOCK_REDUCE, 96).             %% 格挡减伤
-define(ATTR_BLOCK_DEFY, 97).               %% 无视格挡
-define(ATTR_BLOCK_PASS, 98).               %% 格挡穿透
-define(ATTR_HP_HEAL_RATE, 99).             %% 治疗效果加成
-define(ATTR_CONFINE_BLOCK_REDUCE, 100).    %% 境界提高格挡减伤
-define(ATTR_CONFINE_BLOCK_RATE, 101).      %% 境界提高格挡几率
-define(ATTR_DIZZY_HURT_ADD, 102).          %% 对晕眩敌人伤害加成
-define(ATTR_SLOW_HURT_ADD, 103).           %% 对减速敌人伤害加成
-define(ATTR_POISON_BUFF_ADD, 104).         %% 中毒buff伤害加成
-define(ATTR_BURN_BUFF_ADD, 105).           %% 燃烧buff伤害加成
-define(ATTR_POISON_HURT_REDUCE, 106).      %% 中毒敌人造成伤害降低
-define(ATTR_BURN_HURT_REDUCE, 107).        %% 燃烧敌人造成伤害降低
-define(ATTR_SLOW_HURT_REDUCE, 108).        %% 减速敌人造成伤害降低
-define(ATTR_SEAL_LEVEL_HP, 109).           %% 铭文等级生命加成
-define(ATTR_SEAL_LEVEL_ATTACK, 110).       %% 铭文等级攻击加成
-define(ATTR_ROLE_HURT_ADD, 111).           %% pvp伤害加成
-define(ATTR_LEVEL10_DOUBLE_RATE, 112).     %% 每10级暴击率

%% 战斗力系数
-define(POWER_ATTACK, 10).          %% 攻击系数
-define(POWER_HP, 0.5).             %% 生命系数
-define(POWER_ARP, 10).             %% 破甲系数
-define(POWER_DEFENCE, 10).         %% 防御系数
-define(POWER_HIT_RATE, 10).        %% 命中系数
-define(POWER_MISS, 10).            %% 闪避系数
-define(POWER_DOUBLE, 10).          %% 暴击系数
-define(POWER_DOUBLE_ANTI, 10).     %% 坚韧系数

-record(c_skill, {
    skill_id=0,                 %% skill_id
    skill_type_id=0,            %% 技能类型ID
    skill_lv=0,                 %% 技能等级
    skill_name="",              %% 技能名
    skill_type=0,               %% 技能类型 0普通技能 1主动技能 2被动技能
    sub_skill_type,             %% 技能细分
    effect_type=0,              %% 0.敌方…全体单位 1.友方 2.自己 3.敌方…仅玩家单位
    bullet_speed=0,             %% 子弹飞行速度 cm/s
    attack_result_condition,    %% 攻击结果加成条件
    add_buff_type,              %% 1. 生命值低于某值时触发
    add_buff_args,              %% 参数
    hit_prop_condition,         %% 攻击/被攻击加成条件
    props=[],                   %% 属性加成
    map_prop_effect=[],         %% 场景效果参数
    add_prop_effect,            %% 增强被动技能8的效果
    fight_buff_condition=[],    %% 战斗buff触发条件
    add_skill_type_list=[],     %% 增强技能类型ID
    add_skill_args=[],          %% 增强技能参数
    be_buff_args=[],            %% 被加buff触发
    self_buffs=[],              %% 给自己加的buff
    direct_buffs=[],            %% 对敌方直接生效的buff
    hit_buffs=[],               %% 命中后生效的buff
    level_cost=[],
    learn_category=0,
    learn_level=0,              %% 学习需求等级
    learn_relive_level=0,       %% 学习转生等级
    action_cd=0,                %% 动画时长
    common_cd=0,                %% 技能释放完的公共CD
    cd=0,                       %% cd 单位 ms
    dis=0,                      %% 攻击距离 cm
    hit_value="",               %% 伤害系数（>0时会带effect效果）
    hit_again_args,             %% 被动概率和目标数量
    pos_type=0,                 %% 技能目标中心点（）
    attack_type,                %% 攻击范围类型
    range_args,                 %% 范围参数
    summon_traps,               %% 召唤陷阱
    power_type,                 %% 战力类型
    power_val,                  %% 战力值
    seal_list                   %% 铭文编号
}).

%% 铭文技能配置
-record(c_skill_seal, {
    seal_id,                %% 铭文ID
    seal_name,              %% 铭文名称
    seal_level,             %% 铭文等级
    need_role_level,        %% 升级等级
    need_item,              %% 升级道具
    type,                   %% 铭文效果类型
    rate,                   %% 概率
    positive_self_buffs,    %% 主动铭文-自身增加buff
    positive_enemy_buffs,   %% 主动铭文-敌人增加buff
    positive_add_props,     %% 主动铭文-施放时属性加成
    sub_type,               %% 被动铭文子类型
    passive_condition,      %% 被动铭文-条件参数 []
    passive_self_buffs,     %% 被动铭文-自身增加buff
    passive_enemy_buffs,    %% 被动铭文-敌方buff
    passive_args,           %% 特殊类型参数
    passive_cd              %% 被动铭文cd
}).

%% 主动铭文效果参数
-record(seal_effect_args, {
    self_buff_effects = [],     %% 自身加成buff
    enemy_buff_effects = [],    %% 给敌人加成buff
    prop_effects = []           %% 施放时属性加成
}).

%% 技能效果
%% effect_type:int32() 效果类型
%% skill_type 0普攻 1主动技能 2被动技能
%% value:int32() 效果值
%% args 各个effect args会不同
-record(r_skill_effect, {skill_id=0, skill_type=0, effect_type=0, value=0, args}).

%% 伤害增加
-record(r_skill_add_hurt, {skill_type_id, rate_list=[]}).
-record(fight_args, {
    src_id,                     %% src_id
    src_type,                   %% src_type
    skill_id,                   %% 技能ID
    skill_pos,                  %% 技能位置
    dest_id_list = [],          %% 目标列表
    enemy_effect_list = [],     %% 对敌人的效果 [#r_skill_effect{}|...]
    self_effect_list = [],      %% 对自己的效果 [#r_skill_effect{}|...]
    friend_effect_list = [],    %% 对友方（不包括自己）的效果 [#r_skill_effect{}|...]
    prop_effect_list = []       %% 主动技能的EffectList [#actor_prop_effect{}|...]
}).

-record(r_skill_action, {
    skill_id,           %% 技能动作列表
    step_id,            %% 动作段
    hurt_list = []      %% 伤害列表
}).

-record(r_skill_hurt, {
    delay = 0,          %% 延时
    self_effect=[],     %% 自身作用效果
    enemy_effect=[]     %% 敌人作用效果
}).


-record(actor_fight, {
    actor_id,
    actor_type,
    skill_pos,
    map_info,
    attr
}).

%% 改这里注意数据库的db_role_fight_p的数据！！
-record(actor_fight_attr, {
    max_hp = 0,             %% 血量
    attack = 0,             %% 攻击
    defence = 0,            %% 防御
    arp = 0,                %% 破甲
    hit_rate = 0,           %% 命中
    miss = 0,               %% 闪避
    double = 0,             %% 暴击
    double_anti = 0,        %% 韧性

    %% 万分比
    hurt_rate = 0,          %% 加伤
    hurt_derate = 0,        %% 免伤
    double_rate = 0,        %% 暴击几率
    double_multi=0,         %% 暴伤
    miss_rate = 0,          %% 闪避几率
    double_anti_rate  = 0,  %% 暴击抵抗
    armor = 0,              %% 护甲
    skill_hurt = 0,         %% 技能伤害增加
    skill_hurt_anti = 0,    %% 技能伤害减少
    skill_dps = 0,          %% 技能DSP系数
    skill_ehp = 0,          %% 技能EHP系数
    role_hurt_add = 0,      %% pvp伤害增加
    role_hurt_reduce = 0,   %% pvp伤害减免
    boss_hurt_add = 0,      %% 对Boss伤害加深
    boss_hurt_reduce = 0,   %% Boss伤害降低
    drain = 0,              %% 攻击力吸血
    rebound = 0,            %% 伤害反弹
    monster_hurt_add = 0,   %% 怪物伤害增加

    move_speed = 0,         %% 移动速度
    monster_exp_add = 0,    %% 杀怪经验万分比
    imprison_hurt_add = 0,  %% 击中定身伤害加成
    silent_hurt_add = 0,    %% 击中沉默伤害加成
    poison_hurt_add = 0,    %% 击中中毒状态伤害加成
    burn_hurt_add = 0,      %% 击中燃烧状态伤害加成
    dizzy_hurt_add = 0,     %% 击中晕眩伤害加成
    slow_hurt_add = 0,      %% 减速伤害加成
    poison_buff_add = 0,    %% 中毒buff伤害加成
    burn_buff_add = 0,      %% 燃烧buff伤害加成
    poison_hurt_reduce = 0, %% 被中毒敌人攻击时伤害减低
    burn_hurt_reduce = 0,   %% 被燃烧敌人攻击时伤害减低
    slow_hurt_reduce = 0,   %% 被减速敌人攻击时伤害减低

    dizzy_rate = 0,         %% 眩晕万分比
    min_reduce_rate=0,      %% 怪物伤害血量下限
    max_reduce_rate=0,      %% 怪物伤害血量上限(0的时候默认为不取上限)
    double_damage_rate=0,   %% 2次伤害概率（暴击按原始伤害算）
    double_miss_rate=0,     %% 2次闪避概率
    metal = 0,              %% 金攻
    metal_anti = 0,         %% 金抗
    wood = 0,               %% 木攻
    wood_anti = 0,          %% 木抗
    water = 0,              %% 水攻
    water_anti = 0,         %% 水抗
    fire = 0,               %% 火攻
    fire_anti = 0,          %% 火抗
    earth = 0,              %% 土攻
    earth_anti = 0,         %% 土抗
    block_rate = 0,         %% 格挡几率
    block_reduce = 0,       %% 格挡减伤
    block_defy = 0,         %% 无视格挡
    block_pass = 0,         %% 格挡穿透
    hp_heal_rate = 0,       %% 治疗效果加成

    prop_effects=[]         %% 攻击时根据特定条件增加的属性
}).

-record(actor_extra_attr, {
    hp_recover = {0, 0},        %% 回血
    war_spirit_time = {0, 0}    %% 战灵持续时间
}).

%%{绝对值 ，万分比}
-record(actor_cal_attr, {
    max_hp = {0, 0},             %% 血量
    attack = {0, 0},             %% 攻击
    defence = {0, 0},            %% 防御
    arp = {0, 0},                %% 破甲
    hit_rate = {0, 0},           %% 命中
    miss = {0, 0},               %% 闪避
    double = {0, 0},             %% 暴击
    double_anti = {0, 0},        %% 韧性

    %% 万分比
    hurt_rate = 0,              %% 加伤、用list
    hurt_derate = 0,            %% 免伤、用list
    double_rate = {0, 0},        %% 暴击几率
    double_multi = {0, 0},       %% 暴伤
    miss_rate = {0, 0},          %% 闪避几率
    double_anti_rate  = {0, 0},  %% 暴击抵抗
    armor = {0, 0},              %% 护甲
    skill_hurt = {0, 0},         %% 技能伤害增加
    skill_hurt_anti = {0, 0},    %% 技能伤害减少
    skill_dps = {0, 0},          %% 技能DSP系数
    skill_ehp = {0, 0},          %% 技能EHP系数

    move_speed = {0, 0},         %% 移动速度
    monster_exp_add = {0, 0},    %% 杀怪经验万分比
    role_hurt_add = 0,          %% pvp伤害增加
    role_hurt_reduce = {0, 0},   %% pvp伤害减免
    boss_hurt_add = {0, 0},      %% Boss伤害加深
    boss_hurt_reduce = {0, 0},   %% Boss伤害降低
    drain = {0, 0},              %% 攻击力吸血
    rebound = {0, 0},            %% 伤害反弹
    monster_hurt_add = {0, 0},   %% 怪物伤害增加
    imprison_hurt_add = {0, 0},  %% 定身伤害加成
    silent_hurt_add = {0, 0},    %% 沉默伤害加成
    poison_hurt_add = {0, 0},    %% 中毒伤害加成
    burn_hurt_add = {0, 0},      %% 燃烧伤害加成
    dizzy_hurt_add = 0,         %% 击中晕眩伤害加成
    slow_hurt_add = 0,          %% 减速伤害加成
    poison_buff_add = 0,        %% 中毒buff伤害加成
    burn_buff_add = 0,          %% 燃烧buff伤害加成
    poison_hurt_reduce = 0,     %% 被中毒敌人攻击时伤害减低
    burn_hurt_reduce = 0,       %% 被燃烧敌人攻击时伤害减低
    slow_hurt_reduce = 0,       %% 被减速敌人攻击时伤害减低
    dizzy_rate = {0, 0},         %% 眩晕万分比
    min_reduce_rate = {0, 0},    %% 扣血下限
    max_reduce_rate = {0, 0},    %% 扣血上限
    double_damage_rate = {0, 0}, %% 2次伤害概率
    double_miss_rate = {0, 0},   %% 2次闪避概率
    metal = {0, 0},             %% 金攻
    metal_anti = {0, 0},        %% 金抗
    wood = {0, 0},              %% 木攻
    wood_anti = {0, 0},         %% 木抗
    water = {0, 0},             %% 水攻
    water_anti = {0, 0},        %% 水抗
    fire = {0, 0},              %% 火攻
    fire_anti = {0, 0},         %% 火抗
    earth = {0, 0},             %% 土攻
    earth_anti = {0, 0},        %% 土抗
    block_rate = 0,             %% 格挡几率
    block_reduce = 0,           %% 格挡减伤
    block_defy = 0,             %% 无视格挡
    block_pass = 0,             %% 格挡穿透
    hp_heal_rate = 0,           %% 治疗效果加成

    %% 下面属性不归属于fight_attr
    hp_recover = {0, 0},         %% 回血相关
    war_spirit_time = {0, 0}     %% 战灵存在时间
}).


-record(actor_cal_base_attr, {
    base_hp = 0 ,             %% 血量
    base_attack = 0 ,             %% 攻击
    base_defence = 0,            %% 防御
    base_arp = 0              %% 破甲
}).

%% 攻击时属性加成
-record(actor_prop_effect, {
    type,               %% PROP_TYPE_XXX
    hp_rate,            %% 万分比
    rate,               %% 万分比
    add_props           %% [#p_kv{}|...]
}).

%%

-record(buff_args, {
    buff_id=0,                  %% buffID
    from_actor_id=0,            %% 发起者
    buff_last_time=0,           %% buff持续时间（部分buff会强制用这个时间）
    extra_value                 %% 值（部分buff会用到这个值）
}).

%% buff表的配置
-record(c_buff, {
    buff_id=0,          %% buff_id
    buff_class=0,       %% 系列ID
    buff_name="",       %% buff名
    buff_type=0,        %% buff类型 增减益、抵抗
    buff_attr=0,        %% buff效果
    buff_exist_type=0,  %% Buff存在类型 可替换、共存
    add_rate=0,         %% 触发几率
    bid_level=0,        %% 冲顶等级
    dispel_level=0,     %% 驱散等级
    last_time=0,        %% 持续时间
    is_add_time=0,      %% 可否叠加时间
    cover_times=0,      %% 同个BuffID的值叠加次数
    remove_type=0,      %% 取消方式
    offline_type=0,     %% 下线处理
    effect_interval=0,  %% 起效间隔
    value=0,            %% 值
    immune_list=[],     %% 抵抗buff
    aura_range=0,       %% 光环范围
    aura_type=0,        %% 光环类型
    aura_num=0,         %% 光环数量
    aura_value=0        %% 光环发射BUFF
}).

%% buff
-record(r_buff, {
    buff_id=0,          %% buff_id
    buff_class=0,       %% 系列ID
    buff_attr=0,        %% buff效果
    cover_times=0,      %% 叠加次数
    bid_level=0,        %% 冲顶等级
    extra_value,        %% 额外参数
    from_actor_id=0,    %% 发起者
    start_time=0,       %% 开始时间
    last_effect_time=0, %% 上次作用时间
    end_time=0          %% 结束时间
}).

-endif.