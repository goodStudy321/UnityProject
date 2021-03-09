--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:C_藏宝图基础表.xml, excel:C 藏宝图基础表.xls, sheet:Sheet1
--******************************************************************************
TreasureBaseCfg={}
local We=TreasureBaseCfg
We["101"]={id=101, des="道具奖励", bossInfo={}, teamInfo={}, sceneId=0}
We["201"]={id=201, des="boss挑战", bossInfo={{id=210204, minLv=1, maxLv=300, weight=10000}, {id=210206, minLv=301, maxLv=500, weight=10000}}, teamInfo={}, sceneId=60001, pos={{x=-50, y=-360}, {x=-50, y=-360}}}
We["301"]={id=301, des="组队挑战", bossInfo={}, teamInfo={{id=60002, minLv=1, maxLv=300, weight=10000}, {id=60003, minLv=301, maxLv=500, weight=10000}}, sceneId=60002}
