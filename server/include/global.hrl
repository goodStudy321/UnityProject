%%%-------------------------------------------------------------------
%%% @author
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. 四月 2017 1:15
%%%-------------------------------------------------------------------
-ifndef(GLOBAL_HRL).
-define(GLOBAL_HRL, global_hrl).
-include("common.hrl").
-include("common_records.hrl").
-include("global_lang.hrl").
-include("db.hrl").
-include("map.hrl").
-include("fight.hrl").
-include("behavior_log.hrl").
-include("broadcast.hrl").
-include("background.hrl").
-include("letter_template.hrl").

-include("all_pb.hrl").
-include("proto/common_error_no.hrl").


-define(RETURN_OK(Result), erlang:throw({ok, Result})).
-define(RETURN, erlang:throw(ok)).

-define(FALSE, 0).
-define(TRUE, 1).

%%简单类型转换
-define(BOOL2INT(Bool), ?IF((Bool), 1, 0)).
-define(INT2BOOL(INT), ?IF((INT =:= ?FALSE), false, true)).


-define(MAX_AGENT_ID, 1000).
-define(MAX_SERVER_ID, 100000).
-define(MAX_ROLE_NUM, 100000000).
-define(MAX_FAMILY_NUM, 1000000).
-define(ROLE_ID_OFFSET, (?MAX_SERVER_ID * ?MAX_ROLE_NUM)).

-define(RATE_100, 100).
-define(RATE_10000, 10000).
-define(RATE_1000000, 1000000).
-define(RATE_10000000, 10000000).
-define(HALF_SECOND_MS, 500).
-define(SECOND_MS, 1000).
-define(ONE_MINUTE, 60).
-define(TEN_MINUTE,  600).
-define(AN_HOUR, 3600).
-define(ONE_DAY, 86400).
-define(ONE_WEEK, 604800).

-define(SEX_GIRL, 0).
-define(SEX_BOY, 1).

-define(CATEGORY_1, 1).     %% 职业1琼英
-define(CATEGORY_2, 2).     %% 职业2天罡

-define(IS_BIND(BindNum), (BindNum =/= 0)).

-define(ITEM_SILVER, 1).    %% 银两道具
-define(ITEM_GOLD, 2).      %% 元宝道具
-define(ITEM_BIND_GOLD, 3). %% 绑定元宝道具

%% 实名&&防沉迷要求
-define(ADDICT_TYPE_NONE, 0).       %% 无
-define(ADDICT_TYPE_NORMAL, 1).     %% 宽松版
-define(ADDICT_TYPE_STRICT, 2).     %% 严格版

-define(ADDICT_STRICT_WINDOW, 1).      %% 弹窗提示
-define(ADDICT_STRICT_WINDOW_I, 10).   %% 弹窗提示2
-define(ADDICT_STRICT_BENEFIT, 2).     %% 收益下降
-define(ADDICT_STRICT_PAY, 3).         %% 充值年龄1小
-define(ADDICT_STRICT_PAY_I, 8).       %% 充值年龄2大
-define(ADDICT_GAME_CHANNEL,4).        %% 包渠道推送防沉迷状态
-define(ADDICT_STRICT_OFFLINE, 5).              %% 强制下线
-define(ADDICT_STRICT_ONLINE_TIME, 6).          %% 允许登录时间
-define(ADDICT_STRICT_ONLINE_TIME_LENGTH, 7).   %% 允许登录时长
-define(ADDICT_STRICT_IS_HOLIDAY, 9).           %% 是否法定假日    挂载在world_activity_server 每日零点重置

-define(ADDICT_TOURIST_PAY, 11).             %% 游客不可付费消费
-define(ADDICT_TOURIST_PLAY_TIME, 12).       %% 游客时长
-define(ADDICT_TOURIST_EQUIPMENT_TIME, 13).  %% 设备时长



