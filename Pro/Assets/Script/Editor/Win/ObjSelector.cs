/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/3/15 16:13:38
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

    /// 对象选择窗口
    /// </summary>
    public class ObjSelector : EditorWindow
    {
        #region 字段
        /// <summary>
        /// 对象列表
        /// </summary>
        private Object[] objs = null;


        private Vector2 scroll = Vector2.zero;

        private GUILayoutOption[] btnOpts = new GUILayoutOption[] { GUILayout.Width(100) };

        private GUILayoutOption[] horOpts = new GUILayoutOption[] { GUILayout.Height(20) };

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        public delegate void OnSelect(Object obj);

        private OnSelect onSelect = null;
        #endregion

        #region 构造方法
        public ObjSelector()
        {

        }
        #endregion

        #region 私有方法
        private void OnGUI()
        {
            GUILayout.Label(titleContent.text, "LODLevelNotifyText");
            EditorGUILayout.Space();
            if (objs == null || objs.Length < 1)
            {
                EditorGUILayout.HelpBox("未发现!", MessageType.Info);
                return;
            }
            scroll = EditorGUILayout.BeginScrollView(scroll);
            int length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                Draw(objs[i]);
            }

            EditorGUILayout.EndScrollView();
        }

        private void Draw(Object obj)
        {
            if (obj == null) return;

            EditorGUILayout.BeginHorizontal(horOpts);

            string path = AssetDatabase.GetAssetPath(obj);

            if (string.IsNullOrEmpty(path))
            {
                path = "场景资源";
            }
            else if (path.StartsWith("Library/"))
            {
                path = "系统";
            }

            if (GUILayout.Button(obj.name, "TextArea", GUILayout.Width(160)))
            {
                SetSelect(obj);
            }

            if (GUILayout.Button(path, "TextArea"))
            {
                SetSelect(obj);
            }
            if (GUILayout.Button("选择", btnOpts))
            {
                SetSelect(obj);
            }
            if (GUILayout.Button("定位", btnOpts))
            {
                EditorGUIUtility.PingObject(obj);
            }
            EditorGUILayout.EndHorizontal();
        }

        private void SetSelect(Object obj)
        {
            if (obj == null) return;
            if (onSelect != null) onSelect(obj);
            UIEditTip.Log("已选择:{0}", obj.name);
            Close();
        }

        private int Compare(Object lhs, Object rhs)
        {
            if (lhs == null) return (rhs == null) ? 0 : 1;
            if (rhs == null) return -1;
            return lhs.name.CompareTo(rhs.name);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开选择窗口
        /// </summary>
        /// <typeparam name="T">资源类型</typeparam>
        /// <param name="cb">选择回调</param>
        /// <param name="scene">true:场景资源</param>
        public static void Open<T>(OnSelect cb, bool scene = false) where T : Object
        {
            var win = GetWindow<ObjSelector>(true);
            string title = "选择:" + typeof(T).Name;
            win.SetTitle(title);
            win.SetSize(500, 800);
            win.onSelect = cb;
            Object[] objs = null;
            if (scene)
            {
                objs = GameObject.FindObjectsOfType<T>();
            }
            else
            {
                objs = Resources.FindObjectsOfTypeAll<T>();
            }
            Array.Sort(objs, win.Compare);
            win.objs = objs;
        }
        #endregion
    }
}