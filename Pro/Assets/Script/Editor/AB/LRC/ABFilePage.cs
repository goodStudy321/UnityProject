//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/29 0:42:41
//=============================================================================

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ABFilePage
    /// </summary>
    [Serializable]
    public class ABFilePage : Page<ABFileInfo>
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ABFilePage()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void DrawItem(UnityEngine.Object obj, int i)
        {
            lst[i].OnGUI(obj);
        }

        protected override GUILayoutOption[] GetScrOp()
        {
            return new GUILayoutOption[] { GUILayout.MinHeight(Screen.height) };
        }
        #endregion

        #region 公开方法

        #endregion
    }
}