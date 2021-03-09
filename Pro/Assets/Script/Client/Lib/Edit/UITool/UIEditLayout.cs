/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/3/8 00:00:00
 ============================================================================*/

#if UNITY_EDITOR
using System;
using System.IO;
using UnityEngine;
using UnityEditor;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// 编辑器自动排版工具
    /// </summary>
    public static class UIEditLayout
    {
        /// <summary>
        /// 绘制颜色
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void ColorField(string label, ref Color value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Color newValue = EditorGUILayout.ColorField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("ColorValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制动画曲线
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void CurveField(string label, ref AnimationCurve value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            AnimationCurve newValue = EditorGUILayout.CurveField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("CurveValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制折页
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="style">样式</param>
        public static void Foldout(string label, ref bool value, Object obj, Action changed = null, string style = "foldout")
        {
            EditorGUI.BeginChangeCheck();
            bool newValue = EditorGUILayout.Foldout(value, label, style);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("FoldoutValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制监视面板标题
        /// </summary>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="obj">标题对象</param>
        /// <param name="expandable">true:可扩展</param>
        /// <param name="changed">改变事件</param>
        public static void InspectorTitleBar(ref bool value, Object obj, Object target, bool expandable = false, Action changed = null)
        {
            EditorGUI.BeginChangeCheck();
            bool newValue = EditorGUILayout.InspectorTitlebar(value, target, expandable);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("FoldoutValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制整数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void IntField(string label, ref int value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.IntField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("IntValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 在区间内绘制整数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="min">最小值</param>
        /// <param name="max">最大值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void IntField(string label, ref int value, int min, int max, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.IntField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("IntValue", obj);
            newValue = Mathf.Clamp(newValue, min, max);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制正整数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void UIntField(string label, ref int value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.IntField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("IntValue", obj);
            value = (newValue < 0) ? 0 : newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制长整数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void LongField(string label, ref long value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            long newValue = EditorGUILayout.LongField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("LongValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制正长整数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void UlongField(string label, ref long value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            long newValue = EditorGUILayout.LongField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("UlongValue", obj);
            value = (newValue < 0) ? 0 : newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制枚举遮罩
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void EnumMaskField(string label, ref Enum value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            //Enum newValue = EditorGUILayout.EnumMaskField(label, value, options);
            Enum newValue = EditorGUILayout.EnumFlagsField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("EnumMaskValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制枚举选项列表
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void EnumPopup(string label, ref Enum value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Enum newValue = EditorGUILayout.EnumPopup(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("EnumPopupValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制浮点数
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void FloatField(string label, ref float value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            float newValue = EditorGUILayout.FloatField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("FloatValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制整数选项数组
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="displayOptions">显示选项</param>
        /// <param name="optionValues">整数数组</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void IntPopup(string label, ref int value, string[] displayOptions, int[] optionValues, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.IntPopup(label, value, displayOptions, optionValues, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("IntPopupValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制整数滑动条
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="lefValue">左值</param>
        /// <param name="rigValue">右值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void IntSlider(string label, ref int value, int lefValue, int rigValue, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.IntSlider(label, value, lefValue, rigValue, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("IntSliderValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制遮罩
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="displayOptions">显示选项数组</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void MaskField(string label, ref int value, string[] displayOptions, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.MaskField(label, value, displayOptions, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("MaskValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制对象
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void ObjectField<T>(string label, ref T value, Object obj, Action changed = null, params GUILayoutOption[] options) where T : Object
        {
            EditorGUI.BeginChangeCheck();
            T newValue = EditorGUILayout.ObjectField(label, value, typeof(T), true, options) as T;
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("ObjectValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制矩形结构
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void RectField(string label, ref Rect value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Rect newValue = EditorGUILayout.RectField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("RectValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制密码
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void PasswordField(string label, ref string value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            string newValue = EditorGUILayout.PasswordField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("PasswordValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制整数弹窗
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="displayOptions">显示选项数组</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Popup(string label, ref int value, string[] displayOptions, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.Popup(label, value, displayOptions, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("PopupValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制整数弹窗
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="displayOptions">显示选项数组</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static int Popup(string label, object value, string[] displayOptions, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            int newValue = EditorGUILayout.Popup(label, (int)value, displayOptions, options);
            if (!EditorGUI.EndChangeCheck()) return newValue;
            EditUtil.RegisterUndo("PopupValue", obj);
            if (changed != null) changed();
            return newValue;
        }

        /// <summary>
        /// 绘制浮点型滑动条
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="lefValue">左值</param>
        /// <param name="rigValue">右值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Slider(string label, ref float value, float lefValue, float rigValue, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            float newValue = EditorGUILayout.Slider(label, value, lefValue, rigValue, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("SliderValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制标签
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void TagField(string label, ref string value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            string newValue = EditorGUILayout.TagField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("TagValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制文本区域
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void TextArea(string label, ref string value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUILayout.LabelField(label);
            EditorGUI.BeginChangeCheck();
            string newValue = EditorGUILayout.TextArea(value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("TextAreaValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制文本字段
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void TextField(string label, ref string value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            string newValue = EditorGUILayout.TextField(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("TextFieldValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制布尔值
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Toggle(string label, ref bool value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            bool newValue = EditorGUILayout.Toggle(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("ToggleValue", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制二维向量
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Vector2Field(string label, ref Vector2 value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Vector2 newValue = EditorGUILayout.Vector2Field(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("Vector2Value", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制三维向量
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Vector3Field(string label, ref Vector3 value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Vector3 newValue = EditorGUILayout.Vector3Field(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("Vector3Value", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 绘制四维向量
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void Vector4Field(string label, ref Vector4 value, Object obj, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUI.BeginChangeCheck();
            Vector4 newValue = EditorGUILayout.Vector4Field(label, value, options);
            if (!EditorGUI.EndChangeCheck()) return;
            EditUtil.RegisterUndo("Vector4Value", obj);
            value = newValue;
            if (changed != null) changed();
        }

        /// <summary>
        /// 帮助
        /// </summary>
        /// <param name="msg"></param>
        public static void HelpNone(string msg)
        {
            EditorGUILayout.HelpBox(msg, MessageType.None);
        }

        /// <summary>
        /// 普通帮助框
        /// </summary>
        /// <param name="msg"></param>
        public static void HelpInfo(string msg)
        {
            EditorGUILayout.HelpBox(msg, MessageType.Info);
        }

        /// <summary>
        /// 警告帮助框
        /// </summary>
        /// <param name="msg"></param>
        public static void HelpWaring(string msg)
        {
            EditorGUILayout.HelpBox(msg, MessageType.Warning);
        }

        /// <summary>
        /// 错误帮助框
        /// </summary>
        /// <param name="msg"></param>
        public static void HelpError(string msg)
        {
            EditorGUILayout.HelpBox(msg, MessageType.Error);
        }

        /// <summary>
        /// 设置目录
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="inPro">在工程内</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void SetFolder(string label, ref string value, Object obj, bool inPro = false, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            TextField(label, ref value, obj, changed, options);
            DragDropUtil.SetDir(obj, ref value);
            if (GUILayout.Button("设置", UIOptUtil.btn))
            {
                string path = value;
                if (path == null || path == "")
                {
                    path = Directory.GetCurrentDirectory();
                }
                string temp = EditorUtility.OpenFolderPanel(label, path, null);
                string tip = label.Replace(":", "");
                tip = tip.Replace("：", "");
                if (string.IsNullOrEmpty(temp))
                {
                    UIEditTip.Error("设置{0}的目录无效", tip);
                }
                else if (temp.Equals(value))
                {
                    UIEditTip.Warning("目录未发生改变");
                }
                else
                {
                    bool valid = true;
                    if (inPro)
                    {
                        var rDir = FileUtil.GetProjectRelativePath(temp);
                        if (string.IsNullOrEmpty(rDir))
                        {
                            UIEditTip.Error("非法目录:{0}", rDir);
                            valid = false;
                        }
                    }
                    if (valid)
                    {
                        UIEditTip.Log("成功设置{0}为:{1}", tip, temp);
                        EditUtil.RegisterUndo("SetFolder", obj);
                        value = temp;
                        if (changed != null) changed();
                    }
                }
            }
            else if (GUILayout.Button("打开目录", UIOptUtil.btn))
            {
                var dir = Path.GetFullPath(value);
                if (Directory.Exists(dir))
                {
                    ProcessUtil.Start(dir);
                }
                else
                {
                    UIEditTip.Error("{0}不存在", dir);
                }
            }
            EditorGUILayout.EndHorizontal();
        }

        /// <summary>
        /// 设置路径
        /// </summary>
        /// <param name="label">标签</param>
        /// <param name="value">值</param>
        /// <param name="obj">所在对象</param>
        /// <param name="sfx">后缀名无标点</param>
        /// <param name="inPro">在工程内</param>
        /// <param name="changed">改变事件</param>
        /// <param name="options">选项</param>
        public static void SetPath(string label, ref string value, Object obj, string sfx, bool inPro = false, Action changed = null, params GUILayoutOption[] options)
        {
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            TextField(label, ref value, obj, changed, options);
            DragDropUtil.SetPath(obj, ref value);
            if (GUILayout.Button("设置", UIOptUtil.btn))
            {
                string temp = EditorUtility.OpenFilePanel(label, Directory.GetCurrentDirectory(), sfx);
                string tip = label.Replace(":", "");
                tip = tip.Replace("：", "");
                if (string.IsNullOrEmpty(temp))
                {
                    UIEditTip.Error("设置{0}的路径无效", tip);
                }
                else if (temp.Equals(value))
                {
                    UIEditTip.Error("路径未发生改变");
                }
                else
                {
                    bool valid = true;
                    if (inPro)
                    {
                        var rDir = FileUtil.GetProjectRelativePath(temp);
                        if (string.IsNullOrEmpty(rDir))
                        {
                            UIEditTip.Error("非法路径:{0}", rDir);
                            valid = false;
                        }
                    }
                    if (valid)
                    {
                        UIEditTip.Log("成功设置{0}为:{1}", tip, temp);
                        EditUtil.RegisterUndo("SetFilePath", obj);
                        value = temp;
                        if (changed != null) changed();
                    }
                }
            }
            else if (GUILayout.Button("打开目录", UIOptUtil.btn))
            {
                if (string.IsNullOrEmpty(value))
                {
                    UIEditTip.Error("未设置");
                    return;
                }
                var dir = Path.GetDirectoryName(value);
                dir = Path.GetFullPath(dir);
                if (Directory.Exists(dir))
                {
                    ProcessUtil.Start(dir);
                }
                else
                {
                    UIEditTip.Error("{0}不存在", dir);
                }
            }
            EditorGUILayout.EndHorizontal();
        }
    }
}
#endif