/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/18 15:47:00
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// UIAtlasRefWin
    /// </summary>
    public class AtlasRefWin : EditWinBase
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
        [MenuItem(AtlasUtil.Menu + "引用工具", false, AtlasUtil.Pri)]
        [MenuItem(AtlasUtil.AMenu + "引用工具", false, AtlasUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<AtlasRefWin, AtlasRefView>("图集引用", 800, 800);
        }
        #endregion
    }
}