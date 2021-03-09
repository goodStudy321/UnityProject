/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2018/2/4 14:56:23
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    public class ABExView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 资源包总数量
        /// </summary>
        public int total = 0;

        /// <summary>
        /// 要设置的资源包名
        /// </summary>
        public string abName = "";
        /// <summary>
        /// 搜索完整名称
        /// </summary>
        public string searchName = "";

        /// <summary>
        /// 搜索制定后缀名
        /// </summary>
        public string searchSfx = "";

        /// <summary>
        /// 搜索指定选项
        /// </summary>
        public string searchStr = "";


        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void SetName()
        {
            if (string.IsNullOrEmpty(abName))
            {
                UIEditTip.Error("包名为空");
            }
            else if (EditorUtility.DisplayDialog("", "选择的文件将被设置相同包名", "Y", "N"))
            {
                ABNameUtil.SetSelect(abName);
            }
        }

        private void SetTotal()
        {
            var names = AssetDatabase.GetAllAssetBundleNames();
            if (names == null)
            {
                total = 0;
            }
            else
            {
                total = names.Length;
            }
        }

        private void RefreahABName()
        {
            DialogUtil.Show("", "刷新所有AB的名称\n此操作很耗时", ABNameUtil.Refresh);
        }

        /// <summary>
        /// 搜索
        /// </summary>
        private void Search()
        {
            if (!UIEditTool.DrawHeader("搜索", "ABExSearch", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField("资源包总数量:", total.ToString());
            if (GUILayout.Button("刷新", UIOptUtil.btn)) SetTotal();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("搜索名称:", ref searchName, this);
            if (GUILayout.Button("搜索", UIOptUtil.btn)) ABNameUtil.Search(searchName);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("搜索后缀:", ref searchSfx, this);
            if (GUILayout.Button("搜索", UIOptUtil.btn)) ABNameUtil.SearchBySfx(searchSfx);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("搜索选项:", ref searchStr, this);

            if (GUILayout.Button("搜索", UIOptUtil.btn)) ABNameUtil.SearchByStr(searchStr);
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 设置包名
        /// </summary>
        private void DrawName()
        {
            if (!UIEditTool.DrawHeader("设置名称", "ABExSetName", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("包名:", ref abName, this);
            if (GUILayout.Button("设置")) SetName();
            EditorGUILayout.EndHorizontal();
            UIEditLayout.HelpWaring("将选择的文件夹或者文件设置为同一包名");
            EditorGUILayout.EndVertical();
        }

        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            Search();
            EditorGUILayout.Space();
            DrawName();
            EditorGUILayout.Space();

            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            if (GUILayout.Button("刷新所有AB名称")) RefreahABName();
            if (GUILayout.Button("刷新所有ShadreAB名")) ABNameUtil.SetShader();
            EditorGUILayout.EndVertical();
        }

        protected override void OpenCustom()
        {
            base.OpenCustom();
            SetTotal();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}