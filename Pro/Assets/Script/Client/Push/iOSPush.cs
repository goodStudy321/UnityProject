//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/7 21:47:13
//=============================================================================

#if UNITY_IPHONE || UNITY_IOS
using System;
using UnityEngine.iOS;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// iOSNotify
    /// </summary>
    public class iOSPush : IPush
    {
#region 字段
        public static readonly iOSPush Instance = new iOSPush();
#endregion

#region 属性

#endregion

#region 委托事件

#endregion

#region 构造方法
        private iOSPush()
        {

        }
#endregion

#region 私有方法
        private void Add(int id, string name, string title, string content, DateTime dt, long repeat)
        {
            var ln = new LocalNotification();
            ln.alertBody = content;
            ln.hasAction = false;
            ln.applicationIconBadgeNumber = 1;
            ln.fireDate = dt;
            ln.soundName = LocalNotification.defaultSoundName;

            if (repeat > 0)
            {
                ln.repeatCalendar = CalendarIdentifier.ChineseCalendar;
                ln.repeatInterval = CalendarUnit.Week;
            }

            NotificationServices.ScheduleLocalNotification(ln);
        }
#endregion

#region 保护方法

#endregion

#region 公开方法
        public void Init()
        {
            Clear();
            NotificationServices.RegisterForNotifications(NotificationType.Alert);
        }

        public void Add(int id, string name, string title, string content, long mills, long repeat)
        {
            var dt = new DateTime(mills);
            Add(id, name, title, content, dt, repeat);
        }

        public void AddFromNow(int id, string name, string title, string content, long mills, long repeat)
        {
            var rMills = mills * 10000;
            var dt = DateTime.Now + new TimeSpan(rMills);
            Add(id, name, title, content, dt, repeat);
        }

        public void Remove(int id)
        {

        }

        public void Save()
        {

        }

        public void Clear()
        {
            var ln = new LocalNotification() { applicationIconBadgeNumber = -1 };
            NotificationServices.PresentLocalNotificationNow(ln);
            NotificationServices.CancelAllLocalNotifications();
            NotificationServices.ClearLocalNotifications();
        }
#endregion
    }
}
#endif