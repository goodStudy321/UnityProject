//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/8 12:24:33
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// UILocalLblChkPage
    /// </summary>
    [Serializable]
    public class UILocalLblChkPage : Page<UILabelInfo>
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
        protected override void DrawItem(Object obj, int i)
        {
            lst[i].OnGUI(obj);
        }

        protected override GUILayoutOption[] GetScrOp()
        {
            return new GUILayoutOption[] { GUILayout.MinHeight(Screen.height) };
        }

        protected override void DrawTitle(Object obj)
        {
            base.DrawTitle(obj);
            BegTitle();
            EditorGUILayout.LabelField("", UIOptUtil.smallWd);
            EditorGUILayout.TextField("名称", EditorStyles.label, UIOptUtil.btn);
            EditorGUILayout.TextField("路径", EditorStyles.label);
            EditorGUILayout.TextField("内容", EditorStyles.label);
            EditorGUILayout.LabelField("", UIOptUtil.plus);
            EditorGUILayout.LabelField("", UIOptUtil.btn);

            EndTitle();
        }
        #endregion
    }
}