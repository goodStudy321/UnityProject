//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/9 12:01:59
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
    /// ModQueryWin
    /// </summary>
    public class ModQueryWin : EditWinBase
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
        [MenuItem(ModUtil.menu + "查询", false, MatUtil.Pri + 2)]
        [MenuItem(ModUtil.AMenu + "查询", false, MatUtil.Pri + 2)]
        public static void Open()
        {
            WinUtil.Open<ModQueryWin, ModQueryView>("模型查询", 800, 800);
        }
        #endregion
    }
}