/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/13 16:07:55
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
    /// 资源CDN窗口
    /// </summary>
    public class AssetCdnWin : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetCdnWin()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开编辑窗口
        /// </summary>
        [MenuItem(AssetCdnUtil.menu + "窗口", false, AssetCdnUtil.Pri)]
        [MenuItem(AssetCdnUtil.AMenu + "窗口", false, AssetCdnUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetCdnWin, AssetCdnView>("资源CDN窗口", 600, 800);
        }
        #endregion
    }
}