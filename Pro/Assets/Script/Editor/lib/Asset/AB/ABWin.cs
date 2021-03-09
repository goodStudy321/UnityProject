/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/9 2:31:16
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源包窗口
    /// </summary>
    public class ABWin : EditWinBase
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
        /// 打开编辑窗口
        /// </summary>
        [MenuItem(ABTool.menu + "打开编辑窗口 &%o", false, ABTool.Pri + 1)]
        [MenuItem(ABTool.AMenu + "打开编辑窗口", false, ABTool.Pri + 1)]
        public static void Open()
        {
            WinUtil.Open<ABWin, ABView>("资源包", 600, 800);
        }

        #endregion
    }
}