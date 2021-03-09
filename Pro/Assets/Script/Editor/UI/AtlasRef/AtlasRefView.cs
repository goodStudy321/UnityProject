/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/18 15:47:13
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AtlasRefView
    /// </summary>
    public class AtlasRefView : AssetRefViewBase<UIAtlas>
    {
        #region 字段
        public string spriteName = "";

        public Texture refTex = null;

        /// <summary>
        /// 默认选择UI Root
        /// </summary>
        public bool defaulUIRoot = true;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void LoadALLUI()
        {
            NGUIUtil.LoadAllUI();
        }

        private void SearchSprite()
        {
            if (string.IsNullOrEmpty(spriteName))
            {
                UIEditTip.Log("未设置精灵名称(不区分大小写)");
            }
            else
            {
                var objs = AtlasUtil.Search(target, spriteName, defaulUIRoot);
                page.SetLst(objs);
                SearchTip();
            }
        }

        private void SearchTexture()
        {
            if (refTex == null)
            {
                UIEditTip.Log("未设置搜索图片");
            }
            else
            {
                var objs = AtlasUtil.Search(refTex, defaulUIRoot);
                page.SetLst(objs);
                //SearchTip();
                if (objs == null || objs.Count < 1)
                {
                    UIEditTip.Warning("未搜索到");
                }
            }
        }


        #endregion

        #region 保护方法
        protected override void SetObjs()
        {
            objs = AtlasUtil.SearchSelect(target, defaulUIRoot);
        }

        protected override void Help()
        {
            UIEditTip.Log("在层级面板中选择指定的游戏对象进行搜索");
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);

            EditorGUILayout.BeginHorizontal();

            UIEditLayout.Toggle("默认搜索UI根节点:", ref defaulUIRoot, this);
            if (GUILayout.Button("创建所有UI", UIOptUtil.btn))
            {
                DialogUtil.Show("", "创建所有UI?", LoadALLUI);
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.BeginHorizontal();
            DrawObj(this);
            if (GUILayout.Button("查询", UIOptUtil.btn))
            {
                DialogUtil.Show("", "确定搜索?", Search);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.TextField("精灵名称:", ref spriteName, this);
            if (GUILayout.Button("查询", UIOptUtil.btn))
            {
                DialogUtil.Show("", "确定搜索?", SearchSprite);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.ObjectField<Texture>("引用图片:", ref refTex, this);
            if (GUILayout.Button("查询", UIOptUtil.btn))
            {
                DialogUtil.Show("", "确定搜索?", SearchTexture);
            }
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.EndVertical();

            page.OnGUI(this);
        }


        #endregion

        #region 公开方法

        #endregion
    }
}