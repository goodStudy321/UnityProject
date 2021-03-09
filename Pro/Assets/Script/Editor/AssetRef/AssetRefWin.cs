/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/17 17:28:18
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetDependentWin
    /// </summary>
    public class AssetRefWin : EditWinBase
    {
        #region 字段
        public const int Pri = AssetUtil.Pri + 90;

        public const string Menu = AssetUtil.menu + "引用工具/";

        public const string AMenu = AssetUtil.AMenu + "引用工具/";
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
        [MenuItem(Menu + "窗口", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetRefWin, AssetRefView>("资源引用", 800, 800);
        }
        #endregion
    }
}