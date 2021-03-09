using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitTimer
{
    #region 私有字段
    private DateTimer mTimer = null;
    private Unit mUnit = null;
    #endregion

    #region 私有方法
    private void TimeInvl()
    {
        CommenNameBar bar = GetBar();
        if (bar == null)
            return;
        bar.TimeStr = mTimer.Remain;
    }
    private void TimeCp()
    {
        CommenNameBar bar = GetBar();
        if (bar == null)
            return;
        bar.TimeStr = null;
    }

    private CommenNameBar GetBar()
    {
        if (mUnit == null)
            return null;
        if (mUnit.TopBar == null)
            return null;
         return mUnit.TopBar as CommenNameBar;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 计时开始
    /// </summary>
    /// <param name="endTime"></param>
    public void Start(Unit unit, double endTime)
    {
        double time = TimeTool.GetServerTimeNow() / 1000;
        time = endTime - time;
        if (mTimer == null)
            mTimer = ObjPool.Instance.Get<DateTimer>();
        if(mTimer.Running)
            mTimer.Stop();
        mUnit = unit;
        mTimer.Seconds = (float)time;
        mTimer.invl += TimeInvl;
        mTimer.complete += TimeCp;
        mTimer.Start();
    }

    /// <summary>
    /// 停止计时
    /// </summary>
    public void Stop()
    {
        if (mTimer == null)
            return;
        if (mTimer.Running)
            mTimer.Stop();
        CommenNameBar bar = GetBar();
        if (bar == null)
            return;
        bar.TimeStr = null;
    }

    public void Dispose()
    {
        Stop();
        mUnit = null;
        mTimer = null;
    }
    #endregion
}
