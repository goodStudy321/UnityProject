//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/3 13:16:43
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// SymbolWin
    /// </summary>
    public class SymbolWin : EditWinBase
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
        [MenuItem(MenuTool.Plan + "符号工具", false, -1004)]
        [MenuItem(MenuTool.APlan + "符号工具", false, -1004)]
        public static void Open()
        {
            WinUtil.Open<SymbolWin, SymbolView>("符号工具", 800, 800);
        }
        #endregion
    }
}