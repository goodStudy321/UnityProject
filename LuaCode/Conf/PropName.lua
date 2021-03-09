--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:S_角色属性字段.xml, excel:S 角色属性字段.xls, sheet:Sheet1
--******************************************************************************
PropName={}
local We=PropName
We[1]={id=1, name="生命", nLua="hp", show=0, fight=0.5, Text="生命"}
We[2]={id=2, name="攻击", nLua="atk", show=0, fight=10, Text="攻击"}
We[3]={id=3, name="防御", nLua="def", show=0, fight=10, Text="防御"}
We[4]={id=4, name="破甲", nLua="arm", show=0, fight=10, Text="破甲"}
We[5]={id=5, name="命中", nLua="hit", show=0, fight=10, Text="命中"}
We[6]={id=6, name="闪避", nLua="dodge", show=0, fight=10, Text="闪避"}
We[7]={id=7, name="暴击", nLua="crit", show=0, fight=10, Text="暴击"}
We[8]={id=8, name="韧性", nLua="tena", show=0, fight=10, Text="韧性"}
We[9]={id=9, name="暴击伤害", nLua="critdam", show=1, Text="暴击伤害"}
We[10]={id=10, name="暴伤减免", nLua="resil", show=1, Text="暴伤减免"}
We[11]={id=11, name="伤害加深", nLua="ampdam", show=1, Text="伤害加深"}
We[12]={id=12, name="伤害减免", nLua="damred", show=1, Text="伤害减免"}
We[13]={id=13, name="暴击几率", nLua="critpro", show=1, Text="暴击几率"}
We[14]={id=14, name="闪避几率", nLua="dodgepro", show=1, Text="闪避几率"}
We[15]={id=15, name="暴击抵抗", nLua="critdef", show=1, Text="暴击抵抗"}
We[16]={id=16, name="技能伤害增加", nLua="addskilldam", show=1, Text="技能伤害增加"}
We[17]={id=17, name="技能伤害减少", nLua="reduceskilldam", show=1, Text="技能伤害减少"}
We[18]={id=18, name="生命加成", nLua="hpadd", show=1, Text="生命加成"}
We[19]={id=19, name="攻击加成", nLua="atkadd", show=1, Text="攻击加成"}
We[20]={id=20, name="防御加成", nLua="defadd", show=1, Text="防御加成"}
We[21]={id=21, name="破甲加成", nLua="armadd", show=1, Text="破甲加成"}
We[22]={id=22, name="命中加成", nLua="hitadd", show=1, Text="命中加成"}
We[23]={id=23, name="闪避加成", nLua="dodgeadd", show=1, Text="闪避加成"}
We[24]={id=24, name="暴击加成", nLua="critadd", show=1, Text="暴击加成"}
We[25]={id=25, name="韧性加成", nLua="tenaadd", show=1, Text="韧性加成"}
We[26]={id=26, name="经验加成", nLua="exp", show=1, Text="经验加成"}
We[27]={id=27, name="移动速度", nLua="speed", show=0, Text="移动速度"}
We[28]={id=28, name="人物护甲", nLua="rolearmor", show=1, Text="人物护甲"}
We[29]={id=29, name="每3级攻击", nLua="lv_atk", show=0, Text="每3级攻击"}
We[30]={id=30, name="每3级破甲", nLua="lv_arm", show=0, Text="每3级破甲"}
We[31]={id=31, name="每3级生命", nLua="lv_hp", show=0, Text="每3级生命"}
We[32]={id=32, name="每3级防御", nLua="lv_def", show=0, Text="每3级防御"}
We[33]={id=33, name="金币掉落", nLua="money_drop", show=1, Text="金币掉落"}
We[34]={id=34, name="物品掉落", nLua="item_drop", show=1, Text="物品掉落"}
We[35]={id=35, name="宠物总属性增加", nLua="cwAllAdd", show=1, Text="宠物总属性增加"}
We[36]={id=36, name="坐骑总属性增加", nLua="zqAllAdd", show=1, Text="坐骑总属性增加"}
We[37]={id=37, name="翅膀总属性增加", nLua="cbAllAdd", show=1, Text="翅膀总属性增加"}
We[38]={id=38, name="法宝总属性增加", nLua="fbAllAdd", show=1, Text="法宝总属性增加"}
We[39]={id=39, name="神兵总属性增加", nLua="sbAllAdd", show=1, Text="神兵总属性增加"}
We[40]={id=40, name="防具生命", nLua="equiphp", show=1, Text="防具生命"}
We[41]={id=41, name="防具防御", nLua="equipdef", show=1, Text="防具防御"}
We[42]={id=42, name="武器攻击", nLua="weaponatt", show=1, Text="武器攻击"}
We[43]={id=43, name="武器破甲", nLua="weaponarm", show=1, Text="武器破甲"}
We[44]={id=44, name="仙器攻击", nLua="immatt", show=1, Text="仙器攻击"}
We[45]={id=45, name="基础攻击", nLua="baseatt", show=1, Text="基础攻击"}
We[46]={id=46, name="基础生命", nLua="basehp", show=1, Text="基础生命"}
We[47]={id=47, name="基础破甲", nLua="basearm", show=1, Text="基础破甲"}
We[48]={id=48, name="基础防御", nLua="basedef", show=1, Text="基础防御"}
We[49]={id=49, name="pvp伤害减免", show=1, Text="pvp伤害减免"}
We[50]={id=50, name="boss伤害加深", show=1, Text="boss伤害加深"}
We[51]={id=51, name="每级10点攻击", show=0, Text="每级10点攻击"}
We[52]={id=52, name="每50级boss伤害增加", show=1, Text="每50级boss伤害增加"}
We[53]={id=53, name="伤害反弹", show=1, Text="伤害反弹"}
We[54]={id=54, name="对所有怪物伤害加深", show=1, Text="对所有怪物伤害加深"}
We[55]={id=55, name="移动速度百分比加成", show=1, Text="移动速度百分比"}
We[56]={id=56, name="对定身状态敌人伤害加深", show=1, Text="对定身状态敌人伤害加深"}
We[57]={id=57, name="对沉默状态敌人伤害加深", show=1, Text="对沉默状态敌人伤害加深"}
We[58]={id=58, name="攻击触发眩晕概率", show=1, Text="每次攻击触发眩晕效果的概率"}
We[59]={id=59, name="强化属性加成", show=1, Text="装备强化总属性增加"}
We[60]={id=60, name="每级回血加成", show=0, Text="每级回血加成"}
We[61]={id=61, name="最大血量回血万分比", show=1, Text="最大血量回血"}
We[62]={id=62, name="装备基础属性万分比", show=1, Text="装备基础属性"}
We[63]={id=63, name="套装基础属性", show=1, Text="战神套装属性万分比"}
We[64]={id=64, name="绝对闪避", show=1, Text="受到攻击有概率必定闪避一次伤害"}
We[65]={id=65, name="绝命一击", show=1, Text="攻击有概率对目标追加一次技能伤害"}
We[66]={id=66, name="中毒伤害加成", show=1, Text="对中毒状态的角色伤害加成"}
We[67]={id=67, name="燃烧伤害加成", show=1, Text="对燃烧状态的角色伤害加成"}
We[68]={id=68, name="受到boss伤害降低", show=1, Text="受到boss伤害降低"}
We[69]={id=69, name="攻击力百分比吸血", nLua="atkP", show=1, Text="攻击力百分比吸血"}
We[70]={id=70, name="战灵持续时长", show=0, Text="战灵存在的时长"}
We[71]={id=71, name="金攻击", nLua="metal", show=0, Text="金攻击"}
We[72]={id=72, name="木攻击", nLua="wood", show=0, Text="木攻击"}
We[73]={id=73, name="水攻击", nLua="water", show=0, Text="水攻击"}
We[74]={id=74, name="火攻击", nLua="fire", show=0, Text="火攻击"}
We[75]={id=75, name="土攻击", nLua="soil", show=0, Text="土攻击"}
We[76]={id=76, name="金抗性", show=0, Text="金抗性"}
We[77]={id=77, name="木抗性", show=0, Text="木抗性"}
We[78]={id=78, name="水抗性", show=0, Text="水抗性"}
We[79]={id=79, name="火抗性", show=0, Text="火抗性"}
We[80]={id=80, name="土抗性", show=0, Text="土抗性"}
We[81]={id=81, name="角色等级提升生命（变量）", show=0, Text="角色等级提升生命（变量）"}
We[82]={id=82, name="角色等级提升攻击（变量）", show=0, Text="角色等级提升攻击（变量）"}
We[83]={id=83, name="角色等级提高防御", show=0, Text="角色等级提高防御"}
We[84]={id=84, name="角色等级提高破甲", show=0, Text="角色等级提高破甲"}
We[85]={id=85, name="角色等级提高命中", show=1, Text="角色等级提高命中"}
We[86]={id=86, name="角色等级提高闪避", show=0, Text="角色等级提高闪避"}
We[87]={id=87, name="每200级加成1%伤害减免", show=0, Text="每200级加成1%伤害减免"}
We[88]={id=88, name="境界提升生命", show=0, Text="境界提升生命"}
We[89]={id=89, name="境界提升攻击", show=0, Text="境界提升攻击"}
We[90]={id=90, name="境界提升技能伤害减免", show=1, Text="境界提升技能伤害减免"}
We[91]={id=91, name="境界提升技能伤害加成", show=1, Text="境界提升技能伤害加成"}
We[92]={id=92, name="穿戴状态受到玩家伤害降低", show=0, Text="穿戴状态受到玩家伤害降低"}
We[93]={id=93, name="境界提升伤害减免", show=0, Text="境界提升伤害减免"}
We[94]={id=94, name="境界提升伤害加成", show=0, Text="境界提升伤害加成"}
We[95]={id=95, name="格挡几率", show=1, Text="格挡几率"}
We[96]={id=96, name="格挡减伤", show=1, Text="格挡减伤"}
We[97]={id=97, name="无视格挡", show=1, Text="无视格挡"}
We[98]={id=98, name="格挡穿透", show=1, Text="格挡穿透"}
We[99]={id=99, name="治疗加成", show=1, Text="治疗加成"}
We[100]={id=100, name="境界提升格挡减伤", show=1, Text="境界提升格挡减伤"}
We[101]={id=101, name="境界提升格挡几率", show=1, Text="境界提升格挡几率"}
We[102]={id=102, name="晕眩伤害加成", show=1, Text="晕眩伤害加成"}
We[103]={id=103, name="减速伤害加成", show=1, Text="减速伤害加成"}
We[104]={id=104, name="中毒buff伤害加成", show=1, Text="中毒buff伤害加成"}
We[105]={id=105, name="燃烧buff伤害加成", show=1, Text="燃烧buff伤害加成"}
We[106]={id=106, name="受到中毒敌人伤害降低", show=1, Text="中毒伤害降低"}
We[107]={id=107, name="受到燃烧敌人伤害减低", show=1, Text="燃烧伤害减低"}
We[108]={id=108, name="受到减速敌人伤害降低", show=1, Text="减速伤害降低"}
We[109]={id=109, name="铭文等级生命", show=0, Text="铭文等级生命"}
We[110]={id=110, name="铭文等级攻击", show=0, Text="铭文等级攻击"}
We[111]={id=111, name="PVP伤害加成", nLua="pvpAdd", show=1, Text="PVP伤害加成"}
We[112]={id=112, name="每10级提高暴击率万分比", show=1, Text="每10级提高1%暴击率"}
