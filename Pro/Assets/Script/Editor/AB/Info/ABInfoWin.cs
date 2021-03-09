//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/29 15:03:58
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
    /// ABInfoWin
    /// </summary>
    public class ABInfoWin : EditWinBase
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
        [MenuItem(ABTool.menu + "信息查询", false, ABTool.Pri + 16)]
        [MenuItem(ABTool.AMenu + "信息查询", false, ABTool.Pri + 16)]
        public static void Open()
        {
            WinUtil.Open<ABInfoWin, ABInfoView>("信息查询", 800, 800);
        }
        #endregion
    }
}