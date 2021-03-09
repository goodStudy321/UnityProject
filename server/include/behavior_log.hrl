%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. 十二月 2017 19:57
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(BEHAVIOR_LOG).
-define(BEHAVIOR_LOG, behavior_log).

%% 货币消耗相关
-define(CONSUME_SILVER, 1).                 %% 消耗银两
-define(CONSUME_UNBIND_GOLD, 2).            %% 消耗不绑定元宝
-define(CONSUME_ANY_GOLD, 3).               %% 优先消耗绑定元宝
-define(CONSUME_BIND_GOLD, 4).              %% 只扣除绑定元宝

%% 积分的消耗货币ID，必须跟role.hrl里的类型一致
-define(CONSUME_GLORY, 11).                 %% 消耗荣誉
-define(CONSUME_TREASURE_SCORE, 12).        %% 消耗寻宝积分
-define(CONSUME_FORGE_SOUL, 13).            %% 铸魂精华
-define(CONSUME_WAR_GOD_SCORE, 14).         %% 玄晶
-define(CONSUME_HUNT_TREASURE_SCORE, 15).   %% 宝珠
-define(CONSUME_PRESTIGE, 26).              %% 威望
-define(CONSUME_FAMILY_CON, 99).            %% 消耗帮派贡献

-define(IS_USE_GOLD_ACTION(Action), (?ASSET_GOLD_REDUCE_FROM_GM =< Action andalso Action < ?ASSET_GOLD_REDUCE_FROM_MARKET_DEMAND andalso 
Action =/= ?ASSET_GOLD_REDUCE_FROM_LUCKY_CAT andalso Action =/= ?ASSET_GOLD_REDUCE_FROM_MARRY_PROPOSE andalso Action =/= ?ASSET_GOLD_REDUCE_FROM_MARRY_WISH)). %% 花费元宝的行为
-define(IS_GAIN_SILVER_ACTION(Action), (?ASSET_SILVER_ADD_FROM_GM =< Action andalso Action < ?ASSET_SILVER_REDUCE_FROM_GM)).    %% 获得铜钱的行为


%%%===================================================================
%%% 玩家道具日志 start
%%%===================================================================
%% 表格相关字段
%% {<<"role_id">>, <<"action">>, <<"type_id">>, <<"bind">>, <<"num">>}



