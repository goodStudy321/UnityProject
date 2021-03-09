/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/12 23:36:43
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetMfCmpSizeWin
    /// </summary>
    public class AssetMfCmpSizeWin : EditWinBase
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
        /// 打开编辑窗口
        /// </summary>
        [MenuItem(AssetMfUtil.menu + "对比不同清单大小", false, AssetMfUtil.Pri + 1)]
        [MenuItem(AssetMfUtil.AMenu + "对比不同清单大小", false, AssetMfUtil.Pri + 1)]
        public static void Open()
        {
            WinUtil.Open<AssetMfCmpSizeWin, AssetMfCmpSizeView>("对比不同清单大小", 600, 800);
        }
        #endregion
    }
}