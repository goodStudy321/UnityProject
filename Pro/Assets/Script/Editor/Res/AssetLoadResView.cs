//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 14:27:57
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
    public class AssetLoadResView : EditViewBase
    {
        #region 字段
        public LoadResCfg res = new LoadResCfg();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Load()
        {
            res = Loong.Game.XmlTool.Deserializer<LoadResCfg>(AssetLoadRes.path);
            EditUtil.SetDirty(this);
            AssetDatabase.SaveAssets();
        }

        private void Save()
        {
            XmlTool.Serializer(AssetLoadRes.path, res);
            UIEditTip.Log("保存成功");
            AssetDatabase.Refresh();
        }

        private void Upload()
        {
            SvnUtil.Commit(AssetLoadRes.path, "更新本地资源配置");
        }


        private void Draw(string title, string k, string kLst, List<string> dirs)
        {
            if (!UIEditTool.DrawHeader(title, k, StyleTool.Host)) return;
            UIDrawTool.StringLst(this, dirs, kLst, title);
            DragDropUtil.AddDirs(dirs);
        }

        #endregion

        #region 保护方法

        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("加载"))
            {
                DialogUtil.Show("", "加载", Load);
            }
            else if (TitleBtn("保存"))
            {
                DialogUtil.Show("", "保存", Save);
            }
            else if (TitleBtn("上传"))
            {
                DialogUtil.Show("", "上传", Upload);
            }

            EndTitle();
        }

        protected override void OnGUICustom()
        {
            Draw("加载图片路径", "AssetLoadResTexDirs", "k_AssetLoadResTexDirs", res.texDirs);
            Draw("加载文本路径", "AssetLoadResTextDirs", "k_AssetLoadResTextDirs", res.textDirs);
            Draw("加载动画路径", "AssetLoadResAnimDirs", "k_AssetLoadResAnimDirs", res.animDirs);
            Draw("加载音效路径", "AssetLoadResAudioDirs", "k_AssetLoadResAudioDirs", res.audioDirs);
            Draw("加载Prefab路径", "AssetLoadResPrefabDirs", "k_AssetLoadResPrefabDirs", res.prefabDirs);
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            if (res.NoCfg())
            {
                Load();
            }
        }
        #endregion
    }
}