%% 获得
-define(ITEM_GAIN_GM, 10000).                       %% GM途径获得道具
-define(ITEM_GAIN_PICK, 10001).                     %% 拾取掉落获得
-define(ITEM_GAIN_MISSION, 10002).                  %% 任务获得
-define(ITEM_GAIN_SHOP_BUY, 10003).                 %% 商店购买获得
-define(ITEM_GAIN_COPY_CLEAN, 10005).               %% 副本扫荡获得
-define(ITEM_GAIN_VIP_GIFT, 10006).                 %% VIP等级礼物获得
-define(ITEM_GAIN_FAMILY_DEPOT, 10007).             %% 帮派兑换获得
-define(ITEM_GAIN_BATTLE_SCORE, 10008).             %% 战场积分获得
-define(ITEM_GAIN_BATTLE_RANK, 10009).              %% 战场排行奖励获得
-define(ITEM_GAIN_SOLO_STEP_REWARD, 10010).         %% 1v1段位奖励获得
-define(ITEM_GAIN_SOLO_ENTER_REWARD, 10011).        %% 1v1进入次数获得
-define(ITEM_GAIN_FINISH_TOWER_REWARD, 10012).      %% 爬塔副本通关获得
-define(ITEM_GAIN_SUMMIT_TOWER_REWARD, 10013).      %% 巅峰爬塔升层获得
-define(ITEM_GAIN_COPY_FINISH, 10014).              %% 副本通关获得
-define(ITEM_GAIN_TOWER_ACCEPT, 10015).             %% 爬塔副本首次通关奖励获得
-define(ITEM_GAIN_ACT_SIGN, 10016).                 %% 每日签到获得
-define(ITEM_GAIN_ACT_TIMES_REWARD, 10018).         %% 每日签到总次数奖励
-define(ITEM_GAIN_ACT_LEVEL_REWARD, 10019).         %% 冲级奖励
-define(ITEM_GAIN_SURVEY_REWARD, 10020).            %% 问卷奖励
-define(ITEM_GAIN_ACT_RANK, 10021).                 %% 开服冲榜获得
-define(ITEM_GAIN_VIP_BUY, 10022).                  %% VIP卡购买赠送
-define(ITEM_GAIN_VIP_DAY_GIFT, 10023).            %% VIP日礼包
-define(ITEM_GAIN_SUMMIT_TOWER_RANK, 10024).        %% 爬塔副本获得
-define(ITEM_GAIN_EQUIP_REPLACE, 10101).            %% 替换装备获得
-define(ITEM_GAIN_EQUIP_STONE_PUNCH, 10102).        %% 装备镶嵌替换灵石获得
-define(ITEM_GAIN_EQUIP_STONE_REMOVE, 10103).       %% 装备拆卸灵石获得
-define(ITEM_GAIN_EQUIP_COMPOSE, 10104).            %% 装备合成获得
-define(ITEM_GAIN_EXTRA_COMPOSE, 10105).            %% 合成获得
-define(ITEM_GAIN_STONE_COMPOSE, 10106).            %% 宝石合成获得
-define(ITEM_GAIN_ACTIVATION_CODE, 10107).          %% 激活码兑换获得
-define(ITEM_GAIN_EQUIP_TREASURE, 10108).           %% 装备寻宝获得
-define(ITEM_GAIN_VIP_EXPIRE_STONE, 10109).         %% vip过期灵石自动卸下
-define(ITEM_GAIN_ACHIEVEMENT, 10110).              %% 成就系统获得
-define(ITEM_GAIN_GOD_BOOK, 10111).                 %% 天书获得
-define(ITEM_GAIN_RUNE_TREASURE, 10112).            %% 符文寻宝获得
-define(ITEM_GAIN_VIP_INVEST, 10113).               %% vip投资获得
-define(ITEM_GAIN_SELECT_ITEM, 10114).              %% 道具选择获得
-define(ITEM_GAIN_ACT_RETURN_REWARD, 10151).        %% 回归好礼类活动
-define(ITEM_GAIN_ACT_LOGIN_REWARD, 10152).         %% 普通登录活动
-define(ITEM_GAIN_ACT_ACC_PAY_REWARD, 10153).       %% 累积充值获得奖励
-define(ITEM_GAIN_WORLD_ROBOT, 10154).              %% 离线挂机获得
-define(ITEM_GAIN_SOLO_END, 10155).                 %% 1v1结束获得道具
-define(ITEM_GAIN_ACT_ENTRY_REWARD, 10156).         %% 登录有礼获得道具
-define(ITEM_GAIN_CHAPTER_REWARD, 10157).           %% 章节奖励获得道具
-define(ITEM_GAIN_MISSION_DROP, 10158).             %% 任务掉落获得道具
-define(ITEM_GAIN_MOUNT_STEP, 10201).               %% 坐骑进阶获得
-define(ITEM_GAIN_WING_LOAD, 10301).                %% 翅膀装备获得
-define(ITEM_GAIN_PACKAGE, 10302).                  %% 开启礼包获得
-define(ITEM_GAIN_BEOVERDUE, 10303).                %% 物品过期返回背包获得
-define(ITEM_GAIN_DAILY_LIVENESS, 10304).           %% 活跃度奖励
-define(ITEM_GAIN_ACT_ONLINE, 10305).               %% 在线奖励
-define(ITEM_GAIN_ACT_DAYREECHARGE, 10306).         %% 开服日冲
-define(ITEM_GAIN_ACT_ACCREECHARGE, 10307).         %% 开服累充
-define(ITEM_GAIN_ACT_FIRSTREECHARGE, 10308).       %% 开服首冲
-define(ITEM_GAIN_ACT_CLWORD, 10309).               %% 集字
-define(ITEM_GAIN_ACT_SEVEN_LOGIN, 10310).          %% 七日登陆
-define(ITEM_GAIN_MARKET_OFF_SHELVES, 10311).       %% 拍卖流拍回退
-define(ITEM_GAIN_MARKET, 10312).                   %% 拍卖获得
-define(ITEM_GAIN_MARKET_REVOKE, 10313).            %% 拍卖撤回
-define(ITEM_GAIN_FAMILY_ANSWER, 10314).            %% 采集获得奖励
-define(ITEM_GAIN_FAMILY_TEMPLE, 10315).            %% 神殿俸禄
-define(ITEM_GAIN_ACT_ZERO_PANIC_BUY, 10316).       %% 零元抢购
-define(ITEM_GAIN_LEVEL_PANIC_BUY,10317).           %% 等级限时购买
-define(ITEM_GAIN_FAMILY_DAY_REWARD,10318).         %% 仙盟每日奖励
-define(ITEM_GAIN_FAMILY_BATTLE_RANK, 10319).       %% 仙盟战排名奖励
-define(ITEM_GAIN_ACT_ZERO_RETURN, 10320).          %% 0元限购返还
-define(ITEM_GAIN_ADDICT, 10321).                   %% 实名认证获取
-define(ITEM_GAIN_LETTER_DAILY_TOWER, 10322).       %% 爬塔日常奖励
-define(ITEM_GAIN_LETTER_PAY_GIFT, 10324).          %% 充值礼包返还
-define(ITEM_GAIN_LETTER_JUNHAI_GIFT, 10325).       %% 君海礼包发放
-define(ITEM_GAIN_LETTER_WEB_SINGLE, 10326).        %% 后台接口获得
-define(ITEM_GAIN_LETTER_WEB_ALL, 10327).           %% 全服邮件获得
-define(ITEM_GAIN_LETTER_ANSWER_REWARD, 10328).     %% 答题奖励发放
-define(ITEM_GAIN_LETTER_FAMILY_ANSWER, 10329).     %% 仙盟晚宴排行奖励
-define(ITEM_GAIN_LETTER_FB_ROUND, 10330).          %% 仙盟战区域胜败奖励
-define(ITEM_GAIN_LETTER_FB_TITLE, 10331).          %% 仙盟战称号奖励
-define(ITEM_GAIN_LETTER_FAMILY_BT_END_CV, 10332).  %% 仙盟战终结连胜
-define(ITEM_GAIN_LETTER_FAMILY_BT_CV, 10333).      %% 仙盟战连胜
-define(ITEM_GAIN_LETTER_MARKET_BUY, 10334).        %% 市场购买获得
-define(ITEM_GAIN_LETTER_MARKET_SELL, 10335).       %% 市场贩卖获得元宝
-define(ITEM_GAIN_LETTER_MARKET_TIMEOUT, 10336).    %% 市场上架超时获得
-define(ITEM_GAIN_COMMENT_REWARD, 10337).           %% 好评奖励获得
-define(ITEM_GAIN_ACT_FAMILY_CREATE, 10338).        %% 开宗立派活动获得
-define(ITEM_GAIN_ACT_FAMILY_BATTLE, 10339).        %% 仙盟争霸活动获得
-define(ITEM_GAIN_ACT_HUNT_BOSS, 10340).            %% 猎杀boss活动获得
-define(ITEM_GAIN_MARRY_PROPOSE_REFUSE, 10341).     %% 提亲被拒/超时返还
-define(ITEM_GAIN_MARRY_PROPOSE_SUCC, 10342).       %% 提亲成功获得
-define(ITEM_GAIN_MARRY_TREE_REWARD, 10343).        %% 姻缘树奖励
-define(ITEM_GAIN_CONFINE_MISSION, 10344).          %% 渡劫任务
-define(ITEM_GAIN_MARRY_COPY_REWARD, 10345).        %% 姻缘副本奖励
-define(ITEM_GAIN_LIMITEDTIME_BUY_BIG_REWARD, 10346).%% 云购大奖
-define(ITEM_GAIN_LIMITEDTIME_BUY, 10347).          %% 云购
-define(ITEM_GAIN_MARRY_APPOINT, 10348).            %% 预约婚礼获得奖励
-define(ITEM_GAIN_MARRY_GUEST, 10349).              %% 成为宾客获得奖励
-define(ITEM_GAIN_DAY_TARGET_REWARD, 10350).        %% 七日目标 - 普通奖励
-define(ITEM_GAIN_DAY_TARGET_PROGRESS, 10351).      %% 七日目标 - 进度奖励
-define(ITEM_GAIN_RESOURCE_RETRIEVE, 10352).        %% 资源找回获得奖励
-define(ITEM_GAIN_DOWNLOAD_STATUS, 10353).          %% 下载完成获得奖励
-define(ITEM_GAIN_ACT_ACC_CONSUME, 10354).          %% 累积消费获得奖励
-define(ITEM_GAIN_ACT_RANK_BUY, 10355).             %% 开服冲榜购买获得道具
-define(ITEM_GAIN_BG_ACT_RECHARGE, 10356).          %% 充值有礼
-define(ITEM_GAIN_BG_ACT_STORE, 10357).             %% 商店
-define(ITEM_GAIN_SUMMIT_TREASURE, 10358).          %% 巅峰寻宝获得
-define(ITEM_GAIN_WEEK_CARD, 10359).                %% 周卡获得
-define(ITEM_GAIN_WAR_SPIRIT_DECOMPOSE, 10360).     %% 灵饰分解获得
-define(ITEM_GAIN_TREVI_FOUNTAIN, 10361).           %% 许愿池抽奖
-define(ITEM_GAIN_TREVI_FOUNTAIN_REWARD, 10362).    %% 许愿池兑奖
-define(ITEM_GAIN_ACT_MARRY_THREE_LIFE, 10363).     %% 三生三世活动奖励
-define(ITEM_GAIN_PAY_BACK, 10364).                 %% 封测预充值返还
-define(ITEM_GAIN_OSS_REWARD, 10365).               %% 开服二阶活动奖励
-define(ITEM_GAIN_HUNT_TREASURE_ITEM, 10366).       %% 打开藏宝图获得宝珠
-define(ITEM_GAIN_HUNT_TREASURE_SUCC, 10367).       %% 藏宝图挑战成功获得
-define(ITEM_GAIN_OSS_BUY, 10368).                  %% 开服二阶活动购买
-define(ITEM_GAIN_OSS_SEVEN, 10369).                %% 开服二阶七日
-define(ITEM_GAIN_EQUIP_SEAL_PUNCH, 10370).         %% 纹印镶嵌替换获得
-define(ITEM_GAIN_EQUIP_SEAL_REMOVE, 10371).        %% 纹印移除获得
-define(ITEM_GAIN_SEAL_COMPOSE, 10372).             %% 纹印合成获得
-define(ITEM_GAIN_OSS_TREVI_FOUNTAIN, 10373).       %% 开服二阶许愿积分
-define(ITEM_GAIN_SUMMIT_INVEST, 10374).            %% 化神投资领取获得
-define(ITEM_GAIN_OSS_FUNCTION, 10375).             %% 系统开启奖励
-define(ITEM_GAIN_BOSS_REWARD, 10376).              %% BOSS悬赏
-define(ITEM_GAIN_ACT_OTF, 10377).                  %% 开服仙途
-define(ITEM_GAIN_BG_ALCHEMY, 10378).               %% 炼丹
-define(ITEM_GAIN_BG_ACTIVE_TURNTABLE, 10379).      %% 活跃抽奖
-define(ITEM_GAIN_FIRST_BOSS_REWARD, 10380).        %% 世界boss奖励
-define(ITEM_GAIN_DEMON_BOSS, 10381).               %% 魔域boss归属奖励
-define(ITEM_GAIN_CAVE_ASSIST, 10382).              %% 洞天福地援助获得
-define(ITEM_GAIN_DABAO, 10383).                    %% 打宝
-define(ITEM_GAIN_SUIT_RETURN, 10384).              %% 套装部件分解返回
-define(ITEM_GAIN_CONFINE, 10385).                  %% 提升境界增加
-define(ITEM_GAIN_DIRECT_V4, 10386).                %% V4专属奖励
-define(ITEM_GAIN_GUIDE_BOSS_REWARD, 10387).        %% 世界boss引导归属奖励
-define(ITEM_GAIN_BLESS, 10388).                    %% 祈福
-define(ITEM_GAIN_DISCOUNT_PAY, 10389).             %% 特惠礼包充值获得
-define(ITEM_GAIN_DAILY_PANIC_BUY, 10390).          %% 每日限时购获得
-define(ITEM_GAIN_FGB_SELF, 10391).                 %% 道庭神兽个人
-define(ITEM_GAIN_FGB_INSPIRE, 10392).                 %% 道庭神兽个人鼓舞
-define(ITEM_GAIN_KING_GUARD, 10393).                 %% 开服买精灵王
-define(ITEM_GAIN_PET_SWALLOW, 10394).              %% 吞噬装备获得
-define(ITEM_GAIN_FAMILY_ASM, 10395).              %% 道庭任务获得
-define(ITEM_GAIN_FAMILY_ASM_SEEK_HELP, 10396).    %% 道庭任务帮助获得
-define(ITEM_GAIN_WAR_SPIRIT_ARMOR_UNLOAD, 10397). %% 战灵灵器卸载
-define(ITEM_GAIN_FAMILY_BOX, 10398).              %% 道庭宝箱
-define(ITEM_GAIN_FAIRY, 10399).                   %% 护送仙灵
-define(ITEM_GAIN_FAIRY_ROB, 10400).               %% 护送仙灵抢夺
-define(ITEM_GAIN_NATURE_DIS_BOARD, 10401).        %% 天机系统天机印卸下
-define(ITEM_GAIN_NATURE_SUBSTITUTE, 10402).        %% 天机系统天机印替换
-define(ITEM_GAIN_NATURE_RESOLVE, 10403).        %% 天机系统分解获得
-define(ITEM_GAIN_FIVE_ELEMENTS_UNLOCK, 10404).     %% 五行副本解锁获得
-define(ITEM_GAIN_ACT_STORE,10405).                 %% 活动商店
-define(ITEM_GAIN_ACT_TTA,10406).                   %% 神秘宝藏
-define(ITEM_GAIN_ACT_TTA_I,10408).                 %% 神秘宝藏多次
-define(ITEM_GAIN_ACT_TTB,10407).                   %% 神秘宝藏秘境
-define(ITEM_GAIN_DEMON_BOSS_HP_REWARD, 10409).     %% 魔域boss参与奖励发放
-define(ITEM_GAIN_SUMMER_RECHARGE ,10410).          %% 夏日活动充值
-define(ITEM_GAIN_CONSUME_RANK ,10411).             %% 夏日活动消费排行
-define(ITEM_GAIN_NEW_ALCHEMY_A ,40415).            %%  仙品炼丹炉
-define(ITEM_GAIN_DISCOUNT_DAILY, 10412).           %% 特惠-每日活跃礼包获得
-define(ITEM_GAIN_TIME_STORE,10414).                %%  限时商店
-define(ITEM_GAIN_NEW_ALCHEMY_B,10416).             %%  凡品炼丹炉
-define(ITEM_GAIN_FIVE_ELEMENTS_PASS, 10417).       %% 五行秘境通关获得
-define(ITEM_GAIN_BG_WEEK_TWO, 10418).              %% 第二周 充值大礼
-define(ITEM_GAIN_BG_QINXIN, 10419).              %% 一见倾心
-define(ITEM_GAIN_MINING_GOODS, 10420).             %% 秘境探索（挖矿）获得
-define(ITEM_GAIN_DAY_BOX, 10421).                  %% 每日礼包
-define(ITEM_GAIN_SERVER_MERGE, 10422).             %% 合服获得
-define(ITEM_GAIN_NATURE_COMPOSE, 10423).           %% 天机印合成获得
-define(ITEM_GAIN_SOLO_SINGLE_SERVER_AWARD,10424).  %% 单服论剑排名奖励
-define(ITEM_GAIN_SOLO_SPAN_SERVER_AWARD,  10425).  %% 跨服论剑排名奖励
-define(ITEM_GAIN_FIRST_RECHARGE,  10426).          %% 首充返元宝
-define(ITEM_GAIN_LUCKY_TOKEN, 10427).              %% 幸运上上签获得
-define(ITEM_GAIN_EGG_REWARD, 10428).               %% 砸蛋累计
-define(ITEM_GAIN_EGG, 10429).                      %% 砸蛋
-define(ITEM_GAIN_IDENTIFY_TREASURE_RARE_REWARD,  10430).  %% 鉴宝活动稀有奖励获取
-define(ITEM_GAIN_IDENTIFY_TREASURE_ONE_REWARD,  10431).  %% 鉴宝活动普通奖励获取
-define(ITEM_GAIN_FASHION_GIVE, 10432).             %% 时装赠送
-define(ITEM_GAIN_ACT_CHOOSE_REWARD,  10433).  %% 黑市鉴宝活动抽取获取
-define(ITEM_GAIN_ACT_OBTAIN,  10434).      %% 拍卖行下架获得
-define(ITEM_GAIN_UNIVERSE_ADMIRE, 10435).          %% 太虚通天塔膜拜获得
-define(ITEM_GAIN_ACT_TRENCH_CEREMONY,  10436).      %% 绝版壕礼获得
-define(ITEM_GAIN_UNIVERSE_POWER_SET, 10437).       %% 太虚通天塔--战力设置发放奖励
-define(ITEM_GAIN_CYCLE_TOWER, 10438).              %% 周期活动通天宝塔
-define(ITEM_GAIN_ACT_ESOTERICA_ORDINARY, 10439).       %% 领取修炼秘籍系统的凡籍
-define(ITEM_GAIN_ACT_ESOTERICA_CELESTIAL, 10440).      %% 领取修炼秘籍系统的仙籍
-define(ITEM_GAIN_ACT_ESOTERICA_SERVER_AWARD,10441).    %% 领取修炼秘籍系统没领取奖励
-define(ITEM_GAIN_ACT_TREASURE_CHEST,  10442).          %% 欢乐宝箱获得
-define(ITEM_GAIN_ACT_CYCLE_MISSION,  10443).           %% 全城热恋
-define(ITEM_GAIN_MARRY_FAIRY_REWARD, 10444).           %% 仙侣互赠获得

