//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/29 15:03:37
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
    /// ABInfo
    /// </summary>
    public class ABInfoView : EditViewBase
    {
        #region 字段
        public string minStr = "";

        public string maxStr = "";

        public string dir = "";

        public long min = 1024 * 1024;

        public long max = 1024 * 1024 * 10;

        public ABFilePage page = new ABFilePage();

        public int type = (1 << (int)AssetType.Prefab) | (1 << (int)AssetType.Scene);
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
            var ty = (AssetType)type;
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            if (files == null) return;
            page.lst.Clear();
            var title = "搜集中···";
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var name = Path.GetFileNameWithoutExtension(file);
                var sfx = Path.GetExtension(name);
                if (AssetQueryUtil.Contains(ty, sfx))
                {
                    var fi = new FileInfo(file);
                    var size = fi.Length;
                    if (size < min) continue;
                    if (size > max) continue;
                    var info = new ABFileInfo();
                    info.DiskUsage = size;
                    var abName = Path.GetFileName(file);
                    info.abName = abName;
                    var arr = AssetDatabase.GetAssetPathsFromAssetBundle(abName);
                    info.assetPaths = new List<string>(arr);
                    page.lst.Add(info);
                }
                ProgressBarUtil.Show(title, name, i / length);
            }
            page.lst.Sort();
            page.LastPage();
            ProgressBarUtil.Clear();
        }

        private void MinChange()
        {
            minStr = ByteUtil.GetSizeStr(min);
        }

        private void MaxChange()
        {
            maxStr = ByteUtil.GetSizeStr(max);
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

            EndTitle();
        }

        protected override void OnGUICustom()
        {
            UIEditLayout.SetFolder("搜索目录:", ref dir, this);
            UIEditLayout.MaskField("搜索选项:", ref type, AssetQueryUtil.typeNames, this);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.LongField("搜索范围:", ref min, this, MinChange);
            EditorGUILayout.LabelField(minStr);
            EditorGUILayout.Space();
            UIEditLayout.LongField("", ref max, this, MaxChange);
            EditorGUILayout.LabelField(maxStr);
            EditorGUILayout.EndHorizontal();
            page.OnGUI(this);
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            minStr = ByteUtil.GetSizeStr(min);
            maxStr = ByteUtil.GetSizeStr(max);
        }
        #endregion
    }
}