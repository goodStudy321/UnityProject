//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 16:57:55
//=============================================================================

using System;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseWin
    /// </summary>
    public class ConfuseWin : EditWinBase
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
        [MenuItem(ConfuseMgr.menu + "混淆设置", false, ConfuseMgr.Pri)]
        [MenuItem(ConfuseMgr.AMenu + "混淆设置", false, ConfuseMgr.Pri)]
        public static void Open()
        {
            WinUtil.Open<ConfuseWin, ConfuseView>("混淆设置", 600, 800);
        }

        #endregion
    }
}