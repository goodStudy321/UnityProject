using System;
using System.Collections.Generic;


/// <summary>
/// buff的一些类型定义
/// </summary>
public class BuffTypeDefine
{
    public struct ConstructParam
    {
        public System.Type CreateType;
        public System.Type[] CreateParams;
    }

    /// <summary>
    /// buff类型
    /// </summary>
    public enum BuffType
    {
        Add = 1,//增益buff
        Minite = 2,//减益buff
        Defence,//抵抗buff
    };

    /// <summary>
    /// buffeffect类型
    /// </summary>
    public enum BuffEffectType
    {
        ChangeAction = 1,//动作改变buff
        InvertCamp = 2,//改变阵营
        ChangeSize = 3,//改变大小
        Invincible = 4,//无敌buff
        Hiding = 5,//隐身buff
        ExpChange = 6,//经验值改变
        CoinChange = 7,//金币改变
        ImmunityBuff = 8,//免疫buff
        PoisoningBuff = 9,//中毒buff
        Cure = 10,//治疗
        PropertyChange = 11,//属性改变buff
        DamageRedution = 12,//伤害减免
        Burn = 17,//灼烧
        Frozen = 18,//冰冻

        //限制类buff
        Tieup = 30,//禁锢(定身)
        Dizziness = 31,//眩晕buff
        ForbidNormalAttack = 32,//限制普通攻击buff
        ForbidSkillAttack = 33,//限制技能攻击buff
        ForbidUniqueSkill = 34,//限制必杀技
        ForbidUseItem = 35,//限制使用物品
        ForbidAtkBoss = 36,//限制攻击boss
        Deform = 37,    //变身buff
    };

    /// <summary>
    /// 禁止行为字典
    /// </summary>
    public static Dictionary<ushort, byte> mForbidActionDic = new Dictionary<ushort, byte>()
    {
        { (ushort)BuffEffectType.ForbidNormalAttack, 1 },//限制释放普通攻击
        { (ushort)BuffEffectType.ForbidSkillAttack, 2 },//限制技能攻击
        { (ushort)BuffEffectType.ForbidUniqueSkill, 4 },//限制必杀技
        { (ushort)BuffEffectType.ForbidUseItem, 8 }//限制使用物品
    };

    /// <summary>
    /// buff效果实例类型字典
    /// </summary>
    public static Dictionary<ushort, ConstructParam> mBuffEffectTypeDic = new Dictionary<ushort, ConstructParam>()
    {
        {
             (ushort)BuffEffectType.ChangeAction,
             new ConstructParam{
                 CreateType = typeof(ChangeActionBuff),
                 CreateParams = BuffUnit.sConstructorTypes
             }
         },
            {
             (ushort)BuffEffectType.InvertCamp,
             new ConstructParam{
                 CreateType = typeof(InvertCampBuf),
                 CreateParams = BuffUnit.sConstructorTypes
             }
        },
            {
             (ushort)BuffEffectType.ChangeSize,
             new ConstructParam{
                 CreateType = typeof(ChangeSizeBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
             (ushort)BuffEffectType.Invincible,
             new ConstructParam{
                 CreateType = typeof(InvincibleBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
             (ushort)BuffEffectType.Hiding,
             new ConstructParam{
                 CreateType = typeof(HidingBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
             (ushort)BuffEffectType.ExpChange,
             new ConstructParam{
                 CreateType = typeof(ExpChangeBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
             (ushort)BuffEffectType.CoinChange,
             new ConstructParam{
                 CreateType = typeof(CoinChangeBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
          {
             (ushort)BuffEffectType.ImmunityBuff,
             new ConstructParam{
                 CreateType = typeof(ImmunityBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
          {
             (ushort)BuffEffectType.PoisoningBuff,
             new ConstructParam{
                 CreateType = typeof(PoisoningBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
            (ushort)BuffEffectType.Tieup,
            new ConstructParam{
                CreateType = typeof(TieupBuff),
                CreateParams = BuffUnit.sConstructorTypes,
            }
        },
            {
             (ushort)BuffEffectType.Dizziness,
             new ConstructParam{
                 CreateType = typeof(DizzinessBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
         },
            {
            (ushort)BuffEffectType.ForbidNormalAttack,
             new ConstructParam{
                 CreateType = typeof(ForbidActionBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.ForbidSkillAttack,
             new ConstructParam{
                 CreateType = typeof(ForbidActionBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.ForbidUniqueSkill,
             new ConstructParam{
                 CreateType = typeof(ForbidActionBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.ForbidUseItem,
             new ConstructParam{
                 CreateType = typeof(ForbidActionBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.Deform,
             new ConstructParam{
                 CreateType = typeof(DeformBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.ForbidAtkBoss,
             new ConstructParam{
                 CreateType = typeof(ForbidAtkBoss),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.Burn,
             new ConstructParam{
                 CreateType = typeof(BurnBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        },
             {
            (ushort)BuffEffectType.Frozen,
             new ConstructParam{
                 CreateType = typeof(FrozenBuff),
                 CreateParams = BuffUnit.sConstructorTypes,
             }
        }
    };
}

