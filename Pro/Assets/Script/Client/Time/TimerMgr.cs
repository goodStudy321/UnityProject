using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.12.03
    /// BG:时间/计时器管理器
    /// </summary>
    public static class TimerMgr
    {
        #region 字段
        private static Timer cur = null;

        /// 计时器列表
        /// </summary>
        private static List<Timer> lst = new List<Timer>();

        #endregion

        #region 属性

        #region 构造方法
        static TimerMgr()
        {

        }
        #endregion

        #endregion

        #region 私有方法
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            if (lst.Count == 0) return;
            int beg = lst.Count - 1;
            for (int i = beg; i > -1; i--)
            {
                cur = lst[i];
                if (cur.IsPause) continue;
                cur.Update();
                if (cur.Running) continue;
                ListTool.Remove<Timer>(lst, i);
                if (cur.AutoPool)
                {
                    ObjPool.Instance.Add(cur);
                    cur.Dispose();
                }
                cur.IsLock = false;
            }
        }

        /// <summary>
        /// 创建计时器并启动
        /// </summary>
        /// <param name="sec">时间</param>
        /// <param name="loop">true:循环</param>
        /// <param name="autoPool">true:自动放入对象池</param>
        /// <param name="ignoreTS">true:忽略时间缩放</param>
        /// <returns></returns>
        public static T Create<T>(float sec, bool autoPool, bool loop = false, bool ignoreTS = true) where T : Timer, new()
        {
            if (sec < 0) sec = 1;
            T tm = ObjPool.Instance.Get<T>();
            tm.Loop = loop;
            tm.Seconds = sec;
            tm.AutoPool = autoPool;
            tm.IgnoreTimeScale = ignoreTS;
            tm.Start();
            return tm;
        }


        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="timer"></param>
        public static void Add(Timer timer)
        {
            if (timer.Running) return;
            if (timer.IsLock) return;
            timer.IsLock = true;
            lst.Add(timer);
        }


        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            ListTool.Clear<Timer>(lst);
        }
        #endregion
    }
}