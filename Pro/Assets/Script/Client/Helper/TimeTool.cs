using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class TimeTool
{
    private static DateTime beg = TimeZone.CurrentTimeZone.ToLocalTime(new DateTime(1970, 1, 1));

    /// <summary>
    /// 开始时间戳
    /// </summary>
    public static DateTime Beg
    {
        get { return beg; }
    }

    #region 共有方法



    /// <summary>
    /// 获取服务器当前时间（单位毫秒）
    /// </summary>
    /// <returns></returns>
    public static double GetServerTimeNow()
    {
        double serverTime = Utility.GetCurTime() - HeartBeat.mTimeDefference;
        return serverTime;
    }

    public static UInt32 GetTodaySecond()
    {
        return (uint)((System.DateTime.Now.Ticks - System.DateTime.Today.Ticks) / 10000000);
    }
    /// <summary>
    ///  获取服务器当前时间(当前区域)
    /// </summary>
    /// <returns></returns>
    public static double GetServerTimeLacol()
    {
        System.DateTime startTime = beg; // 当地时区
        DateTime dt = startTime.AddSeconds(GetServerTimeNow() / 1000);
        return dt.Ticks / 10000000;
    }
    //得到服务器今天已经过的时间
    public static double GetSeverTodaySecond()
    {
        double time = GetServerTimeLacol();
        double dayhour = 86400;
        double todaySecond = time % dayhour;
        return todaySecond;
    }

    public static double GetSeverTimeRemain()
    {
        double time = GetSeverTodaySecond();
        double dayhour = 86400;
        return dayhour-time;
    }


    #endregion
}
