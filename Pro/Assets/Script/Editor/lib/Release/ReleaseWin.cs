/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/1 14:34:08
 ============================================================================*/


using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ReleaseWin
    /// </summary>
    public class ReleaseWin : EditWinBase
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

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开窗口
        /// </summary>
        [MenuItem(ReleaseUtil.menu + "设置", false, ReleaseUtil.Pri + 1)]
        [MenuItem(ReleaseUtil.AMenu + "设置", false, ReleaseUtil.Pri + 1)]
        public static void Open()
        {
            WinUtil.Open<ReleaseWin, ReleaseView>("发布设置", 600, 800);
        }
        #endregion
    }
}