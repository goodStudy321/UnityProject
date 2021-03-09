//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/9/16 14:25:07
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AtlasSearchView
    /// </summary>
    public class AtlasSearchView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 图集目录
        /// </summary>
        public string atlasDir = "Assets/Pkg/ui";

        /// <summary>
        /// 精灵名称
        /// </summary>
        public string spriteName = null;


        public ObjPage page = new ObjPage();

        private List<UIAtlas> atlases = null;
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
            if (atlases == null)
            {
                Refresh();
            }
            if (string.IsNullOrEmpty(spriteName))
            {
                UIEditTip.Error("未设置精灵名称");
            }
            else
            {
                var lst = AtlasUtil.Search<Object>(atlases, spriteName);
                page.SetLst(lst);
            }
        }
        #endregion

        #region 保护方法



        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("刷新"))
            {
                DialogUtil.Show("", "刷新图集", Refresh);
            }
            else if (TitleBtn("搜索"))
            {
                var msg = string.Format("搜索名称:{0}的精灵?", spriteName);
                DialogUtil.Show("", msg, Search);

            }
            EndTitle();
        }
        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetFolder("图集目录:", ref atlasDir, this, true);
            UIEditLayout.TextField("精灵名称:", ref spriteName, this);
            EditorGUILayout.EndVertical();

            page.OnGUI(this);
        }

        protected override void OpenCustom()
        {
            base.OpenCustom();
            Refresh();
        }
        #endregion

        #region 公开方法
        public override void Refresh()
        {
            base.Refresh();
            atlases = AtlasUtil.Search(atlasDir);
        }

        public override void OnCompiled()
        {
            base.OnCompiled();
            Refresh();
        }
        #endregion
    }
}