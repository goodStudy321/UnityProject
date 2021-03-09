//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/1 14:31:46
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
    /// ABToLsnrWin
    /// </summary>
    public class ABToLsnrWin : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ABToLsnrWin()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        [MenuItem(ABTool.menu + "AB转换监听信息", false, ABTool.Pri + 16)]
        [MenuItem(ABTool.AMenu + "AB转换监听信息", false, ABTool.Pri + 16)]
        public static void Open()
        {
            WinUtil.Open<ABToLsnrWin, ABToLsnrView>("AB转换监听信息", 800, 800);
        }
        #endregion
    }
}