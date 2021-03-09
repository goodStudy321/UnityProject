//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/1 14:31:36
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
    /// ABToLsnView
    /// </summary>
    public class ABToLsnrView : EditViewBase
    {
        #region 字段
        public string dir = "";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Change()
        {
            if (string.IsNullOrEmpty(dir))
            {
                UIEditTip.Error("未设置目录"); return;
            }
            if (!Directory.Exists(dir))
            {
                UIEditTip.Error("{0} 不存在", dir); return;
            }
            var title = "设置保存的路径";
            var path = EditorUtility.SaveFilePanel(title, "../", "XXX", ".xml");
            if (string.IsNullOrEmpty(path)) return;
            var files = Directory.GetFiles(dir, "*.ab", SearchOption.AllDirectories);
            float length = files.Length;
            title = "检查AB中";
            var set = new HashSet<string>();
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                var abName = Path.GetFileName(file);
                var assetPaths = AssetDatabase.GetAssetPathsFromAssetBundle(abName);
                var assetPathLen = assetPaths.Length;
                for (int j = 0; j < assetPathLen; j++)
                {
                    var assetPath = assetPaths[j];
                    if (string.IsNullOrEmpty(assetPath)) continue;
                    if (set.Contains(assetPath)) continue;
                    set.Add(assetPath);
                }
                ProgressBarUtil.Show(title, abName, i / length);
            }
            ProgressBarUtil.Clear();
            var infos = new List<AssetLoadInfo>();
            var em = set.GetEnumerator();
            while (em.MoveNext())
            {
                var assetPath = em.Current;
                var info = new AssetLoadInfo(); ;
                info.path = assetPath;
                infos.Add(info);
            }
            XmlTool.Serializer<List<AssetLoadInfo>>(path, infos);
            UIEditTip.Warning("保存:{0}", path);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        protected override void Title()
        {
            BegTitle();

            if (TitleBtn("转换"))
            {
                DialogUtil.Show("", "确定转换", Change);
            }

            EndTitle();
        }


        protected override void OnGUICustom()
        {
            UIEditLayout.SetFolder("要转换的AB目录:", ref dir, this);

        }
        #endregion
    }
}