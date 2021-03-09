using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class TimeTool
{
    private static DateTime beg = TimeZone.CurrentTimeZone.ToLocalTime(new DateTime(1970, 1, 1));

    /// <summary>
    /// ��ʼʱ���
    /// </summary>
    public static DateTime Beg
    {
        get { return beg; }
    }

    #region ���з���



    /// <summary>
    /// ��ȡ��������ǰʱ�䣨��λ���룩
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
    ///  ��ȡ��������ǰʱ��(��ǰ����)
    /// </summary>
    /// <returns></returns>
    public static double GetServerTimeLacol()
    {
        System.DateTime startTime = beg; // ����ʱ��
        DateTime dt = startTime.AddSeconds(GetServerTimeNow() / 1000);
        return dt.Ticks / 10000000;
    }
    //�õ������������Ѿ�����ʱ��
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
