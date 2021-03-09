%%%-------------------------------------------------------------------
%%% @author laijichang
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. 七月 2017 10:02
%%%-------------------------------------------------------------------
-author("laijichang").
-ifndef(BROADCAST_HRL).
-define(BROADCAST_HRL, broadcast_hrl).

-define(ETS_BROADCAST_ROLE, ets_broadcast_role).
-define(ETS_BROADCAST_CHANNEL, ets_broadcast_channel).

-define(CHANNEL_WORLD, 1).      %% 世界广播频道
-define(CHANNEL_FAMILY, 2).     %% 道庭广播频道
-define(CHANNEL_TEAM,  3).      %% 队伍广播频道
-define(CHANNEL_CROSS_AREA, 4). %% 跨服区域频道

-define(CHAT_CHANNEL_WORLD, 1).     %% 聊天-世界频道
-define(CHAT_CHANNEL_FAMILY, 2).    %% 聊天-道庭频道
-define(CHAT_CHANNEL_TEAM, 3).      %% 聊天-组队频道
-define(CHAT_CHANNEL_PRIVATE, 4).   %% 聊天-私人频道
-define(CHAT_CHANNEL_CROSS_AREA, 6).%% 聊天-区域频道

-define(MAX_WORKER_NUM, 10).    %% 工作者的最大数量

-define(BROADCAST_RECORD, broadcast_record).    %% 广播消息，直接发送至网关
-define(BROADCAST_TO_ROLE, broadcast_to_role).  %% 广播消息至角色进程

%% 公告宏定义
-define(NOTICE_EQUIP_TREASURE, 2).      %% 装备寻宝获取公告
-define(NOTICE_STOP_SERVER, 3).         %% 服务器将在X秒后维护
-define(NOTICE_WING_SKIN_UP, 104).      %% 养成功能皮肤升星
-define(NOTICE_FAIRY_COMMIT_BEST, 107). %% 护送最高仙灵完成


-define(NOTICE_MOUNT_OPEN, 1001).                   %% 坐骑系统开启
-define(NOTICE_PET_OPEN, 1002).                     %% 宠物系统开启
-define(NOTICE_WING_OPEN, 1003).                    %% 翅膀系统开启
-define(NOTICE_MAGIC_WEAPON_OPEN, 1004).            %% 法宝系统开启
-define(NOTICE_GOD_WEAPON_OPEN, 1005).              %% 神兵系统开启
-define(NOTICE_MOUNT_SKILL_OPEN, 1011).             %% 坐骑技能解锁
-define(NOTICE_PET_SKILL_OPEN, 1012).               %% 宠物技能解锁
-define(NOTICE_WING_SKILL_OPEN, 1013).              %% 翅膀技能解锁
-define(NOTICE_MAGIC_WEAPON_SKILL_OPEN, 1014).      %% 法宝技能解锁
-define(NOTICE_GOD_WEAPON_SKILL_OPEN, 1015).        %% 神兵技能解锁
-define(NOTICE_PET_LEVEL_UP, 1021).                 %% 宠物等级提升（每10级广播）
-define(NOTICE_WING_LEVEL_UP, 1022).                %% 翅膀等级提升（每10级广播）
-define(NOTICE_MAGIC_WEAPON_LEVEL_UP, 1023).        %% 法宝等级提升（每10级广播）
-define(NOTICE_GOD_WEAPON_LEVEL_UP, 1024).          %% 神兵等级提升（每10级广播）
-define(NOTICE_MOUNT_STEP_UP, 1031).                %% 坐骑进阶
-define(NOTICE_PET_STEP_UP, 1032).                  %% 宠物进阶
-define(NOTICE_MOUNT_PELLET, 1041).                 %% 坐骑丹药使用
-define(NOTICE_PET_PELLET, 1042).                   %% 宠物丹药使用
-define(NOTICE_WING_PELLET, 1043).                  %% 翅膀丹药使用
-define(NOTICE_MAGIC_WEAPON_PELLET, 1044).          %% 法宝丹药使用
-define(NOTICE_GOD_WEAPON_PELLET, 1045).            %% 神兵丹药使用

