/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/25 11:15:31
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源升级窗口
    /// </summary>
    public class AssetUpgWin : EditWinBase
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
        [MenuItem(AssetUpgUtil.menu + "编辑 %#&u", false, AssetUpgUtil.Pri)]
        [MenuItem(AssetUpgUtil.AMenu + "编辑", false, AssetUpgUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetUpgWin, AssetUpgView>("资源升级窗口", 600, 800);
        }

        #endregion
    }
}