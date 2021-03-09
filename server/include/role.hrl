%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. 四月 2017 16:22
%%%-------------------------------------------------------------------
-ifndef(ROLE_HRL).
-define(ROLE_HRL, role_hrl).
-include("global.hrl").

-define(STATE_WAITING_FOR_AUTH, state_waiting_for_auth).
-define(STATE_WAITING_FOR_SELECT, state_waiting_for_select). %% 等待重连
-define(STATE_WAITING_FOR_RECONNECT, state_waiting_for_reconnect).
-define(STATE_WAITING_FOR_ENTER, state_waiting_for_enter).
-define(STATE_NORMAL_GAME, state_normal_game).

-define(FRESH_REMAIN_HP, 2000).     %% 新手10%以下会加血



%%    改动后前端也需要通知    如 - 闭关
-define(WORLD_LEVEL_OPEN_LV, 110).      %% 世界等级开启等级
-define(WORLD_LEVEL_EVERY_RATE, 600).   %% 每级6%





%% attr变化key
-define(ATTR_LAST_LEVEL_TIME, 2).       %% 上次升级时间
-define(ATTR_OFFLINE_FIGHT_TIME, 3).    %% 离线挂机时间

%% bag相关定义
-define(MAX_ITEM_CREATE_NUM, 99999).    %% 单次创建物品最大数量上限
-define(IS_ITEM_COVER(CoverNum), (CoverNum > 1)).

-define(BAG_ID_BAG, 1).             %% 背包
-define(BAG_ID_DEPOT, 2).           %% 个人仓库
-define(BAG_ID_TREASURE, 3).        %% 寻宝临时仓库
-define(BAG_ID_TREVI_FOUNTAIN, 4).  %% 许愿池
-define(BAG_ID_NATURE, 5).          %% 天机背包
-define(BAG_ID_ALCHEMY, 6).         %% 新炼丹炉背包
-define(BAG_ID_CYCLE_TOWER, 8).     %% 周期活动宝塔

-define(BAG_KEY_NUM, 2).            %% 开启一个格子需要的钥匙数量

%%  道具相关宏定义
-define(BAG_ASSET_SILVER, ?ITEM_SILVER).        %% 银两
-define(BAG_ASSET_GOLD, ?ITEM_GOLD).            %% 元宝
-define(BAG_ASSET_BIND_GOLD, ?ITEM_BIND_GOLD).  %% 绑定元宝
-define(BAG_ITEM_GLORY, 11).                    %% 荣誉
-define(BAG_ITEM_FAMILY_MONEY, 12).             %% 帮派资金
-define(BAG_ITEM_FAMILY_CON, 13).               %% 帮派贡献
-define(BAG_ITEM_RUNE_EXP, 14).                 %% 符文经验
-define(BAG_ITEM_CONFINE_EXP, 16).              %% 境界经验
-define(BAG_HANDBOOK_ESSENCE, 17).              %% 图鉴卡片精华
-define(BAG_ITEM_FORGE_SOUL, 18).               %% 镇魂石
-define(BAG_ITEM_TALENT_SKILL, 19).             %% 天赋点数
-define(BAG_THRONE_ESSENCE, 20).                %% 宝座精华
-define(BAG_ITEM_WAR_GOD_SCORE, 21).            %% 玄晶
-define(BAG_ITEM_HUNT_TREASURE_SCORE, 22).      %% 宝珠
-define(BAG_ITEM_PRESTIGE, 26).                 %% 威望
-define(BAG_TRAINING_POINT, 27).                %% 修炼点
-define(BAG_ITEM_EXP, 100).                     %% 经验
-define(BAG_RUNE_ESSENCE, 101).                 %% 魂晶
-define(BAG_ACT_RUNE_BOX, 107).                 %% 符文活动宝箱
-define(BAG_NAT_INTENSIFY_GOODS, 700006).       %% 天机勾玉

-define(BAG_ITEM_SEAL_RESET, 2999).     %% 铭文重置卷轴
-define(BAG_ITEM_PET_STEP, 30361).      %% 伙伴进阶丹
-define(BAG_ITEM_MOUNT_STEP, 30301).    %% 坐骑进阶丹
-define(BAG_ITEM_STONE_ATTACK, 30001).  %% 1级攻击宝石
-define(BAG_ITEM_STONE_HP, 30011).      %% 1级生命宝石

%% asset 货币相关宏定义
-define(ASSET_SILVER, 1).               %% 银两
-define(ASSET_GOLD, 2).                 %% 元宝
-define(ASSET_BIND_GOLD, 3).            %% 绑定元宝
%% 积分的货币ID，必须跟behavior_log.hrl里的类型一致
-define(ASSET_GLORY, 11).               %% 荣誉       %%商城
-define(ASSET_TREASURE_SCORE, 12).      %% 寻宝积分
-define(ASSET_FORGE_SOUL, 13).          %% 铸魂精华
-define(ASSET_WAR_GOD_SCORE, 14).       %% 玄晶
-define(ASSET_HUNT_TREASURE_SCORE, 15). %% 宝珠
-define(ASSET_LIVENESS, 23).            %% 活跃货币
-define(ASSET_PRESTIGE, 26).            %% 威望
-define(ASSET_FAMILY_CON, 99).          %% 帮派贡献   %%升级帮派技能

%%活动
-define(ACT_REWARD_CANNOT_GET, 1).         %%不能领取
-define(ACT_REWARD_CAN_GET, 2).            %%可领
-define(ACT_REWARD_GOT, 3).                %%已领

