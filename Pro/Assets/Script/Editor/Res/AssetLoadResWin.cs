//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 14:28:04
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;


namespace Loong.Edit
{
    /// <summary>
    /// AssetLoadResWin
    /// </summary>
    public class AssetLoadResWin : EditWinBase
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
        [MenuItem(ABTool.menu + "加载本地资源设置", false, ABTool.Pri + 21)]
        [MenuItem(ABTool.AMenu + "加载本地资源设置", false, ABTool.Pri + 21)]
        public static void Open()
        {
            WinUtil.Open<AssetLoadResWin, AssetLoadResView>("加载本地资源设置", 800, 800);
        }
        #endregion
    }
}