-define(GLOBAL_COPY_EXP_COST, 8).	        %% 经验副本相关
-define(GLOBAL_BAG_GRID, 10).               %% 背包格子相关
-define(GLOBAL_NOTICE_LEVEL, 11).           %% 神兵，翅膀，法宝公告，每X级广播一次公告
-define(GLOBAL_EQUIP_TREASURE, 14).         %% 装备寻宝
-define(GLOBAL_RUNE_TREASURE, 15).          %% 符文寻宝
-define(GLOBAL_MAX_TREASURE_TIMES, 16).     %% 寻宝次数上限
-define(GLOBAL_TREASURE_LOGS, 17).          %% 装备寻宝记录上限
-define(GLOBAL_FAMILY_TD_LEFT_BASE, 19).    %% 守卫仙盟左边守卫信息
-define(GLOBAL_FAMILY_TD_RIGHT_BASE, 20).   %% 守卫仙盟右边守卫信息
-define(GLOBAL_FAMILY_TD_BASE, 21).         %% 守卫仙盟中间守卫信息
-define(GLOBAL_FIRST_DROP_ITEM, 22).        %% 初始掉落道具
-define(GLOBAL_COPY_EXP_MONSTER, 23).       %% 经验副本刷怪
-define(GLOBAL_OFFLINE_SOLO, 25).           %% 离线竞技
-define(GLOBAL_EQUIP_TREASURE_WEIGHT, 26).  %% 装备寻宝权重
-define(GLOBAL_FRIENDLY_ADD, 27).           %% 亲密度增加
-define(GLOBAL_FAMILY_TD_STAR_EXP, 28).     %% 仙盟TD星级经验
-define(GLOBAL_INVEST_GOLD, 31).            %% 投资字画额度
-define(GLOBAL_MONTH_CARD, 32).             %% 月卡投资需要的元宝
-define(GLOBAL_VIP_INVEST, 33).             %% VIP投资
-define(GLOBAL_CONCISE_OPEN, 35).           %% 装备洗练相关
-define(GLOBAL_ROLE_RENAME, 38).            %% 角色改名
-define(GLOBAL_FAMILY_RENAME, 39).          %% 仙盟改名
-define(GLOBAL_WORLD_CHAT_LEVEL,41).        %% 加入世界频道聊天的等级限制
-define(GLOBAL_WORLD_BOSS_QUIT_TIME, 43).   %% 世界boss退出时间
-define(GLOBAL_ROBOT_LEVEL, 44).            %% 离线挂机等级
-define(GLOBAL_IMMORTAL_POS, 47).           %% 仙魂副本寻路坐标
-define(GLOBAL_IMMORTAL_GUARD_AND_BOSS, 48).%% 仙魂副本守卫和召唤boss
-define(GLOBAL_ADDICT_REWARD, 51).          %% 实名认证奖励
-define(GLOBAL_PROPOSE_LEVEL, 52).          %% 提亲最小等级
-define(GLOBAL_MARRY_TREE, 53).             %% 姻缘树相关
-define(GLOBAL_COPY_MARRY_ICON, 54).        %% 仙侣副本结束图标
-define(GLOBAL_MARRY_COPY_HEART1, 55).      %% 仙侣副本大心
-define(GLOBAL_MARRY_COPY_HEART2, 56).      %% 仙侣副本小心
-define(GLOBAL_MARRY_COPY_REWARD1, 57).     %% 仙侣副本心有灵犀奖励
-define(GLOBAL_MARRY_COPY_REWARD2, 58).     %% 仙侣副本缘差一线奖励
-define(GLOBAL_LIMITEDTIME_BUY, 59).        %% 限时云购
-define(GLOBAL_TEAM_WILD, 60).              %% 野外挂机
-define(GLOBAL_MARRY_FEAST_APPOINT, 61).    %% 仙侣预约/宾客
-define(GLOBAL_MARRY_WISH, 62).             %% 婚礼祝福
-define(GLOBAL_MARRY_HEAT_COLLECT, 63).     %% 婚礼采集热度事件相关
-define(GLOBAL_MARRY_HEAT_BOSS, 64).        %% 婚礼boss相关
-define(GLOBAL_MARRY_TASTE, 65).            %% 婚礼品尝次数
-define(GLOBAL_SOLO_BESTIR_BUFF, 66).       %% 竞技场战力增幅
-define(GLOBAL_SOLO_BESTIR_GOLD, 67).       %% 鼓舞单价
-define(GLOBAL_SOLO_BESTIR_TIMES, 68).      %% 竞技场可鼓舞上限
-define(GLOBAL_MARRY_BOSS_DROP_IDS, 69).    %% 抢亲boss掉落
-define(GLOBAL_MARRY_BOSS_DROP_ARGS, 70).   %% 抢亲boss其他参数
-define(GLOBAL_MARRY_BUY_JOIN, 71).         %% 购买成为宾客
-define(GLOBAL_MARRY_EXP, 75).              %% 婚宴场景每X秒加经验
-define(GLOBAL_WORLD_BOSS_RANK, 76).        %% 世界boss显示条数
-define(GLOBAL_TASTE_REFRESH, 77).          %% 品尝美食刷新
-define(GLOBAL_DOWNLOAD_REWARD, 79).        %% 下载奖励配置
-define(GLOBAL_WORLD_BOSS_LEVEL, 80).       %% 世界boss超过配置等级不掉落
-define(GLOBAL_RELIVE_DESTINY_LEVEL, 81).   %% 天命觉醒等级
-define(GLOBAL_MYTHICAL_COLLECT, 84).       %% 龙灵水晶采集次数
-define(GLOBAL_MYTHICAL_COLLECT2, 85).      %% 凤血水晶采集次数
-define(GLOBAL_MYTHICAL_TIMES, 86).         %% 神兽岛疲劳次数
-define(GLOBAL_WORLD_ROBOT_HOUR, 87).       %% 离线挂机最大小时数
-define(GLOBAL_MYTHICAL_EXP, 88).           %% 神兽岛经验加成
-define(GLOBAL_MYTHICAL_REFINE_GOLD, 89).   %% 神兽装备强化翻倍，每增加100点强化值需要消耗元宝数量
-define(GLOBAL_RESOURCE_RETRIEVE, 94).      %% 资源找回等级
-define(GLOBAL_SUMMIT_TREASURE, 95).        %% 巅峰寻宝
-define(GLOBAL_WAR_SPIRIT_BAG_NUM, 96).     %% 战灵背包格子
-define(GLOBAL_LEVEL_TALENT_POINTS, 97).    %% 4转后每级赠送天赋点
-define(GLOBAL_RELIVE_TALENT_PINTS, 98).    %% 完成4转赠送天赋点
-define(GLOBAL_RESET_TALENT_ITEM, 99).      %% 天赋洗点道具消耗
-define(GLOBAL_BAN_FUNCTION_LIST, 100).     %% 功能屏蔽的id
-define(GLOBAL_MAX_RECOVER_HP, 101).        %% 最大血量
-define(GLOBAL_ANCIENTS_REDUCE_RATE, 105).  %% 远古宝箱掉血万分比
-define(GLOBAL_COPY_TREASURE_SKILL_1, 110). %% 藏宝图技能1
-define(GLOBAL_COPY_TREASURE_SKILL_2, 111). %% 藏宝图技能2
-define(GLOBAL_FIRST_WORLD_BOSS, 113).      %% 世界BOSS击杀引导
-define(GLOBAL_SUMMIT_INVEST_GOLD, 116).    %% 化神投资
-define(GLOBAL_EQUIP_GUIDE, 118).           %% 装备副本机器人引导
-define(GLOBAL_MISSION_ONE_KEY, 119).       %% 一键完成任务配置
-define(GLOBAL_GUIDE_BOSS, 121).            %% 世界BOSS引导副本机器人数据
-define(GLOBAL_FIRST_BOSS, 122).            %% 世界boss相关参数
-define(GLOBAL_DEMON_BOSS, 125).            %% 魔域boss相关
-define(GLOBAL_DEMON_BOSS_LEVEL, 126).      %% 魔域boss等级
-define(GLOBAL_CAVE_BOSS, 127).             %% 洞天福地相关
-define(GLOBAL_BOSS_SEEK_HELP, 131).        %% boss求助相关
-define(GLOBAL_WORLD_BOSS_RECOVER, 132).    %% 世界boss血量恢复
-define(GLOBAL_COPY_EXP, 133).              %% 经验副本引导配置
-define(GLOBAL_GUIDE_BOSS_POINT, 137).      %% 世界BOSS引导副本机器人出生坐标
-define(GLOBAL_DEMON_BOSS_LOOP, 140).       %% 魔域boss循环用到的参数
-define(GLOBAL_FAMILY_ASM_REWARD, 141).     %% 每次帮助可获取的道绩
-define(GLOBAL_FAMILY_ASM_RENOVATE, 142).   %% 道庭极品任务刷新时间
-define(GLOBAL_FAMILY_ASM_TIME, 143).       %% 单次帮助加速总时间万分比
-define(GLOBAL_FAMILY_ASM_DINGBAT, 144).    %% 道庭任务刷新消耗元宝or绑元
-define(GLOBAL_DISCOUNT_PAY_LEVEL, 145).    %% 特惠充值开启等级
-define(GLOBAL_DAILY_BUY, 147).             %% 每日限时购（开放）等级
-define(GLOBAL_FAMILY_ASM_COUNT, 148).      %% 道庭任务普通玩家单个任务可被帮助的总次数
-define(GLOBAL_PET_SWALLOW, 149).           %% 宠物吞噬
-define(GLOBAL_AUCTION_ARGS, 151).          %% 拍卖行相关
-define(GLOBAL_AUCTION_NUM, 152).           %% 拍卖行条数
-define(GLOBAL_ILLUSION_BUY, 156).          %% 五行副本幻力购买相关
-define(GLOBAL_OFFLINE_SOLO_IMMUNE, 158).   %% 免伤buff
-define(GLOBAL_RUNE_FIRST_ITEM, 159).       %% 符文首次寻宝必定获得
-define(GLOBAL_DEMON_BOSS_BUFF, 163).       %% 魔域boss减伤buff
-define(GLOBAL_CROSS_ACTIVITY_LEVEL, 164).  %% 本服活动转跨服转换世界等级
-define(GLOBAL_CROSS_LEVEL, 165).           %% 区域聊天开启等级
-define(GLOBAL_MINING_LATTICE_WIDTH_HEIGHT, 166).   % 迷境探索的宽和高
-define(GLOBAL_MINING_LATTICE_RENOVATE, 167). %% 迷境探索的空单元格刷新时间
-define(GLOBAL_MINING_START_NUM, 168).       %% 开启时赠送的行动次数
-define(GLOBAL_MINING_SHIFT_NUM, 169).       %% 每天玩家补充的行动次数
-define(GLOBAL_MINING_MINING_INSPIRE, 170).  %% 每天的鼓舞数据
-define(GLOBAL_DAY_BOX, 173).                %% 每日宝箱
-define(GLOBAL_ILLUSION_ITEM_TIMES, 174).    %% 幻能珠每日使用限制
-define(GLOBAL_FAMILY_POPULAR, 175).         %% 道庭称号-人气甜心
-define(GLOBAL_SOLO_CROSS_DOMAIN_SERVER, 176).   %% lvl赛季周期天数
-define(GLOBAL_UNIVERSE_ADMIRE, 177).       %% 太虚通天塔膜拜
-define(GLOBAL_FIRST_CHARGE, 179).   %% 首冲返元宝
-define(GLOBAL_ACT_LUCKY_TOKEN, 182).       %% 幸运上上签
-define(GLOBAL_ACT_MARRY_CREATE_TIME, 200).       %% 婚礼注册和冷却
-define(GLOBAL_TEAM_COPY, 201).             %% 组队副本助战配置
-define(GLOBAL_ACTIVITY_REMIND, 203).       %% 活动提醒功能配置
-define(GLOBAL_PRIVATE_CHAT, 204).       %% 私聊等级限制