%% 对应的属性与战力key
-define(CALC_KEY_LEVEL, 1).                         %% 等级
-define(CALC_KEY_EQUIP_BASE, 2).                    %% 装备基础属性
-define(CALC_KEY_EQUIP_REFINE, 3).                  %% 装备强化属性
-define(CALC_KEY_EQUIP_REFINE_LEVEL, 4).            %% 装备强化等级属性
-define(CALC_KEY_EQUIP_SUIT, 5).                    %% 装备套装属性
-define(CALC_KEY_STONE, 6).                         %% 宝石属性
-define(CALC_KEY_STONE_LEVEL, 7).                   %% 宝石等级属性
-define(CALC_KEY_MOUNT, 8).                         %% 坐骑
-define(CALC_KEY_MAGIC_WEAPON, 9).                  %% 法宝
-define(CALC_KEY_PET, 10).                          %% 宠物
-define(CALC_KEY_GOD_WEAPON, 11).                   %% 神兵
-define(CALC_KEY_WING, 12).                         %% 翅膀
-define(CALC_KEY_FASHION, 13).                      %% 时装
-define(CALC_KEY_FAMILY, 14).                       %% 帮派技能加成
-define(CALC_KEY_RUNE, 15).                         %% 符文加成
-define(CALC_KEY_VIP, 16).                          %% VIP属性加成
-define(CALC_KEY_DECORATION, 17).                   %% 饰品属性
-define(CALC_KEY_WORLD, 18).                        %% 世界相关加成
-define(CALC_KEY_RELIVE, 19).                       %% 转生属性
-define(CALC_KEY_EQUIP_EXCELLENT, 20).              %% 装备卓越属性
-define(CALC_KEY_SKILL_PASSIVE, 21).                %% 角色被动技能加成
-define(CALC_KEY_CONFINE, 22).                      %% 角色境界加成
-define(CALC_KEY_GUARD, 23).                        %% 守护信息
-define(CALC_KEY_SEAL, 24).                         %% 装备纹印加成
-define(CALC_KEY_TITLE, 28).                        %% 称号属性
-define(CALC_KEY_GM, 29).                           %% GM调整
-define(CALC_KEY_EQUIP_CONCISE, 30).                %% 装备洗练
-define(CALC_KEY_TEAM, 31).                         %% 组队属性加成
-define(CALC_IMMORTAL_SOUL, 32).                    %% 仙魂加成
-define(CALC_MARRY_KNOT, 33).                       %% 仙侣-同心结加成
-define(CALC_MYTHICAL_EQUIP, 34).                   %% 魂兽装备加成
-define(CALC_KEY_HANDBOOK, 35).                     %% 图鉴属性加成
-define(CALC_KEY_THRONE, 36).                       %% 宝座属性加成
-define(CALC_KEY_EQUIP_FORGE_SOUL, 37).             %% 镇魂属性加成
-define(CALC_KEY_FORGE_EQUIP_SOUL_CULTIVATE, 38).   %% 镇魂属性养成加成
-define(CALC_KEY_EQUIP_STAR_SUIT, 39).              %% 装备星级属性加成
-define(CALC_KEY_SUIT, 40).                         %% 套装系统属性加成
-define(CALC_KEY_NATURE, 41).                       %% 天机系统属性加成
-define(CALC_KEY_PELLET_MEDICINE, 42).              %% 丹药系统属性加成
-define(CALC_EQUIP_COLLECT, 43).                    %% 装备收集套装属性加成

-define(CALC_KEY_GM_PROP, 99).                      %% GM属性加成

%% 道具配置相关定义
-define(ITEM_USE_ID, 0).            %% 唯一ID
-define(ITEM_USE_TYPE_ID, 1).       %% 道具ID

-define(ITEM_CAN_USE, 1).   %% 道具可以使用
-define(IS_ITEM_NOTICE(IsNotice), (IsNotice =:= 1)).    %% 道具是否公告
-define(IS_CATEGORY_ITEM(TypeID), (70000 < TypeID andalso TypeID < 90000)). %% 职业道具ID

-define(ITEM_EQUIP, 1).                     %% 穿上装备
-define(ITEM_MOUNT_QUALITY, 2).             %% 坐骑丹药
-define(ITEM_MAGIC_WEAPON_SOUL, 3).         %% 法宝丹药
-define(ITEM_GOD_WEAPON_SOUL, 4).           %% 神兵丹药
-define(ITEM_PTE_SPIRIT, 5).                %% 宠物丹药
-define(ITEM_WING_QUALITY, 6).              %% 翅膀丹药
-define(ITEM_PTE_EXP, 7).                   %% 宠物经验
-define(ITEM_MOUNT_SKIN, 8).                %% 坐骑时装
-define(ITEM_MAGIC_WEAPON_SKIN, 9).         %% 法宝时装
-define(ITEM_GOD_WEAPON_SKIN, 10).          %% 神兵时装
-define(ITEM_ADD_WING_SKIN, 11).            %% 翅膀时装
-define(ITEM_PET_SURFACE, 12).              %% 宠物时装
-define(ITEM_MOUNT_STEP_EXP, 13).           %% 坐骑进阶丹
-define(ITEM_ADD_MAGIC_WEAPON_EXP, 14).     %% 法宝进阶丹
-define(ITEM_ADD_GOD_WEAPON_EXP, 15).       %% 神兵进阶丹
-define(ITEM_PTE_STEP_EXP, 16).             %% 宠物进阶丹
-define(ITEM_ADD_WING_EXP, 17).             %% 增加翅膀经验
-define(ITEM_ADD_RUNE_PIECE, 18).           %% 增加符文碎片
-define(ITEM_ADD_RUNE_ESSENCE, 19).         %% 增加符文精粹
-define(ITEM_ADD_RUNE, 20).                 %% 增加符文
-define(ITEM_ADD_SILVER, 21).               %% 增加银两
-define(ITEM_ADD_GOLD, 22).                 %% 增加元宝
-define(ITEM_ADD_BIND_GOLD, 23).            %% 增加绑定元宝
-define(ITEM_ADD_GLORY, 24).                %% 增加荣耀
-define(ITEM_USE_PACKAGE, 25).              %% 使用礼包
-define(ITEM_ADD_BUFF, 26).                 %% 增加buff
-define(ITEM_ADD_OFFLINE_TIME, 27).         %% 增加离线挂机时间
-define(ITEM_USE_GUARD, 28).                %% 小精灵/饰品/守护
-define(ITEM_CATEGORY_GENERATE, 30).        %% 根据职业生成道具
-define(ITEM_STONE, 31).                    %% 宝石
-define(ITEM_VIP_EXPERIENCE_CARD, 32).      %% VIP体验卡
-define(ITEM_ADD_BAG_GRID, 33).             %% 增加背包格子
-define(ITEM_ADD_FAMILY_CON, 34).           %% 道具增加帮贡
-define(ITEM_ADD_COPY_TIMES, 35).           %% 增加副本次数
-define(ITEM_ADD_EXP, 36).                  %% 增加经验
-define(ITEM_ADD_VIP, 37).                  %% 使用VIP卡
-define(ITEM_ADD_TITLE, 38).                %% 使用称号
-define(ITEM_ADD_WORLD_BOSS_TIMES, 39).     %% 增加世界boss疲劳次数
-define(ITEM_ADD_LEVEL_EXP, 40).            %% 增加等级经验
-define(ITEM_ADD_FASHION, 41).              %% 使用时装
-define(ITEM_WORLD_LEVEL, 44).              %% 根据世界等级生成道具
-define(ITEM_SELECT, 45).                   %% 选择某个道具
-define(ITEM_IMMORTAL_SOUL, 46).            %% 增加仙魂
-define(ITEM_IMMORTAL_SOUL_STONE, 47).      %% 增加仙魂石
-define(ITEM_INSIDE_PAY, 48).               %% 内部充值道具
-define(ITEM_CONFINE_UP, 49).               %% 境界提升
-define(ITEM_MARRY_KNOT, 51).               %% 同心结养成
-define(ITEM_MARRY_FIREWORKS, 52).          %% 婚礼烟花
-define(ITEM_FLOWER, 53).					%% 鲜花道具
-define(ITEM_EQUIP_DROPS, 54).              %% 装备副本掉落
-define(ITEM_CLEAR_PK_VALUE, 56).           %% 清理PK值
-define(ITEM_MYTHICAL_COLLECT, 57).         %% 神兽岛礼包类型
-define(ITEM_MYTHICAL_COLLECT2, 58).        %% 神兽岛礼包类型2
-define(ITEM_ADD_MYTHICAL_TIMES, 59).       %% 增加神兽岛疲劳次数
-define(ITEM_MYTHICAL_EQUIP, 60).           %% 神兽装备
-define(ITEM_RED_PACKET, 61).               %% 红包
-define(ITEM_WAR_SPIRIT_EQUIP, 62).         %% 战灵灵饰
-define(ITEM_GOLD_PAY, 65).                 %% 道具触发充值，但是不记入充值金额
-define(ITEM_ADD_EXP_OR_LEVEL, 71).         %% 道具加经验或者等级（大于某等级加经验，小于某等级升等级）.
-define(ITEM_WORLD_BOSS_REFRESH, 72).       %% 世界BOSS刷新令
-define(ITEM_WAR_GOD_PIECE, 73).            %% 战神套装碎片
-define(ITEM_HUNT_TREASURE, 75).            %% 藏宝图
-define(ITEM_WORLD_BOSS_FLOOR_REFRESH,79).  %% 洞天福地（世界boss)【整层】刷新令
-define(ITEM_OPEN_SKILL, 80).               %% 开启技能
-define(ITEM_NATURE_ITEM, 86).              %% 天机系统的强化道具
-define(ITEM_ADD_TALENT_POINTS, 87).        %% 增加天赋点
-define(ITEM_ADD_NEW_ALCHEMY_SCHEDULE, 90). %% 增加炼丹炉进度
-define(ITEM_VIP_EXP_CARD, 91).             %% VIP经验卡
-define(ITEM_LIMIT_ADD_ILLUSION, 92).       %% 增加幻力（有使用次数限制）
-define(ITEM_ADD_ILLUSION, 93).             %% 增加幻力
-define(ITEM_ADD_TIME_FASHION_1, 94).       %% 时装限时1
-define(ITEM_ADD_TIME_FASHION_2, 95).       %% 时装限时2

