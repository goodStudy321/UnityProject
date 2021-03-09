using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnumUtility
{


    #region 通过枚举获取
    #endregion
}

public enum GameSceneType
{
    GST_Three = 0,            /* 流程树副本 */
    GST_MainScene,              /* 主城 */
    GST_Copy,
    GST_Unknown
}

/// <summary>
/// 场景子类型
/// </summary>
public enum SceneSubType
{
    None = 0,
    WordBoss = 1,       //1 世界Boss地图
    HomeOfBoss = 2,     //2 洞天福地Boss地图
    PersonalBoss = 3,   //3 个人Boss地图
    WildFBoss = 4,      //4 蛮荒禁地Boss地图
    AnswerMap = 5,      //5 答题副本地图
    CampMap = 6,        //6 多阵营对战地图
    OVOMap = 7,         //7 1v1对战地图
    OffL1V1Map = 8,        //8 离线1v1对战地图
    DftMap = 9,         //9 道庭守卫
    TopFight = 12,       //12 青云之巅
    ImmotalSoul = 13,   //仙魂副本地图
    CrossServer = 15,   //15 跨服副本地图
    DemonBoss = 18,   //魔域BOSS
    WorldBossGuid = 19, //19 世界Boss引导地图
}

public enum CopyType
{
    None = -1,                      //不在副本
    FlowChart = 0,                  /* 流程树副本 */
    Exp = 1,                        /* 经验副本 */
    Glod = 2,                       /* 金币副本 */
    Equip = 3,                      /* 装备副本 */
    Tower = 4,                      /* 爬塔副本 */
    Light = 5,                      /* 光照图副本 */
    PsnalBoss = 6,                  //Vip个人boss副本
    SingleTD = 7,                   //单人塔防副本
    Offl1v1 = 8,                    //离线1v1副本
    EvilSpirits = 9,                //心魔副本
    HjkCopy = 14,                   //渡劫副本
    Online1v1 = 25,                 //在线1v1副本
}

public enum CameraType
{
    Player = 0,
    Camp = 1
}

public enum FightValueType
{
    None = 0,
    Level = 1,      //等级战斗力
    Equip = 2,      //装备战斗力
}


public enum PropertyBaseType
{
    HP                              = 1,
    Attack                          = 2,
    Defence                         = 3,                            //防御
    Arp                             = 4,                            //破甲
    Hit                             = 5,                            //命中
    Miss                            = 6,                            //闪避
    Crit                            = 7,                            //暴击
    Crit_Anti                       = 8,                            //韧性
    Crit_Multi                      = 9,                            //暴伤
    Hurt_Rate                       = 11,                           //加伤
    Hurt_Derate                     = 12,                           //免伤
    Cirt_Doubel                     = 13,                           //暴击几率
    Miss_Double                     = 14,                            //躲闪几率
    Crit_Multi_anti                 = 15,                            //暴免
    Skill_Add                       = 16,                            //技能伤害增加
    Skill_Reduce                    = 17,                            //技能伤害减少
    Kill_Monster_Exp_Add_Buff       = 26,                            //经验加成
    ATTR_MOVE_SPEED                 = 27,                            //移动速度
    Role_Def                        = 28,                            //人物护甲



    Kill_Monster_Pick = 202                            //经验加成

    /**
    Crit_Max                        = 12,                           //会心一击
    Crit_Max_Def                    = 13,                           //会心抵抗
    Parry_Odds                      = 14,                           //格挡几率
    Parry_Def                       = 15,                           //抵抗格挡
    Ignore_Def                      = 16,                           //忽视防御
    Ignore_Def_Resistance           = 17,                           //忽视防御抵抗
    FEAttack                        = 18,                           //五行攻击
    FEDefence                       = 19,                           //五行防御
    Poison                          = 20,                           //中毒
    Poison_Anti                     = 21,                           //中毒抵抗
    Slow                            = 22,                           //迟缓
    Slow_Anti                       = 23,                           //迟缓抵抗
    Dizzy                           = 24,                           //眩晕
    Dizzy_Anti                      = 25,                           //眩晕抵抗"
    ATTR_RATE_ADD_HP = 35,                //生命增加万分比
    ATTR_RATE_REDUCE_HP = 36,             //生命减少万分比
    ATTR_RATE_ADD_ATTACK = 37,            //攻击增加万分比
    ATTR_RATE_REDUCE_ATTACK = 38,         //攻击减少万分比
    ATTR_RATE_ADD_DEFENCE = 39,           //防御增加万分比
    ATTR_RATE_REDUCE_DEFENCE = 40,        //防御减少万分比
    ATTR_RATE_ADD_ARP = 41,               //破甲增加万分比
    ATTR_RATE_REDUCE_ARP = 42,            //破甲减少万分比
    ATTR_RATE_ADD_HIT = 43,               //命中增加万分比
    ATTR_RATE_REDUCE_HIT = 44,            //命中减少万分比
    ATTR_RATE_ADD_MISS = 45,              //闪避增加万分比
    ATTR_RATE_REDUCE_MISS = 46,           //闪避减少万分比
    ATTR_RATE_ADD_DOUBLE = 47,            //暴击增加万分比
    ATTR_RATE_REDUCE_DOUBLE = 48,         //暴击减少万分比
    ATTR_RATE_ADD_DOUBLE_A = 49,          //韧性增加万分比
    ATTR_RATE_REDUCE_DOUBLE_A = 50,       //韧性减少万分比
    */
}

