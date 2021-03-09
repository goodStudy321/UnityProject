using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 技能主被动类型
/// </summary>
public enum SkillEnum
{
    NormalAtk = 0,  //普通攻击
    Active = 1,     //主动类型
    passtive = 2,   //被动类型
}

/// <summary>
/// 点击技能枚举
/// </summary>
public enum PreSkillEnum
{
    NormalAttack = 1,    //普通攻击
    Skill_1 = 2,         //技能1
    Skill_2 = 3,         //技能2
    Skill_3 = 4,         //技能3
    Skill_4 = 5,         //技能4
    Skill_5 = 6,         //技能5
    Skill_6 = 7,         //技能6
    Skill_7 = 8,         //技能7
    Skill_8 = 9,         //技能8
}

/// <summary>
/// 伤害类型
/// </summary>
public enum HarmType
{
    Normal = 0x01,     //普通伤害
    Dodge = 0x02,      //闪避
    Critical = 0x04,   //暴击
    Knowing = 0x08,    //会心
    Parry = 0x10,       //格挡
    Cure = 0x20,        //治疗（加血）
    Absorb = 0x40,      //吸收伤害



    PoisonReductionHp = 9,    //buff中毒减血
    CureAddHp = 10,            //buff治疗加血
}

/// <summary>
/// 技能归属
/// </summary>
public enum SkillBelongEnum
{
    RoleSkill = 1,      //角色技能
    MonsterSkill = 2,   //怪物技能
    PetSkill = 3,       //宠物技能
    MountSkill = 4,     //坐骑技能
    MagicWeaponSkill = 5,//法宝技能
    Wing = 6,           //翅膀技能
    Fashion = 13,           //翅膀技能
}