-define(ITEM_GAIN_CYCLE_ACT_COUPLE_LOGIN, 10450).   %% 一见钟情登录获得
-define(ITEM_GAIN_CYCLE_ACT_PROPOSE_REWARD, 10451). %% 告别单身奖励
-define(ITEM_GAIN_CYCLE_ACT_PRAY, 10452).           %% 月下情人抽奖获得
-define(ITEM_GAIN_CYCLE_ACT_PRAY_EXCHANGE, 10453).  %% 月下情人兑换获得
-define(ITEM_GAIN_CYCLE_ACT_COUPLE_CHARM, 10454).   %% 魅力之王排行获得

-define(ITEM_GAIN_AUCTION_BUY, 10500).              %% 竞拍购买获得
-define(ITEM_GAIN_AUCTION_REWARD, 10501).           %% 竞拍获得元宝
-define(ITEM_GAIN_AUCTION_RETURN, 10502).           %% 竞拍流拍返还
-define(ITEM_GAIN_AUCTION_COMPETE_RETURN, 10503).   %% 竞拍失败返还元宝

-define(ITEM_GAIN_TTC_BUY, 10504).                  %% 后台商城
-define(ITEM_GAIN_TOWER, 10505).                    %% 通天宝塔

-define(ITEM_GAIN_WEB_SUPPORT, 10999).              %% 后台扶持号

%%添加ACTION时注意，  非系统首次产生已获得物品   例：装备替换 帮派兑换获得（合成统一例外，算作系统首次产生）
-define(NON_SYSTEM_CREATE,[?ITEM_GAIN_FAMILY_DEPOT,?ITEM_GAIN_EQUIP_REPLACE,?ITEM_GAIN_EQUIP_STONE_PUNCH,?ITEM_GAIN_EQUIP_STONE_REMOVE,
    ?ITEM_GAIN_VIP_EXPIRE_STONE,?ITEM_GAIN_BEOVERDUE, ?ITEM_GAIN_MARKET_OFF_SHELVES, ?ITEM_GAIN_MARKET_REVOKE,
    ?ITEM_GAIN_LETTER_MARKET_BUY, ?ITEM_GAIN_LETTER_MARKET_SELL, ?ITEM_GAIN_LETTER_MARKET_TIMEOUT, ?ITEM_GAIN_MARRY_PROPOSE_REFUSE,
    ?ITEM_GAIN_WAR_SPIRIT_ARMOR_UNLOAD,?ITEM_GAIN_NATURE_DIS_BOARD, ?ITEM_GAIN_NATURE_SUBSTITUTE, ?ITEM_GAIN_SUIT_RETURN,
    ?ITEM_GAIN_AUCTION_BUY, ?ITEM_GAIN_AUCTION_REWARD, ?ITEM_GAIN_AUCTION_RETURN, ?ITEM_GAIN_WEB_SUPPORT]).

