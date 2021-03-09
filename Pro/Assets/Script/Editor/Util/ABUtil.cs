/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/1 2:11:27
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 资源包工具
    /// </summary>
    public static class ABUtil
    {
        #region 字段

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
        /// 获取工程内资源包
        /// </summary>
        /// <param name="dir"></param>
        /// <param name="paths"></param>
        /// <returns></returns>
        public static long GetSize(string dir, string[] paths)
        {
            if (!Directory.Exists(dir)) return 0;
            var title = "搜集依赖···";
            var pro = UnityEngine.Random.Range(0.2f, 1f);
            ProgressBarUtil.Show("", title, pro);
            var depends = AssetDatabase.GetDependencies(paths);
            title = "计算";
            var nameSet = new HashSet<string>();
            long total = 0;
            float dLen = depends.Length;
            for (int i = 0; i < dLen; i++)
            {
                var dPath = depends[i];
                var sfx = Path.GetExtension(dPath);
                if (!AssetUtil.IsValidSfx(sfx)) continue;
                ProgressBarUtil.Show(title, dPath, i / dLen);
                var ai = AssetImporter.GetAtPath(dPath);
                if (ai == null) continue;
                var abName = ai.assetBundleName;
                if (string.IsNullOrEmpty(abName)) continue;
                var variant = ai.assetBundleVariant;
                if (!string.IsNullOrEmpty(variant))
                {
                    abName = string.Format("{0}.{1}", abName, variant);
                }
                if (nameSet.Contains(abName)) continue;
                nameSet.Add(abName);
                string abPath = Path.Combine(dir, abName);
                if (!File.Exists(abPath)) continue;
                var fi = new FileInfo(abPath);
                total += fi.Length;
            }
            ProgressBarUtil.Clear();
            return total;
        }

        /// <summary>
        /// 校验AB有效性
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static List<string> Check(string dir)
        {
            if (!Directory.Exists(dir)) return null;
            var files = Directory.GetFiles(dir, "*.ab", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return null;
            List<string> lst = null;
            var title = "检查AB";
            float len = files.Length;
            for (int i = 0; i < len; i++)
            {
                var path = files[i];
                ProgressBarUtil.Show(title, path, i / len);
                try
                {
                    var ab = AssetBundle.LoadFromFile(path);
                    ab.Unload(true);
                }
                catch (Exception)
                {
                    if (lst == null) lst = new List<string>();
                    lst.Add(path);
                }
            }
            ProgressBarUtil.Clear();
            EditorUtility.UnloadUnusedAssetsImmediate();
            GC.Collect();
            return lst;
        }

        #endregion
    }
}