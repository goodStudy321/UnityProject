//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/28 20:32:20
// 在搜索目录中根据搜索选项搜集到的AB,在下方显示所有其未依赖到的AB
//=============================================================================

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
    /// ABLrcView
    /// </summary>
    public class ABLrcView : EditViewBase
    {
        #region 字段
        public string dir = "";

        public int type = (1 << (int)AssetType.Prefab) | (1 << (int)AssetType.Scene);

        public ABFilePage page = new ABFilePage();

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
            if (string.IsNullOrEmpty(dir))
            {
                UIEditTip.Error("未设置搜索目录"); return;
            }
            if (!Directory.Exists(dir))
            {
                UIEditTip.Error("搜索目录:{0}不存在", dir); return;
            }
            page.lst = ABLrcUtil.Compare(dir, (AssetType)type);
        }

        override protected void Help()
        {
            var msg = "在搜索目录中根据搜索选项搜集到的AB,在下方显示所有其未依赖到的AB";
            EditorUtility.DisplayDialog("", msg, "确定");
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            BegTitle();

            if (TitleBtn("查询"))
            {
                DialogUtil.Show("", "确定搜索", Search);
            }
            if (TitleBtn("帮助"))
            {
                Help();
            }


            EndTitle();
        }

        protected override void OnGUICustom()
        {
            UIEditLayout.SetFolder("搜索目录:", ref dir, this);
            UIEditLayout.MaskField("搜索选项:", ref type, AssetQueryUtil.typeNames, this);
            page.OnGUI(this);
        }

        #endregion

        #region 公开方法

        #endregion
    }
}