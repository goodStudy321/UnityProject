/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/31 18:09:52
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// MonoRefWin
    /// </summary>
    public class MonoRefWin : EditWinBase
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
        [MenuItem(ScriptUtil.Menu + "引用窗口", false, ScriptUtil.Pri)]
        [MenuItem(ScriptUtil.AMenu + "引用窗口", false, ScriptUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<MonoRefWin, MonoRefView>("脚本引用", 800, 800);
        }
        #endregion
    }
}