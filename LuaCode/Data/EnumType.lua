--Phantom
--Not Edit

ProType = {}
ProType.HP                              = 1                         --生命
ProType.Atk                              = 2                            --攻击
ProType.Def                              = 3                            --防御
ProType.Arp                             = 4                           --破甲
ProType.Hit                             = 5                            --命中
ProType.Miss                            = 6                            --闪避
ProType.Crit                            = 7                            --暴击
ProType.Crit_Anti                       = 8                            --韧性
ProType.Crit_Multi                      = 9                            --暴伤
ProType.Hurt_Rate                       = 11                           --加伤
ProType.Hurt_Derate                     = 12                           --免伤
ProType.Cirt_Doubel                     = 13                           --暴击几率
ProType.Miss_Double                     = 14                            --躲闪几率
ProType.Crit_Multi_anti                 = 15                            --暴击抵抗
ProType.Skill_Add                       = 16                           --技能伤害增加
ProType.Skill_Reduce                    = 17                           --技能伤害减少
ProType.Kill_Monster_Exp_Add_Buff       = 26                           --经验加成
ProType.ATTR_MOVE_SPEED                 = 27                            --移动速度
ProType.Role_Def                        = 28                            --人物护甲

ProType.Metal_Atk                       = 71                            --金攻
ProType.Wood_Atk                        = 72                            --木攻
ProType.Water_Atk                       = 73                            --水攻
ProType.Fire_Atk                        = 74                            --火攻
ProType.Soil_Atk                        = 75                            --土攻
ProType.Metal_Def                       = 76                            --金抗性
ProType.Wood_Def                        = 77                            --木抗性
ProType.Water_Def                       = 78                            --水抗性
ProType.Fire_Def                        = 79                            --火抗性 
ProType.Soil_Def                        = 80                            --土抗性

--[[

ProType.ATTR_RATE_ADD_PET_HURT 			= 34      	--宠物伤害增加
ProType.ATTR_RATE_ADD_WING_HURT 		= 35       	--翅膀伤害增加
ProType.ATTR_RATE_ADD_SILVER			= 36       	--金币掉落增加
ProType.ATTR_RATE_ADD_EQUIP 			= 37       	--装备掉落增加
ProType.ATTR_MOVE_SPEED 				= 38       	--移动速度
ProType.ATTR_RATE_ADD_HP 				= 35       	--生命增加万分比
ProType.ATTR_RATE_REDUCE_HP 			= 36       	--生命减少万分比
ProType.ATTR_RATE_ADD_ATTACK 			= 37       	--攻击增加万分比
ProType.ATTR_RATE_REDUCE_ATTACK 		= 38       	--攻击减少万分比
ProType.ATTR_RATE_ADD_DEFENCE 			= 39       	--防御增加万分比
ProType.ATTR_RATE_REDUCE_DEFENCE		= 40       	--防御减少万分比
ProType.ATTR_RATE_ADD_ARP 				= 41       	--破甲增加万分比
ProType.ATTR_RATE_REDUCE_ARP 			= 42       	--破甲减少万分比
ProType.ATTR_RATE_ADD_HIT 				= 43       	--命中增加万分比
ProType.ATTR_RATE_REDUCE_HIT 			= 44       	--命中减少万分比
ProType.ATTR_RATE_ADD_MISS 				= 45       	--闪避增加万分比
ProType.ATTR_RATE_REDUCE_MISS 			= 46       	--闪避减少万分比
ProType.ATTR_RATE_ADD_DOUBLE			= 47       	--暴击增加万分比
ProType.ATTR_RATE_REDUCE_DOUBLE 		= 48       	--暴击减少万分比
ProType.ATTR_RATE_ADD_DOUBLE_A 			= 49       	--韧性增加万分比
ProType.ATTR_RATE_REDUCE_DOUBLE_A 		= 50		--韧性减少万分比
]]--

