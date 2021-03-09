/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/20 1:42:45
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
    /// NGUIAnchorWin
    /// </summary>
    public class NGUIAnchorPickWin : EditWinBase
    {
        #region 字段
        public const int Pri = NGUIUtil.Pri + 10;

        public const string menu = NGUIUtil.menu + "锚点拾取工具";

        public const string AMenu = NGUIUtil.AMenu + "锚点拾取工具";
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
        /// <summary>
        /// 创建NGUI根结点
        /// </summary>
        [MenuItem(menu + "窗口", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        public static void CreateRoot()
        {
            WinUtil.Open<NGUIAnchorPickWin, NGUIAnchorPickView>("锚点拾取", 360, 660);
        }
        #endregion
    }
}