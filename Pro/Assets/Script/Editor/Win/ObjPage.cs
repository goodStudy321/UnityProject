/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/11 12:05:01
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// ObjPage
    /// </summary>
    [Serializable]
    public class ObjPage : Page<Object>
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
        private void Delete()
        {
            AssetUtil.Delete(lst);
        }

        private void Delete(int i)
        {
            var o = lst[i];
            var name = o.name;
            if (!EditorUtility.DisplayDialog("删除?", name, "确定", "取消")) return;
            AssetUtil.Delete(o);
            ListTool.Remove<Object>(lst, i);
            UIEditTip.Log("删除:{0}", name);
        }
        #endregion

        #region 保护方法
        protected override void DrawItem(Object obj, int i)
        {
            var o = lst[i];
            EditorGUILayout.TextField(o.name);

            if (GUILayout.Button("定位", UIOptUtil.btn))
            {
                EditUtil.Ping(o);
            }
            else if (GUILayout.Button("删除", UIOptUtil.btn))
            {
                Delete(i);
            }
        }
        #endregion

        #region 公开方法
        public override void OnGUI(Object obj)
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("一键删除", EditorStyles.toolbarButton))
            {
                DialogUtil.Show("", "删除所有?", Delete);
            }
            EditorGUILayout.EndHorizontal();
            base.OnGUI(obj);
        }
        #endregion
    }
}