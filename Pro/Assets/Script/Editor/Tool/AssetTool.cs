/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 14:30:15
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源工具
    /// </summary>
    public static class AssetTool
    {
        #region 字段

        /// <summary>
        /// AB资源文件夹
        /// </summary>
        private static string abFolder = null;

        /// <summary>
        /// ActionSetup资源文件夹
        /// </summary>
        private static string actionFolder = "action";

        /// <summary>
        /// table资源文件夹
        /// </summary>
        private static string tableFolder = "table";

        /// <summary>
        /// 协议资源文件夹
        /// </summary>
        private static string protoFolder = "Proto";

        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 50;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "资源处理工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源处理工具/";


        /// <summary>
        /// 过滤文件
        /// </summary>
        public static HashSet<string> filters = new HashSet<string>() { Suffix.Manifest };
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static AssetTool()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 删除文件夹
        /// </summary>
        /// <param name="folder"></param>
        private static void DeleteStreamingFolder(string folder)
        {
            if (string.IsNullOrEmpty(folder)) return;
            string dir = string.Format("{0}/{1}", Application.streamingAssetsPath, folder);
            DirUtil.Delete(dir);
            string metaFile = string.Format("{0}.meta", dir);
            FileTool.Delete(metaFile);
        }



        #endregion

        #region 保护方法

        #endregion

        #region 公开方法



        /// <summary>
        /// 删除清单文件
        /// </summary>
        public static void DeleteManifest()
        {
            string dest = string.Format("{0}/{1}", Application.streamingAssetsPath, AssetMf.Name);
            FileTool.DeleteProjectFile(dest);
        }

        /// <summary>
        /// 拷贝源文件夹资源到流文件夹
        /// </summary>
        /// <param name="srcFolder">源文件夹</param>
        /// <param name="filters">过滤器</param>
        public static void Copy(string srcFolder, HashSet<string> filters)
        {
            if (string.IsNullOrEmpty(srcFolder)) return;
            var srcDir = string.Format("{0}/{1}", ABTool.Data.Output, srcFolder);
            if (!Directory.Exists(srcDir))
            {
                UIEditTip.Error("Loong,{0}目录:{1},不存在,请检查AB导出设置", srcFolder, srcFolder);
                return;
            }
            var destDir = string.Format("{0}/{1}", Application.streamingAssetsPath, srcFolder);
            DeleteStreamingFolder(destDir);
            EditDirUtil.Copy(srcDir, destDir, filters);
            AssetDatabase.Refresh();
            UIEditTip.Log("结束 复制{0}", srcFolder);
        }

        /// <summary>
        /// 复制AssetBundle到流文件夹
        /// </summary>
        [MenuItem(menu + "复制AssetBundle到流文件夹", false, Pri)]
        [MenuItem(AMenu + "复制AssetBundle到流文件夹", false, Pri)]
        public static void CopyABToStreaming()
        {
            abFolder = EditUtil.GetPlatform();
            Copy(abFolder, filters);
        }

        /// <summary>
        /// 复制动作数据到流文件夹
        /// </summary>
        [MenuItem(menu + "复制动作数据到流文件夹", false, Pri + 1)]
        [MenuItem(AMenu + "复制动作数据到流文件夹", false, Pri + 1)]
        public static void CopyActionSetupToStreaming()
        {
            Copy(actionFolder, null);
        }

        /// <summary>
        /// 复制表格数据到流文件夹
        /// </summary>
        [MenuItem(menu + "复制表格数据到流文件夹", false, Pri + 2)]
        [MenuItem(AMenu + "复制表格数据到流文件夹", false, Pri + 2)]
        public static void CopyTableToStreaming()
        {
            Copy(tableFolder, null);
        }

        /// <summary>
        /// 复制协议数据到流文件夹
        /// </summary>
        [MenuItem(menu + "复制协议数据到流文件夹", false, Pri + 3)]
        [MenuItem(AMenu + "复制协议数据到流文件夹", false, Pri + 3)]
        public static void CopyProtoToStreaming()
        {
            Copy(protoFolder, null);
        }

        /// <summary>
        /// 复制协议数据到流文件夹
        /// </summary>
        [MenuItem(menu + "复制清单文件到流文件夹", false, Pri + 4)]
        [MenuItem(AMenu + "复制清单文件到流文件夹", false, Pri + 4)]

        /// <summary>
        /// 拷贝清单文件
        /// </summary>
        public static void CopyManifest()
        {
            string src = string.Format("{0}/{1}", ABTool.Data.Output, AssetMf.Name);
            string dest = string.Format("{0}/{1}", Application.streamingAssetsPath, AssetMf.Name);
            FileTool.Copy(src, dest);
        }

        /// <summary>
        /// 复制所有资源到流文件夹
        /// </summary>
        [MenuItem(menu + "复制所有资源到流文件夹", false, Pri + 5)]
        [MenuItem(AMenu + "复制所有资源到流文件夹", false, Pri + 5)]
        public static void CopyAssetsToStreaming()
        {
            CopyABToStreaming();
            CopyTableToStreaming();
            CopyActionSetupToStreaming();
            CopyProtoToStreaming();
            CopyManifest();
        }

        /// <summary>
        /// 删除流文件夹所有资源
        /// </summary>
        [MenuItem(menu + "删除流文件夹所有资源", false, Pri + 6)]
        [MenuItem(AMenu + "删除流文件夹所有资源", false, Pri + 6)]
        public static void DeleteAssetsFromStreaming()
        {
            abFolder = EditUtil.GetPlatform();
            DeleteStreamingFolder(abFolder);
            DeleteStreamingFolder(tableFolder);
            DeleteStreamingFolder(actionFolder);
            DeleteStreamingFolder(protoFolder);
            DeleteManifest();
            AssetDatabase.Refresh();
            UIEditTip.Log("删除成功");
        }

        /// <summary>
        /// 打开持久化目录
        /// </summary>
        [MenuItem(menu + "打开持久化目录", false, Pri + 7)]
        [MenuItem(AMenu + "打开持久化目录", false, Pri + 7)]
        public static void OpenPersitentDir()
        {
            ProcessUtil.Start(Application.persistentDataPath, "持久化目录");
        }

        /// <summary>
        /// 打开临时缓存目录
        /// </summary>
        [MenuItem(menu + "打开临时缓存目录", false, Pri + 8)]
        [MenuItem(AMenu + "打开临时缓存目录", false, Pri + 8)]
        public static void OpenTempcacheDir()
        {
            ProcessUtil.Start(Application.temporaryCachePath, "临时缓存目录");
        }

        /// <summary>
        /// 清空持久化目录
        /// </summary>
        [MenuItem(menu + "清空持久化目录", false, Pri + 9)]
        [MenuItem(AMenu + "清空持久化目录", false, Pri + 9)]
        public static void ClearPersitentDir()
        {
            DirUtil.DeleteSub(Application.persistentDataPath);
            UIEditTip.Log("清空目录:{0}", Application.persistentDataPath);
        }

        /// <summary>
        /// 打开临时缓存路径
        /// </summary>
        [MenuItem(menu + "清空临时缓存目录", false, Pri + 10)]
        [MenuItem(AMenu + "清空临时缓存目录", false, Pri + 10)]
        public static void ClearTempcacheDir()
        {
            DirUtil.DeleteSub(Application.temporaryCachePath);
            UIEditTip.Log("清空目录:{0}", Application.temporaryCachePath);
        }
        #endregion
    }
}