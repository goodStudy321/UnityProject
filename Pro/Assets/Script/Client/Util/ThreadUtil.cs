//*****************************************************************************
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2018/8/10 16:00:20
//*****************************************************************************

using System;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 线程工具
    /// </summary>
    public static class ThreadUtil
    {
        #region 字段
        private static int mainID = 0;
        #endregion

        #region 属性

        /// <summary>
        /// true:主线程,false:非主线程
        /// </summary>
        public static bool IsMain
        {
            get { return mainID == Thread.CurrentThread.ManagedThreadId; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
            mainID = Thread.CurrentThread.ManagedThreadId;
        }

        /// <summary>
        /// 从线程池启动
        /// </summary>
        /// <param name="cb">启动方法</param>
        /// <param name="obj">启动对象</param>
        /// <param name="sleep">失败后的重启间隔</param>
        public static void Start(WaitCallback cb, object obj = null, int sleep = 20)
        {
            WaitCallback del = delegate (object o)
            {
                try
                {
                    cb(o);
                }
                catch (Exception e)
                {

                    iTrace.Error("Loong", "thread err:{0}", e.Message);
                }
            };
            while (!ThreadPool.QueueUserWorkItem(del, obj))
            {
                Thread.Sleep(sleep);
            }
        }
        #endregion
    }
}