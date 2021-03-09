//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/9/16 14:25:18
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
    /// AtlasSearchWin
    /// </summary>
    public class AtlasSearchWin : EditWinBase
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
        [MenuItem(AtlasUtil.Menu + "搜索工具", false, AtlasUtil.Pri + 1)]
        [MenuItem(AtlasUtil.AMenu + "搜索工具", false, AtlasUtil.Pri + 1)]
        public static void Open()
        {
            WinUtil.Open<AtlasSearchWin, AtlasSearchView>("图集搜索", 800, 800);
        }
        #endregion
    }
}