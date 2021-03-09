using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格编辑窗口
    /// </summary>
    public class SceneGridWin : EditWinBase
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.ArtPri + 1;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Art + "场景九宫格/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.AArt + "场景九宫格/";
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
        protected override void OnPlaymodeChanged(bool playing)
        {
            if (playing)
            {
                Switch<SceneGridEditView>();
            }
            else
            {
                Switch<SceneGridSelectView>();
            }
        }

        #endregion

        #region 公开方法
        public override void Init()
        {
            Add<SceneGridEditView>();
            Add<SceneGridSelectView>();
            OnPlaymodeChanged(EditorApplication.isPlaying);
        }

        [MenuItem(menu + "编辑 &s", false, Pri)]
        [MenuItem(AMenu + "编辑", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<SceneGridWin>(600, Screen.currentResolution.height);
        }
        #endregion
    }
}