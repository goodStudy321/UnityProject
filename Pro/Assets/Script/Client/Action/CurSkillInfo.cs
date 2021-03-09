using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CurSkillInfo
{
    #region 字段
    /// <summary>
    /// 技能基础Id
    /// </summary>
    uint mSkBaseId = 0;
    /// <summary>
    /// 技能等级ID
    /// </summary>
    uint mSkLvId = 0;
    /// <summary>
    /// 技能等级
    /// </summary>
    int mSkLv = 0;
    /// <summary>
    /// 增加目标数量
    /// </summary>
    int mAddTarNum = 0;
    #endregion

    #region 属性
    /// <summary>
    /// 技能基础Id
    /// </summary>
    public uint SkBaseId { get { return mSkBaseId; } }
    /// <summary>
    /// 技能等级ID
    /// </summary>
    public uint SkLvId { get { return mSkLvId; } }
    /// <summary>
    /// 技能等级
    /// </summary>
    public int SkLv { get { return mSkLv; } }
    /// <summary>
    /// 增加目标数量
    /// </summary>
    public int AddTarNum { get { return mAddTarNum; } }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置技能信息
    /// </summary>
    /// <param name="skLvId"></param>
    /// <param name="addTarNum"></param>
    public void Set(uint skLvId, int addTarNum)
    {
        if (skLvId <= 0)
            return;
        mSkLvId = skLvId;
        mSkBaseId = skLvId / 1000;
        mSkLv = (int)(skLvId % (mSkBaseId * 1000));
        mAddTarNum = addTarNum;
    }

    /// <summary>
    /// 重置技能信息
    /// </summary>
    public void ReSet()
    {
        mSkBaseId = 0;
        mSkLvId = 0;
        mAddTarNum = 0;
    }
    #endregion
}
