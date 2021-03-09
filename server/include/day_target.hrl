%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. 十二月 2018 9:50
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(DAY_TARGET_HRL).
-define(DAY_TARGET_HRL, day_target_hrl).

-define(DAY_TARGET_TYPE_VALUE_REACH, 101).      %% 数值达成
-define(DAY_TARGET_TYPE_SHOP_BUY, 201).         %% 商店购买
-define(DAY_TARGET_TYPE_USE_ITEM, 301).         %% 消耗指定道具
-define(DAY_TARGET_TYPE_ADD_COUNTER, 401).      %% 行为计数

-define(DAY_TARGET_TYPE_THUNDER_ACTIVE_NUM, 501).   %% 神雷套装激活的数量
-define(DAY_TARGET_TYPE_THUNDER_SUIT, 502).         %% 神雷套装X件X阶
-define(DAY_TARGET_TYPE_WAR_SPIRIT_ARMOR, 601).     %% 战灵装备橙色X阶装备
-define(DAY_TARGET_TYPE_WAR_SPIRIT_EQUIP, 602).     %% 战灵装备橙色X阶灵饰
-define(DAY_TARGET_TYPE_NATURE_COLOR, 701).         %% 激活X个X色品质的天机套装
-define(DAY_TARGET_TYPE_NATURE_REFINE_LEVEL, 703).  %% X级以上的天机印达到X个
-define(DAY_TARGET_TYPE_STONE_PUNCH, 801).          %% 镶嵌X级宝石X个

-define(DAY_TARGET_ARGS_ROLE_LEVEL, 10101).     %% 角色等级
-define(DAY_TARGET_GOD_WEAPON_LEVEL, 10102).    %% 神兵等级
-define(DAY_TARGET_WING_LEVEL, 10103).          %% 翅膀等级
-define(DAY_TARGET_MAGIC_WEAPON_LEVEL, 10104).  %% 法宝等级
-define(DAY_TARGET_NATURE_REFINE_LEVEL, 10105). %% 天机印总强化等级
-define(DAY_TARGET_EQUIP_CONCISE_NUM, 10106).   %% 解锁装备洗练属性条目
-define(DAY_TARGET_NATURE_HOLE_NUM, 10107).     %% 镶嵌天机印个数
-define(DAY_TARGET_MOUNT_STEP, 10108).          %% 坐骑等阶
-define(DAY_TARGET_PET_STEP, 10109).            %% 宠物等阶
-define(DAY_TARGET_GUARD_ELF, 10110).           %% 激活小精灵
-define(DAY_TARGET_GUARD_FAIRY, 10111).         %% 激活小仙女
-define(DAY_TARGET_COPY_TOWER, 10112).          %% 九九窥星塔层数
-define(DAY_TARGET_COPY_FIVE_ELEMENTS, 10113).  %% 五行秘境解锁层数
-define(DAY_TARGET_DAILY_ACTIVE, 10114).        %% 活跃度

-define(DAY_TARGET_MISSION_TYPE_RING, 40101).   %% 日常任务
-define(DAY_TARGET_COPY_EXP, 40102).            %% 青竹院
-define(DAY_TARGET_ANSWER, 40103).              %% 蜀山论道
-define(DAY_TARGET_OFFLINE_SOLO, 40104).        %% 决斗场
-define(DAY_TARGET_COPY_TEAM, 40105).           %% 装备副本
-define(DAY_TARGET_FAMILY_ESCORT, 40106).       %% 道庭护送
-define(DAY_TARGET_WORLD_BOSS, 40107).          %% 世界BOSS
-define(DAY_TARGET_WORLD_BOSS_OWNER, 40108).    %% 世界BOSS归属
-define(DAY_TARGET_DEMON_BOSS, 40109).          %% 魔域Boss
-define(DAY_TARGET_DEMON_BOSS_OWNER, 40110).    %% 魔域Boss归属
-define(DAY_TARGET_COPY_PET, 40111).            %% 失落谷
-define(DAY_TARGET_COPY_IMMORTAL, 40112).       %% 仙魂副本
-define(DAY_TARGET_WORLD_BOSS_TIME, 40113).     %% 幽冥禁地
-define(DAY_TARGET_CAVE_BOSS, 40114).           %% 洞天福地Boss
-define(DAY_TARGET_PERSONAL_BOSS, 40115).       %% 个人Boss
-define(DAY_TARGET_ADD_COPY_EXP_TIMES, 40116).  %% 增加青竹院次数
-define(DAY_TARGET_FAMILY_BOX, 40117).          %% 道庭宝箱
-define(DAY_TARGET_SUIT_UP, 40118).             %% 套装升阶
-define(DAY_TARGET_PET_STAR, 40119).            %% 伙伴升星
-define(DAY_TARGET_PET_UP_STEP, 40120).         %% 伙伴升阶
-define(DAY_TARGET_NATURE_REFINE, 40121).       %% 天机印强化
-define(DAY_TARGET_STONE_COMPOSE, 40122).       %% 合成宝石
-define(DAY_TARGET_SKILL_UP, 40123).            %% 升级一次技能
-define(DAY_TARGET_BUY_WORLD_BOSS_TIMES, 40124).%% 购买世界boss次数
-define(DAY_TARGET_COMPOSE_EQUIP, 40125).       %% 合成装备
-define(DAY_TARGET_COMPOSE_JEWELRY, 40126).     %% 合成饰品
-define(DAY_TARGET_AUCTION_BUY, 40127).         %% 拍卖行购买
-define(DAY_TARGET_ACT_RANK_BUY, 40128).        %% 开服冲榜购买
-define(DAY_TARGET_AUCTION_SELL, 40129).        %% 拍卖行上架
-define(DAY_TARGET_REFINE_NAT_INTENSIFY, 40130).%% 分解获得天机勾玉
-define(DAY_TARGET_BLESS, 40131).               %% 闭关修炼



-record(c_seven_day_target, {
    id,
    desc,               %% 描述
    day,                %% 天数
    type,               %% 条件ID
    args,               %% 条件参数
    val,                %% 次数
    reward,             %% 奖励
    add_progress        %% 增加任务度
}).

-endif.