-define(GLOBAL_IDENTIFY_TREASURE,181). %% 鉴宝活动其他数据

-define(GLOBAL_ACT_CHOOSE_LAST_TIME_OR_NUM, 186). %% 黑市鉴宝的持续时间 鉴宝的宝箱个数
-define(GLOBAL_ACT_CHOOSE_CONSUME, 187). %% 每消耗多少元宝可获得鉴宝次数
-define(GLOBAL_ACT_TRENCH_CEREMONY, 189). %% 绝版壕礼

-define(GLOBAL_ACT_ESOTERICA_LIMIT_EXTRACTION,192). %% 数值2：多少修炼点提升1级，修炼秘籍的总等级  数值3：每日抽取的任务上限
-define(GLOBAL_ACT_ESOTERICA_LARGESS ,193). %% 购买仙品秘籍增送的修炼点数
-define(GLOBAL_ACT_RED_PACKET, 194).        %% 全服红包发送时间
-define(GLOBAL_ACT_ESOTERICA_RECOVERY_PRICE, 195). %% 数值2：修炼秘籍追回价格，绑元优先 数值3：升满级所需修炼点数
-define(GLOBAL_CYCLE_ACT_COUPLE_CHARM, 196).%% 魅力之王
-define(GLOBAL_CYCLE_ACT_COUPLE_PRAY, 197). %% 月下情缘相关