%% 装备相关宏定义
-define(VIP_STONE_INDEX, 6).    %% VIP孔数位置
-define(HAS_STONE(StoneID), (StoneID > 0)).
-define(STONE_HONING_LEVEL, 4). %% 宝石大于4级才能获取属性

-define(VIP_SEAL_INDEX, 5).     %% vip纹印孔数

-define(EQUIP_REFINE_NORMAL, 0).    %% 普通强化
-define(EQUIP_REFINE_ONE_KEY, 1).   %% 一键强化

-define(EQUIP_STONE_ONE_KEY_UP, 1).     %% 一键穿戴
-define(EQUIP_STONE_ONE_KEY_REMOVE, 2). %% 一键卸下

-define(EQUIP_SUIT_LEVEL_IMMORTAL, 1).  %% 诛仙
-define(EQUIP_SUIT_LEVEL_GOD, 2).       %% 诛神

-define(EQUIP_FORGE_SOUL_LEVEL, 7).     %% 7阶装备铸魂才生效

%% 装备星级属性列表
-define(EQUIP_EXCELLENT_PROPS, [?ATTR_RATE_ADD_DEFENCE, ?ATTR_RATE_ADD_HP, ?ATTR_HURT_DERATE, ?ATTR_RATE_ADD_ATTACK, ?ATTR_RATE_ADD_ARP, ?ATTR_HURT_RATE,
    ?ATTR_DOUBLE_RATE, ?ATTR_EVERY_THREE_ATTACK, ?ATTR_EVERY_THREE_ARP, ?ATTR_EVERY_THREE_HP, ?ATTR_EVERY_THREE_DEFENCE, ?ATTR_DOUBLE_ANTI_RATE, ?ATTR_MISS_RATE]).

-define(EQUIP_CONCISE_PROPS, [?ATTR_ATTACK, ?ATTR_RATE_ADD_ATTACK, ?ATTR_ARP, ?ATTR_RATE_ADD_ARP, ?ATTR_HIT_RATE, ?ATTR_RATE_ADD_HIT, ?ATTR_DOUBLE, ?ATTR_RATE_ADD_DOUBLE,
    ?ATTR_HP, ?ATTR_RATE_ADD_HP, ?ATTR_DEFENCE, ?ATTR_RATE_ADD_DEFENCE, ?ATTR_MISS, ?ATTR_RATE_ADD_MISS, ?ATTR_DOUBLE_ANTI, ?ATTR_RATE_ADD_DOUBLE_A]).

-define(CONCISE_FIRST_OPEN, 0).     %% 第一次开启 属性不能给紫色
-define(CONCISE_ITEM_OPEN, 1).      %% 用道具洗练 随机给
-define(CONCISE_GOLD_OPEN, 2).      %% 用元宝洗练

-define(QUALITY_PURPLE, 3). %% 紫色品质
-define(QUALITY_ORANGE, 4). %% 橙色品质
-define(QUALITY_RED, 5).    %% 红色品质

-define(IS_EQUIP_WEAPON(Index), (Index =:= 1)).     %% 武器
-define(IS_EQUIP_ARMOR(Index), (lists:member(Index, [2,3,4,5,6]))). %% 防器
-define(IS_EQUIP_GOD(Index), (lists:member(Index, [7,8,9,10]))).    %% 仙器

-define(AMULET_1_INDEX, 9).     %% 护符1
-define(AMULET_2_INDEX, 10).    %% 护符2

%% 战斗相关宏定义
-define(WEAPON_CHANGE_TIME, 5).
-define(FIGHT_STATUS_CHANGE_TIME, 5).

%% 时装相关宏定义
-define(SKIN_KEY_FASHION, 1).

-define(FASHION_INFO_ONLINE, 0).    %% 上线推送
-define(FASHION_INFO_ACTIVATE, 1).  %% 激活推送
-define(FASHION_INFO_STAR, 2).      %% 升星推送

-define(FASHION_CHANGE_LOAD, 1).    %% 穿时装
-define(FASHION_CHANGE_UNLOAD, 2).  %% 脱时装


-define(FASHION_TYPE_CLOTH, 1).     %% 衣服
-define(FASHION_TYPE_WEAPON, 2).    %% 武器
-define(FASHION_TYPE_BUBBLE, 3).    %% 气泡
-define(FASHION_TYPE_HEADER, 4).    %% 头像框
-define(FASHION_TYPE_FOOTPRINT, 5). %% 足迹

-define(FASHION_SUIT_TYPE_NORMAL, 1).   %% 单人套装
-define(FASHION_SUIT_TYPE_MARRY, 2).    %% 仙侣套装

%% 功能开启相关宏定义
-define(FUNCTION_TYPE_LEVEL, 1).            %% 等级
-define(FUNCTION_TYPE_MISSION, 2).          %% 任务
-define(FUNCTION_TYPE_KILL_MONSTER, 3).     %% 杀怪触发
-define(FUNCTION_TYPE_GOD_BOOK, 4).         %% 天书触发
-define(FUNCTION_TYPE_ITEM, 5).             %% 道具触发
-define(FUNCTION_TYPE_CONFINE, 6).          %% 境界触发


