/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/3 11:20:41
 ============================================================================*/

using System;
using UnityEngine;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 耗时
    /// </summary>
    public class ElapsedTime
    {
        #region 字段
        private Stopwatch sw = new Stopwatch();
        #endregion

        #region 属性
        public TimeSpan Elapsed
        {
            get
            {
                return sw.Elapsed;
            }
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
        public void Beg()
        {
            sw.Reset();
            sw.Start();
        }

        public void End()
        {
            sw.Stop();
        }


        public void End(string fmt,params object[] args)
        {
            sw.Stop();
            if (fmt == null) fmt = "";
            var tip = string.Format(fmt, args);
            Debug.LogWarningFormat("Loong, {0} elapsed time:{1}", tip, sw.Elapsed);
        }

        #endregion
    }
}