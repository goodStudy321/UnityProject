/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/4 0:12:49
 ============================================================================*/

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
    /// AssetModPage
    /// </summary>
    [Serializable]
    public class eAssetPage : Page<eAssetInfo>
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
            EditorGUILayout.LabelField("索引", UIOptUtil.btn);
            EditorGUILayout.LabelField("", UIOptUtil.plusWd);
            EditorGUILayout.TextField("路径", EditorStyles.label);
            EditorGUILayout.LabelField("等级", UIOptUtil.btn);
            EditorGUILayout.LabelField("排序", UIOptUtil.btn);
            EditorGUILayout.LabelField("", UIOptUtil.btn);
            EditorGUILayout.LabelField("", UIOptUtil.btn);
            EditorGUILayout.EndHorizontal();
        }

        protected override void DrawItem(Object obj, int i)
        {
            lst[i].Draw(obj, lst, i);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}