/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/27 17:47:56
 * 通过指定要比对的文件类型,将其所有依赖的资源和其所在的目录的资源做个比对
 * 若目录资源不再其依赖的资源列表中,则此资源是冗余的
 ============================================================================*/

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
    /// 资源冗余检查工具
    /// </summary>
    public static class AssetLrcUtil
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
        /// 检查资源是否有效
        /// </summary>
        /// <returns></returns>
        public static bool ValidSfx(string sfx)
        {
            if (sfx == Suffix.CS) return false;
            if (sfx == Suffix.Meta) return false;
            if (sfx == Suffix.Js) return false;
            return true;
        }

        /// <summary>
        /// 将指定资源列表的所有依赖资源和指定目录的所有资源进行差异化比对
        /// </summary>
        /// <param name="paths">指定资源列表</param>
        /// <param name="dir">目录</param>
        /// <returns>差异化资源路径列表</returns>
        public static List<string> Get(List<string> paths, string dir)
        {
            if (paths == null) return null;
            if (string.IsNullOrEmpty(dir)) return null;
            if (!Directory.Exists(dir)) return null;
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            if (files == null) return null;
            var pro = UnityEngine.Random.Range(0.2f, 1f);
            var msg = "搜集依赖中···";
            ProgressBarUtil.Show("", msg, pro);
            var depends = AssetDatabase.GetDependencies(paths.ToArray());
            var set = new HashSet<string>();
            float dLen = depends.Length;
            for (int i = 0; i < dLen; i++)
            {
                var path = depends[i];
                ProgressBarUtil.Show("", msg, i / dLen);
                string sfx = Path.GetFileName(path);
                if (!ValidSfx(sfx)) continue;
                set.Add(depends[i]);
            }
            List<string> lst = null;
            float length = files.Length;
            var msg2 = "比对中···";
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                ProgressBarUtil.Show("", msg2, i / dLen);
                var rPath = FileUtil.GetProjectRelativePath(path);
                rPath = rPath.Replace('\\', '/');
                if (set.Contains(rPath)) continue;
                if (lst == null) lst = new List<string>();
                var sfx = Path.GetExtension(rPath);
                if (!ValidSfx(sfx)) continue;
                lst.Add(rPath);
            }
            ProgressBarUtil.Clear();
            return lst;
        }
        #endregion
    }
}