/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/13 0:14:49
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
    /// AssetMfCmpSizePage
    /// </summary>
    [Serializable]
    public class AssetMfSizePage : Page<AssetMfSizeInfo>
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
        protected override void DrawTitle(Object obj)
        {
            base.DrawTitle(obj);

            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            EditorGUILayout.TextField("名称", EditorStyles.label);
            EditorGUILayout.LabelField("大小1", UIOptUtil.btn);
            EditorGUILayout.LabelField("大小2", UIOptUtil.btn);
            EditorGUILayout.LabelField("差值(B)", UIOptUtil.btn);
            EditorGUILayout.LabelField("差值", UIOptUtil.btn);
            EditorGUILayout.LabelField("", UIOptUtil.btn);
            EditorGUILayout.LabelField("", UIOptUtil.plusWd);
            EditorGUILayout.EndHorizontal();
        }

        protected override void DrawItem(Object obj, int i)
        {
            if (lst[i] == null) return;
            lst[i].OnGUI(obj);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}