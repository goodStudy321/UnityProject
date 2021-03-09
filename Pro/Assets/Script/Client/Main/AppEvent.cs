/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/19 19:48:45
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// App事件
    /// </summary>
    public static class AppEvent
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void LowMem()
        {
            var mem = Device.Instance.AvaiMem;
            var str = string.Format("Loong, LowMem, AvaiMem:{0}M ", mem);
            if (mem < 150)
            {
                Debug.LogError(str);
            }
            else if (App.IsDebug)
            {
                Debug.LogWarning(str);
            }
            GC.Collect();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
            Application.lowMemory += LowMem;
        }
        #endregion
    }
}