%% 获得公告忽略的行为
-define(ITEM_COMMON_NOTICE_IGNORE, [?ITEM_GAIN_AUCTION_BUY, ?ITEM_GAIN_EQUIP_REPLACE, ?ITEM_GAIN_WING_LOAD, ?ITEM_GAIN_EQUIP_STONE_REMOVE, ?ITEM_GAIN_VIP_EXPIRE_STONE,
    ?ITEM_GAIN_BEOVERDUE, ?ITEM_GAIN_WAR_SPIRIT_ARMOR_UNLOAD, ?ITEM_GAIN_AUCTION_RETURN, ?ITEM_GAIN_WEB_SUPPORT]).


%% 失去
-define(ITEM_REDUCE_GM, 20000).                     %% GM扣除
-define(ITEM_REDUCE_EXTRA_COMPOSE, 20001).          %% 合成扣除
-define(ITEM_REDUCE_ITEM_USE, 20002).               %% 道具使用扣除
-define(ITEM_REDUCE_ITEM_SELL, 20003).              %% 道具出售扣除
-define(ITEM_REDUCE_MAP_TRANSFER, 20004).           %% 地图传送扣除
-define(ITEM_REDUCE_FAMILY_DONATE, 20005).          %% 帮派捐献扣除
-define(ITEM_REDUCE_ENTER_MAP, 20006).              %% 进入地图扣除
-define(ITEM_REDUCE_COPY_CLEAN, 20007).             %% 副本扫荡扣除
-define(ITEM_REDUCE_BAG_GRID_OPEN, 20008).          %% 背包格子开启扣除
-define(ITEM_REDUCE_EQUIP_TREASURE, 20009).         %% 装备寻宝扣除
-define(ITEM_REDUCE_RUNE_TREASURE, 20010).          %% 符文寻宝扣除
-define(ITEM_REDUCE_RUNE_CONFINE, 20011).           %% 提升境界扣除
-define(ITEM_REDUCE_MISSION_ITEM, 20012).           %% 完成任务提交物品
-define(ITEM_REDUCE_FASHION_DECOMPOSE, 20013).      %% 时装分解
-define(ITEM_REDUCE_ROLE_RENAME, 20014).            %% 角色改名扣除
-define(ITEM_REDUCE_FAMILY_RENAME, 20015).          %% 仙盟改名扣除
-define(ITEM_REDUCE_EQUIP_SUIT, 20101).             %% 装备套装升级扣除
-define(ITEM_REDUCE_EQUIP_PUNCH, 20102).            %% 装备镶嵌扣除
-define(ITEM_REDUCE_EQUIP_COMPOSE, 20103).          %% 装备合成扣除
-define(ITEM_REDUCE_STONE_COMPOSE, 20104).          %% 宝石合成扣除
-define(ITEM_REDUCE_EQUIP_CONCISE, 20105).          %% 装备洗练扣除
-define(ITEM_REDUCE_SELECT_ITEM, 20106).            %% 道具选择扣除
-define(ITEM_REDUCE_GOD_WEAPON_ACTIVATE, 20201).    %% 激活神兵扣除
-define(ITEM_REDUCE_GOD_WEAPON_REFINE, 20202).      %% 神兵炼化扣除
-define(ITEM_REDUCE_GOD_WEAPON_LEVEL, 20203).       %% 神兵升级扣除
-define(ITEM_REDUCE_MAGIC_WEAPON_ACTIVATE, 20301).  %% 激活法宝扣除
-define(ITEM_REDUCE_MAGIC_WEAPON_LEVEL, 20302).     %% 法宝升级扣除
-define(ITEM_REDUCE_MOUNT_STEP, 20401).             %% 坐骑进阶扣除
-define(ITEM_REDUCE_MOUNT_QUALITY, 20402).          %% 坐骑提升资质扣除
-define(ITEM_REDUCE_MOUNT_POTENTIAL, 20403).        %% 坐骑提升潜能扣除
-define(ITEM_REDUCE_MOUNT_STAR, 20404).             %% 坐骑提星扣除
-define(ITEM_REDUCE_MOUNT_SKIN, 20405).             %% 坐骑皮肤提星扣除
-define(ITEM_REDUCE_PET_LEVEL, 20502).              %% 宠物升级扣除
-define(ITEM_REDUCE_WING_REFINE, 20601).            %% 翅膀炼化扣除
-define(ITEM_REDUCE_WING_LEVEL, 20602).             %% 翅膀升级扣除
-define(ITEM_REDUCE_DO_FAIRY, 20603).               %% 仙灵任务扣除
-define(ITEM_REDUCE_ACT_CLWORD, 20604).             %% 集字扣除
-define(ITEM_REDUCE_MARKET_ON_SHELF, 20605).        %% 拍卖上架
-define(ITEM_REDUCE_MARKET_SELL, 20606).            %% 求购市场上出售
-define(ITEM_REDUCE_FAMILY_BOSS_GRAIN, 20607).      %% 仙盟兽粮提交
-define(ITEM_REDUCE_CREATE_FAMILY, 20608).          %% 创建仙盟
-define(ITEM_REDUCE_CONFINE_UP, 20609).             %% 渡劫突破境界
-define(ITEM_REDUCE_WAR_SPIRIT, 20610).             %% 战灵升级
-define(ITEM_REDUCE_MARRY_WISH, 20611).             %% 婚礼祝福失去
-define(ITEM_REDUCE_FLOWER_SEND, 20612).            %% 送花失去
-define(ITEM_REDUCE_DESTINY_UP, 20613).             %% 命格点亮扣除
-define(ITEM_REDUCE_MYTHICAL_STATUS, 20614).        %% 增加魂兽上限扣除
-define(ITEM_REDUCE_PET_SURFACE_ACTIVATE, 20615).   %% 宠物幻化激活扣除
-define(ITEM_REDUCE_PET_SURFACE_STEP, 20616).       %% 宠物幻化激活扣除
-define(ITEM_REDUCE_MOUNT_SURFACE_ACTIVATE, 20617). %% 坐骑幻化激活扣除
-define(ITEM_REDUCE_MOUNT_SURFACE_STEP, 20618).     %% 坐骑幻化激活扣除
-define(ITEM_REDUCE_SUMMIT_TREASURE, 20619).        %% 巅峰寻宝扣除
-define(ITEM_REDUCE_TALENT_SKILL_RESET, 20620).     %% 天赋技能重置扣除
-define(ITEM_REDUCE_SEND_RED_PACKET, 20621).        %% 发红包
-define(ITEM_REDUCE_JEWELRY_STEP, 20622).           %% 首饰进阶（手镯，戒指）扣除
-define(ITEM_REDUCE_WAR_SPIRIT_EQUIP_STEP, 20623).  %% 战灵灵饰进阶
-define(ITEM_REDUCE_HANDBOOK_CATIVATE, 20624).      %% 图鉴卡片激活扣除
-define(ITEM_REDUCE_HANDBOOK_RESOLVE, 20625).       %% 图鉴材料分解扣除
-define(ITEM_REDUCE_HANDBOOK_UPGRADE, 20626).       %% 图鉴升级扣除
-define(ITEM_REDUCE_TREVI_FOUNTAIN, 20627).         %% 许愿池
-define(ITEM_REDUCE_THRONE_RESOLVE, 20628).         %% 宝座材料分解扣除
-define(ITEM_REDUCE_THRONE_SURFACE_ACT, 20629).     %% 宝座幻化激活扣除
-define(ITEM_REDUCE_THRONE_SURFACE_UPGRADE, 20630). %% 宝座幻化升级扣除
-define(ITEM_REDUCE_FORGE_SOUL_CULTIVATE_UPGRADE, 20631).   %% 镇魂养成升级扣除
-define(ITEM_REDUCE_SEAL_COMPOSE, 20632).           %% 纹印合成扣除
-define(ITEM_REDUCE_STONE_HONING, 20633).           %% 宝石淬炼扣除
-define(ITEM_REDUCE_GUARD, 20634).                  %% 摧毁小精灵
-define(ITEM_REDUCE_SUIT_STAR, 20635).              %% 套装系统升星扣除
-define(ITEM_REDUCE_SKILL_UP, 20636).               %% 技能升级扣除
-define(ITEM_REDUCE_SEAL_RESET, 20637).             %% 技能铭文重置扣除
-define(ITEM_REDUCE_MAGIC_WEAPON_LEVEL_UP, 20638).  %% 法宝升级
-define(ITEM_REDUCE_SEAL_CHOOSE, 20639).            %% 铭文选择扣除
-define(ITEM_REDUCE_SEAL_LEVEL, 20640).             %% 铭文升级扣除
-define(ITEM_REDUCE_AUCTION_SELL, 20641).           %% 拍卖行出售扣除
-define(ITEM_REDUCE_WAR_SPIRIT_ARMOR_LOAD, 20642).  %% 战灵装备灵器扣除
-define(ITEM_REDUCE_NATURE_INSTALL,        20643).  %% 天机系统天机印装备
-define(ITEM_REDUCE_NATURE_REFINE,        20644).   %% 天机系统强化扣除
-define(ITEM_REDUCE_NATURE_RESOLVE,        20645).  %% 天机系统分解扣除
-define(ITEM_REDUCE_ACT_STORE,        20646).       %% 仙途商店
-define(ITEM_REDUCE_BG_TREASURE_TROVE,  20647).     %% 后台宝藏抽奖
-define(ITEM_REDUCE_PELLET_MEDICINE,  20648).       %% 丹药系统扣除
-define(ITEM_REDUCE_NEW_ALCHEMY_A,  20649).         %% 仙品丹炉
-define(ITEM_REDUCE_NEW_ALCHEMY_B,  20650).         %% 凡品丹炉扣除
-define(ITEM_REDUCE_NATURE_PLACE_OPEN,    20651).   %% 天机系统孔开启扣除
-define(ITEM_REDUCE_NATURE_COMPOSE, 20652).         %% 天机印合成扣除
-define(ITEM_REDUCE_EQUIP_OPEN, 20653).             %% 装备开孔道具扣除
-define(ITEM_REDUCE_EGG, 20654).                    %% 砸蛋
-define(ITEM_REDUCE_CYCLE_ACT_COUPLE_PRAY, 20655).  %% 月下情缘
-define(ITEM_REDUCE_MARRY_FAIRY, 20656).            %% 仙侣互赠扣除

