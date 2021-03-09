//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/8 12:23:38
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// UILocalLblChkWin
    /// </summary>
    public class UILocalLblChkWin : EditWinBase
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
        [MenuItem(NGUIUtil.menu + "检查UILabel是否非数字", false, NGUIUtil.Pri + 10)]
        [MenuItem(NGUIUtil.AMenu + "检查UILabel是否非数字", false, NGUIUtil.Pri + 10)]
        public static void Open()
        {
            WinUtil.Open<UILocalLblChkWin, UILocalLblChkView>("检查UILabel", 800, 800);
        }
        #endregion
    }
}