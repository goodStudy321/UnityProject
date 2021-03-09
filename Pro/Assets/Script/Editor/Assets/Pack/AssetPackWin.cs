/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 15:13:07
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
    /// AssetMenifestWin
    /// </summary>
    public class AssetPackWin : EditWinBase
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
        /// <summary>
        /// 打开窗口
        /// </summary>
        [MenuItem(AssetPackUtil.menu + "窗口", false, AssetPackUtil.Pri)]
        [MenuItem(AssetPackUtil.AMenu + "窗口", false, AssetPackUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetPackWin, AssetPackView>("清单", 600, 800);
        }
        #endregion
    }
}