%%%===================================================================
%%% 玩家道具获取日志 end
%%%===================================================================


%%%===================================================================
%%% 玩家银两日志 start
%%%===================================================================
%% 表格相关字段
%% {<<"role_id">>, <<"action">>, <<"silver">>, <<"remain_silver">>}
%% 银两获得30000-39999
-define(ASSET_SILVER_ADD_FROM_GM, 30000).               %% GM途径获得
-define(ASSET_SILVER_ADD_FROM_ITEM, 30001).             %% 银两道具获得
-define(ASSET_SILVER_ADD_FROM_SELL_ITEM, 30002).        %% 出售道具获得
-define(ASSET_SILVER_ADD_FROM_OFFLINE_SOLO, 30003).     %% 离线1v1获得
-define(ASSET_SILVER_ADD_FROM_WORLD_ROBOT, 30005).      %% 离线挂机获得
-define(ASSET_SILVER_ADD_FROM_BLESS, 30006).            %% 祈福
-define(ASSET_SILVER_ADD_FROM_ALCHEMY, 30007).          %% 炼丹
-define(ASSET_GOLD_ADD_FROM_BG_NEW_ALCHEMY, 30008).     %% 新炼丹炉
-define(ASSET_GOLD_ADD_FROM_MONEY_TREE, 30009).         %% 摇钱树
-define(ASSET_GOLD_ADD_FROM_CYCLE_TOWER, 30010).        %% 周期活动
-define(ASSET_SILVER_ADD_FROM_ACT_RED_PACKET, 30011).   %% 全服红包获得

%% 银两失去40000-49999
-define(ASSET_SILVER_REDUCE_FROM_GM, 40000).            %% GM途径失去
-define(ASSET_SILVER_REDUCE_FROM_COPY_CHEER, 40001).    %% 经验副本鼓舞失去
-define(ASSET_SILVER_REDUCE_FROM_EQUIP_REFINE, 40002).  %% 装备炼化失去
-define(ASSET_SILVER_REDUCE_FROM_SHOP_BUY, 40003).      %% 商店购买失去
-define(ASSET_SILVER_REDUCE_FROM_WING_STAR, 40004).     %% 翅膀提星失去
-define(ASSET_SILVER_REDUCE_RESOURCE_RETRIEVE, 40005).  %% 资源找回失去
-define(ASSET_SILVER_REDUCE_FAMILY_CREATE, 40006).      %% 创建道庭

%%%===================================================================
%%% 玩家银两日志 end
%%%===================================================================



%%%===================================================================
%%% 玩家元宝日志 start
%%%===================================================================
%% {<<"role_id">>, <<"action">>, <<"gold">>, <<"bind_gold">>, <<"remain_gold">>, <<"remain_bind_gold">>}
%% 元宝获得50000-59999
-define(ASSET_GOLD_ADD_FROM_PAY, 50000).                %% 充值获得
-define(ASSET_GOLD_ADD_FROM_BACK_SEND, 50001).          %% 游戏内部发放
-define(ASSET_GOLD_ADD_FROM_PAY_SEND, 50003).           %% 充值赠送获得
-define(ASSET_GOLD_ADD_FROM_GM, 50004).                 %% GM命令获得
-define(ASSET_GOLD_ADD_FROM_ITEM, 50005).               %% 元宝道具获得
-define(ASSET_GOLD_ADD_FROM_MONTH_CARD, 50006).         %% 月卡获得
-define(ASSET_GOLD_ADD_FROM_INVEST_GOLD, 50007).        %% 投资计划获得
-define(ASSET_GOLD_ADD_FROM_GIVE_RED_PACKET, 50009).    %% 仙盟红包
-define(ASSET_GOLD_ADD_FROM_MARKET_DOWN_SELF, 50010).   %% 下架商品获得
-define(ASSET_GOLD_ADD_FROM_MARRY_WISH, 50011).         %% 婚礼赠送元宝获得
-define(ASSET_GOLD_ADD_FROM_PAY_GOLD_ITEM, 50012).      %% 使用充值效道具获得
-define(ASSET_GOLD_ADD_FROM_OSS_SEVEN, 50013).          %% 冲榜7天投资
-define(ASSET_GOLD_ADD_FROM_ALCHEMY, 50014).            %% 炼丹
-define(ASSET_GOLD_ADD_FROM_BG_TURNTABLE, 50015).       %% 充值转盘
-define(ASSET_GOLD_ADD_FROM_LUCKY_CAT, 50016).           %% 招财猫
-define(ASSET_GOLD_ADD_FROM_ACT_RED_PACKET, 50017).     %% 全服红包获得

