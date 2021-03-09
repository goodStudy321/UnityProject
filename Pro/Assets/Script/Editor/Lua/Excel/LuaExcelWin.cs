//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/9/27 10:21:29
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
    /// LuaExcelWin
    /// </summary>
    public class LuaExcelWin : EditWinBase
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
        public override void Init()
        {
            Add<LuaExcelSelectView>();
            Switch<LuaExcelSelectView>();
        }

        [MenuItem(DataTool.menu + "LUA", false, DataTool.Pri + 4)]
        [MenuItem(DataTool.AMenu + "LUA", false, DataTool.Pri + 4)]
        public static void Open()
        {
            WinUtil.Open<LuaExcelWin>(800, Screen.currentResolution.height);
        }
        #endregion
    }
}