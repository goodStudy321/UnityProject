using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class HitedInfo
{
    #region 私有字段
    /// <summary>
    /// 单位ID
    /// </summary>
    private long mUnitId;
    /// <summary>
    /// 计时时间
    /// </summary>
    private bool mHitTOut;
    /// <summary>
    /// 计时器
    /// </summary>
    private Timer mTimer = null;
    #endregion

    #region 公有字段
    /// <summary>
    /// 单位ID
    /// </summary>
    public Unit mUnit;
    #endregion

    #region 私有方法
    /// <summary>
    /// 计时结束
    /// </summary>
    private void TimeOut()
    {
        mTimer.complete -= TimeOut;
        if (!SettingMgr.instance.HitInfoDic.ContainsKey(mUnitId))
            return;
        ObjPool.Instance.Add(SettingMgr.instance.HitInfoDic[mUnitId]);
        SettingMgr.instance.HitInfoDic.Remove(mUnitId);
    }
    #endregion

    #region 公有方法
    public void SetInfo(Unit unit)
    {
        mUnitId = unit.UnitUID;
        mUnit = unit;
        Reset();
    }

    /// <summary>
    /// 开始计时
    /// </summary>
    public void Reset()
    {
        if (mTimer == null)
            ObjPool.Instance.Get<Timer>();
        if (mTimer.Running)
            mTimer.Stop();
        mTimer.Seconds = 5;
        mTimer.complete += TimeOut;
        mTimer.Start();
    }

    /// <summary>
    /// 释放
    /// </summary>
    public void Dispose()
    {
        if (mTimer != null && mTimer.Running)
        {
            mTimer.Stop();
            ObjPool.Instance.Add(mTimer);
        }
        TimeOut();
    }
    #endregion
}