%% 元宝失去60000-69999
-define(ASSET_GOLD_REDUCE_FROM_GM, 60000).              %% GM命令失去
-define(ASSET_GOLD_REDUCE_FROM_COPY_CHEER, 60001).      %% 经验副本鼓舞失去
-define(ASSET_GOLD_REDUCE_FROM_FAMILY_CREATE, 60002).   %% 创建仙盟失去
-define(ASSET_GOLD_REDUCE_FROM_MAP_RELIVE, 60003).      %% 复活失去
-define(ASSET_GOLD_REDUCE_FROM_MOUNT_STEP, 60004).      %% 坐骑升阶失去
-define(ASSET_GOLD_REDUCE_FROM_SHOP_BUY, 60005).        %% 商店购买失去
-define(ASSET_GOLD_REDUCE_FROM_WING_STAR, 60006).       %% 翅膀提星失去
-define(ASSET_GOLD_REDUCE_FROM_VIP_BUY, 60008).         %% VIP购买失去
-define(ASSET_GOLD_REDUCE_FROM_ENTER_MAP, 60009).       %% 进入野外地图扣除元宝
-define(ASSET_GOLD_REDUCE_FROM_OFFLINE_SOLO, 60010).    %% 购买挑战次数失去
-define(ASSET_GOLD_REDUCE_FROM_COPY_BUY, 60011).        %% 购买副本次数失去
-define(ASSET_GOLD_REDUCE_FROM_EQUIP_TREASURE, 60012).  %% 装备寻宝失去
-define(ASSET_GOLD_REDUCE_FROM_RUNE_TREASURE, 60013).   %% 符文寻宝失去
-define(ASSET_GOLD_REDUCE_FROM_MONTH_CARD, 60014).      %% 购买月卡失去
-define(ASSET_GOLD_REDUCE_FROM_INVEST_GOLD, 60015).     %% 投资计划是去
-define(ASSET_GOLD_REDUCE_FROM_COPY_CD_REMOVE, 60016).  %% 清除副本CD失去
-define(ASSET_GOLD_REDUCE_FROM_GIVE_RED_PACKET, 60017). %% 发红包
-define(ASSET_GOLD_REDUCE_FROM_VIP_INVEST, 60018).      %% VIP投资计划购买失去
-define(ASSET_GOLD_REDUCE_FROM_USE_PACKAGE, 60019).     %% 使用礼包失去
-define(ASSET_GOLD_REDUCE_FROM_CONCISE_OPEN, 60020).    %% 洗练开启失去
-define(ASSET_GOLD_REDUCE_FROM_EQUIP_CONCISE, 60021).   %% 洗练装备失去
-define(ASSET_GOLD_REDUCE_FROM_IMMORTAL_SUMMON, 60022). %% 仙魂副本召唤boss失去
-define(ASSET_GOLD_REDUCE_FROM_BESTIR, 60023).          %% 购买元宝激励次数失去
-define(ASSET_GOLD_REDUCE_FROM_ACT_ZERO_PANIC_BUY, 60024).    %% 0元抢购
-define(ASSET_GOLD_REDUCE_FROM_LEVEL_PANIC_BUY,60025).  %% 等级限时抢购元宝失去
-define(ASSET_GOLD_REDUCE_FROM_MARRY_PROPOSE,  60026).  %% 求婚扣除元宝
-define(ASSET_GOLD_REDUCE_FROM_MARRY_TREE, 60027).      %% 购买姻缘树扣除
-define(ASSET_GOLD_REDUCE_FROM_LIMITEDTIME_BUY, 60028). %% 购买限时云购
-define(ASSET_GOLD_REDUCE_FROM_MARRY_ADD_GUEST, 60029). %% 增加宾客上限扣除
-define(ASSET_GOLD_REDUCE_FROM_MARRY_WISH, 60030).      %% 婚礼赠送元宝扣除
-define(ASSET_GOLD_REDUCE_FROM_MARRY_BUY_JOIN, 60031).  %% 购买成为宾客扣除
-define(ASSET_GOLD_REDUCE_FROM_RESOURCE_RETRIEVE, 60032).   %% 资源找回失去
-define(ASSET_GOLD_REDUCE_FROM_BLESS, 60033).           %% 祈福
-define(ASSET_GOLD_REDUCE_FROM_MYTHICAL_REFINE, 60034). %% 魂兽强化失去
-define(ASSET_GOLD_REDUCE_FROM_VIP_GIFT_BUY, 60035).    %% VIP等级礼包购买失去
-define(ASSET_GOLD_REDUCE_FROM_ACT_RANK_BUY, 60036).    %% 开服冲榜购买失去
-define(ASSET_GOLD_REDUCE_FROM_SUMMIT_TREASURE, 60037). %% 巅峰寻宝失去
-define(ASSET_GOLD_REDUCE_FROM_WEEK_DAY, 60038).        %% 周卡
-define(ASSET_GOLD_REDUCE_FROM_TREVI_FOUNTAIN, 60039).  %% 许愿池
-define(ASSET_GOLD_REDUCE_FROM_BIG_GUARD, 60040).       %% 开启大精灵部位
-define(ASSET_GOLD_REDUCE_FROM_OSS_WING, 60041).        %% 翅膀冲榜抢购
-define(ASSET_GOLD_REDUCE_FROM_OSS_MAGIC_WEAPON, 60042).%% 法宝冲榜抢购
-define(ASSET_GOLD_REDUCE_FROM_OSS_HANDBOOK, 60043).    %% 图鉴冲榜抢购
-define(ASSET_GOLD_REDUCE_FROM_OSS_SEVEN, 60044).       %% 冲榜七天投资
-define(ASSET_GOLD_REDUCE_FROM_OSS_LIMITED_PANIC_BUY, 60045).       %% 冲榜抢购
-define(ASSET_GOLD_REDUCE_FROM_SUMMIT_INVEST, 60046).   %% 化神投资
-define(ASSET_GOLD_REDUCE_FROM_VIP_DIRECT_V4, 60047).   %% 直升V4花费元宝
-define(ASSET_GOLD_REDUCE_FROM_ALCHEMY, 60048).         %% 炼丹
-define(ASSET_GOLD_REDUCE_FROM_MISSION_ONE_KEY, 60049). %% 一键完成任务
-define(ASSET_GOLD_REDUCE_FROM_FIRST_BOSS_BUY, 60050).  %% 购买世界boss次数
-define(ASSET_GOLD_REDUCE_FROM_DEMON_BOSS_CHEER, 60051).%% 魔域boss鼓舞扣除
-define(ASSET_GOLD_REDUCE_FROM_WORLD_BOSS_HP, 60052).   %% 世界boss血量恢复扣除
-define(ASSET_GOLD_REDUCE_FROM_DAILY_PANIC_BUY, 60053). %% 每日限时购扣除
-define(ASSET_GOLD_REDUCE_FROM_COPY_CLEAN, 60054).      %% 副本扫荡扣除
-define(ASSET_GOLD_REDUCE_FROM_FGB_INSPIRE, 60055).     %% 道庭神兽鼓舞
-define(ASSET_GOLD_REDUCE_FROM_TREASURE_TROVE, 60056).  %% 宝藏
-define(ASSET_GOLD_REDUCE_FROM_BG_STORE, 60057).        %% 宝藏商店
-define(ASSET_GOLD_REDUCE_FROM_FAMILY_DO_REF, 60063).   %% 道庭任务元宝刷新
-define(ASSET_GOLD_REDUCE_FROM_MONEY_TREE, 60061).      %% 摇钱树
-define(ASSET_GOLD_REDUCE_MINING_INSPIRE, 60062).      %% 秘境探索（挖矿）鼓舞扣除
-define(ASSET_GOLD_REDUCE_FROM_BG_QINXIN, 60058).       %% 一见倾心
-define(ASSET_GOLD_REDUCE_FROM_NEW_ALCHEMY_A, 60059).   %% 仙品丹炉
-define(ASSET_GOLD_REDUCE_FROM_BG_TIME_STORE, 60060).   %% 仙人指路
-define(ASSET_GOLD_REDUCE_FROM_ILLUSION_BUY, 60071).    %% 购买幻力失去
-define(ASSET_GOLD_REDUCE_FROM_LUCKY_TOKEN, 60072).     %% 幸运上上签购买失去
-define(ASSET_GOLD_IDENTIFY_TREASURE_BEGIN, 60073).     %% 鉴宝活动鉴宝扣除
-define(ASSET_GOLD_REDUCE_FROM_REFRESH_EGG, 60074).     %% 砸蛋刷蛋
-define(ASSET_GOLD_REDUCE_FROM_EGG, 60076).             %% 砸蛋
-define(ASSET_GOLD_REDUCE_FROM_LUCKY_CAT, 60077).       %% 招財貓失去
-define(ASSET_GOLD_REDUCE_FROM_CYCLE_TOWER, 60078).     %% 周期活动通天宝塔
-define(ASSET_GOLD_ACT_ESOTERICA_RECOVERY_PRICE, 60079).     %% 修炼秘籍系统的修炼点找回
-define(ASSET_GOLD_REDUCE_FROM_CYCLE_ACT_COUPLE_PRAY, 60080).   %% 月下情缘抽取扣除

%% >= 65000的花费，不计算在VIP花费
-define(ASSET_GOLD_REDUCE_FROM_MARKET_DEMAND, 65000).   %% 市场求购
-define(ASSET_GOLD_REDUCE_FROM_MARKET_BUY, 65001).      %% 市场购买商品
-define(ASSET_GOLD_REDUCE_FROM_AUCTION_BUY, 65002).     %% 拍卖行购买失去
%%%===================================================================
%%% 玩家元宝日志 end
%%%===================================================================