-define(NOTICE_WING_SKIN, 1053).                    %% 翅膀皮肤激活
-define(NOTICE_MAGIC_WEAPON_SKIN, 1054).            %% 法宝皮肤激活
-define(NOTICE_GOD_WEAPON_SKIN, 1055).              %% 神兵皮肤激活
-define(NOTICE_EQUIP_REFINE, 1061).                 %% 装备强化公告，每10级一次
-define(NOTICE_EQUIP_SUIT, 1062).                   %% 套装进阶公告，进阶时提示
-define(NOTICE_EQUIP_STONE, 1063).                  %% 宝石镶嵌公告，镶嵌7级以上宝石提示
-define(NOTICE_EQUIP_COMPOSE, 1064).                %% 合成出红色装备提示
-define(NOTICE_EQUIP_CONCISE, 1065).                %% 洗练出橙色及以上属性时提示（暂时不做）
-define(NOTICE_RUNE_TOWER, 1066).                   %% 爬塔获得红色符文时公告
-define(NOTICE_RUNE_TREASURE, 1067).                %% 符文寻宝获得符文
-define(NOTICE_RUNE_COMPOSE, 1068).                 %% 符文合成
-define(NOTICE_RUNE_LEVEL, 1069).                   %% 每升10级公告（暂时不做）
-define(NOTICE_BATTLE_COMBO_KILL, 1070).            %% 诛仙战场1.连杀公告
-define(NOTICE_BATTLE_END, 1071).                   %% 诛仙战场2.结算公告
-define(NOTICE_ANSWER_END, 1072).                   %% 蜀山论道结算时，发送公告
-define(NOTICE_FAMILY_ANSWER_END, 1073).            %% 仙盟答题结算时，发送公告
-define(NOTICE_OFFLINE_SOLO, 1074).                 %% 决战瑶台获得排名第一时发送公告
-define(NOTICE_SOLO, 1075).                         %% 仙峰论剑晋升到下一级
-define(NOTICE_WORLD_BOSS, 1076).                   %% 世界boss刷新
-define(NOTICE_WORLD_BOSS_DROP, 1077).              %% 世界boss掉落稀有道具
-define(NOTICE_FAMILY_MEMBER_DEAD, 1078).           %% 帮会帮主或副帮主死亡
-define(NOTICE_FAIRY_MAX, 1079).                    %% 护送刷出最高级美女时公告
-define(NOTICE_FIRST_RECHARGE, 1080).               %% 首冲公告
-define(NOTICE_ITEM_GET, 1081).                     %% 稀有道具获取公告
-define(NOTICE_INVEST_GOLD, 1082).                  %% 投资计划公告
-define(NOTICE_MONTH_CARD, 1083).                   %% 月卡
-define(NOTICE_ACT_GET, 1083).                      %% 领取各档道具时公告
-define(NOTICE_VIP_INVEST, 1085).                   %% VIP投资计划
-define(NOTICE_MONSTER_CONQUERED,1086).             %% 聚灵桩被占领的公告ID
-define(NOTICE_MARRY_ADD_HEAT, 1087).               %% 结婚场景增加热度
-define(NOTICE_MARRY_HEAT_REACH, 1088).             %% 场景热度达到一定等级
-define(NOTICE_MARKET_DEMAND, 1089).                %% 市场求购
-define(NOTICE_FLOWER_999, 1090).                   %% 999玫瑰
-define(NOTICE_FLOWER_KISS_BACK, 1091).             %% 回吻
-define(NOTICE_MARRY_SUCC, 1092).                   %% 结婚公告
-define(NOTICE_MARRY_BOW, 1093).                    %% 拜堂公告
-define(NOTICE_MARRY_FEAST_START, 1094).            %% 婚礼开始公告
-define(NOTICE_FAMILY_OWNER_BE_KILLED, 1095).	    %%（单服）道庭盟主/副盟主被击杀
-define(NOTICE_CROSS_FAMILY_OWNER_BE_KILLED, 1096). %%（跨服）道庭盟主/副盟主被击杀
-define(NOTICE_MYTHICAL_MONSTER_REFRESH, 1097).	    %% 神兽守卫刷新系统提示
-define(NOTICE_MYTHICAL_MONSTER_OVER, 1098).        %% 神兽守卫击杀完毕系统提示
-define(NOTICE_MYTHICAL_COLLECT_REFRESH, 1099).	    %% 龙灵水晶刷新系统提示
-define(NOTICE_MYTHICAL_COLLECT_OVER, 1100).	    %% 龙灵水晶采集完毕系统提示
-define(NOTICE_MARRY_TREE_BUY, 1101).               %% 姻缘树公告
-define(NOTICE_WORLD_BOSS_DEAD, 1102).              %% 世界boss死亡公告
-define(NOTICE_MOUNT_SKIN, 1103).                   %% 坐骑皮肤激活
-define(NOTICE_PET_SKIN, 1104).                     %% 宠物皮肤激活
-define(NOTICE_JEWELRY_STEP, 1105).                 %% 首饰（手镯，戒指）进阶公告
-define(NOTICE_FORE_TOPOLOGY, 1106).                %% 跨服广播
-define(NOTICE_HIDDEN_BOSS_BORN, 1108).             %% 隐藏boss刷新
-define(NOTICE_CONFINE_UP, 1109).                   %% 渡劫成功通知
-define(NOTICE_FASHION_SHOW, 1110).                 %% 穿戴时装公告
-define(NOTICE_GOD_BOOK_OPEN, 1111).                %% 天书技能开启公告
-define(NOTICE_VIP_ACTIVATE, 1112).                 %% 激活VIP公告
-define(NOTICE_GUARD_GOT, 1113).                    %% 获取精灵公告
-define(NOTICE_LIMITED_BUY, 1114).                  %% 显示云购公告
-define(NOTICE_BOSS_SEEK_HELP, 1115).               %% boss求助公告
-define(NOTICE_ESCORT_ASK_FOR_HELP, 1126).          %% 请求援助
-define(NOTICE_ESCORT_OWNER_BE_ROB, 1127).          %% 庭主被拦截
-define(NOTICE_ESCORT_OWNER_BE_HELP, 1128).          %% 庭主被夺回
-define(NOTICE_ESCORT_FAMILY_TASK, 1129).          %% 道庭任务-抽取到最高星任务
-define(NOTICE_FAMILY_JOIN_FAMILY, 1130).          %% 加入道庭
-define(NOTICE_FAMILY_LEAVE_FAMILY, 1131).          %% 退出道庭
-define(NOTICE_FAMILY_KICK_ROLE, 1132).          %% 踢出道庭
-define(NOTICE_FAMILY_RENAME, 1133).          %% 道庭改名
-define(NOTICE_FAMILY_TRANSFERS, 1134).          %% 转让庭主
-define(NOTICE_FAMILY_ADMIN, 1135).          %% 晋升副庭主
-define(NOTICE_TEAM_JOIN_TEAM, 1140).          %% 玩家加入队伍
-define(NOTICE_TEAM_LEAVE_TEAM, 1141).          %% 玩家退出队伍
-define(NOTICE_TEAM_CAPTAIN_TEAM, 1142).          %% 玩家成为队长
-define(NOTICE_HIGH_LUCKY_CAT, 1159).                 %% 招财猫高倍公告
-define(NOTICE_LOW_LUCKY_CAT, 1160).                 %% 招财猫低倍公告
-define(NOTICE_FAMILY_BOX, 1177).                 %% 玩家成为队长


-record(r_broadcast_condition, {ignore_ids=[], min_level=0, max_level=10000 , game_channel_id }).

-record(r_broadcast_role, {role_id, role_pid, gateway_pid, channel_list=[]}).
%% 频道ETS表
%% channel_id   ---- {Type, ID}
-record(r_broadcast_channel, {channel, role_list=[]}).

%% 公告r结构
-record(r_notice, {
    key,                %% {id, GameChannelID}
    send_time,
    start_time,
    end_time,
    record,
    interval
}).
-endif.