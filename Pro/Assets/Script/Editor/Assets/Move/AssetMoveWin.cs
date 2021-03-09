/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/27 15:40:12
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
    /// AssetMoveWin
    /// </summary>
    public class AssetMoveWin : EditWinBase
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = AssetUtil.Pri + 70;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUtil.menu + "移动工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUtil.AMenu + "移动工具/";
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
        /// 打开窗口
        /// </summary>
        [MenuItem(menu + "窗口", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetMoveWin, AssetMoveView>("资源移动", 600, 800);
        }
        #endregion
    }
}