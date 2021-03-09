--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:H_活动系统配置.xml, excel:H 活动系统配置.xlsx, sheet:Sheet1
--******************************************************************************
XsActiveCfg={}
local We=XsActiveCfg
We["1001"]={id=1001, type=1, name="冲级豪礼", detail="冲级豪礼", lv=30, openDay=1, endDay=9999}
We["1002"]={id=1002, type=1, name="七天", detail="七天", lv=30, openDay=1, endDay=9999}
We["1003"]={id=1003, type=1, name="开服累充", detail="开服累充", lv=100, openDay=0, endDay=0}
We["1004"]={id=1004, type=1, name="首冲", detail="首冲", lv=0, openDay=1, endDay=9999}
We["1005"]={id=1005, type=1, name="集字有礼", detail="活动期间内，在线或离线挂机击败野外小怪，可获得“天、道、问、情”道具。世界BOSS和洞天福地击败BOSS，可获得“礼”道具。道具仅在活动期间内可用，过期可出售。", lv=60, openDay=1, endDay=8}
We["1006"]={id=1006, type=1, name="每日充值", detail="每日充值", lv=55, openDay=1, endDay=9999}
We["1007"]={id=1007, type=1, name="开服冲榜", detail="开服冲榜", lv=45, openDay=1, endDay=8}
We["1008"]={id=1008, type=2, name="回归豪礼", detail="在活动时间内登陆游戏将获得大量元宝和银两奖励", lv=0, openDay=0, endDay=0}
We["1009"]={id=1009, type=2, name="累计消费", detail="消费不同额度元宝将获得大量奖励", lv=0, openDay=0, endDay=0}
We["1010"]={id=1010, type=2, name="双倍经验", detail="全服在18点-24点开启打怪经验双倍。\n 1.在野外击败怪物会获得怪物基础经验的双倍经验。\n 2. 可击怪物的副本，且击败会产生经验的，也可获得双倍经验， 例如经验副本、宠物副本等。\n 3. 离线挂机也可获得双倍经验收益。", lv=1, openDay=0, endDay=0, timeStr={"18:00:00-24:00:00"}}
We["1011"]={id=1011, type=2, name="副本双倍", detail="全服全天开启副本掉落双倍。\n 1.每天将有不同的副本享受双倍加成，享受加成的副本将在日常活跃界面显示“掉落双倍”标识。\n 2. 通关副本可以获得双倍掉落和结算奖励。\n 3. 副本扫荡也可以获得双倍奖励。", lv=1, openDay=0, endDay=0}
We["1013"]={id=1013, type=3, name="花光十个亿", detail="容器-------回归豪礼，累计消费，双倍经验，副本双倍，登陆有礼，Boss掉落", lv=100, openDay=0, endDay=0}
We["1014"]={id=1014, type=2, name="登陆有礼", detail="", lv=0, openDay=0, endDay=0}
We["1015"]={id=1015, type=2, name="Boss掉落", detail="在活动时间内击败世界Boss或洞天福地Boss均有几率获得100-1000不等的元宝或绑元", lv=0, openDay=0, endDay=0}
We["1016"]={id=1016, type=1, name="建帮立派", detail="开服7天，一马当先创建道庭完成目标的庭主，将获得大量奖励，以带领道庭成员驰骋仙界", lv=31, openDay=1, endDay=7}
We["1017"]={id=1017, type=1, name="道庭争霸", detail="开服第3天21:00开启，在道庭战中获得主宰神殿掌控权的道庭将获得大量奖励（当前第X天）", lv=80, openDay=1, endDay=4}
We["1018"]={id=1018, type=3, name="开服活动", detail="容器-------集字有礼， 建帮立派， 仙盟争霸，Boss首杀", lv=0, openDay=0, endDay=0}
We["1019"]={id=1019, type=1, name="猎杀BOSS", detail="活动期间内击败游戏中不同的BOSS可获得不同的积分，积分达到条件即可领取丰厚绑元奖励", lv=60, openDay=1, endDay=8}
We["1020"]={id=1020, type=1, name="限时云购", detail="[99886BFF]1、限时云购是将幸运大奖分成200等份，玩家每次购买随机获得1份保底奖励，购买份数越多，大奖的中奖几率越高；\n2、云购库存剩余份数为0时从200份中抽取1份揭晓幸运大奖；同时每日00:00刷新并开启当日幸运大奖，00:00开启规则如下：\n1）全服累计购买[67cc67]不足50份[-]时，有概率开启幸运大奖；\n2）全服累计购买[67cc67]50份以上[-]时，必有一位玩家获的幸运大奖；\n3、开奖之前已购买次数将累计，每次云购开奖后购买次数将重置；\n4、该玩法概率可前往官网查看。[-]", lv=100, openDay=1, endDay=7}
We["1021"]={id=1021, type=1, name="十倍返利", detail="十倍返利", lv=45, openDay=1, endDay=9999}
We["1022"]={id=1022, type=4, name="神仙眷侣", detail="[99886BFF]执子之手，与子偕老。等级达到[67cc67]150级[-]可提亲，活动期间完成[67cc67]3挡提亲[-]，双方均可获得[67cc67]【三生三世神仙眷侣】[-]称号[-]", lv=100, openDay=0, endDay=0}
We["1023"]={id=1023, type=1, name="第二阶段活动", detail="开服第二阶段冲榜 翅膀", lv=100, openDay=8, endDay=10}
We["1024"]={id=1024, type=1, name="第二阶段活动", detail="开服第二阶段冲榜 法宝", lv=100, openDay=10, endDay=12}
We["1025"]={id=1025, type=1, name="第二阶段活动", detail="开服第二阶段冲榜 图鉴", lv=100, openDay=12, endDay=14}
We["1026"]={id=1026, type=1, name="第二阶段活动", detail="七日投资", lv=100, openDay=8, endDay=14}
We["1027"]={id=1027, type=1, name="第二阶段活动", detail="限时抢购", lv=100, openDay=999, endDay=999}
We["1028"]={id=1028, type=1, name="许愿池", detail="许愿池", lv=100, openDay=6, endDay=6}
We["1029"]={id=1029, type=1, name="开服仙途", detail="仙途之路", lv=100, openDay=8, endDay=14}
We["1030"]={id=1030, type=1, name="永久绝版守护", detail="", lv=150, openDay=999, endDay=999}
We["1031"]={id=1031, type=2, name="洞天福地Boss狂潮", detail="洞天福地Boss狂潮", lv=160, openDay=0, endDay=0, timeStr={"12:00:00-14:00:00", "19:00:00-21:00:00"}}
We["1032"]={id=1032, type=3, name="仙途之路容器", detail="仙途之路容器：仙途之路、材料掉落、商店兑换", lv=0, openDay=0, endDay=0}
We["1034"]={id=1034, type=1, name="材料掉落", detail="材料掉落", lv=100, openDay=8, endDay=14}
We["1035"]={id=1035, type=1, name="商店兑换", detail="商店兑换", lv=100, openDay=8, endDay=14}
We["1036"]={id=1036, type=4, name="开服目标", detail="开服目标", lv=140, openDay=0, endDay=0}
We["1037"]={id=1037, type=1, name="每日宝箱", detail="每天每次充值可领取一个宝箱，最多三次", lv=100, openDay=1, endDay=9999}
