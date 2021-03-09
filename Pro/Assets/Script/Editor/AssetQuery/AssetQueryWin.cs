/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/5/30 23:18:14
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
    /// 资源查询窗口
    /// </summary>
    public class AssetQueryWin : EditWinBase
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


        [MenuItem(AssetQueryUtil.Menu + "窗口", false, AssetQueryUtil.Pri)]
        [MenuItem(AssetQueryUtil.AMenu + "窗口", false, AssetQueryUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AssetQueryWin, AssetQueryView>("资源查询", 800, 800);
        }
        #endregion
    }
}