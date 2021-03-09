/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/11 11:42:25
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
    /// MatRefWin
    /// </summary>
    public class MatRefWin : EditWinBase
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
        [MenuItem(MatUtil.Menu + "引用查询", false, MatUtil.Pri)]
        [MenuItem(MatUtil.AMenu + "引用查询", false, MatUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<MatRefWin, MatRefView>("材质引用", 800, 800);
        }
        #endregion
    }
}