-define(FUNCTION_MOUNT, 1).                 %% 坐骑
-define(FUNCTION_MAGIC_WEAPON, 2).          %% 法宝
-define(FUNCTION_PET, 3).                   %% 宠物
-define(FUNCTION_GOD_WEAPON, 4).            %% 神兵
-define(FUNCTION_WING, 5).                  %% 翅膀
-define(FUNCTION_THRONE, 6).                %% 宝座
-define(FUNCTION_EQUIP_REFINE, 11).         %% 装备强化
-define(FUNCTION_EQUIP_SUIT, 12).           %% 套装合成
-define(FUNCTION_EQUIP_COMPOSE, 13).        %% 装备合成
-define(FUNCTION_EQUIP_STONE, 14).          %% 宝石镶嵌
-define(FUNCTION_RUNE_COMPOSE, 22).         %% 符文合成
-define(FUNCTION_FAMILY_CREATE, 31).        %% 仙盟创建
-define(FUNCTION_FAMILY_DINNER, 32).        %% 仙盟晚宴
-define(FUNCTION_FAMILY_MISSION, 33).       %% 仙盟任务
-define(FUNCTION_FAMILY_GUARD, 34).         %% 仙盟守卫
-define(FUNCTION_DAILY_LIVENESS, 41).       %% 日常活跃
-define(FUNCTION_WORLD_BOSS, 42).           %% 世界boss
-define(FUNCTION_OFFLINE_SOLO, 44).         %% 竞技殿
-define(FUNCTION_CONFINE, 46).              %% 境界
-define(FUNCTION_ZERO_PANICBUY, 52).        %% 零元抢购
-define(FUNCTION_BLESS, 55).                %% 祈福
-define(FUNCTION_JEWELRY_STEP, 58).         %% 首饰进阶功能的开启
-define(FUNCTION_HANDBOOK, 59).             %% 图鉴
-define(FUNCTION_UNIVERSE, 69).             %% 太虚通天塔
-define(FUNCTION_ACT_ONLIINE, 302).         %% 在线奖励
-define(FUNCTION_SKILL_BEGIN, 100).         %% 技能开头
-define(FUNCTION_SKILL_END, 200).           %% 技能结尾
-define(FUNCTION_COPY_EXP, 401).            %% 经验副本
-define(FUNCTION_COPY_PET, 402).            %% 宠物副本
-define(FUNCTION_COPY_TOWER, 403).          %% 诛仙塔
-define(FUNCTION_COPY_EQUIP, 404).          %% 装备副本
-define(FUNCTION_COPY_SILVER, 405).         %% 金币副本
-define(FUNCTION_COPY_FIVE_ELEMENTS, 407).  %% 五行神殿
-define(FUNCTION_FORGE_SOUL, 505).          %% 铸魂属性开放
-define(FUNCTION_FORGE_SOUL_CULTIVATE, 505).%% 铸魂属性养成开放
-define(FUNCTION_SEAL, 17).                 %% 纹印
-define(FUNCTION_FAMILY_TEMPLE, 63).        %% 主宰神殿
-define(FUNCTION_DABAO, 601).               %% 打宝
-define(FUNCTION_SUIT, 701).                %% 套装系统
-define(FUNCTION_FAIRY, 66).                %% 护送
-define(FUNCTION_NATURE, 706).              %% 天机印系统
-define(FUNCTION_NEW_ALCHEMY, 708).         %% 炼丹炉 凡
-define(FUNCTION_MONEY_TREE, 709).           %% 摇钱树
-define(FUNCTION_MINING, 710).              %% 秘境探索（挖矿）




-define(FUNCTION_INFO_ONLINE, 0).           %% 上线推送
-define(FUNCTION_INFO_UPDATE, 1).           %% 更新推送

%% 成长系统相关
-define(GET_SKIN_TYPE(SkinID), (SkinID div 100)).
-define(BLESS_END_TIME, 24 * 60 * 60).  %% 24小时祝福
-define(BLESS_CLEAR, 1).

-define(MOUNT_DOUBLE_TIME, [{{8, 0, 0}, {10, 0, 0}}, {{17, 0, 0}, {18, 0, 0}}]).
-define(GROW_INFO_ONLINE, 0).   %% 上线推送
-define(GROW_INFO_UPDATE, 1).   %% 更新推送
-define(MOUNT_STATUS_DOWN, 0).  %% 下马状态
-define(MOUNT_STATUS_UP, 1).    %% 上马状态

-define(THRONE_STATUS_HIDE, 0). %% 宝座隐藏状态
-define(THRONE_STATUS_USE, 1).  %% 宝座使用状态

-define(GET_BASE_ID(ID), (ID div 100)).
-define(GET_NORMAL_ID(BaseID), (BaseID * 100)).

-define(GET_TEN_BASE_ID(ID), (ID div 10)).

-define(GET_MAGIC_WEAPON_ITEM(MagicWeaponID), (MagicWeaponID div 100)).
-define(GET_MAGIC_WEAPON_STEP(MagicWeaponID), (MagicWeaponID rem 100)).

-define(MAGIC_WEAPON_SKIN_LEVEL_UP, 1).     %% 升级
-define(MAGIC_WEAPON_SKIN_STEP, 2).         %% 进阶

-define(MAX_GOD_WEAPON_REFINE, 5).  %% 神兵最大强化次数

-define(WING_GROW_RATE, 100).       %% 单个加成1%
-define(MAX_WING_GROW_RATE, 3000).  %% 翅膀系统连续最大加成值
-define(GET_WING_TYPE(WingID), (WingID div 100)).



%%首饰相关
-define(DECORATION_MONSTER_EXP_ADD, 1).       %% 增加打怪经验
-define(DECORATION_HURT_DERATE, 2).           %% 伤害减免


%% 符文相关hrl
-define(RUNE_LEVEL_ID(TypeID, Level), (TypeID + (Level - 1) * 100000)). %% 符文等级ID
-define(RUNE_TYPE_ID(RuneLevelID), (RuneLevelID - (?RUNE_LEVEL(RuneLevelID) - 1) * 100000)). %% 获取符文ID
-define(RUNE_LEVEL(RuneLevelID), ((RuneLevelID  div 100000) rem 100)). %% 获取符文等级

-define(RUNE_QUALITY_PURPLE, 3).    %% 紫色品质
-define(RUNE_TYPE_EXP, 1).          %% 经验符文
-define(BAG_FULL_RUNE_NUM, 200).    %% 符文背包不能继续寻宝的个数
-define(ENOUGH_BAG_RUNE_NUM, 400).  %% 符文背包达到这个个数，会自动清理紫色一下的符文

%% 转生相关
-define(RELIVE_TRIGGER_MISSION, 1). %% 任务触发
-define(RELIVE_LEVEL_DESTINY, 4).   %% 天命觉醒-4转

%% 寻宝相关
-define(TREASURE_ONE, 1).       %% 单抽
-define(TREASURE_TEN, 10).      %% 10连
-define(TREASURE_FIFTY, 50).    %% 50次

%% 称号相关
-define(IS_FOREVER_TITLE(IsForever), (IsForever =:= 0)).
-define(IS_FOREVER_TIME(Time), (Time =:= 0)).

%% 封禁相关
-define(BAN_TYPE_LOGIN, 1).
-define(BAN_TYPE_CHAT, 2).
-define(BAN_TYPE_WORD_CHAT, 3).

%% 投资相关
-define(MONTH_CARD_DAY, 30).    %% 月卡30天
-define(VIP_INVEST_DAY, 7).     %% VIP投资7天
-define(GET_VIP_INVEST_LEVEL(ID), (ID div 100)).
-define(GET_VIP_INVEST_ID(Level, Day), (Level * 100 + Day)).


