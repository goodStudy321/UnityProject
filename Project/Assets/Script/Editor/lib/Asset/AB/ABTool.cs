using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Debug = UnityEngine.Debug;

namespace Hello.Edit
{
    public static partial class ABTool 
    {
        private static ABView data = null;

        private static ElapsedTime et = new ElapsedTime();

        public const int Pri = MenuTool.AssetPri + 50;

        public const string menu = MenuTool.Hello + "资源包工具/";

        public const string AMenu = MenuTool.AHello + "资源包工具/";

        public static readonly string variant = Suffix.AB.Replace(".", string.Empty);

        public static ABView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<ABView>();
                }
                return data;
            }
        }

        private static BuildAssetBundleOptions GetBuildOpts()
        {
            var opts = Data.AbForce ? BuildAssetBundleOptions.ForceRebuildAssetBundle : BuildAssetBundleOptions.None;
            if (!Data.Compress) opts = opts | BuildAssetBundleOptions.UncompressedAssetBundle;
            return opts;
        }

        private static string GetOutput(BuildTarget target)
        {
            string outputFolder = Data.OutPut;
            string outputDir = outputFolder + "/" + EditUtil.GetPlatform(target);
            if (!Directory.Exists(outputDir)) Directory.CreateDirectory(outputDir);
            return outputDir;
        }

        private static void SetName(bool force)
        {
            Object[] objs = AssetUtil.GetFiltered();
            if (objs == null || objs.Length == 0) return;
            string[] depends = AssetUtil.GetDepends(objs);
            float len = depends.Length;
            for (int i = 0; i < len; i++)
            {
                string path = depends[i];
                float pro = i / len;
                ABNameUtil.Set(path, force);
                ProgressBarUtil.Show("", "正在玩命设置中...", pro);
            }
            UIEditTip.Warning("设置完成\n若有无效资源,请见控制台红色输出");

            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh();
        }

        [MenuItem(menu + "设置资源包名称/引用资源已设则跳过 #&j", false, Pri + 2)]
        [MenuItem(AMenu + "设置资源包名称/引用资源已设则跳过", false, Pri + 2)]
        private static void SetNameSkip()
        {
            SetName(false);
        }

        [MenuItem(menu + "设置资源包名称/强制 #&r", false, Pri + 3)]
        [MenuItem(AMenu + "设置资源包名称/强制", false, Pri + 3)]
        private static void SetNameForce()
        {
            SetName(true);
        }

        public static void Remove(string assetPath)
        {
            AssetImporter importer = AssetImporter.GetAtPath(assetPath);
            if (importer == null) return;
            importer.assetBundleName = null;
        }
    }

}