%%%===================================================================
%%% 玩家积分类日志 start
%%%===================================================================
%% {<<"role_id">>, <<"action">>, <<"key">>, <<"score">>, <<"remain_score">>}
%% 积分获得70000-79999
-define(ASSET_SCORE_ADD_FROM_GM, 70000).                        %% GM途径获得
-define(ASSET_GLORY_ADD_FROM_ITEM, 70001).                      %% 使用道具获得荣耀
-define(ASSET_GLORY_ADD_FROM_SOLO_DAILY_REWARD, 70002).         %% 1v1日常获得荣耀
-define(ASSET_GLORY_ADD_FROM_OFFLINE_SOLO, 70003).              %% 离线1v1排名获得荣耀
-define(ASSET_FAMILY_CON_ADD_FROM_ITEM, 70004).                 %% 道具生成帮贡
-define(ASSET_FAMILY_CON_ADD_FROM_USE_ITEM, 70005).             %% 道具使用加帮贡
-define(ASSET_TREASURE_SCORE_ADD_FROM_EQUIP_TREASURE, 70006).   %% 装备寻宝增加寻宝积分
-define(ASSET_FAMILY_BOSS_GRAIN_TURN_OVER, 70007).              %% 仙盟兽粮上缴获得帮贡
-define(ASSET_GLORY_ADD_FROM_OFFLINE_CHALLENGE, 70009).         %% 离线1v1挑战获得荣耀
-define(ASSET_FAMILY_AS_TURN_OVER, 70010).                      %% 仙盟答题活动获得贡献
-define(ASSET_GLORY_ADD_FROM_SOLO_END, 70011).                  %% 1v1结束获得荣耀
-define(ASSET_FAMILY_BOSS_TURN_OVER, 70012).                    %% 仙盟兽粮
-define(ASSET_TREASURE_SCORE_ADD_FROM_SUMMIT_TREASURE, 70013).  %% 巅峰寻宝增加寻宝积分
-define(ASSET_WAR_GOD_SCORE_ADD_FROM_DECOMPOSE, 70014).         %% 分解获得玄晶
-define(ASSET_FROM_LIVENESS, 70015).                            %% 活跃度增加累计活跃度
-define(ASSET_FAMILY_SCORE_FROM_FAMILY_TD, 70016).              %% 守卫仙盟增加帮派贡献
-define(ASSET_GLORY_ADD_FROM_TEAM_COPY, 70017).                 %% 组队副本助战获得

%% 积分失去80000-89999
-define(ASSET_SCORE_REDUCE_FROM_GM, 80000).             %% GM途径失去
-define(ASSET_SCORE_REDUCE_FROM_FAMILY_SKILL, 80001).   %% 升级仙盟技能失去
-define(ASSET_SCORE_REDUCE_FROM_SHOP, 80002).           %% 购买商城商品失去失去
-define(ASSET_FORGE_SOUL_REDUCE_FROM_FORGE_SOUL_CULTIVATE, 80003).   %% 铸魂养成升级时的失去
-define(ASSET_SCORE_REDUCE_FROM_WAR_GOD_REFINE, 80004). %% 战神套装开光失去
%%%===================================================================
%%% 玩家积分类日志 end
%%%===================================================================


%%%===================================================================
%%% 玩家升级行为日志 start
%%%===================================================================
%% 90000-90999 玩家经验获得
-define(EXP_ADD_FROM_GM, 90000).                %% GM命令获得经验
-define(EXP_ADD_FROM_KILL_MONSTER, 90001).      %% 杀怪获得经验
-define(EXP_ADD_FROM_ITEM_USE, 90002).          %% 道具使用获得经验
-define(EXP_ADD_FROM_ANSWER, 90003).            %% 修仙论道获得经验
-define(EXP_ADD_FROM_COPY_CLEAN, 90004).        %% 副本扫荡获得经验
-define(EXP_ADD_FROM_FAIRLY, 90005).            %% 仙女护送获得经验
-define(EXP_ADD_FROM_FAMILY_ANSWER, 90006).     %% 仙盟答题获得经验
-define(EXP_ADD_FROM_FAMILY_TD, 90007).         %% 守卫仙盟获得经验
-define(EXP_ADD_FROM_MISSION, 90008).           %% 任务获得经验
-define(EXP_ADD_FROM_OFFLINE_SOLO, 90009).      %% 离线竞技获得经验
-define(EXP_ADD_FROM_WORLD_ROBOT, 90010).       %% 离线挂机获得经验
-define(EXP_ADD_FROM_SUMMIT_TOWER, 90011).      %% 青云之巅获得经验
-define(EXP_ADD_FROM_BATTLE, 90012).            %% 战场获得经验
-define(EXP_ADD_FROM_MARRY_FIREWORKS, 90013).   %% 烟花增加经验
-define(EXP_ADD_FROM_MARRY_COUNTER, 90014).     %% 在婚礼场景获得经验
-define(EXP_ADD_FROM_RESOURCE_RETRIEVE, 90015). %% 资源找回获得经验
-define(EXP_ADD_FROM_BLESS, 90016).             %% 祈福获得经验
-define(EXP_ADD_FROM_RELIVE_UP, 90017).         %% 天命觉醒升级
-define(EXP_ADD_FROM_MYTHICAL_LOOP, 90018).     %% 神兽岛加成经验
-define(EXP_ADD_FROM_GUIDE_COPY_EXP, 90019).    %% 经验副本差值经验修补
-define(EXP_ADD_FROM_FAIRLY_ROB, 90020).        %% 仙女护送抢夺获得经验
-define(EXP_ADD_FROM_PASSIVE_BLESS, 90021).     %% 被动闭关获得经验
-define(EXP_ADD_FROM_BATTLE_SCORE, 90022).      %% 战场积分奖励获得经验

%%%===================================================================
%%% 玩家升级行为日志 end
%%%===================================================================