%% 精灵相关
-define(FAKE_ELF, 40003).
-define(GUARD_LIST, [40001 , 40002 , 40003]).  %%精灵

%% 属性计算record结构key
-define(RECORD_PM_TIME_LIMIT, 1000). % 临时丹药属性

-define(DO_ROLE_HANDLE_INFO(Info, State),
    try
        do_handle_info(Info, State)
    catch _:Reason ->
        ?ERROR_MSG("Info:~w~n, Reason: ~w~n, strace:~p", [Info, Reason, erlang:get_stacktrace()]),
        State
    end).

-define(DO_ROLE_HANDLE_CAST(Info, State),
    try
        do_handle_info(Info, State)
    catch _:Reason ->
        ?ERROR_MSG("Info:~w~n, Reason: ~w~n, strace:~p", [Info, State, Reason, erlang:get_stacktrace()]),
        State
    end).

-define(DO_ROLE_HANDLE_CALL(Request, State),
    try
        case Request of
            {tl, Time, Request2} ->
                case time_tool:now_os() * 1000 > Time of
                    true ->
                        {{error, call_timeout}, State};
                    false ->
                        do_handle_call(Request2, State)
                end;
            _ ->
                do_handle_call(Request, State)
        end
    catch _:Reason ->
        ?ERROR_MSG("Request:~w~n, Reason: ~w~n, strace:~p", [Request, Reason, erlang:get_stacktrace()]),
        {error, State}
    end).

-record(r_device, {
    device_name = "",
    os_type = "",
    os_ver = "",
    net_type = "",
    imei = "",
    package_name = "",
    width = 0,
    height = 0
}).

%% 背包其他加成
-record(r_bag_other_doing, {
    add_exp = 0,                %% 经验
    add_essence = 0,            %% 符文碎片
    add_rune_exp = 0,           %% 增加符文经验
    asset_doings = [],          %% 货币加成
    rune_doings = [] ,          %% 增加符文
    immortal_soul_doings = [],  %% 增加仙魂
    immortal_soul_stone = 0,    %% 增加仙魂石
    add_mythical_equips = [],   %% 增加魂兽装备
    add_war_spirit_equips = [], %% 增加战灵装备
    add_handbook_essence = 0,   %% 卡片精华
    add_throne_essence = 0,     %% 宝座精华
    talent_points = 0,          %% 天赋点数
    intensify_nature = 0,       %% 天机勾玉
    training_point = 0,         %% 修炼点
    add_war_god_pieces = []     %% 战神套装碎片
}).

%% 属性计算record结构
-record(r_calc, {key, attr, power}).

%% 面板属性，不影响战力
-record(r_panel_calc, {key, attr}).

-record(r_role_enter, {
    map_id = 0,
    extra_id = 0,
    server_id = 0,
    camp_id = ?DEFAULT_CAMP_ROLE,
    map_pname,
    record_pos,
    old_hp,
    old_pos
}).

-record(r_relive_args, {
    normal_relive_time=0,   %% 正常复活的时间
    normal_relive_times=0,  %% 正常复活的次数
    fee_relive_time=0,      %% 原地复活的时间
    fee_relive_times=0,     %% 原地复活的次数
    fee   =0                %% 原地复活消耗的元宝
}).



%% 道具配置 默认可以cover
%% item_type   1 装备 2 材料 3 消耗品 7天机印

-define(IS_TYPE_OF_EQUIP,1).
-define(IS_TYPE_OF_STUFF,2).
-define(IS_TYPE_OF_CONSUME, 3). %% 消耗品
-define(IS_TYPE_OF_NATURE, 7).

%% 职业生成对应的道具
-record(c_category_item, {
    type_id,        %% 道具ID
    category_1,     %% 职业1
    category_2      %% 职业2
}).

%% 格子上限
-record(c_bag_content, {
    bag_id,         %% 背包ID
    min_grid,       %% 初始拥有格子数
    max_grid        %% 上限格子数
}).

%% 格子开启
-record(c_bag_grid, {
    index,          %% 格子数
    num             %% 消耗道具数量
}).

%% 礼包配置
-record(c_package, {
    package_id,         %% 礼包ID;
    need_grid,          %% 所需格子数
    min_multi,          %% 最小倍率
    max_multi,          %% 最大倍率
    fixed_drop,         %% 固定掉落
    floor_item,         %% 保底
    item1 = [],         %% 物品1
    item2 = [] ,        %% 物品2
    item3 = [],         %% 物品3
    item4 = [],         %% 物品4
    item5 = [],         %% 物品5
    item6 = [],         %% 物品6
    item7 = [],         %% 物品7
    item8 = [],         %% 物品8
    item9 = [],         %% 物品9
    item10 = []         %% 物品10
}).


%% 任务等级 && 属性配置
-record(c_level, {
    sex,
    level,
    category,
    need_exp,
    move_speed,
    hp,
    attack,
    defence,
    arp,
    hp_recover,             %% 每10秒恢复
    hit_rate,
    miss,
    double,
    double_anti,
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
    war_spirit_time = 0,    %% 战灵存时
    skill_list
}).

-record(c_role_level,{
    level,
    bless_exp,          %%祈福经验
    bless_copper,       %%祈福铜币，
    base_exp,            %%活动基准经验
    passive_bless_exp
}).

%% 装备配置
-record(c_equip, {
    id,                     %% 装备ID
    name,                   %% 装备名称
    index,                  %% 穿戴部位
    quality,                %% 装备品质
    limit_level,            %% 穿戴等级
    star,                   %% 星级
    step,                   %% 装备品阶
    limit_category,         %% 穿戴职业限制
    bind_type,              %% 绑定条件
    max_refine_num,         %% 装备强化次数
    refine_props,           %% 强化增加属性ID
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_arp,                %% 破甲
    add_defence,            %% 防御
    add_hit_rate,           %% 命中
    add_miss,               %% 闪避
    add_double,             %% 暴击
    add_double_anti,        %% 韧性
    suit_level1,            %% 套装等级1
    suit_item1,             %% 进阶所需道具ID1 [TypeID, Num]
    suit_id1,               %% 套装组1
    suit_level2,            %% 套装等级2
    suit_item2,             %% 进阶所需道具ID2 [TypeID, Num]
    suit_id2,               %% 套装组2
    pet_exp,                %% 宠物经验值
    stone_num,              %% 宝石孔数
    seal_num,               %% 纹印孔数
    donate_contribution,    %% 捐献贡献值
    exchange_contribution   %% 兑换贡献值
}).

-record(c_equip_special_props, {
    equip_id,
    desc,
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_drain,              %% 攻击力百分比吸血
    add_role_hurt_add,      %% PVP伤害加成
    add_skill_hurt,         %% 技能伤害增加
    add_kill_hurt_anti ,    %% 技能伤害减少
    add_hp_rate,            %% 生命加成
    add_attack_rate,        %% 攻击加成
    add_hurt_rate,          %% 伤害加深
    add_hurt_derate         %% 伤害减免
}).

