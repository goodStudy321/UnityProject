using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using UnityEditor;

namespace Hello.Edit
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