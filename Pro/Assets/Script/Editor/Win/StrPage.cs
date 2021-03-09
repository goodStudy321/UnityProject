//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 11:14:05
//=============================================================================

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// StrPage
    /// </summary>
    public class StrPage : Page<string>
    {
        #region 字段

        #endregion

        #region 属性
        public override bool UseScrollHt
        {
            get { return false; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected override void DrawItem(Object obj, int i)
        {
            var str = lst[i];
            EditorGUILayout.TextField((str == null) ? "null" : str);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}