-record(c_equip_refine, {
    refine_level,       %% 强化等级
    need_role_level,    %% 需要玩家等级
    index_type,         %% 类型
    asset_num,          %% 强化消耗货币数量
    level_mastery,      %% 强化熟练度
    add_mastery,        %% 每次强化提高熟练度
    multi_rate,         %% 强化暴击概率
    add_attack,         %% 攻击
    add_hp,             %% 生命
    add_arp,            %% 破甲
    add_defence         %% 防御
}).

-record(c_equip_refine_suit, {
    level,              %% 等级
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp             %% 破甲
}).

-define(STONE_HP,1).    %%生命宝石
-define(STONE_AT,3).    %%攻击宝石
-define(STONE_DE,2).    %%防御宝石

%% 宝石配置
-record(c_stone, {
    id,                 %% 道具ID;
    name,               %% 宝石名称
    type,               %% 宝石类型
    level,              %% 宝石等级;
    equip_index_list,   %% 镶嵌装备部位
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    compose_type_id,    %% 合成的TypeID
    compose_num
}).

%% 宝石套装配置
-record(c_stone_suit, {
    level,              %% 等级
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_hit_rate,       %% 命中
    add_miss,           %% 闪避
    add_double,         %% 暴击
    add_double_anti     %% 韧性
}).

%% 宝石淬炼配置
-record(c_stone_honing, {
    honing_id,          %% 淬炼ID
    stone_type,         %% 需要的宝石类型
    need_item,          %% 消耗道具
    base_add_rate,      %% 宝石基础属性加成
    prop_string         %% 属性
}).


%% 装备套装配置
-record(c_equip_suit, {
    suit_id,            %% 套装ID
    suit_num1,          %% 组成套装数量1
    suit_props1,        %% 属性值1
    suit_num2,          %% 组成套装数量2
    suit_props2,        %% 属性值2
    suit_num3,          %% 组成套装数量3
    suit_props3         %% 属性值3
}).


%% 宝石配置
-record(c_seal, {
    id,                 %% 道具ID;
    name,               %% 纹印名称
    type,               %% 纹印类型
    level,              %% 纹印等级
    equip_index_list,   %% 镶嵌装备部位
    add_miss,           %% 闪避
    add_hit_rate,       %% 命中
    add_double_anti,    %% 韧性
    add_double,         %% 暴击
    compose_type_id,    %% 合成的TypeID
    compose_num
}).

%% 装备星级配置
-record(c_equip_star, {
    star_id,            %% 编号
    index_list,         %% 装备部位
    quality,            %% 品质
    star,               %% 星级
    groups              %% 属性
}).

%% 星级属性配置
-record(c_equip_excellent, {
    excellent_id,       %% 组ID
    defence_rate,       %% 防御万分比
    hp_rate,            %% 生命万分比
    hurt_derate,        %% 伤害减免
    attack_rate,        %% 攻击万分比
    arp_rate,           %% 破甲万分比
    hurt_rate,          %% 伤害加深
    double_rate,        %% 暴击几率
    every_three_attack, %% 每3级攻击
    every_three_arp,    %% 每3级破甲
    every_three_hp,     %% 每3级生命
    every_three_defence,%% 每3级防御
    silver_drop,        %% 铜钱掉落
    item_drop,          %% 物品掉落
    double_anti_rate,   %% 暴击抵抗
    miss_rate           %% 闪避几率
}).

%% 装备合成配置
-record(c_equip_compose, {
    equip_id,           %% 装备ID
    material_list,      %% 材料列表
    rate                %% 概率
}).

%% 装备洗练-锁定
-record(c_equip_concise_prop, {
    load_index,         %% 部位
    prop_quality,       %% 品质
    attack,             %% 攻击
    attack_rate,        %% 攻击加成
    arp,                %% 破甲
    arp_rate,           %% 破甲加成
    hit_rate,           %% 命中
    hit_rate_r,         %% 命中加成
    double,             %% 暴击
    double_rate,        %% 暴击加成
    hp,                 %% 生命
    hp_rate,            %% 生命加成
    defence,            %% 防御
    defence_rate,       %% 防御加成
    miss,               %% 闪避
    miss_rate,          %% 闪避加成
    double_anti,        %% 韧性
    double_anti_rate,   %% 坚韧加成
    item_weight,        %% 洗练石权重
    gold_weight         %% 元宝洗练权重
}).

%% 装备洗练-锁定
-record(c_equip_concise_lock, {
    lock_num,           %% 锁定条数
    type_id,            %% 洗练道具
    item_num,           %% 需要洗炼石数量
    gold                %% 元宝价格
}).

%% 时装基础表
-record(c_fashion_base, {
    base_id,            %% 基础ID
    shop_id,            %% 商城ID
    type,               %% 类型ID
    exp,                %% 时装精华
    broadcast_id        %% 广播ID
}).

%% 时装升星
-record(c_fashion_star, {
    fashion_id,                 %% 时装ID
    fashion_name,               %% 时装名称
    fashion_type,               %% 类型ID
    star,                       %% 时装星级
    add_hp,                     %% 生命
    add_attack,                 %% 攻击
    add_defence,                %% 防御
    add_arp,                    %% 破甲
    cost,                       %% 升星消耗
    skill_list                  %% 技能
}).

%% 时装精华
-record(c_fashion_essence, {
    level,          %% 等级
    type,           %% 类型ID
    need_exp,       %% 升级所需精华
    hp_rate,        %% 生命加成
    attack_rate,    %% 攻击加成
    defence_rate,   %% 防御加成
    arp_rate        %% 破甲加成
}).

%% 时装套装
-record(c_fashion_suit, {
    suit_id,            %% 套装ID
    suit_name,          %% 套装名称
    suit_type,          %% 套装类型
    suit_base_list,     %% 套装所需部件ID
    suit_props,         %% 套装属性
    suit_skill          %% 技能列表
}).

%% 功能开启配置
-record(c_function, {
    function_id,        %% 激活系统ID
    activate_type,      %% 激活类型
    activate_args,      %% 激活参数
    function_args,      %% 激活完调用的函数参数
    is_preview,         %% 是否预览
    letter_template_id, %% 邮件激活通知
    reward,
    open_reward         %% 开启奖励
}).

%% 进阶系统配置
-record(c_grow, {
    grow_id,            %% 进阶模块
    level,              %% 等阶
    grow_name,          %% 名称
    step_item,          %% 进阶消耗道具ID
    step_item_num,      %% 消耗道具数量
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_hit_rate,       %% 命中
    add_miss,           %% 闪避
    add_double,         %% 暴击
    add_double_anti,    %% 韧性
    add_speed,          %% 速度
    prop_id,            %% 特殊属性ID
    prop_value,         %% 特殊属性值
    step_rewards,       %% 进阶奖励
    min_bless,          %% 进阶所需最小祝福值
    success_rate,       %% 成功概率
    max_bless,          %% 进阶所需最大祝福值
    add_min_bless,      %% 进阶失败最小加成祝福值
    add_max_bless,      %% 进阶失败最大加成祝福值;
    temp_prop_id,       %% 每次进阶失败增加临时属性ID
    temp_prop_value,    %% 每次进阶失败增加临时属性值
    is_bless_clear,     %% 祝福值是否清空
    is_broadcast,       %% 是否向全服广播
    broadcast_id,       %% 广播内容ID
    quality_item,       %% 资质丹ID
    quality_item_num,   %% 资质丹数量
    quality_props,      %% 资质丹属性加成
    quality_max_num,    %% 使用资质丹上限
    potential_item,     %% 潜能丹ID
    potential_item_num, %% 潜能丹数量
    potential_max_num,  %% 使用潜能丹上限
    equip_args,         %% 可装备坐骑装备阶数
    skill_id            %% 开放技能ID
}).

