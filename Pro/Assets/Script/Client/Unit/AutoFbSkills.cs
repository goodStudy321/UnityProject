using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class AutoFbSkills
{
    public static readonly AutoFbSkills instance = new AutoFbSkills();
    private AutoFbSkills() { }
    #region 私有字段
    //禁止列表
    private List<uint> mFbSkillList = new List<uint>();
    #endregion

    #region 属性

    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init()
    {
        AddEvent();
    }

    /// <summary>
    /// 添加事件监听
    /// </summary>
    public void AddEvent()
    {
        EventMgr.Add(EventKey.SetSkState, SetSkState);
    }

    /// <summary>
    /// 设置技能自动状态
    /// </summary>
    /// <param name="agrs"></param>
    public void SetSkState(params object[] agrs)
    {
        if (agrs == null)
            return;
        if (agrs.Length == 0)
            return;
        uint fbSkId = Convert.ToUInt32(agrs[0]);
        if (mFbSkillList.Contains(fbSkId))
            mFbSkillList.Remove(fbSkId);
        else
            mFbSkillList.Add(fbSkId);
    }

    /// <summary>
    /// 检查禁止技能
    /// </summary>
    /// <param name="skId"></param>
    /// <returns></returns>
    public bool CheckFb(Unit unit, uint skId)
    {
        if (unit == null)
            return true;
        if (unit.UnitUID != User.instance.MapData.UID)
            return false;
        if (mFbSkillList.Contains(skId))
            return true;
        return false;
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        mFbSkillList.Clear();
    }
    #endregion
}
