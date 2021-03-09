using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitBuffStateInfo
{
    #region 字段
    ////单位
    //private Unit mOwner;
    //是否无敌
    private bool isInvincible = false;
    //是否免疫
    private bool isImmunity = false;
    //是否被绑定
    private bool isTieUp = false;
    //是否眩晕
    private bool isDizziness = false;
    //禁止类型
    private byte mForbidType = 0;
    //禁止攻击boss
    private bool mForbidAtkBoss = false;
    //翻转阵营信息
    private bool bInvert = false;
    //private CampType mSaveCamp = CampType.CampType1;
    #endregion

    #region 属性
    /// <summary>
    /// 是否禁止移动
    /// </summary>
    public bool IsForbitMove
    {
        get { return (mForbidType & 0x04) != 0; }
    }

    /// <summary>
    /// 是否禁止战斗(包括普通攻击、技能、必杀技)
    /// </summary>
    public bool IsForbitFight
    {
        get { return (mForbidType & 0x07) == 0x07; }
    }

    /// <summary>
    /// 是否禁止普通攻击
    /// </summary>
    public bool IsForbitNormalAttack
    {
        get { return (mForbidType & 0x01) != 0; }
    }

    /// <summary>
    /// 是否禁止技能攻击
    /// </summary>
    public bool IsForbitSkillAttack
    {
        get { return (mForbidType & 0x02) != 0; }
    }

    /// <summary>
    /// 是否禁止必杀技
    /// </summary>
    public bool IsForbitUniqueSkill
    {
        get { return (mForbidType & 0x04) != 0; }
    }

    /// <summary>
    /// 是否禁止使用物品
    /// </summary>
    public bool IsFobitUseItem
    {
        get { return (mForbidType & 0x08) != 0; }
    }

    /// <summary>
    /// 是否在无敌状态
    /// </summary>
    public bool IsInvincible
    {
        get { return isInvincible; }
        set { isInvincible = value; }
    }

    /// <summary> 
    /// 是否在免疫状态(免疫一切的减益buff)
    /// </summary>
    public bool IsImmunity
    {
        get { return isImmunity; }
        set { isImmunity = value; }
    }

    /// <summary>
    /// 是否被绑定
    /// </summary>
    public bool IsTieUp
    {
        get { return isTieUp; }
        set { isTieUp = value; }
    }

    /// <summary>
    /// 是否眩晕状态
    /// </summary>
    public bool IsDizziness
    {
        get { return isDizziness; }
        set { isDizziness = value; }
    }

    /// <summary>
    /// 1=不能普通攻击
    /// 2=不能技能攻击
    /// 4=不能移动
    /// 8=不能使用必杀技
    /// 16=不能使用物品
    /// </summary>
    public byte ForbidType
    {
        get { return mForbidType; }
        set { mForbidType = value; }
    }

    /// <summary>
    /// 禁止攻击boss
    /// </summary>
    public bool ForbidAtkBoss
    {
        get { return mForbidAtkBoss; }
        set { mForbidAtkBoss = value; }
    }

    /// <summary>
    /// 阵营翻转
    /// </summary>
    public bool InvertCamp
    {
        set
        {
            //if (value == true)
            //{
            //    if (!bInvert)
            //    {
            //        mSaveCamp = mOwner.Camp;
            //        if (mOwner.Camp == UnitCamp.Enemy) mOwner.Camp = UnitCamp.Friend;
            //        else mOwner.Camp = UnitCamp.Enemy;
            //    }
            //}
            //else
            //{
            //    if (bInvert) mOwner.Camp = mSaveCamp;
            //}

            bInvert = value;
        }

        get { return bInvert; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void Init(Unit unit)
    {
        //mOwner = unit;
    }

    public void Dispose()
    {
        isInvincible = false;
        isImmunity = false;
        isTieUp = false;
        isDizziness = false;
        mForbidType = 0;
        bInvert = false;
    }
    #endregion
}