%% 道庭宝箱任务
-define(GLOBAL_FAMILY_BOX_PAY, 1000).                  %% 支付宝箱
-define(GLOBAL_FAMILY_BOX_WORLD_BOSS, 2000).           %% 世界boss宝箱
-define(GLOBAL_FAMILY_BOX_MOYU_BOSS, 3000).            %% 魔域boss宝箱
-define(GLOBAL_FAMILY_BOX_FUDI_BOSS, 4000).            %% 福地boss宝箱
-define(GLOBAL_FAMILY_BOX_FBG_BOSS,  5000).            %% 道庭boss宝箱


-define(MARKET_ALLOW_SELL, 1).      %% > 0 可以
-define(MARKET_BAN_SELL, 0).        %% =0 不可以






-define(UNDEFINED, undefined).  %% 原子宏定义
-define(ADD_TITLE, 1).    %% 增加称号
-define(REMOVE_TITLE, 2).  %% 移除称号

-define(WEB_BAN_ROLE_RENAME, 1).        %% 禁止角色重命名
-define(WEB_BAN_FAMILY_RENAME, 2).      %% 禁止仙盟重命名
-define(WEB_BAN_NOTICE_RENAME, 3).      %% 禁止修改仙盟公告

-define(SPACE_CHAR_LIST, [[32], [59254], [12288], [59269], [59410],[9], [10], [13]]).
-define(SEC_CHAR_LIST, ["<","《", ">","》", "\\","＼", "/","、", "&","＆", "\"","“","”", "\'","‘","’", "#","＃", "官网","区-",
    ";","；", ":","：", "-","－", "?","？", "!","！", "*","×", "^","……", "%","％", ",","，", ".","。",
    "~","～", "`","·", "$","￥", "|","｜", "[","【", "]","】", "{","｛", "}","｝", "(","（", ")","）",
    "＝","=", "+","＋", "_","——","@","＠"]).
-endif.