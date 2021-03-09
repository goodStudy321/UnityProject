--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:X_系统等级表.xml, excel:X 系统等级表.xls, sheet:Sheet1
--******************************************************************************
ActivityTemp={}
local We=ActivityTemp
We["101"]={id=101, lv=25, index=3, name="商城", layer=1, icon="icon_shangcheng1", continued=1, zoom=1, type=101, effect=2, ui="UIStore"}
We["102"]={id=102, lv=130, index=8, name="排行榜", layer=1, icon="icon_paihang", continued=1, type=102, effect=0, ui="UIRank"}
We["104"]={id=104, lv=2000, index=18, name="花光十个亿", layer=3, icon="icon_festival", type=301, effect=2, ui="UIFestivalAct"}
We["105"]={id=105, lv=1, index=14, name="双倍经验", layer=3, icon="VIP_0002_Doubel", type=307, effect=2, ui=""}
We["106"]={id=106, lv=2000, index=13, name="实名认证", layer=2, icon="shimingrenzheng", type=104, effect=0, ui="UIIdentification"}
We["107"]={id=107, lv=45, index=4, name="开服冲榜", layer=1, icon="icon_kfcb", continued=1, zoom=1, type=105, effect=2, ui="UIRankActiv", change=1}
We["108"]={id=108, lv=1, index=2, name="首充有礼", layer=6, icon="icon_shouchong", zoom=1, type=106, effect=2, ui="UIFirstPay"}
We["109"]={id=109, lv=230, index=3, name="九九窥星塔", layer=2, icon="tongtianta", continued=1, type=201, effect=0, ui="UICopyTowerPanel"}
We["110"]={id=110, lv=0, index=2, name="副本", layer=4, icon="icon_fuben", continued=1, zoom=1, type=402, effect=0, ui="UICopy"}
We["111"]={id=111, lv=0, index=3, name="竞技殿", layer=3, icon="jingjidian", continued=1, type=202, effect=1, ui="UIArena"}
We["112"]={id=112, lv=0, index=1, name="Boss巢穴", layer=0, icon="icon_boss", continued=1, zoom=1, type=203, effect=0, ui="UIBoss"}
We["114"]={id=114, lv=105, index=4, name="寻宝", layer=2, icon="icon_xunbao", continued=1, type=205, effect=2, ui="UITreasure"}
We["115"]={id=115, lv=60, index=2, name="开服活动", layer=2, icon="icon_festival", continued=1, zoom=1, type=206, effect=2, ui="UIBenefit"}
We["116"]={id=116, lv=96, index=1, name="日常活跃", layer=4, icon="icon_huoyue", continued=1, zoom=1, type=401, effect=0, ui="UILiveness"}
We["117"]={id=117, lv=30, index=6, name="福利", layer=2, icon="icon_fl", continued=1, type=303, effect=0, ui="UILvAward"}
We["118"]={id=118, lv=1, index=11, name="调查问卷", layer=3, icon="diaochawenjuan", continued=1, type=304, effect=2, ui="UISurverPanel"}
We["119"]={id=119, lv=70, index=4, name="天书", layer=3, icon="icon_tianshu", continued=1, type=306, effect=1, ui="UISkyBook"}
We["121"]={id=121, lv=2000, index=7, name="在线奖励", layer=1, icon="icon_zaixian", continued=1, type=302, effect=1, ui="UIAwardPopup"}
We["123"]={id=123, lv=200, index=1, name="守卫道庭", layer=5, icon="shouweixianmeng", type=309, effect=3, ui="UIFamilyDefendWnd"}
We["124"]={id=124, lv=140, index=5, name="道庭Boss", layer=3, icon="xianmengboss", type=310, effect=3, ui="UIFamilyBossIt"}
We["125"]={id=125, lv=130, index=3, name="道庭晚宴", layer=5, icon="xianmengwanyan", type=311, effect=3, ui="UIFamilyAnswerIt"}
We["126"]={id=126, lv=100, index=2, name="蜀山论道", layer=5, icon="sys_41", continued=1, type=502, effect=3, ui=""}
We["127"]={id=127, lv=1, index=16, name="副本双倍", layer=3, icon="VIP_0001_Copy", type=305, effect=2, ui=""}
We["128"]={id=128, lv=90, index=1, name="拍卖行", layer=2, icon="icon_market", continued=1, zoom=1, type=207, effect=0, ui="UIAuction"}
We["129"]={id=129, lv=1, index=1, name="充值", layer=1, icon="icon_chongzhi", continued=1, zoom=1, type=107, effect=1, ui="UIVIP"}
We["131"]={id=131, lv=200, index=4, name="道庭战", layer=5, icon="sys_33", type=312, effect=3, ui="UIFamilyWar"}
We["132"]={id=132, lv=135, index=5, name="逍遥神坛", layer=5, icon="sys_34", continued=1, type=313, effect=3, ui="UITopFightIt"}
We["133"]={id=133, lv=1, index=12, name="论坛", layer=2, icon="icon_lt", continued=1, type=108, effect=0, ui=""}
We["134"]={id=134, lv=125, index=8, name="零元抢购", layer=3, icon="icon_rushbuy", continued=1, type=109, effect=2, ui="UIRushBuy"}
We["135"]={id=135, lv=100, index=7, name="限时云购", layer=3, icon="xsyg", continued=1, type=314, effect=2, ui="UICloudBuy"}
We["136"]={id=136, lv=2, index=2, name="境界", layer=3, icon="icon_robbery", continued=1, zoom=1, type=209, effect=1, ui="UIRobbery"}
We["137"]={id=137, lv=100, index=6, name="结婚请帖", layer=3, icon="xitie", type=315, effect=3, ui="UIProposePop"}
We["138"]={id=138, lv=999, index=9, name="七天目标", layer=1, icon="icon_zaixian", type=316, effect=0, ui="UIDayTarget"}
We["140"]={id=140, lv=100, index=9, name="许愿池", layer=3, icon="xyc", continued=1, type=318, effect=2, ui="UIWish"}
We["143"]={id=143, lv=290, index=5, name="世界服", layer=2, icon="sys_18", type=320, effect=0, ui="UICross"}
We["144"]={id=144, lv=100, index=20, name="展翅高飞", layer=3, icon="icon_zhancigaofei", type=321, effect=2, ui="UITimeLimitActiv"}
We["145"]={id=145, lv=1, index=15, name="七日投资", layer=3, icon="qiretouzhi", type=112, effect=2, ui="UISevenInvest"}
We["146"]={id=146, lv=150, index=9, name="限时抢购", layer=2, icon="xianshiqianggou", type=113, effect=2, ui="UITimeLimitBuy"}
We["147"]={id=147, lv=58, index=5, name="Boss悬赏", layer=1, icon="BossReward", continued=1, type=110, effect=2, ui="UIBossReward"}
We["148"]={id=148, lv=1, index=1, name="V特权", layer=6, icon="icon_V4", zoom=1, type=114, effect=4, ui="UIV4Panel"}
We["149"]={id=149, lv=100, index=7, name="法力无边", layer=2, icon="fabao", type=222, effect=0, ui="UITimeLimitActiv"}
We["150"]={id=150, lv=100, index=8, name="收藏达人", layer=2, icon="shenshou", type=223, effect=0, ui="UITimeLimitActiv"}
We["151"]={id=151, lv=180, index=13, name="魔域禁地", layer=3, icon="moyu", continued=1, type=111, effect=2, ui="UIDemonArea"}
We["153"]={id=153, lv=1, index=2, name="技能", layer=7, icon="icon_jineng", continued=1, zoom=1, type=702, effect=0, ui="UIRole"}
We["154"]={id=154, lv=0, index=3, name="养成", layer=7, icon="sys_26", continued=1, zoom=1, type=703, effect=0, ui="UIAdv"}
We["155"]={id=155, lv=0, index=4, name="炼器", layer=7, icon="icon_lianqi", continued=1, zoom=1, type=704, effect=0, ui="UIEquip"}
We["156"]={id=156, lv=230, index=5, name="符文", layer=7, icon="icon_fuwen", continued=1, zoom=1, type=705, effect=0, ui=""}
We["157"]={id=157, lv=160, index=7, name="图鉴", layer=7, icon="icon_tujian", continued=1, zoom=1, type=706, effect=0, ui=""}
We["158"]={id=158, lv=250, index=8, name="仙魂", layer=7, icon="icon_xianhun", continued=1, zoom=1, type=707, effect=0, ui=""}
We["159"]={id=159, lv=150, index=9, name="仙侣", layer=7, icon="icon_xianlv", continued=1, zoom=1, type=708, effect=0, ui=""}
We["160"]={id=160, lv=0, index=10, name="道庭", layer=7, icon="icon_daoting", continued=1, zoom=1, type=709, effect=0, ui=""}
We["161"]={id=161, lv=34, index=11, name="套装", layer=7, icon="icon_taozhuang", continued=1, zoom=1, type=710, effect=0, ui="UISuit"}
We["162"]={id=162, lv=1, index=14, name="设置", layer=7, icon="setting", continued=1, zoom=1, type=711, effect=0, ui="UISetting"}
We["166"]={id=166, lv=50, index=3, name="特惠充值", layer=6, icon="thcz", continued=1, zoom=1, type=212, effect=4, ui="UIDiscountGift"}
We["167"]={id=167, lv=105, index=12, name="合成", layer=7, icon="hecheng", continued=1, zoom=1, type=712, effect=0, ui="UICompound"}
We["168"]={id=168, lv=1, index=19, name="仙途之路", layer=3, icon="XTZL", type=324, effect=2, ui="UILimitActiv"}
We["312"]={id=312, lv=200, index=12, name="神秘宝藏", layer=3, icon="icon_taozhuang", type=330, effect=2, ui="UITreaFever"}
We["317"]={id=317, lv=1, index=17, name="炼丹炉", layer=3, icon="icon_liandanlu", type=317, effect=2, ui="UIAlchemy"}
We["323"]={id=323, lv=100, index=23, name="上上签", layer=3, icon="icon_ssq", continued=1, type=716, effect=2, ui="UIDrawLots"}
We["324"]={id=324, lv=100, index=24, name="幸运鉴宝", layer=3, icon="icon_jianbao", continued=1, type=328, effect=2, ui="UILuckFull"}
We["325"]={id=325, lv=200, index=25, name="招财猫", layer=3, icon="icon_luckycat", continued=1, type=325, effect=2, ui="UIFortuneCatPanel"}
We["326"]={id=326, lv=1, index=26, name="幸运砸蛋", layer=3, icon="icon_luckagg", continued=1, type=326, effect=2, ui="UIZaDan"}
We["327"]={id=327, lv=1, index=27, name="黑市鉴宝", layer=3, icon="icon_blackmarket", continued=1, type=327, effect=2, ui="UIBlackMarket"}
We["329"]={id=329, lv=100, index=28, name="首充倍送", layer=3, icon="icon_scbs", continued=1, type=329, effect=2, ui="UIPayMul"}
We["332"]={id=332, lv=50, index=32, name="绝版壕礼", layer=3, icon="icon_jbhl", continued=1, type=332, effect=2, ui="UIOutGift"}
We["333"]={id=333, lv=100, index=33, name="通天宝塔", layer=3, icon="tongtian", continued=1, type=333, effect=2, ui="UITongTianTower"}
We["334"]={id=334, lv=100, index=34, name="欢乐宝箱", layer=3, icon="icon_baoxiang", continued=1, type=334, effect=2, ui="UIHappyChest"}
We["335"]={id=335, lv=100, index=35, name="修炼秘籍", layer=3, icon="sys_57", continued=1, type=335, effect=2, ui="UIPracticeSec"}
We["336"]={id=336, lv=100, index=36, name="天道情缘", layer=3, icon="tdqy", continued=1, type=336, effect=2, ui="UIHeavenLove"}
We["602"]={id=602, lv=150, index=10, name="绝版守护", layer=6, icon="icon_guard", type=602, effect=2, ui="UIElvesNew"}
We["706"]={id=706, lv=135, index=6, name="天机印", layer=7, icon="icon_shezhi", continued=1, zoom=1, type=713, effect=0, ui="UISkyMysterySeal"}
We["713"]={id=713, lv=0, index=13, name="战灵", layer=7, icon="sys_2", continued=1, zoom=1, type=714, effect=0, ui="UIRobbery"}
