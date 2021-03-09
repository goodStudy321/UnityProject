/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/21 3:35:19
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetUpgChkWin
    /// </summary>
    public class AssetUpgChkWin : EditWinBase
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
        [MenuItem(AssetUpgUtil.menu + "检查清单升级", false, AssetUpgUtil.Pri + 4)]
        [MenuItem(AssetUpgUtil.AMenu + "检查清单升级", false, AssetUpgUtil.Pri + 4)]
        public static void Open()
        {
            WinUtil.Open<AssetUpgChkWin, AssetUpgChkView>("检查清单升级", 600, 800);
        }
        #endregion
    }
}