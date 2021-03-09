//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/28 20:32:42
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
    /// ABLrcWin
    /// </summary>
    public class ABLrcWin : EditWinBase
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

        [MenuItem(ABLrcUtil.menu + "窗口", false, ABLrcUtil.Pri)]
        [MenuItem(ABLrcUtil.AMenu + "窗口", false, ABLrcUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<ABLrcWin, ABLrcView>("AB冗余查询", 800, 800);
        }
        #endregion
    }
}