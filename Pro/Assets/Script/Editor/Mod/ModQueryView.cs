//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/9 12:01:43
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ModQueryView
    /// </summary>
    public class ModQueryView : EditViewBase
    {
        #region 字段
        public bool importMat = true;

        public ObjPage page = new ObjPage();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Search()
        {
            var type = (AssetType)(1 << ((int)AssetType.Model));
            var pahts = SelectUtil.GetPath(type);
            if (pahts == null || pahts.Count < 1) return;
            float length = pahts.Count;
            var title = "检查中";
            for (int i = 0; i < length; i++)
            {
                var path = pahts[i];
                ProgressBarUtil.Show(title, path, i / length);
                var mi = ModelImporter.GetAtPath(path) as ModelImporter;
                if (Condition(mi))
                {
                    var obj = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                    page.lst.Add(obj);
                }
            }
            ProgressBarUtil.Clear();
        }

        private bool Condition(ModelImporter mi)
        {
            if (mi.importMaterials == importMat) return true;
            return false;
        }

        private void DrawCondition()
        {
            if (!UIEditTool.DrawHeader("搜索条件", "ModQueryCond", StyleTool.Host)) return;
            UIEditLayout.Toggle("是否勾选导入材质球:", ref importMat, this);
        }
        #endregion

        #region 保护方法
        protected override void OpenCustom()
        {
            var msg = "选择指定的文件夹进行搜索";
            DialogUtil.Show("", msg);
        }

        protected override void OnGUICustom()
        {
            DrawCondition();
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            page.OnGUI(this);
        }


        protected override void Title()
        {
            BegTitle();

            if (TitleBtn("搜索"))
            {
                DialogUtil.Show("", "确定搜索?", Search);
            }
            EndTitle();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}