public enum PropertyType
{
    ATTR_HP = 1,                    //血量
    ATTR_STATUS = 2,                //状态 对应值1是死亡状态
    ATTR_MOVE_SPEED = 3,            //移速
    ATTR_BUFF_UPDATE = 4,           //buff更新
    ATTR_BUFF_DEL = 5,              //buff删除
    ATTR_CAMP_ID = 6,               //阵营变化
    ATTR_PK_MODE = 7,               //pk模式变化
    ATTR_RE_NAME = 8,               //名字发生变化
    ATTR_LEVEL_CHANGE = 101,        //角色等级变化
    ATTR_WEAPON_CHANGE = 102,       //武器状态变化
    ATTR_PENDANT_CHANGE = 103,      //挂件外观变化
    ATTR_PK_VALUE = 104,            //PK值变化
    ATTR_FAMILY_ID_CHANGE = 105,    //角色帮派ID变化
    ATTR_FAMILY_NAME_CHANGE = 106,  //角色帮派名字变化
    ATTR_TEAM_ID = 107,             //角色队伍ID变化
    ATTR_POWER_CHANGE = 108,        //角色战斗力变化
    ATTR_CONFINE_CHANGE = 109,      //境界变化
    ATTR_TITLE_CHANGE = 110,        //称号变化
    ATTR_POSITION_CHANGE = 111,     //道庭职位变化
    ATTR_MarryID_CHANGE = 112,        //情侣变化
    ATTR_Marry_CHANGE = 113,        //情侣变化
    ATTR_LEVEL_REBIRTH = 114,       //转生等级
    ATTR_ORNAMENT_LIST = 115,       //角色装饰列表变化
    ATTR_BATTLE_OWNER = 201,        //战斗归属
    ATTR_COUNTDOWN = 203,           //倒计时更新
}

/// <summary>
/// 个人属性类型
/// </summary>
public enum PersonalProType
{
    ATTR_LSTLEVUP = 2,              //上次升级时间
    ATTR_OFFLFIGHTTIME = 3,         //离线挂机时间
}

/// <summary>
/// 任务类型
/// </summary>
public enum MissionType
{
    Main = 1,                           //主线任务\
    Turn = 101,                         //循环任务
}

/// <summary>
/// 任务状态
/// </summary>
public enum MissionStatus
{
    None       = 0,
    NOT_RECEIVE= 1,             //未领取
    EXECUTE = 2,                //未完成，执行中
    ALLOW_SUBMIT = 3,           //已完成，未提交
    COMPLETE = 4                //已经完成
}

/// <summary>
/// 任务目标类型
/// </summary>
public enum MissionTargetType
{
    KILL_MONSTER = 0,
    TALK,
    COLLECTION,
    PATHFINDING = 4, 
    KLL_MONSTER_PR = 5,
    FLOW_CHART
}


public enum PendantSystemEnum
{
    Mount = 1,              //坐骑
    MagicWeapon = 2,        //法宝 
    Pet = 3,                //宠物
    Artifact = 4,           //神兵
    Wing = 5,               //翅膀
    FashionableDress = 6,   //时装
    PetMount = 8,           //宠物坐骑
    FootPrint = 9,          //足迹
}

/// <summary>
/// 时装类型
/// </summary>
public enum FashionType
{
    None = 0,       
    Cloth = 1,      //衣服
    Weapon = 2,     //武器
}

/// <summary>
/// 操作状态类型
/// </summary>
public enum OpStateType
{
    Jump = 0,       //跳跃
    Revive = 1,     //复活
    ChangeScene = 2,//切换场景
    MoveToPoint = 3,//普通跳转点跳转
    SetUnitActive = 4, //设置单位显示隐藏
}

/// <summary>
/// 货币类型
/// </summary>
public enum CurrencyType
{
    Silver = 1,         //银两
    Gold = 2,           //元宝
    Bin_Gold = 3,       //绑定元宝
    Honor = 11,         //荣誉
    HontIntegral = 12,  //寻宝积分
    FamilyCon = 99,     //帮派贡献
}

/// <summary>
/// 消耗类型
/// </summary>
public enum ConsumeType
{
    Silver = 1,         //消耗银两
    Gold = 2,           //消耗不绑定元宝
    Any_Gold = 3,       //优先消耗绑定元宝
    Honor = 11,         //消耗荣誉
    HontIntegral = 12,  //寻宝积分
    FamilyCon = 99,     //消耗帮派贡献
}

public enum SceneStatus
{
    Normal = 0,
    LoadMod,
    LoadData
}
