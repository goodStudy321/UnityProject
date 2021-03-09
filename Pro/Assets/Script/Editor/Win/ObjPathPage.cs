/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/3 23:16:53
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
    /// ObjsPage
    /// </summary>
    [Serializable]
    public class ObjPathPage : Page<string>
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
        private void SetAB()
        {
            if (lst == null) return;
            float length = lst.Count;
            var title = "设置AB";
            for (int i = 0; i < length; i++)
            {
                var path = lst[i];
                ABNameUtil.Set(path, true);
                ProgressBarUtil.Show(title, path, i / length);
            }
            ProgressBarUtil.Clear();
            UIEditTip.Log("设置完毕");
        }

        private void SetAB(string path)
        {
            ABNameUtil.Set(path, true);
        }

        private void CancelAB(string path)
        {
            ABTool.Remove(path);
        }

        private void Delete()
        {
            AssetUtil.Delete(lst);
        }


        private void Delete(int i)
        {
            var path = lst[i];
            if (!EditorUtility.DisplayDialog("删除?", path, "确定", "取消")) return;
            var suc = AssetDatabase.DeleteAsset(path);
            ListTool.Remove<string>(lst, i);
            UIEditTip.Mutex(suc, "删除:{0}", path);
        }
        #endregion

        #region 保护方法
        protected override void DrawItem(Object obj, int i)
        {
            var path = lst[i];
            EditorGUILayout.TextField(path);

            if (GUILayout.Button("定位", UIOptUtil.btn))
            {
                EditUtil.Ping(path);
            }
            if (GUILayout.Button("设置AB", UIOptUtil.btn))
            {
                SetAB(path);
            }
            if (GUILayout.Button("取消AB", UIOptUtil.btn))
            {
                CancelAB(path);
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
            if (GUILayout.Button("设置所有AB", EditorStyles.toolbarButton))
            {
                DialogUtil.Show("", "设置所有AB?", SetAB);
            }
            if (GUILayout.Button("一键删除", EditorStyles.toolbarButton))
            {
                DialogUtil.Show("", "删除所有资源?", Delete);
            }
            EditorGUILayout.EndHorizontal();
            base.OnGUI(obj);
        }
        #endregion
    }
}