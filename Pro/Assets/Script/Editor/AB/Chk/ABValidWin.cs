/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/19 22:58:46
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
    /// ABChkWin
    /// </summary>
    public class ABValidWin : EditWinBase
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
        [MenuItem(ABTool.menu + "有效性检查", false, ABTool.Pri + 11)]
        [MenuItem(ABTool.AMenu + "有效性检查", false, ABTool.Pri + 11)]
        public static void Open()
        {
            WinUtil.Open<ABValidWin, ABValidView>("有效性检查", 600, 800);
        }
        #endregion
    }
}