/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/5/14 17:46:56
 ============================================================================*/

#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 编辑器UI选项工具
    /// </summary>
    public static class UIOptUtil
    {
        #region 字段
        /// <summary>
        /// 加号选项
        /// </summary>
        public static readonly GUILayoutOption[] plus = new GUILayoutOption[] { GUILayout.Width(16), GUILayout.Height(16) };

        /// <summary>
        /// 加号宽度选项
        /// </summary>
        public static readonly GUILayoutOption[] plusWd = new GUILayoutOption[] { GUILayout.Width(16) };

        /// <summary>
        /// 加号高度选项
        /// </summary>
        public static readonly GUILayoutOption[] plusHt = new GUILayoutOption[] { GUILayout.Height(16) };

        /// <summary>
        /// 屏幕宽高选项
        /// </summary>
        public static readonly GUILayoutOption[] screen = new GUILayoutOption[] { GUILayout.Width(Screen.height), GUILayout.Height(Screen.width) };


        /// <summary>
        /// 普通按钮宽度选项
        /// </summary>
        public static readonly GUILayoutOption[] smallWd = new GUILayoutOption[] { GUILayout.Width(40) };

        /// <summary>
        /// 关闭按钮宽高选项
        /// </summary>
        public static readonly GUILayoutOption[] closeBtn = new GUILayoutOption[] { GUILayout.Width(20), GUILayout.Height(20) };


        /// <summary>
        /// 屏幕宽选项
        /// </summary>
        public static readonly GUILayoutOption[] screenWd = new GUILayoutOption[] { GUILayout.Height(Screen.width) };

        /// <summary>
        /// 屏幕高选项
        /// </summary>
        public static readonly GUILayoutOption[] screenHt = new GUILayoutOption[] { GUILayout.Width(Screen.height) };

        /// <summary>
        /// 工具栏按钮选项
        /// </summary>
        public static readonly GUILayoutOption[] toolBarBtn = new GUILayoutOption[] { GUILayout.Width(80) };


        /// <summary>
        /// 普通按钮宽度选项
        /// </summary>
        public static readonly GUILayoutOption[] btn = new GUILayoutOption[] { GUILayout.Width(80) };


        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}
#endif