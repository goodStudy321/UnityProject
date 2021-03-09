--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:H_活动配置.xml, excel:H 活动配置.xls, sheet:Sheet1
--******************************************************************************
ActiveInfo={}
local We=ActiveInfo
We["10001"]={id=10001, name="诛仙战场", needLv=115, begDay={2, 4, 6}, begTime={{k=14, v=0}, {k=18, v=0}}, lastTime=600, desc="1.玩家被随机分入一个阵营，加入战斗。\n2.攻击其他阵营的聚灵桩或玩家可以得到积分。\n3.玩家阵亡可选择回到复活点复活，或是花费元宝原地复活。\n4.占领其他阵营聚灵桩后，每隔一段时间，己方阵营玩家可\n增加积分。\n5.积分越高，奖励越丰富！", rewards={100, 30322, 220004}, sceneId=30001}
We["10002"]={id=10002, name="仙峰论剑", needLv=115, begDay={2, 4, 6}, begTime={{k=21, v=0}}, lastTime=1800, desc="1.每天前10场可获得经验奖励\n2.每天获得积分决定段位\n3.开服前7天为单服阶段，第7天结束后将结算并发放单服排名奖励\n4.第8天开始进入跨服区，开启跨服赛季", rewards={11, 107, 30322}, sceneId=30002}
We["10003"]={id=10003, name="守卫道庭", needLv=200, begDay={1, 3, 5}, begTime={{k=21, v=0}}, lastTime=1800, desc="召唤同伴[00ff00]极道祖师[-]，共同抵御来犯敌人可获得[00ff00]海量经验[-]", rewards={13, 100}, sceneId=0}
We["10004"]={id=10004, name="蜀山论道", needLv=120, begDay={1, 2, 3, 4, 5, 6, 7}, begTime={{k=12, v=0}}, lastTime=521, desc="", rewards={}, sceneId=0}
We["10006"]={id=10006, name="道庭答题", needLv=130, begDay={1, 2, 3, 4, 5, 6, 7}, begTime={{k=20, v=30}}, lastTime=900, desc="", rewards={}, sceneId=0}
We["10008"]={id=10008, name="逍遥神坛", needLv=135, begDay={1, 3, 5, 7}, begTime={{k=14, v=0}, {k=18, v=0}}, lastTime=1800, desc="1.活动即将开始，给为道长做好准备~", rewards={}, sceneId=30009}
We["10009"]={id=10009, name="神魔之战", needLv=350, begDay={}, begTime={{k=20, v=0}}, lastTime=1800, desc="1.每天前10场可获得经验奖励\n2.每天获得积分决定段位,每天24小时刷新奖励 ", rewards={20001, 20002, 31001, 31002}, sceneId=0}
We["10010"]={id=10010, name="道庭大战", needLv=200, begDay={7}, begTime={{k=21, v=0}}, lastTime=1800, desc="", rewards={}, sceneId=30008}
We["10011"]={id=10011, name="魔域boss", needLv=180, begDay={1, 2, 3, 4, 5, 6, 7}, begTime={{k=10, v=0}, {k=13, v=0}, {k=16, v=0}, {k=19, v=0}}, lastTime=660, desc="", rewards={}, sceneId=30021}
We["10012"]={id=10012, name="道庭神兽", needLv=140, begDay={1, 2, 3, 4, 5, 6, 7}, begTime={{k=12, v=30}, {k=19, v=30}}, lastTime=600, desc="", rewards={}, sceneId=0}
We["10013"]={id=10013, name="迷境探索", needLv=240, begDay={1}, begTime={{k=9, v=0}}, lastTime=486000, desc="秘境探索表", rewards={}, sceneId=0}
We["90001"]={id=90001, name="道庭护送", needLv=138, begDay={1, 2, 3, 4, 5, 6, 7}, begTime={{k=9, v=0}}, lastTime=50400, desc="", rewards={}, sceneId=0}