%%%===================================================================
%%% 玩家战力变化日志 start
%%%===================================================================
%% 91000-91999 玩家经验获得
-define(POWER_UPDATE_LOAD_EQUIP, 91000).            %% 穿戴装备
-define(POWER_UPDATE_EQUIP_REFINE, 91001).          %% 装备强化
-define(POWER_UPDATE_EQUIP_STONE, 91002).           %% 灵石镶嵌
-define(POWER_UPDATE_EQUIP_REMOVE_STONE, 91004).    %% 灵石镶嵌
-define(POWER_UPDATE_EQUIP_SUIT, 91005).            %% 装备套装等级
-define(POWER_UPDATE_EQUIP_ONE_KEY_UP, 91006).      %% 灵石一键穿戴
-define(POWER_UPDATE_EQUIP_ONE_KEY_DOWN, 91007).    %% 灵石一键卸下
-define(POWER_UPDATE_EQUIP_CONCISE_OPEN, 91008).    %% 开启装备洗练孔数
-define(POWER_UPDATE_EQUIP_CONCISE, 91009).         %% 装备洗练
-define(POWER_UPDATE_CONFINE_UP, 91010).            %% 境界提升
-define(POWER_UPDATE_FAMILY_SKILL, 91011).          %% 仙盟技能提升
-define(POWER_UPDATE_FASHION_STAR, 91012).          %% 激活or升星时装
-define(POWER_UPDATE_FASHION_DECOMPOSE, 91013).     %% 时装分解
-define(POWER_UPDATE_GOD_WEAPON_STEP, 91014).       %% 神兵开启
-define(POWER_UPDATE_GOD_WEAPON_LEVEL, 91015).      %% 神兵升级
-define(POWER_UPDATE_GOD_WEAPON_SOUL, 91016).       %% 神兵丹药
-define(POWER_UPDATE_MAGIC_WEAPON_STEP, 91017).     %% 法宝开启
-define(POWER_UPDATE_MAGIC_WEAPON_LEVEL, 91018).    %% 法宝升级
-define(POWER_UPDATE_MAGIC_WEAPON_SOUL, 91019).     %% 法宝丹药
-define(POWER_UPDATE_WING_STEP, 91020).             %% 翅膀开启
-define(POWER_UPDATE_WING_LEVEL, 91021).            %% 翅膀升级
-define(POWER_UPDATE_WING_SOUL, 91022).             %% 翅膀丹药
-define(POWER_UPDATE_GUARD_LOAD, 91023).            %% 守护穿戴/脱下
-define(POWER_UPDATE_LEVEL_UP, 91024).              %% 角色升级
-define(POWER_UPDATE_MOUNT_STEP, 91025).            %% 坐骑升阶
-define(POWER_UPDATE_MOUNT_QUALITY, 91026).         %% 坐骑丹药
-define(POWER_UPDATE_MOUNT_SKIN, 91027).            %% 坐骑皮肤升星
-define(POWER_UPDATE_PET_STEP, 91028).              %% 宠物升阶
-define(POWER_UPDATE_PET_LEVEL, 91029).             %% 宠物升级
-define(POWER_UPDATE_PET_SOUL, 91030).              %% 宠物丹药
-define(POWER_UPDATE_RELIVE_STEP, 91032).           %% 转生等级提升
-define(POWER_UPDATE_RELIVE_PROGRESS, 91033).       %% 转生阶段提升
-define(POWER_UPDATE_RUNE_LEVEL_UP, 91034).         %% 符文升级
-define(POWER_UPDATE_RUNE_COMPOSE, 91035).          %% 符文合成
-define(POWER_UPDATE_RUNE_LOAD, 91036).             %% 符文装备
-define(POWER_UPDATE_PASSIVE_SKILL, 91037).         %% 被动技能提升
-define(POWER_UPDATE_TITLE_ADD, 91038).             %% 称号添加
-define(POWER_UPDATE_TITLE_DEL, 91039).             %% 称号移除
-define(POWER_UPDATE_VIP_ON, 91040).                %% VIP激活
-define(POWER_UPDATE_VIP_EXPIRE, 91041).            %% VIP过期
-define(POWER_UPDATE_GOD_WEAPON_SKIN, 91042).       %% 神兵皮肤激活
-define(POWER_UPDATE_MAGIC_WEAPON_SKIN, 91043).     %% 法宝皮肤激活
-define(POWER_UPDATE_WING_SKIN, 91044).             %% 翅膀皮肤激活
-define(POWER_UPDATE_WORLD_LEVEL, 91045).           %% 世界等级加成
-define(POWER_UPDATE_IMMORTAL_SOUL_WEAR, 91046).    %% 仙魂穿戴
-define(POWER_UPDATE_IMMORTAL_SOUL_UP, 91047).      %% 仙魂升级
-define(POWER_UPDATE_IMMORTAL_SOUL_BD, 91048).      %% 仙魂分解
-define(POWER_UPDATE_IMMORTAL_SOUL_COMPOSE, 91049). %% 仙魂融合
-define(POWER_UPDATE_IMMORTAL_SOUL_DOWN, 91050).    %% 仙魂取下
-define(POWER_UPDATE_MARRY_KNOT, 91051).            %% 同心结加成
-define(POWER_UPDATE_MARRY_CHANGE, 91052).          %% 婚姻状况改变
-define(POWER_DELETE_PASSIVE_SKILL, 91053).         %% 被动丢失
-define(POWER_RELIVE_DESTINY_UP, 91054).            %% 命格点亮改变
-define(POWER_UPDATE_PET_SKIN_ACTIVE, 91055).       %% 宠物皮肤激活
-define(POWER_UPDATE_PET_SKIN_STEP, 91056).         %% 宠物皮肤进阶
-define(POWER_UPDATE_MOUNT_SKIN_ACTIVE, 91057).     %% 坐骑皮肤激活
-define(POWER_UPDATE_MOUNT_SKIN_STEP, 91058).       %% 坐骑皮肤进阶
-define(POWER_UPDATE_HANDBOOK_ACTIVATE, 91059).     %% 图鉴激活
-define(POWER_UPDATE_HANDBOOK_UPGRADE, 91060).      %% 图鉴升级
-define(POWER_UPDATE_HANDBOOK_GROUP_ACT, 91061).    %% 图鉴组阶段激活
-define(POWER_UPDATE_THRONE_ACTIVATE, 91062).       %% 宝座激活
-define(POWER_UPDATE_THRONE_UPGRADE, 91063).        %% 宝座升级
-define(POWER_UPDATA_THRONE_UNREAL_ACTIVATE, 91064).   %% 宝座幻化激活
-define(POWER_UPDATA_THRONE_UNREAL_UPGRADE, 91065).   %% 宝座幻化升级
-define(POWER_UPDATE_EQUIP_STONE_UP, 91066).        %% 装备身上灵石升级
-define(POWER_UPDATE_FASHION_SUIT, 91067).          %% 时装套装激活
-define(POWER_UPDATE_SUIT_PLACE, 91068).          %% 套装系统部件激活
-define(POWER_UPDATE_SEAL_LEVEL_CHANGE, 91069).     %% 铭文等级改变
-define(POWER_UPDATE_FAMILY_TITLE, 91070).          %% 人气甜心气泡改变
-define(POWER_UPDATE_FASHION_SUIT_CHANGE, 91071).   %% 套装数量改变
-define(POWER_UPDATE_FASHION_TIMEOUT, 91072).       %% 时装过期

-define(POWER_UPDATE_MYTHICAL_EQUIP_UNLOAD, 91100). %% 魂兽装备卸除
-define(POWER_UPDATE_MYTHICAL_EQUIP_STATUS, 91101). %% 魂兽状态更改
-define(POWER_UPDATE_MYTHICAL_EQUIP_REFINE, 91102). %% 魂兽强化修改
-define(POWER_UPDATE_MYTHICAL_EQUIP_LOAD, 91103).   %% 魂兽装备替换
-define(POWER_UPDATE_SUIT_RESOLVE, 91104).   %% 套装系统部件分解

-define(POWER_UPDATE_WAR_SPIRIT_EQUIP_LOAD, 91200).     %% 战灵灵饰替换
-define(POWER_UPDATE_WAR_SPIRIT_EQUIP_UNLOAD, 91201).   %% 战灵灵饰卸下
-define(POWER_UPDATE_WAR_SPIRIT_EQUIP_REFINE, 91202).   %% 战灵强化
-define(POWER_UPDATE_JEWELRY_STEP, 91203).              %% 首饰进阶（手镯，戒指）
-define(POWER_UPDATE_FORGE_SOUL_OPEN, 91204).           %% 铸魂属性激活
-define(POWER_UPDATE_FORGE_SOUL_CULTIVATE, 91205).      %% 铸魂属性养成升级
-define(POWER_UPDATE_WAR_GOD_PIECE_ACTIVE, 91210).      %% 战神装备碎片激活
-define(POWER_UPDATE_WAR_GOD_EQUIP_ACTIVE, 91211).      %% 战神套装激活
-define(POWER_UPDATE_WAR_GOD_EQUIP_REFINE, 91212).      %% 战神装备强化
-define(POWER_UPDATE_WAR_SPIRIT_ARMOR_LOAD, 91213).     %% 战灵灵器装备
-define(POWER_UPDATE_WAR_SPIRIT_ARMOR_UNLOAD, 91214).   %% 战灵灵器卸载

-define(POWER_UPDATE_EQUIP_SEAL_UP, 91301).             %% 纹印升级
-define(POWER_UPDATE_EQUIP_SEAL, 91302).                %% 纹印镶嵌
-define(POWER_UPDATE_EQUIP_REMOVE_SEAL, 91303).         %% 纹印移除
-define(POWER_UPDATE_EQUIP_SEAL_ONE_KEY_UP, 91304).     %% 灵石一键穿戴
-define(POWER_UPDATE_EQUIP_SEAL_ONE_KEY_DOWN, 91305).   %% 灵石一键卸下
-define(POWER_UPDATE_EQUIP_STONE_HONING, 91306).        %% 灵石淬炼

-define(POWER_UPDATE_NATURE_REMOVE_SEAL, 91404).        %% 天机印移除
-define(POWER_UPDATE_NATURE_SEAL, 91401).               %% 天机印镶嵌
-define(POWER_UPDATE_NATURE_SEAL_UP, 91402).            %% 天机印替换
-define(POWER_UPDATE_NATURE_REFINE, 91403).             %% 天机印强化

-define(POWER_UPDATE_PELLET_MEDICINE, 91410).           %% 丹药使用
-define(POWER_UPDATE_PELLET_MEDICINE_TIME_OUT , 91411). %% 限时丹药到期

-define(POWER_UPDATE_COLLECT_EQUIP_SUIT, 91412).   %% 装备收集系统套装激活
-define(POWER_UPDATE_COLLECT_EQUIP_SKILL, 91413).   %% 装备收集系统技能激活

-define(POWER_UPDATE_EQUIP_GM_PROP, 91400).             %% GM命令修改属性
%%%===================================================================
%%% 玩家战力变化日志 end
%%%===================================================================
-endif.
