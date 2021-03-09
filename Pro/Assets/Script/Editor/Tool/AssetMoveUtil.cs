/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/27 15:34:56
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
    /// 资源批量移动工具
    /// </summary>
    public static class AssetMoveUtil
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
        /// 移动指定路径资源到指定目录
        /// </summary>
        /// <param name="path">资源路径</param>
        /// <param name="dir">目录</param>
        /// <param name="filters">过滤字符列表</param>
        public static void Move(string path, string dir, List<string> filters = null)
        {
            var sfx = Path.GetExtension(path);
            if (string.IsNullOrEmpty(sfx)) return;
            if (sfx == Suffix.Shader) return;
            if (sfx == Suffix.CS) return;
            if (sfx == Suffix.Js) return;
            if (path.Contains("Editor")) return;
            if (path.Contains("Resources")) return;
            if (filters != null && filters.Count > 0)
            {
                var length = filters.Count;
                for (int i = 0; i < length; i++)
                {
                    var filter = filters[i];
                    if (string.IsNullOrEmpty(filter)) continue;
                    if (path.Contains(filter))
                    {
                        return;
                    }
                }
            }
            var name = Path.GetFileName(path);
            string nPath = Path.Combine(dir, name);
            AssetDatabase.MoveAsset(path, nPath);
        }


        /// <summary>
        /// 移动选择的资源/包含依赖到指定目录
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="filters">过滤字符列表</param>
        public static void MoveSelect(string dir, List<string> filters = null)
        {
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            dir = FileUtil.GetProjectRelativePath(dir);
            var objs = SelectUtil.Get<Object>();
            if (objs == null) return;
            float length = objs.Length;
            List<string> lst = null;
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                var sfx = Path.GetExtension(path);
                ProgressBarUtil.Show("搜集中···", path, i / length);
                if (string.IsNullOrEmpty(sfx)) continue;
                if (lst == null) lst = new List<string>();
                lst.Add(path);
            }
            if (lst == null) return;
            var paths = AssetDatabase.GetDependencies(lst.ToArray());

            length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                ProgressBarUtil.Show("移动中···", path, i / length);
                Move(path, dir, filters);
            }
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }
        #endregion
    }
}