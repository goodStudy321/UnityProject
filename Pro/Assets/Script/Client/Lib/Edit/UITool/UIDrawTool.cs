//=============================================================================
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2014.10.16 20:36:31
// 编辑器UI绘制工具
//=============================================================================

#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    public static class UIDrawTool
    {
        #region 字段

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
        /// <summary>
        /// 绘制整数列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">整数列表</param>
        /// <param name="key">折叠键值</param>
        /// <param name="title">标题</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void IntLst(Object obj, List<int> lst, string key, string title, Action<int> changed = null)
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add(0);
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();

            if (EditorPrefs.GetBool(key))
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUI.BeginChangeCheck();
                    int newVal = EditorGUILayout.IntField("元素" + i, lst[i]);
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst[i] = newVal;
                        if (changed != null) changed(i);
                    }

                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    EditorGUILayout.EndHorizontal();

                }
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制长整型列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">长整型列表</param>
        /// <param name="key">折叠键值</param>
        /// <param name="title">标题</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void LongLst(Object obj, List<long> lst, string key, string title, Action<int> changed = null)
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add(0);
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();

            if (EditorPrefs.GetBool(key))
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUI.BeginChangeCheck();
                    long newVal = EditorGUILayout.LongField("元素" + i, lst[i]);
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst[i] = newVal;
                        if (changed != null) changed(i);
                    }

                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    EditorGUILayout.EndHorizontal();

                }
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制字符列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">字符列表</param>
        /// <param name="key">折叠键值</param>
        /// <param name="title">标题</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void StringLst(Object obj, List<string> lst, string key, string title, Action<int> changed = null)
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add("");
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();
            if (EditorPrefs.GetBool(key))
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUI.BeginChangeCheck();
                    string newVal = EditorGUILayout.TextField("元素" + i, lst[i]);
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst[i] = newVal;
                        if (changed != null) changed(i);
                    }
                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    EditorGUILayout.EndHorizontal();
                    if (string.IsNullOrEmpty(lst[i]))
                    {
                        EditorGUILayout.HelpBox("为空", MessageType.Warning);
                    }

                }
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制Unity对象列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">Unity对象列表</param>
        /// <param name="key">键值</param>
        /// <param name="title">标题</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少 其它对应索引值改变</param>
        public static void ObjectLst<T>(Object obj, List<T> lst, string key, string title, Action<int> changed = null) where T : Object
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);

            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add(null);
                    UIEditTip.Log("请点开圆圈,选择指定对象");
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();
            if (EditorPrefs.GetBool(key))
            {
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginHorizontal();
                    EditorGUI.BeginChangeCheck();
                    T newval = EditorGUILayout.ObjectField("元素" + i, lst[i], typeof(T), true) as T;
                    if (EditorGUI.EndChangeCheck())
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst[i] = newval;
                        if (changed != null) changed(i);
                    }
                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    if (lst[i] == null) EditorGUILayout.HelpBox("不能为空", MessageType.Error);
                    EditorGUILayout.EndHorizontal();

                }
            }
            EditorGUILayout.EndVertical();
        }


        /// <summary>
        /// 绘制实现IDraw接口的列表
        /// </summary>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">IDraw接口列表</param>
        /// <param name="key">键值</param>
        /// <param name="title">标题</param>
        /// <param name="vertical">默认true:纵向排列</param>
        /// <param name="changed">改变事件,参数-1:新增 -2减少</param>
        public static void IDrawLst<T>(Object obj, List<T> lst, string key, string title, bool vertical = true, Action<int> changed = null) where T : IDraw, new()
        {
            if (lst == null) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            if (EditorGUILayout.Foldout(EditorPrefs.GetBool(key), title))
            {
                EditorPrefs.SetBool(key, true);
                if (GUILayout.Button("", StyleTool.Plus, UIOptUtil.plusWd))
                {
                    EditUtil.RegisterUndo(key, obj);
                    lst.Add(new T());
                    Event.current.Use();
                    if (changed != null) changed(-1);
                }
            }
            else
            {
                EditorPrefs.SetBool(key, false);
            }
            EditorGUILayout.EndHorizontal();

            if (EditorPrefs.GetBool(key))
            {
                if (vertical) EditorGUILayout.BeginVertical();
                else EditorGUILayout.BeginHorizontal();
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.BeginVertical(StyleTool.Group);
                    EditorGUILayout.BeginHorizontal();
                    EditorGUILayout.LabelField(i.ToString());
                    if (GUILayout.Button("", StyleTool.Minus, UIOptUtil.plusWd))
                    {
                        EditUtil.RegisterUndo(key, obj);
                        lst.RemoveAt(i);
                        Event.current.Use();
                        if (changed != null) changed(-2);
                        break;
                    }
                    EditorGUILayout.EndHorizontal();
                    lst[i].Draw(obj, lst, i);
                    EditorGUILayout.EndVertical();
                }
                if (vertical) EditorGUILayout.EndVertical();
                else EditorGUILayout.EndHorizontal();
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制按钮列表
        /// </summary>
        /// <param name="obj">所在对象</param>
        /// <param name="title">标题</param>
        /// <param name="btn">按钮内容</param>
        /// <param name="length">长度</param>
        /// <param name="idx">按钮点击后设置的索引</param>
        /// <param name="onClick">按钮点击事件</param>
        public static void Buttons(Object obj, string title, string btn, int length, ref int idx, Action onClick = null)
        {
            if (length <= 0) return;
            EditorGUILayout.HelpBox(title, MessageType.Info);
            for (int i = 0; i < length; i++)
            {
                GUI.color = (idx == i ? Color.yellow : Color.white);
                if (GUILayout.Button(btn + i))
                {
                    if (idx == i) continue;
                    EditUtil.RegisterUndo("SetSelect", obj);
                    idx = i;
                    Event.current.Use();
                    if (onClick != null) onClick();
                }
            }
            GUI.color = Color.white;
        }
        #endregion
    }
}
#endif