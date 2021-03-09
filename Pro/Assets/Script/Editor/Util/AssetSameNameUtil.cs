/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/28 23:48:56
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
    /// 资源重名工具
    /// </summary>
    public static class AssetSameNameUtil
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
        /// 搜索
        /// </summary>
        /// <param name="dir">资源目录</param>
        /// <returns>重名路径列表的字典,k:文件名,v:文件路径列表</returns>
        public static Dictionary<string, List<string>> Find(List<string> dirs)
        {
            if (dirs == null) return null;
            int dirLen = dirs.Count;
            var dic = new Dictionary<string, List<string>>();
            for (int j = 0; j < dirLen; j++)
            {
                var dir = dirs[j];
                if (!Directory.Exists(dir)) continue;
                var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
                if (files == null || files.Length < 1) continue;

                string rDir = FileUtil.GetProjectRelativePath(dir);
                string title = string.Format("检查中···,{0}", rDir);
                float length = files.Length;
                for (int i = 0; i < length; i++)
                {
                    var path = files[i];
                    ProgressBarUtil.Show(title, path, i / length);
                    var sfx = Path.GetExtension(path);
                    if (sfx == Suffix.Meta) continue;
                    if (sfx == Suffix.CS) continue;
                    if (sfx == Suffix.Js) continue;
                    var name = Path.GetFileName(path);
                    if (name == LightingDataUtil.LightingDataName) continue;
                    List<string> lst = null;
                    if (dic.ContainsKey(name))
                    {
                        lst = dic[name];
                    }
                    else
                    {
                        lst = new List<string>();
                        dic.Add(name, lst);
                    }
                    var rPath = FileUtil.GetProjectRelativePath(path);
                    lst.Add(rPath);
                }
            }

            ProgressBarUtil.Clear();
            var oneKeys = new List<string>();
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                if (it.Value.Count < 2)
                {
                    oneKeys.Add(it.Key);
                }
            }

            int oneKeyLen = oneKeys.Count;
            for (int i = 0; i < oneKeyLen; i++)
            {
                var key = oneKeys[i];
                dic.Remove(key);
            }
            EditorUtility.UnloadUnusedAssetsImmediate();
            return dic;
        }

        /// <summary>
        /// 删除重名路径列表中具有指定字符的资源
        /// </summary>
        /// <param name="dic"></param>
        /// <param name="keyword"></param>
        public static void Delete(Dictionary<string, List<string>> dic, string keyword)
        {
            if (dic == null) return;
            if (string.IsNullOrEmpty(keyword)) return;
            float count = dic.Count;
            string title = "删除中···";
            int idx = 0;
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                var lst = it.Value;
                int length = lst.Count;
                for (int i = 0; i < length; i++)
                {
                    ++idx;
                    var path = lst[i];
                    if (!path.Contains(keyword)) continue;
                    if (AssetDatabase.DeleteAsset(path))
                    {
                        iTrace.Log("Loong", string.Format("删除:{0} 成功", path));
                    }
                    ProgressBarUtil.Show(title, path, idx / count);
                }
            }
            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 将重名列表中的资源进行移动覆盖
        /// </summary>
        /// <param name="paths">重名资源路径列表</param>
        /// <param name="fromIdx">要移动的索引</param>
        /// <param name="toIdx">将要移动的索引</param>
        public static bool Ovrrite(List<string> paths, int fromIdx, int toIdx)
        {
            var length = paths.Count;
            if (length < 2) return false;
            if (toIdx >= length) return false;
            if (fromIdx >= length) return false;
            if (fromIdx == toIdx) return false;

            var srcPath = paths[fromIdx];
            var destPath = paths[toIdx];
            var cur = Directory.GetCurrentDirectory();
            var destFullPath = Path.Combine(cur, destPath);
            if (!File.Exists(destFullPath))
            {
                AssetDatabase.DeleteAsset(destPath);
            }
            AssetDatabase.MoveAsset(srcPath, destPath);
            paths.RemoveAt(fromIdx);
            return true;

        }
        #endregion
    }
}