%% 养成功能丹药加成
-record(c_pellet, {
    type_id,            %% 道具ID
    props,              %% 属性
    max_num             %% 最大使用数量
}).

%% 坐骑进阶系统配置
-record(c_mount_up, {
    mount_id,           %% 进阶模块
    mount_step,         %% 等级
    mount_star,         %% 星级
    mount_name,         %% 坐骑名称
    step_item_num,      %% 进阶消耗精华
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    speed
}).

%% 坐骑基础配置
-record(c_mount_base, {
    mount_id,           %% 坐骑id
    mount_name,         %% 坐骑名字
    is_bc,              %% 是否向全服广播 1-是 0-否
    broadcast_id,       %% 广播ID
    have_skills,        %% 拥有技能ID
    open_skill          %% 开放技能
}).


-record(c_mount_skin, {
    mount_id,           %% 进阶模块
    mount_step,         %% 等阶
    step_item,          %% 进阶消耗道具ID
    step_item_num,      %% 消耗道具数量
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    add_move_speed,     %% 速度
    need_bless,         %% 进阶所需总祝福值
    add_min_bless,      %% 进阶失败最小加成祝福值
    add_max_bless,      %% 进阶失败最大加成祝福值;
    is_broadcast,       %% 是否向全服广播
    skill_list          %% 开放技能ID
}).

%% 宠物进阶配置
-record(c_pet, {
    pet_id,                 %% 宠物ID
    pet_step,               %% 宠物等阶
    pet_star,               %% 宠物星级
    pet_name,               %% 宠物名称
    use_step_exp,           %% 进阶消耗精华
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_defence,            %% 防御
    add_arp,                %% 破甲
    is_broadcast,           %% 是否向全服广播
    broadcast_id,           %% 广播内容ID
    skills                  %% 宠物开启技能
}).

%% 宠物
-record(c_pet_base, {
    base_id,
    name,
    broadcast_id
}).

%% 宠物等级配置
-record(c_pet_level, {
    pet_level,          %% 宠物等级
    need_exp,           %% 升级需要的经验
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp             %% 破甲
}).

-record(c_pet_surface, {
    id,                     %% 宠物皮肤ID 每升一级加一 不同皮肤id不连续
    step,                   %% 宠物皮肤等阶
    star,                   %% 星级
    name,                   %% 宠物皮肤名称
    need_item,              %% 升级物品需要的消耗
    item_num,               %% 需要数量
    step_exp,               %% 消耗经验
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_defence,            %% 防御
    add_arp,                %% 破甲
    broadcast,              %% 是否广播
    skill_list              %% 拥有的技能ID  (list)
}).

-record(c_mount_surface, {
    id,                     %% 宠物皮肤ID 每升一级加一 不同皮肤id不连续
    step,                   %% 宠物皮肤等阶
    star,                   %% 星级
    name,                   %% 宠物皮肤名称
    need_item,              %% 升级物品需要的消耗
    item_num,               %% 需要数量
    step_exp,               %% 消耗经验
    add_hp,                 %% 生命
    add_attack,             %% 攻击
    add_defence,            %% 防御
    add_arp,                %% 破甲
    broadcast,              %% 是否广播
    skill_list              %% 拥有的技能ID  (list)
}).

%% 法宝基础表
-record(c_magic_weapon_base, {
    base_id,            %% ID
    name,               %% 名称
    broadcast_id
}).

%% 法宝外观
-record(c_magic_weapon_skin, {
    skin_id,            %% 法宝皮肤ID
    type,               %% 类型 是可以进阶的还是可以升级的
    item_num,           %% 皮肤【进阶】消耗数量
    exp_item,           %% 升级需要的道具
    exp_need,           %% 皮肤【升级】消耗的经验
    add_hp,             %% 生命
    add_attack,         %% 攻击
    add_defence,        %% 防御
    add_arp,            %% 破甲
    add_hit_rate,       %% 命中
    add_miss,           %% 闪避
    add_double,         %% 暴击
    add_double_anti,    %% 韧性
    add_attack_rate,    %% 攻击加成
    add_hp_rate,        %% 生命加成
    skill_list          %% 皮肤的技能列表
}).

%% 法宝等级表
-record(c_magic_weapon_level, {
    level,                      %% 等级
    exp,                        %% 经验
    add_attack,                 %% 攻击
    add_arp,                    %% 破甲
    add_miss,                   %% 闪避
    add_hit_rate,               %% 命中
    skill_list                  %% 法宝技能列表
}).

%% 神兵基础表
-record(c_god_weapon_base, {
    base_id,            %% ID
    name,               %% 名称
    broadcast_id        %% 广播ID
}).

%% 神兵外观
-record(c_god_weapon_skin, {
    skin_id,            %% 神兵ID
    star,               %% 星级
    item_num,           %% 进阶消耗数量
    add_attack,         %% 攻击
    add_arp,            %% 破甲
    add_double,         %% 暴击
    add_double_rate     %% 暴击几率
}).

%% 神兵等级表
-record(c_god_weapon_level, {
    level,              %% 等级
    exp,                %% 经验
    add_attack,         %% 攻击
    add_arp,            %% 破甲
    add_hit_rate,       %% 命中
    add_double,         %% 暴击
    add_double_anti,    %% 韧性
    add_double_rate,    %% 暴击几率
    skill_list          %% 法宝技能列表
}).

%% 翅膀基础表
-record(c_wing_base, {
    base_id,            %% ID
    name,               %% 名称
    broadcast_id        %% 广播ID
}).

%% 翅膀外观
-record(c_wing_skin, {
    skin_id,                %% 神兵ID
    star,                   %% 星级
    item_num,               %% 进阶消耗数量
    add_hp_rate,            %% 生命加成
    add_attack,             %% 攻击
    add_defence,            %% 防御
    add_arp                 %% 破甲
}).

%% 翅膀等级表
-record(c_wing_level, {
    level,              %% 等级
    exp,                %% 经验
    add_hp,             %% 生命
    add_defence,        %% 防御
    add_miss,           %% 闪避
    add_double_anti,    %% 韧性
    skill_list          %% 法宝技能列表
}).

%% 合成配置
-record(c_compose, {
    compose_id,         %% 合成ID
    compose_name,       %% 描述
    need_items,         %% 合成所需道具ID
    compose_items,      %% 合成后道具ID
    compose_rate,       %% 合成概率
    add_rate_item,      %% 增加成功率道具
    add_rate            %% 道具加成的概率
}).

%% 商城配置
-record(c_shop, {
    id,                 %% 商店物品id
    item_id,            %% 物品id
    name,               %% 物品名字
    is_bind,            %% 是否绑定
    shop_type,          %% 商城类型
    asset_type,         %% 货币属性
    asset_value,        %% 货币价钱
    limit_type,         %% 限购类型
    limit_num,          %% 每天限购次数
    limit_level,        %% 限购等级
    limit_vip_level,    %% 限购VIP等级
    is_broadcast,       %% 是否全服公告
    need_family_level
}).

