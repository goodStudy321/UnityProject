using UnityEngine;
using System;
using System.Collections.Generic;

public class GameSkill
{
    #region 私有变量

    #endregion
    //技能ID
    private uint mSkillID = 0;
    //技能等级
    private uint mSkillLevel = 1;
    //技能ID+等级
    private uint mSkillLevelID = 0;
    //技能基础表
    private SkillBase mSkillTable = null;
    //技能属性表
    private SkillLevelAttr mSkillLevelAttrTable = null;
    //技能实时CD
    private float mCD = 0f;
    //技能CD基础总长
    private float mCDLen = 0;
    //总CD减少时间
    private float mRdcTime = 0;
    //技能正在使用的总时长
    private float mUseCDLen = 0;
    //技能攻击增加目标数量
    private int mAddTarNum = 0;
    #region 公有变量

    #endregion

    #region 属性
    /// <summary>
    /// 是否CD中
    /// </summary>
    public bool isCding { get { return mCD > 0; } }

    /// <summary>
    /// CD时间
    /// </summary>
    public float CD { get { return mCD; } set { mCD = value; } }

    /// <summary>
    /// CD时间比例
    /// </summary>
    public float cdPercent { get { return mCD / mUseCDLen; } }

    /// <summary>
    /// 技能ID
    /// </summary>
    public uint SkillID { get { return mSkillID; } }

    /// <summary>
    /// 技能等级
    /// </summary>
    public uint SkillLevel { get { return mSkillLevel; } }

    /// <summary>
    /// 技能等级ID
    /// </summary>
    public uint SkillLevelID { get { return mSkillLevelID; } }

    /// <summary>
    /// 技能攻击增加目标数量
    /// </summary>
    public int AddTarNum { get { return mAddTarNum; } }
    
    /// <summary>
    /// 技能基础表
    /// </summary>
    public SkillBase SkillTable
    {
        get
        {
            if (mSkillTable == null)
                mSkillTable = SkillBaseManager.instance.Find((ushort)mSkillID);
            return mSkillTable;
        }
    }

    /// <summary>
    /// 技能等级表
    /// </summary>
    public SkillLevelAttr SkillLevelAttrTable
    {
        get
        {
            if (mSkillLevelAttrTable == null)
                mSkillLevelAttrTable = SkillLevelAttrManager.instance.Find((uint)(SkillLevelID));
            return mSkillLevelAttrTable;
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化技能
    /// </summary>
    public void Init(uint skLvID,float cdTime)
    {
        mSkillLevelID = skLvID;
        mSkillLevelAttrTable = SkillLevelAttrManager.instance.Find(mSkillLevelID);
        mSkillLevel = mSkillLevelAttrTable.level;
        mSkillID = mSkillLevelAttrTable.baseid;
        mSkillTable = SkillBaseManager.instance.Find(mSkillID);
        mCD = cdTime != 0 ? cdTime : 0;
        mCDLen = mSkillLevelAttrTable.skillCd * 0.001f;
    }

    /// <summary>
    /// 设置添加攻击目标数量
    /// </summary>
    /// <param name="addNum"></param>
    public void SetAddTarNum(int addNum)
    {
        mAddTarNum = addNum;
    }

    /// <summary>
    /// 缩减技能CD
    /// </summary>
    /// <param name="rdcTime"></param>
    public void ReduceCD(int rdcTime)
    {
        mRdcTime = rdcTime/1000;
    }

    /// <summary>
    /// 开启技能CD
    /// </summary>
    public void Cast()
    {
        mUseCDLen = mCDLen - mRdcTime;
        mCD = mUseCDLen;
    }

    /// <summary>
    /// 更新技能CD
    /// </summary>
    public void Update(float deltaTime)
    {
        if (mCD <= 0)
            return;
        mCD -= deltaTime;
    }
    #endregion
}