--[[######################################################################################]]--
CopyType = {}
CopyType.Mission 									= 0
CopyType.Exp										= 1 		--经验副本
CopyType.Glod										= 2 		--金币副本
CopyType.Equip										= 3 		--装备副本
CopyType.Tower 										= 4 		--爬塔副本
CopyType.Light 										= 5 		--光照图副本
CopyType.PBoss                                      = 6         --个人boss副本
CopyType.SingleTD                                   = 7         --单人td副本
CopyType.XM                                         = 9         --心魔
CopyType.HYC                                        =10         --守护海源村
CopyType.YML                                        =11         --妖魔岭
CopyType.MLGK                                       =12         --魔龙洞窟
CopyType.GWD                                        =13         --鬼王殿
CopyType.Hjk                                        =14         --渡劫副本
CopyType.XH                                         = 15        --仙魂副本
CopyType.Loves                                      = 16        --情侣副本
CopyType.Disaster                                   = 17        --境界渡劫副本
CopyType.ZLT                                        = 18        --战灵台
CopyType.ZHTower                                    = 19        --镇魂塔
CopyType.TreasureBoss                               = 20        --藏宝图
CopyType.TreasureTeam                               = 21        --藏宝图组队
CopyType.Five                                       = 23        --五行副本
CopyType.Fever                                      = 24        -- 神秘宝藏
CopyType.TXTower                                    = 26        -- 太虚通天塔
CopyType.Team 										= 101 		--组队副本
--[[######################################################################################]]--
SceneType = {}
SceneType.Wild      							= 1 		--野外
SceneType.Copy								    = 2 		--副本
SceneType.Other                                 = 3         --其他没有地图数据

--场景子类型
--[[######################################################################################]]--
SceneSubType = {}
SceneSubType.None = 0
SceneSubType.WordBoss = 1                          --1 世界Boss地图
SceneSubType.HomeOfBoss = 2     --2 洞天福地Boss地图
SceneSubType.PersonalBoss = 3   --3 个人Boss地图
SceneSubType.WildFBoss = 4      --4 蛮荒禁地Boss地图
SceneSubType.AnswerMap = 5      --5 答题副本地图
SceneSubType.CampMap = 6        --6 多阵营对战地图
SceneSubType.OVOMap = 7         --7 1v1对战地图
SceneSubType.OffL1V1Map = 8     --8 离线1v1对战地图
SceneSubType.DftMap = 9         --9 道庭守卫
SceneSubType.FamilyBoss = 10    --道庭Boss
SceneSubType.FamilyBattle = 11  --帮会战
--[[######################################################################################]]--
MissionType = {}
MissionType.Main 									= 1 		--主线任务
MissionType.Feeder 									= 2 		--支线任务
MissionType.Turn									= 3		    --循环任务（日常任务）
MissionType.Family									= 4		    --帮派任务
MissionType.Escort                                  = 909        --护送任务(假任务)
MissionType.Liveness                                = 6          --每日活跃任务（并入日常任务）

--任务目标类型
MTType = {}
MTType.KILL 										= 0
MTType.TALK											= 1
MTType.COLLECTION									= 2
MTType.PATHFINDING 									= 4
MTType.KILL_PR 										= 5
MTType.FlowChart 									= 6
MTType.Copy                                         = 7
MTType.Fighting                                     = 8
MTType.Strengthen                                   = 9
MTType.GetExp                                       = 10
MTType.Liveness                                     = 11
MTType.Friend                                       = 12
MTType.WorldBoss                                    = 13
--MTType.Copy_UI                                      = 14
MTType.Compose                                      = 15
MTType.OVO                                          = 16
MTType.AllStrengthen                                = 17
MTType.Mission                                      = 18
MTType.Item                                         = 19
MTType.Confine                                      = 20
MTType.FamilyNum                                    = 21
MTType.FamilyEscort                                 = 22
MTType.FamilyRobbery                                = 23
MTType.CopyFive                                     = 24
--任务状态
MStatus = {}
MStatus.None										= 0
MStatus.NOT_RECEIVE									= 1            --未领取
MStatus.EXECUTE 									= 2            --未完成，执行中
MStatus.ALLOW_SUBMIT 								= 3           	--已完成，未提交
MStatus.COMPLETE 									= 4             --已经完成
MStatus.Fail 									    = 5             --失败
--任务执行
MExecute = {}
MExecute.None										= 1
MExecute.ClickItem									= 2
MExecute.ClickNpc									= 3
--[[######################################################################################]]--
FightValueType = {}
FightValueType.LEVLE 								= 1 		--等级
FightValueType.EQUIP_BASE 							= 2 		--装备基础
FightValueType.EQUIP_REFINE							= 3 		--装备强化
FightValueType.EQUIP_SUIT							= 4 		--装备套装
FightValueType.STONE 								= 5 		--宝石属性
FightValueType.STONE_SUIT 							= 6 		--宝石套装
FightValueType.MOUNT 								= 7 		--坐骑
FightValueType.MAGIC_WEAPON 						= 8 		--法宝
FightValueType.PET 									= 9 		--宠物
FightValueType.GOD_WEAPON 							= 10 		--神兵
FightValueType.WING 								= 11 		--翅膀
FightValueType.FASHION 								= 12 		--时装
--[[#########################################################################################]]--
UIMessageBtn = {}
UIMessageBtn.OK										= 1
UIMessageBtn.NO										= 2
UIMessageBtn.OKAndNO								= 3
UIMessageBtn.Confirm								= 4
UIMessageBtn.Cancel 								= 5
UIMessageBtn.ConfirmAndCancel 						= 5
--[[#########################################################################################]]--
PathRType = {}
PathRType.PRT_UNKNOWN 								= 0
--PathRType.PRT_NOPATH								= 1         --没有路径
PathRType.PRT_FORBIDEN							    = 1 	    --禁止
PathRType.PRT_PATH_SUC                              = 2         --寻路成功
PathRType.PRT_CALL_BREAK							= 3 	    --主动停止
PathRType.PRT_PASSIVEBREAK                          = 4         --被动引起中断
PathRType.PRT_ERROR_BREAK                           = 5         --错误引起中断

--PathRType.PRT_SHOES_SUC                             = 3         --小飞鞋成功
--PathRType.PRT_CHANGE_SCENE_BREAK					= 4         --转换场景中断
--PathRType.PRT_RESTART_BREAK							= 5 		--再次调用中断
--PathRType.PRT_MAX							        = 6
--[[#########################################################################################]]--
RankType = {}
RankType.None										= 0
RankType.RP 										= 10001		--战力排行
RankType.RL 										= 10002		--等级排行
RankType.MP 										= 10003		--坐骑战力排行
RankType.MWP 										= 10004		--法宝战力排行
RankType.PP 										= 10005		--宠物战力排行
RankType.GWP 										= 10006		--神兵战力排行
RankType.WP 										= 10007		--翅膀战力排行
RankType.OFF                                        = 10008     --离线效率排行
RankType.ZX                                         = 10009     --诛仙塔排行

--[[#########################################################################################]]--
RankPType = {}
RankPType.KRL										= 101		--角色等级
RankPType.KP										= 102		--战力
RankPType.KMI										= 103		--坐骑ID
RankPType.KPI										= 104		--宠物ID
RankPType.KGWI										= 105		--神兵ID
RankPType.KGWL										= 106		--神兵等级
RankPType.KMWL										= 108		--法宝等级
RankPType.KWI										= 109		--翅膀ID
RankPType.KWL										= 110		--翅膀等级
RankPType.ZXC                                       = 111       --诛仙通关层数
RankPType.KFN										= 201		--道庭名字
RankPType.OFFL										= 112		--离线效率
--[[#################################消耗货币#########################################]]
CostType = {}
CostType.Copper                                     = 1         --消耗银两
CostType.Glod                                       = 2         --消耗不绑定元宝
CostType.AnyGlod                                    = 3         --消耗任意元宝
CostType.Honor                                      = 11        --消耗荣誉
CostType.FamilyCon                                  = 99        --消耗帮派贡献
--[[#################################战力枚举#####################################]]
FightType = {}
FightType.All                                       = 0
FightType.LEVEL                                     = 1         --等级
FightType.EQUIP_BASE                                = 2         --装备基础属性
FightType.EQUIP_REFINE                              = 3         --装备强化属性
FightType.EQUIP_REFINE_LEVEL                        = 4         --装备强化等级属性
FightType.EQUIP_SUIT                                = 5         --装备套装属性
FightType.STONE                                     = 6         --宝石属性
FightType.STONE_LEVEL                               = 7         --宝石等级属性
FightType.MOUNT                                     = 8         --坐骑
FightType.MAGIC_WEAPON                              = 9         --法宝
FightType.PET                                       = 10        --宠物
FightType.GOD_WEAPON                                = 11        --神兵
FightType.WING                                      = 12        --翅膀
FightType.FASHION                                   = 13        --时装
FightType.FAMILY                                    = 14        --帮派技能加成
FightType.RUNE                                      = 15        --符文加成
FightType.ROLE_STATE                                = 22        --角色境界加成
FightType.THRONE                                    = 36        --宝座
--[[#################################好友列表类型#####################################]]
FriendsType = {}
FriendsType.Request                                 = 0         --请求列表
FriendsType.Friend                                  = 1         --好友列表
FriendsType.Black                                   = 2         --黑名单列表
FriendsType.Chat                                    = 3         --上次交流
--[[#################################sdk平台#####################################]]
SDKType = {}
SDKType.JH                                          = 1         --君海
--[[#################################道具id#####################################]]
ItemID = {}
ItemID.EXP = 100
--[[#################################怪物类型i#####################################]]
MonsterType = {}
MonsterType.Cmm                                     = 1         --小怪，
MonsterType.Elites                                  = 2         --精英，
MonsterType.Boss                                    = 3         --普通boss
MonsterType.WorldBoss                               = 4          --世界boss

--[[#################################服务器选项#####################################]]
SVR_OP = {Name = "SVR_OP"}
--默认
SVR_OP.DEFAULT=0
--评测
SVR_OP.EVALUATION=1
--[[################################完成副本类型#####################################]]
CopyEType = {} 
CopyEType.NONE = 0   --无限制
CopyEType.KILL = 1   --打怪
CopyEType.KILLLimit = 2   --杀N波怪
CopyEType.CONTIUNE = 3    --坚持固定时间
CopyEType.GUARD = 4    --守护

--[[################################角色挂件类型#####################################]]
PendantType = {} 
PendantType.NONE = 0             --无
PendantType.Mount = 1            --坐骑
PendantType.MagicWeapon = 2      --法宝 
PendantType.Pet = 3               --宠物
PendantType.Artifact = 4          --神兵
PendantType.Wing = 5              --翅膀
PendantType.FashionableDress = 6  --时装
PendantType.PetMount = 8          --宠物坐骑
PendantType.FootPrint = 9         --足迹
--[[################################菜单分类#####################################]]
MenuType = {}
MenuType.Mission = 1
MenuType.Rank = 2
MenuType.Strengthen = 3
MenuType.SkyBook = 4
MenuType.Team = 5
MenuType.ActivityBtn = 6
MenuType.MissionGroup = 7
--[[################################战斗类型#####################################]]
FightStatus = {}
FightStatus.PeaceMode = 1      --和平模式
FightStatus.ForceMode = 2      --强制模式
FightStatus.AllMode = 3        --全体模式
FightStatus.CampMode = 4       --阵营对战模式
FightStatus.CrsSvrMode = 5     --跨服模式
FightStatus.BossExclusive = 6  --世界boss专属
--[[################################道具#####################################]]
ItemQuality = {}
ItemQuality.All = 0
ItemQuality.White = 1
ItemQuality.Blue = 2
ItemQuality.Purple = 3
ItemQuality.Orange = 4
ItemQuality.Red = 5
ItemQuality.Powder = 6

ItemStep = {}
ItemStep.All = 0
ItemStep.One = 1
ItemStep.Two = 2
ItemStep.Three = 3
ItemStep.Four = 4
ItemStep.Five = 5
ItemStep.Six = 6
ItemStep.Seven = 7
ItemStep.Eight = 8
ItemStep.Nine = 9
ItemStep.Ten = 10
ItemStep.Eleven = 11
ItemStep.Twelve = 12
ItemStep.Thirteen = 13
ItemStep.Fourteen = 14
ItemStep.Fifteen = 15

--宝石类型
GemType = {}
GemType.HP = 1;
GemType.Attack = 3;

--屏蔽入口
ShieldEnum = {}
--图标
ShieldEnum.RechargeIcon = 1;    --充值图标
ShieldEnum.VIPIcon = 2;         --VIP图标
ShieldEnum.VIPStore = 3;        --VIP商城图标
ShieldEnum.Market = 4;          --市场图标
ShieldEnum.Rank = 12;          --排行榜图标
ShieldEnum.V4 = 13;          --V4图标
ShieldEnum.FirstPayIcon = 14;          --首充图标
--以下是具体功能
ShieldEnum.Recharge = 5;        --充值
ShieldEnum.MonthCard = 6;       --超值月卡
ShieldEnum.InvestFinance = 7;   --投资理财
ShieldEnum.VIPPower = 8;        --VIP特权
ShieldEnum.VIPInvest = 9;       --VIP投资
ShieldEnum.ActivationCode = 10; --激活码
ShieldEnum.Feedback = 11; --意见反馈
ShieldEnum.FirstPay = 15;          --首充