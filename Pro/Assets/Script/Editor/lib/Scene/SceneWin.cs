/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/1 13:58:15
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;

namespace Loong.Edit
{
    /// <summary>
    /// SceneWin
    /// </summary>
    public class SceneWin : EditWinBase
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
        /// 显示设置面板
        /// </summary>
        [MenuItem(SceneMgr.menu + "设置 %&#o", false, SceneMgr.Pri)]
        [MenuItem(SceneMgr.AMenu + "设置", false, SceneMgr.Pri)]
        public static void Open()
        {
            WinUtil.Open<SceneWin, EditSceneView>("场景管理", 600, 800);
        }
        #endregion
    }
}