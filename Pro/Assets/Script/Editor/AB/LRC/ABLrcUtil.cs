//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/28 20:32:05
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
    /// 资源包冗余工具
    /// </summary>
    public static class ABLrcUtil
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = ABTool.Pri + 20;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = ABTool.menu + "冗余工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = ABTool.AMenu + "冗余工具/";

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 搜索制定AB目录,返回指定类型的资源列表
        /// </summary>
        /// <param name="dir">AB目录</param>
        /// <param name="type">资源类型</param>
        /// <param name="lst">列表</param>
        /// <returns></returns>
        public static List<string> SearchPath(string dir, AssetType type, List<string> lst = null, bool isName = true)
        {
            if (string.IsNullOrEmpty(dir)) return null;
            if (!Directory.Exists(dir)) return null;
            var pattern = "*" + Suffix.AB + "*";
            var files = Directory.GetFiles(dir, pattern, SearchOption.AllDirectories);
            if (files == null) return null;
            if (lst == null) lst = new List<string>();
            var title = "搜集中";
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                var abName = Path.GetFileName(path);
                var name2 = Path.GetFileNameWithoutExtension(abName);
                var sfx = Path.GetExtension(name2);
                if (AssetQueryUtil.Contains(type, sfx))
                {
                    lst.Add(isName ? abName : path);
                }
                ProgressBarUtil.Show(title, abName, i / length);
            }
            ProgressBarUtil.Clear();
            return lst;
        }

        /// <summary>
        /// 搜索AB目录,具有指定类型的资源所关联引用的AB名称集合
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        public static HashSet<string> SearchNames(string dir, AssetType type)
        {
            var names = SearchPath(dir, type, null);
            if (names == null || names.Count < 1) return null;
            var set = new HashSet<string>();
            var title = "设置工程内路径";
            float length = names.Count;
            for (int i = 0; i < length; i++)
            {
                var name = names[i];
                set.Add(name);
                var arr = AssetDatabase.GetAssetBundleDependencies(name, true);
                if (arr == null) continue;
                int arrLen = arr.Length;
                for (int j = 0; j < arrLen; j++)
                {
                    var abName = arr[j];
                    if (set.Contains(abName)) continue;
                    set.Add(abName);
                }
                ProgressBarUtil.Show(title, name, i / length);
            }
            return set;
        }


        /// <summary>
        /// 搜索指定AB目录,具有指定类型的AB信息
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        public static List<ABFileInfo> Search(string dir, AssetType type)
        {
            var paths = SearchPath(dir, type, null, false);
            return Search(paths, type);
        }

        /// <summary>
        /// 搜索指定资源列表中，具有指定类型的AB信息
        /// </summary>
        /// <param name="paths">路径</param>
        /// <param name="type">指定类型</param>
        /// <returns></returns>
        public static List<ABFileInfo> Search(List<string> paths, AssetType type)
        {
            if (paths == null || paths.Count < 1) return null;
            float length = paths.Count;
            var lst = new List<ABFileInfo>();
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                var info = Create(path);
                lst.Add(info);
            }
            return lst;
        }

        public static ABFileInfo Create(string path)
        {
            var info = new ABFileInfo();
            var fi = new FileInfo(path);
            info.DiskUsage = fi.Length;
            var abName = Path.GetFileName(path);
            info.abName = abName;
            var arr = AssetDatabase.GetAssetPathsFromAssetBundle(abName);
            info.assetPaths = new List<string>(arr);
            return info;
        }

        /// <summary>
        /// 比较,搜索指定目录类的指定类型的AB,然后将在工程中的
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        public static List<ABFileInfo> Compare(string dir, AssetType type)
        {
            if (!Directory.Exists(dir)) return null;
            var set = SearchNames(dir, type);
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            var title = "比较中···";
            var plat = EditUtil.GetPlatform();
            var infos = new List<ABFileInfo>();
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                var name = Path.GetFileName(path);
                ProgressBarUtil.Show(title, name, i / length);
                if (set.Contains(name)) continue;
                if (name == plat) continue;
                var info = Create(path);
                infos.Add(info);
            }
            infos.Sort();
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            return infos;
        }

        #endregion
    }
}