/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/7 22:10:41
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetMd5ChkWin
    /// </summary>
    public class AssetMfChkWin : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetMfChkWin()
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
        [MenuItem(AssetMfUtil.menu + "检查清单", false, AssetMfUtil.Pri)]
        [MenuItem(AssetMfUtil.AMenu + "检查清单", false, AssetMfUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetMfChkWin, AssetMfChkView>("检查清单", 600, 800);
        }
        #endregion
    }
}