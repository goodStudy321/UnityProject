/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/9 12:05:18
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源包视图
    /// </summary>
    public class ABView : EditViewBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private bool abForce = false;

        [SerializeField]
        [HideInInspector]
        private bool compress = false;

        [SerializeField]
        [HideInInspector]
        private string output = "../Assets";
        [SerializeField]
        [HideInInspector]
        private readonly List<string> originSfxs = new List<string>();
        #endregion

        #region 属性
        /// <summary>
        /// true:强制打包
        /// </summary>
        public bool AbForce { get { return abForce; } }

        /// <summary>
        /// true:压缩
        /// </summary>
        public bool Compress { get { return compress; } }

        /// <summary>
        /// 输出目录
        /// </summary>
        public string Output
        {
            get
            {
                if (string.IsNullOrEmpty(output))
                {
                    output = "../Assets";
                    SetOutput();
                }
                return output;
            }
        }
        #endregion

        #region 构造方法

        private void SetOutput()
        {
            output = Path.GetFullPath(output);
            output.Replace("\\", "/");
        }

        /// <summary>
        /// 构造函数
        /// </summary>
        public ABView()
        {
            Type type = typeof(Suffix);
            FieldInfo[] fields = type.GetFields(BindingFlags.Public | BindingFlags.Static);
            if (fields == null || fields.Length == 0)
            { iTrace.Error("Loong", "没有查找到Suffix的字段信息"); return; }
            int length = fields.Length;
            for (int i = 0; i < length; i++)
            {
                string key = fields[i].GetValue(null) as string;
                if (!AssetUtil.IsValidSfx(key)) continue;
                originSfxs.Add(key);
            }
        }
        #endregion

        #region 私有方法

        private void OutputChanged()
        {
            if (string.IsNullOrEmpty(Output)) return;
            SetOutput();
            string key = Path.GetFullPath("./iOutputFolder");
            EditorPrefs.SetString(key, Output);
            UIEditTip.Warning("设置路径为:{0}", Output);
        }

        /// <summary>
        /// 设置资源包保存目录
        /// </summary>
        private void SetOutputFilePath()
        {
            if (!UIEditTool.DrawHeader("设置资源包保存目录", "setOutput", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetFolder("目录:", ref output, this, false, OutputChanged);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("目录完整路径:", Output);
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 显示Unity资源后缀名
        /// </summary>
        private void ShowSuffix()
        {
            if (!UIEditTool.DrawHeader("可打包的资源后缀名称", "originSfxs", StyleTool.Host)) return;
            if (originSfxs.Count == 0)
            {
                EditorGUILayout.LabelField("空");
                return;
            }
            int index = 0;
            int row = 1;
            if (originSfxs.Count > 5) row = Mathf.CeilToInt(originSfxs.Count / 5f);
            for (int i = 0; i < row; i++)
            {
                EditorGUILayout.BeginHorizontal();
                for (int j = 0; j < 5; j++)
                {
                    if (index >= originSfxs.Count) break;
                    EditorGUILayout.BeginVertical();
                    GUILayout.Label(originSfxs[index], StyleTool.Group, GUILayout.Width(100));
                    EditorGUILayout.EndVertical();
                    index++;
                }
                GUILayout.FlexibleSpace();
                EditorGUILayout.EndHorizontal();
            }
        }

        /// <summary>
        /// 设置打包选项
        /// </summary>
        private void SetBuildOption()
        {
            if (!UIEditTool.DrawHeader("设置打包选项", "setBuildOption", StyleTool.Host)) return;
            UIEditTool.BeginContents();
            UIEditLayout.Toggle("强制打包", ref abForce, this);
            UIEditLayout.Toggle("压缩资源包:", ref compress, this);
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            EditorGUILayout.HelpBox("当前平台为:" + EditorUserBuildSettings.activeBuildTarget, MessageType.Warning);
            EditorGUILayout.HelpBox("不要尝试打包平台和工程设置不一样,因为会将资源重新导入目标平台", MessageType.Warning);


            UIEditTool.EndContents();
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("工程设置"))
            {
                DialogUtil.Show("", "打包工程设置平台的AB?", ABTool.BuildUserSettings);
            }
            else if (TitleBtn("打包Ios"))
            {
                DialogUtil.Show("", "打包iOS平台的AB?", ABTool.BuildIOS);
            }
            else if (TitleBtn("打包Android"))
            {
                DialogUtil.Show("", "打包Android平台的AB?", ABTool.BuildAndroid);
            }
            EndTitle();
        }

        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            SetOutputFilePath();
            EditorGUILayout.Space();
            ShowSuffix();
            EditorGUILayout.Space();
            SetBuildOption();

        }
        #endregion

        #region 公开方法

        #endregion

    }
}