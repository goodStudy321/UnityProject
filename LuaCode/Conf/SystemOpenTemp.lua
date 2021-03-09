--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:X_系统开放表.xml, excel:X 系统开放表.xls, sheet:Sheet1
--******************************************************************************
SystemOpenTemp={}
local We=SystemOpenTemp
We["1"]={id=1, flyType=3, lvid=154, trigType=2, trigParam=10014, des="坐骑开启", objID={3010001}, openType=1, modid=9002, openAnim=1, delay=8000, icon={"sys_12.png", "test_open_zj", "ZJ_HeiLinMiShi_UI"}, preview=1, preViewDes="[bdefff]初始坐骑，进阶可增加战力，改变形态[ffffff]", lvLimit=1, jump={"UIAdv", "1"}}
We["2"]={id=2, flyType=3, lvid=154, trigType=2, trigParam=10406, des="法宝开启", objID={30200000}, openType=1, modid=9004, openAnim=1, delay=5000, icon={"sys_21.png", "test_open_fb", "FB_ShuangLongFaQiu_UI"}, preview=1, preViewDes="[bdefff]初始法宝，进阶可增加战力，改变形态[ffffff]", lvLimit=21, jump={"UIAdv", "2"}}
We["3"]={id=3, flyType=3, lvid=154, trigType=2, trigParam=10121, des="伙伴开启", objID={3030101}, openType=1, modid=9003, openAnim=1, delay=8000, icon={"sys_13.png", "test_open_cw", "CW_TuZi_UI"}, preview=1, preViewDes="[bdefff]初始伙伴，进阶可增加战力，改变形态[ffffff]", lvLimit=1, jump={"UIAdv", "3"}}
We["4"]={id=4, flyType=3, lvid=154, trigType=2, trigParam=10114, des="开启神兵系统", objID={3040000}, openType=1, modid=9001, openAnim=1, delay=6000, icon={"sys_2.png", "test_open_sb", "P_Sword02_UI"}, preview=1, preViewDes="[bdefff]开启神兵，养成神兵，可增加战力，改变形态[ffffff]", lvLimit=4, jump={"UIAdv", "4"}}
We["5"]={id=5, flyType=3, lvid=154, trigType=2, trigParam=10426, des="翅膀开启", objID={3050000}, openType=1, modid=9005, openAnim=1, delay=8000, icon={"sys_1.png", "test_open_cb", "SK_Wing02_H"}, preview=1, preViewDes="[bdefff]初始翅膀，进阶可增加战力，改变形态[ffffff]", lvLimit=1, jump={"UIAdv", "5"}}
We["6"]={id=6, flyType=3, lvid=154, trigType=1, trigParam=370, des="宝座开启", openType=2, openAnim=0, delay=6000, icon={"sys_13.png"}, preViewDes="[bdefff]初始宝座，进阶可增加战力，改变形态[ffffff]", lvLimit=320, jump={"UIAdv", "6"}}
We["11"]={id=11, flyType=3, lvid=155, trigType=2, trigParam=10412, des="装备强化", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preview=1, preViewDes="[bdefff]开启装备强化，可将装备升级[ffffff]", lvLimit=1, jump={"UIEquip", "1"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["13"]={id=13, flyType=3, lvid=155, trigType=1, trigParam=105, des="合成系统", openType=2, openAnim=0, delay=6000, icon={"hecheng.png"}, preViewDes="[bdefff]开启合成，万物皆可合合合[ffffff]"}
We["14"]={id=14, flyType=3, lvid=155, trigType=1, trigParam=120, des="宝石镶嵌", openType=2, openAnim=0, delay=6000, icon={"sys_22.png"}, preview=1, preViewDes="[bdefff]玩家可通过宝石镶嵌加强属性[ffffff]", lvLimit=105, jump={"UIEquip", "3"}, award={{id=30001, num=2, bind=0}, {id=30011, num=2, bind=0}}}
We["15"]={id=15, flyType=3, lvid=155, trigType=1, trigParam=220, des="装备洗练", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preview=1, preViewDes="[bdefff]开启洗练功能，更高装备属性！[ffffff]", jump={"UIEquip", "2"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["17"]={id=17, flyType=3, lvid=155, trigType=1, trigParam=350, des="纹印", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preview=1, preViewDes="[bdefff]玩家可通过纹印镶嵌加强属性[ffffff]", jump={"UIEquip", "5"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["18"]={id=18, flyType=3, lvid=155, trigType=1, trigParam=360, des="淬炼", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preview=1, preViewDes="[bdefff]开启宝石淬炼功能，获得更高装备属性！[ffffff]", jump={"UIEquip", "4"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["19"]={id=19, flyType=3, lvid=155, trigType=1, trigParam=240, des="装备合成", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preViewDes="[bdefff]装备合成，极品红装不是梦[ffffff]", jump={"UICompound", "3"}}
We["20"]={id=20, flyType=3, lvid=155, trigType=1, trigParam=170, des="装备收集", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preViewDes="[bdefff]收集装备，激活技能[ffffff]"}
We["21"]={id=21, flyType=3, lvid=109, trigType=1, trigParam=230, des="九九窥星塔", openType=2, openAnim=0, delay=6000, icon={"sys_34.png"}, preview=1, preViewDes="[bdefff]开启窥星塔，通关可得符文[ffffff]", lvLimit=48, jump={"UICopyTowerPanel"}, award={{id=35100, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["22"]={id=22, flyType=3, lvid=156, trigType=1, trigParam=350, des="符文合成", openType=2, openAnim=0, delay=6000, icon={"sys_50.png"}, preViewDes="[bdefff]符文助力！战力更上一层！[ffffff]"}
We["23"]={id=23, flyType=3, lvid=156, trigType=1, trigParam=230, des="符文", openType=2, openAnim=0, delay=6000, icon={"sys_50.png"}, preview=1, preViewDes="[bdefff]符文助力！战力更上一层！[ffffff]", jump={"UIRune"}, award={{id=30301, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["31"]={id=31, flyType=3, lvid=160, trigType=2, trigParam=10403, des="道庭", openType=2, openAnim=0, delay=6000, icon={"sys_5.png"}, preview=1, preViewDes="[bdefff]开启道庭，按照指引可以加入[ffffff]", lvLimit=1, jump={"UIFamilyMainWnd"}, award={{id=30321, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["33"]={id=33, flyType=3, trigType=1, trigParam=110, des="道庭任务", openType=2, openAnim=0, delay=6000, icon={"sys_5.png"}, preview=1, preViewDes="[bdefff]开启道庭任务，完成得道绩奖励[ffffff]", lvLimit=130, jump={"UIFamilyMission"}, award={{id=31018, num=1, bind=0}, {id=1, num=100000, bind=0}}}
We["41"]={id=41, flyType=3, lvid=116, trigType=1, trigParam=96, des="日常活跃", openType=2, openAnim=0, delay=6000, icon={"sys_7.png"}}
We["42"]={id=42, flyType=3, lvid=112, trigType=2, trigParam=10409, des="世界BOSS", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]玩家击败世界boss可得海量奖励[ffffff]", lvLimit=62, jump={"UIBoss", "1"}, award={{id=31018, num=1, bind=0}, {id=1, num=100000, bind=0}}}
We["43"]={id=43, lvid=102, trigType=1, trigParam=130, des="排行榜", openType=2, openAnim=0}
We["44"]={id=44, flyType=3, lvid=111, trigType=2, trigParam=10226, des="竞技殿", openType=2, openAnim=0, delay=6000, icon={"sys_48.png"}, preview=1, preViewDes="[bdefff]开启竞技大厅，PK得奖励[ffffff]", lvLimit=100, jump={"UIArena"}, award={{id=30321, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["46"]={id=46, flyType=3, lvid=136, trigType=1, trigParam=2, des="境界", openType=2, openAnim=0, delay=6000, icon={"sys_51.png"}}
We["49"]={id=49, trigType=1, trigParam=45, des="首充第一次弹出", openType=2, openAnim=0}
We["50"]={id=50, trigType=1, trigParam=85, des="首充第二次弹出", openType=2, openAnim=0}
We["51"]={id=51, trigType=2, trigParam=10109, des="首充第三次弹出", openType=2, openAnim=0}
We["52"]={id=52, trigType=1, trigParam=125, des="零元抢购", openType=2}
We["53"]={id=53, flyType=3, lvid=159, trigType=1, trigParam=150, des="仙侣", openType=2, openAnim=0, delay=6000, icon={"sys_43.png"}, preview=1, preViewDes="[bdefff]寂寞吗，找个伴侣一起玩吧！[ffffff]", lvLimit=155, jump={"UIMarry", "1"}, award={{id=31005, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["54"]={id=54, flyType=3, lvid=158, trigType=1, trigParam=250, des="仙魂", openType=2, openAnim=0, delay=6000, icon={"sys_8.png"}, preview=1, preViewDes="[bdefff]收集合成仙魂，提升战力[ffffff]", lvLimit=240, jump={"UIImmortalSoul"}, award={{id=31018, num=1, bind=0}, {id=1, num=100000, bind=0}}}
We["55"]={id=55, flyType=3, lvid=139, trigType=1, trigParam=125, des="闭关修炼", openType=2, openAnim=0, delay=6000, icon={"sys_44.png"}, preview=1, preViewDes="[bdefff]闭关修炼可获取额外经验和银两[ffffff]", lvLimit=90, jump={"UIRobbery", "1"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["56"]={id=56, flyType=3, lvid=157, trigType=1, trigParam=290, des="神兽", openType=2, openAnim=0, delay=6000, icon={"sys_45.png"}, preview=1, preViewDes="[bdefff]收集装备激活神兽，提升战力[ffffff]", lvLimit=260, jump={"UISoulBearst"}, award={{id=31018, num=1, bind=0}, {id=1, num=100000, bind=0}}}
We["58"]={id=58, flyType=3, lvid=155, trigType=1, trigParam=105, des="首饰进阶", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preViewDes="[bdefff]开启首饰进阶，可进阶戒指手镯[ffffff]", lvLimit=300, jump={"UICompound", "5"}, award={{id=30003, num=2, bind=0}, {id=30013, num=2, bind=0}}}
We["59"]={id=59, flyType=3, lvid=157, trigType=1, trigParam=160, des="图鉴", openType=2, openAnim=0, delay=6000, icon={"sys_45.png"}, preview=1, preViewDes="[bdefff]开启图鉴功能，战力更高[ffffff]", lvLimit=120, jump={"UIPicCollect"}, award={{id=30331, num=5, bind=0}, {id=1001, num=1, bind=0}}}
We["60"]={id=60, trigType=1, trigParam=320, des="化神寻宝", openType=0}
We["61"]={id=61, trigType=1, trigParam=90, des="拍卖行", openType=0}
We["62"]={id=62, flyType=3, lvid=136, trigType=1, trigParam=380, des="战神套装", openType=2, openAnim=0, delay=6000, icon={"sys_51.png"}, preViewDes="[bdefff]战灵变战神，让战斗力爆炸吧！[ffffff]"}
We["63"]={id=63, flyType=3, lvid=149, trigType=1, trigParam=200, des="主宰神殿", openType=2, jump={"UITemple"}}
We["65"]={id=65, flyType=3, lvid=153, trigType=1, trigParam=150, des="天赋", openType=2, openAnim=0, delay=6000, icon={"sys_28.png"}, preview=1, preViewDes="[bdefff]万法归宗，天赋开启！[ffffff]", jump={"UIRole", "3"}, award={{id=30301, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["66"]={id=66, lvid=103, trigType=1, trigParam=138, des="道庭护送", openType=2, openAnim=0, delay=6000, icon={"sys_25.png"}}
We["67"]={id=67, flyType=3, trigType=1, trigParam=270, des="战灵灵饰", openType=2, openAnim=0, delay=6000, preViewDes="[bdefff]战灵灵饰开启，战灵更强力！[ffffff]"}
We["68"]={id=68, flyType=3, lvid=713, trigType=6, trigParam=1302, des="战灵", openType=2, openAnim=0, delay=6000, preViewDes="[bdefff]战灵开启，战力暴增！[ffffff]"}
We["69"]={id=69, flyType=3, lvid=109, trigType=1, trigParam=275, des="太虚通天塔", openType=2, openAnim=0, delay=6000, icon={"sys_34.png"}, preViewDes="[bdefff]开启太虚通天塔，通关获得战灵装备开孔道具[ffffff]"}
We["100"]={id=100, flyType=3, trigType=2, trigParam=10099, des="习得新技能", objID={1011001, 1002001}, openType=2, openAnim=0, delay=6000}
We["101"]={id=101, flyType=3, trigType=2, trigParam=10099, des="习得新技能", objID={1012001, 1003001}, openType=2, openAnim=0, delay=6000}
We["102"]={id=102, flyType=3, trigType=2, trigParam=10099, des="习得新技能", objID={1013001, 1004001}, openType=2, openAnim=0, delay=6000}
We["103"]={id=103, flyType=3, trigType=2, trigParam=10099, des="习得新技能", objID={1014001, 1005001}, openType=2, openAnim=0, delay=6000}
We["104"]={id=104, flyType=1, trigType=3, trigParam=270101, des="习得新技能", objID={1101001, 1101001}, openType=3}
We["105"]={id=105, flyType=1, trigType=3, trigParam=270102, des="习得新技能", objID={1102001, 1102001}, openType=3}
We["106"]={id=106, flyType=1, trigType=3, trigParam=270103, des="习得新技能", objID={1103001, 1103001}, openType=3}
We["107"]={id=107, flyType=1, trigType=3, trigParam=270104, des="习得新技能", objID={1104001, 1104001}, openType=3}
We["108"]={id=108, flyType=1, trigType=3, trigParam=270105, des="习得新技能", objID={1105001, 1105001}, openType=3}
We["109"]={id=109, flyType=1, trigType=3, trigParam=270106, des="习得新技能", objID={1106001, 1106001}, openType=3}
We["110"]={id=110, flyType=1, trigType=3, trigParam=270107, des="习得新技能", objID={1107001, 1107001}, openType=3}
We["111"]={id=111, flyType=1, lvid=153, trigType=4, trigParam=1, des="习得新技能", objID={1123001, 1123001}, openType=3}
We["112"]={id=112, flyType=1, lvid=153, trigType=4, trigParam=2, des="习得新技能", objID={1124001, 1124001}, openType=3}
We["113"]={id=113, flyType=1, lvid=153, trigType=4, trigParam=3, des="习得新技能", objID={1126001, 1126001}, openType=3}
We["114"]={id=114, flyType=1, lvid=153, trigType=5, trigParam=31057, des="习得新技能", objID={1125001, 1125001}, openType=3}
We["115"]={id=115, flyType=1, lvid=153, trigType=4, trigParam=4, des="习得新技能", objID={1127001, 1127001}, openType=3}
We["303"]={id=303, lvid=103, trigType=1, trigParam=30, des="冲级豪礼", openType=2, openAnim=0}
We["401"]={id=401, flyType=3, lvid=110, trigType=2, trigParam=10420, des="青竹院", openType=2, openAnim=0, delay=6000, icon={"sys_41.png"}, preview=1, preViewDes="[bdefff]开启经验副本，通关得大量经验[ffffff]", lvLimit=55, jump={"UICopy", "1"}, award={{id=31008, num=2, bind=0}, {id=1, num=100000, bind=0}}}
We["402"]={id=402, lvid=110, trigType=1, trigParam=200, des="失落谷", openType=2, openAnim=0, delay=6000, icon={"sys_26.png"}, preview=1, preViewDes="[bdefff]开启伙伴副本，通关得进阶材料[ffffff]", lvLimit=75, jump={"UICopy", "7"}, award={{id=30361, num=15, bind=0}, {id=1, num=100000, bind=0}}}
We["404"]={id=404, flyType=3, lvid=110, trigType=1, trigParam=170, des="青松魔庭", openType=2, openAnim=0, delay=6000, icon={"sys_41.png"}, preview=1, preViewDes="[bdefff]开启装备副本，通关得新装备[ffffff]", lvLimit=130, jump={"UICopy", "3"}, award={{id=30341, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["405"]={id=405, flyType=3, lvid=110, trigType=2, trigParam=10221, des="百湾角", openType=2, openAnim=0, delay=6000, icon={"sys_16.png"}, preview=1, preViewDes="[bdefff]开启银两副本，通关得大量银两[ffffff]", lvLimit=150, jump={"UICopy", "2"}, award={{id=30331, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["406"]={id=406, flyType=3, lvid=110, trigType=1, trigParam=999, des="战魂台", openType=2, openAnim=0, delay=6000, icon={"sys_41.png"}, preViewDes="[bdefff]开启战灵副本，通关得进阶材料[ffffff]", lvLimit=180, award={{id=31018, num=1, bind=0}, {id=1, num=100000, bind=0}}}
We["407"]={id=407, flyType=3, lvid=110, trigType=1, trigParam=135, des="五行幻境", openType=2, openAnim=0, delay=6000, icon={"sys_32.png"}, preview=1, preViewDes="[bdefff]开启五行幻境，通关得极品天机印[ffffff]", jump={"UIRobbery", "11"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["408"]={id=408, flyType=2, lvid=110, trigType=1, trigParam=250, des="幽魂林", openType=2, openAnim=0, delay=6000, icon={"sys_26.png"}, preview=1, preViewDes="[bdefff]开启幽魂林，通关得极品仙魂[ffffff]", jump={"UICopy", "15"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["409"]={id=409, flyType=3, lvid=109, trigType=1, trigParam=340, des="镇魂塔", openType=2, openAnim=0, delay=6000, icon={"sys_34.png"}, preview=1, preViewDes="[bdefff]开启镇魂塔，通关得铸魂材料[ffffff]", jump={"UICopyTowerPanel", "19"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["410"]={id=410, flyType=3, lvid=112, trigType=1, trigParam=270, des="幽冥地界", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]开启幽冥地界，击败得套装材料[ffffff]", lvLimit=220, jump={"UIBoss", "4"}, award={{id=31009, num=2, bind=0}, {id=1, num=100000, bind=0}}}
We["411"]={id=411, flyType=3, lvid=112, trigType=2, trigParam=10409, des="个人BOSS", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]还去抢BOSS？个人独享BOSS，你值得拥有[ffffff]", jump={"UIBoss", "3"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["412"]={id=412, flyType=3, lvid=112, trigType=1, trigParam=160, des="洞天福地", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]Boss无限刷，装备道具随便拿[ffffff]", jump={"UIBoss", "2"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["413"]={id=413, flyType=3, lvid=143, trigType=1, trigParam=290, des="神兽岛", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]开启神兽岛，激活神兽套装[ffffff]", jump={"UICross", "5"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["414"]={id=414, flyType=3, lvid=143, trigType=1, trigParam=300, des="世界服", openType=2, openAnim=0, delay=6000, icon={"sys_18.png"}, preview=1, preViewDes="[bdefff]进击！角逐世界服！[ffffff]", jump={"UICross", "6"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["415"]={id=415, flyType=3, lvid=143, trigType=1, trigParam=380, des="远古遗迹", openType=2, openAnim=0, delay=6000, icon={"sys_17.png"}, preview=1, preViewDes="[bdefff]开启远古遗迹，激活战神套装[ffffff]", jump={"UICross", "7"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["502"]={id=502, trigType=2, trigParam=10230, des="日常任务", openType=2, openAnim=0, delay=6000, icon={"sys_7.png"}, preview=1, preViewDes="[bdefff]开启日常任务，循环得经验奖励[ffffff]", lvLimit=1, jump={"UILiveness"}, award={{id=30321, num=5, bind=0}, {id=1, num=100000, bind=0}}}
We["503"]={id=503, flyType=3, lvid=119, trigType=2, trigParam=10208, des="天书寻主", openType=2, openAnim=0, delay=6000, icon={"sys_19.png"}}
We["504"]={id=504, trigType=1, trigParam=230, des="符文寻宝", openType=2, openAnim=0}
We["505"]={id=505, flyType=3, lvid=155, trigType=1, trigParam=340, des="铸魂", openType=2, openAnim=0, delay=6000, icon={"sys_11.png"}, preview=1, preViewDes="[bdefff]开启装备铸魂功能，获得更高装备属性！[ffffff]", jump={"UIEquip", "6"}, award={{id=30301, num=5, bind=0}, {id=1, num=200000, bind=0}}}
We["701"]={id=701, lvid=161, trigType=2, trigParam=10409, des="套装开启", openType=0}
We["706"]={id=706, flyType=3, lvid=706, trigType=1, trigParam=135, des="天机印", openType=2, openAnim=0, delay=6000, icon={"sys_52.png"}, preViewDes="[bdefff]可通过天机印镶嵌加强属性，指定搭配可激活套装效果[ffffff]"}
We["707"]={id=707, flyType=3, lvid=714, trigType=1, trigParam=140, des="丹药", openType=2, openAnim=0, delay=6000, icon={"sys_27.png"}, preViewDes="[bdefff]吸收丹药可提升属性，战力飞跃[ffffff]"}
We["708"]={id=708, trigType=1, trigParam=140, des="凡品丹炉", openType=0}
We["709"]={id=709, flyType=3, lvid=136, trigType=1, trigParam=90, des="摇钱树", openType=2, openAnim=0, delay=6000, icon={"sys_51.png"}, preViewDes="[bdefff]来看看今日财运如何吧[ffffff]"}
We["710"]={id=710, flyType=3, lvid=136, trigType=1, trigParam=240, des="迷境探索", openType=2, openAnim=0, delay=6000, icon={"sys_51.png"}, preViewDes="[bdefff]探索迷境，看看上仙机遇如何吧[ffffff]"}