%% 饰品
-record(c_decoration, {
    type_id,            %% ID
    index,              %% 部位
    attr                %% 属性
}).

%% 符文配置表
-record(c_rune, {
    level_id,           %% 符文等级id TypeID * 1000 + Level
    prop_id1,           %% 增加属性ID1
    prop_value1,        %% 增加属性值1
    prop_id2,           %% 增加属性ID2
    prop_value2,        %% 增加属性值2
    level_exp,          %% 升级经验
    decompose_exp       %% 分解经验
}).

%% 符文基础表
-record(c_rune_base, {
    type_id,            %% 符文类型id
    name,               %% 符文名称
    type_list,          %% 类型
    quality,            %% 品质
    punch_list          %% 可镶嵌孔位
}).

%% 符文兑换表
-record(c_rune_exchange, {
    level_id,           %% LevelID
    piece_cost,         %% 碎片消耗
    need_tower_id       %% 爬塔ID
}).

%% 符文合成表
-record(c_rune_compose, {
    level_id,           %% LevelID
    essence_cost,       %% 消耗货币数量
    compose_rune1,      %% 合成消耗1
    compose_rune2,      %% 合成消耗2
    need_tower_id       %% 开启副本ID
}).

%% 符文开启表
-record(c_rune_open, {
    index,              %% 符文部位
    need_tower_floor    %% 开启副本灌输
}).

%% 转生表
-record(c_relive, {
    relive_level,       %% 转生等级
    role_level,         %% 角色等级
    level_props,        %% 属性
    target,             %% 目标
    category_1_skills,  %% 技能升级职业1
    category_2_skills,  %% 技能升级职业2
    stage_props         %% 阶段属性
}).

%% 命格表
-record(c_destiny, {
    destiny_id,         %% 激活顺序
    destiny_desc,       %% 天命名称
    need_items,         %% 道具消耗
    need_exp,           %% 经验消耗
    props               %% 点亮获得属性
}).

%% 装备寻宝
-record(c_equip_treasure, {
    id,                 %% 序号
    type_id,            %% 道具ID
    name,               %% 名字
    bind,               %% 是否绑定
    role_level,         %% 人物等级
    category,           %% 职业
    weight,             %% 权重
    num,                %% 数量
    is_broadcast,       %% 是否广播
    is_control,         %% 是否概率控制
    control_weight      %% 必出物品概率
}).

%% 符文寻宝
-record(c_rune_treasure, {
    id,                 %% 编号
    box_id,             %% 宝藏枚举
    rune_base_id,       %% 物品id
    weight,             %% 概率
    rare_weight         %% 贵重权重
}).


%% 称号
-record(c_title, {
    id,             %% ID
    name,           %% 名字
    add_attack,     %% 攻击
    add_hp,         %% 生命
    add_arp,        %% 破甲
    add_defence,    %% 防御
    special_props,  %% 特殊属性
    is_forever      %% 是否永久生效
}).

%% 月卡奖励
-record(c_month_card, {
    day,    %% 天数
    gold    %% 元宝
}).

%% 投资奖励
-record(c_invest_gold, {
    level,      %% 等级
    gold_list   %% 返还元宝
}).

%% vip投资
-record(c_vip_invest, {
    id,         %% ID
    min_level,  %% 最小等级
    max_level,  %% 最大等级
    rewards     %% 返利
}).

%% 化身投资
-record(c_summit_invest_gold, {
    level,      %% 等级
    goods_1,    %% 1档
    goods_2,    %% 2档
    goods_3     %% 3档
}).

%% 日常活跃度
-record(c_daily_liveness, {
    type,              %% 活跃度类型
    times,             %% 可完成次数
    once_liveness     %% 完成单次活跃的
}).

%% 日常活跃度奖励
-record(c_daily_liveness_reward, {
    liveness,              %%活跃度
    reward                 %%奖励
}).

%% 七天奖励
-record(c_seven_day, {
    day,                       %%天数
    reward                     %%奖励
}).

%% 章节
-record(c_chapter, {
    chapter_id,         %% 章节ID
    chapter_name,       %% 章节名
    need_num,           %% 任务数量
    rewards,            %% 章节奖励
    start_mission_id,   %% 开始任务id
    end_mission_id      %% 结束任务id
}).

%% 世界等级道具
-record(c_world_level_item, {
    type_id,            %% 道具ID
    desc,               %% 描述
    item_string         %% 道具列表（根据等级筛选）
}).

%% 选择道具
-record(c_select_item, {
    type_id,
    desc,               %% 描述
    item_list           %% 道具列表
}).

%% 等级限时抢购道具
-record(c_role_level_panicbuy, {
    id,             %%限时抢购id
    level,          %%等级
    item_id,        %%道具ID
    quantity,       %%道具数量
    price,          %%现价
    currency_type,  %%货币类型
    discount,       %%折扣数值
    time_expire,    %%抢购时间
    gender          %%角色性别
}).

%% 天赋页签
-record(c_talent_tab, {
    tab_id,         %% 页签ID
    tree_list,      %% 天赋树列表
    pre_points      %% 前置技能点
}).

%% 天赋技能
-record(c_talent_skill, {
    skill_id,       %% 技能ID
    need_point,     %% 升级消耗
    reset_point,    %% 重置返回天赋点数
    pre_skill,      %% 前置技能限制
    tree_id,        %% 天赋树ID
    need_role_level,%% 等级限制
    need_all_points,%% 页签点数
    props           %% 属性
}).

%% 首饰进阶（手镯，戒指）
-record(c_jewelry_step, {
    id,             %% 进阶前的id
    name1,          %% 进阶前的名字
    cost,           %% 消耗, string
    step_id,        %% 进阶后的道具id
    name2           %% 进阶后的名字
}).

-record(c_forge_soul, {
    location_id,                  %% 装备部位id
    forge_soul_property,          %% 铸魂属性阶数
    forge_soul_cultivate_level,   %% 铸魂养成阶数（条件）查看铸魂养成表
    tower_floor,                  %% 需要通关镇魂塔层数（条件）
    add_attribute_recursive       %% 累加属性（string）
}).

-record(c_forge_soul_cultivate, {
    id,                         %% ID 铸魂养成ID
    location_id,                %% 部位id
    level,                      %% 等级
    consume,                    %% 升级消耗（条件）
    tower_floor,                %% 塔层数（条件）
    step,                       %% 装备阶数
    add_attribute_recursive     %% 累加属性（string）
}).


%% boss悬赏
-record(c_boss_reward, {
    grade,
    type,          %% 场景
    level,         %% 等级
    reward,         %% 奖励
    times
}).

%% 凡品丹炉
-record(c_new_alchemy, {
    id,
    type,           %% 场景
    num,            %% 等级
    weight
}).


%% 摇钱树
-record(c_money_tree, {
    times,
    need,   %%  扣除
    reward  %%  奖励
}).

-record(c_money_tree_rate, {
    rate,
    weight  %%  奖励
}).
-endif.

