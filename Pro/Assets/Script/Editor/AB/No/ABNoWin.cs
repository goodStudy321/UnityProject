/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/3 15:57:38
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ABNoWin
    /// </summary>
    public class ABNoWin : EditWinBase
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
        [MenuItem(ABTool.menu + "无包名工具", false, ABTool.Pri + 10)]
        [MenuItem(ABTool.AMenu + "无包名工具", false, ABTool.Pri + 10)]
        public static void Open()
        {
            WinUtil.Open<ABNoWin, ABNoView>("无包名工具", 600, 800);
        }
        #endregion
    }
}