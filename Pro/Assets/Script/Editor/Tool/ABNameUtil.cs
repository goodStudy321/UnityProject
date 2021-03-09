/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2018/2/4 14:55:23
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
    using NameDic = Dictionary<string, List<string>>;
    /// <summary>
    /// 资源包名称工具
    /// </summary>
    public static class ABNameUtil
    {
        #region 字段
        public const int Pri = ABTool.Pri + 20;

        /// <summary>
        /// true:所有的shader打成一个ab
        /// </summary>
        public static bool oneShader = true;

        /// <summary>
        /// shader AB名称
        /// </summary>
        public const string shaderName = "shader";

        /// <summary>
        /// lua AB名称
        /// </summary>
        public const string luaName = "lua.bytes";

        /// <summary>
        /// AB 变体后缀名
        /// </summary>
        public static readonly string variant = Suffix.AB.Replace(".", string.Empty);
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void RefreshAssets()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 向列表中添加指定ab名称的路径
        /// </summary>
        /// <param name="all"></param>
        /// <param name="name"></param>
        private static void Add(List<string> all, string name)
        {
            var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1) return;
            int length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                all.Add(paths[i]);
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 显示指定包名的资源路径
        /// </summary>
        /// <param name="name"></param>
        public static void Search(string name)
        {
            if (string.IsNullOrEmpty(name))
            {
                UIEditTip.Error("名称为空");
                return;
            }
            name = name.ToLower();
            var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1)
            {
                UIEditTip.Log("无"); return;
            }
            ObjsWin.Open(paths);
        }


        /// <summary>
        /// 显示具有指定后缀名的资源包
        /// </summary>
        /// <param name="sfx">后缀名</param>
        public static void SearchBySfx(string sfx)
        {
            if (string.IsNullOrEmpty(sfx)) return;
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            if (names == null || names.Length < 1) return;
            float length = names.Length;
            var all = new List<string>();
            for (int i = 0; i < length; i++)
            {
                var name = names[i];
                ProgressBarUtil.Show("", name, i / length);
                string sSfx = Path.GetExtension(name);
                if (sfx != sSfx) continue;
                Add(all, name);
            }
            ProgressBarUtil.Clear();
            ObjsWin.Open(all);
        }

        /// <summary>
        /// 显示包含指定字符串的资源包名称
        /// </summary>
        /// <param name="op"></param>
        public static void SearchByStr(string op)
        {
            if (string.IsNullOrEmpty(op)) return;
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            if (names == null || names.Length < 1) return;
            var all = new List<string>();
            float length = names.Length;
            for (int i = 0; i < length; i++)
            {
                var name = names[i];
                ProgressBarUtil.Show("", name, i / length);
                if (!name.Contains(op)) continue;
                Add(all, name);
            }
            ObjsWin.Open(all);
            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 刷新所有资源的的AB名称
        /// </summary>
        public static void Refresh()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            if (names == null || names.Length < 1)
            {
                iTrace.Log("Loong", "无 AB"); return;
            }

            int pathsLen = 0;
            float length = names.Length;
            for (int i = 0; i < length; i++)
            {
                string name = names[i];
                ProgressBarUtil.Show("", name, i / length);
                var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
                if (paths == null || paths.Length < 1) continue;
                pathsLen = paths.Length;
                for (int j = 0; j < pathsLen; j++)
                {
                    string path = paths[j];
                    Set(path);
                }
            }
            ProgressBarUtil.Clear();
            RefreshAssets();
        }

        /// <summary>
        /// 设置所有shader的名称
        /// </summary>
        public static void SetShader()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            if (names == null || names.Length < 1) return;
            float length = names.Length;
            for (int i = 0; i < length; i++)
            {
                string name = names[i];
                ProgressBarUtil.Show("", name, i / length);
                if (!name.Contains("shader")) continue;
                var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
                int plen = paths.Length;
                for (int j = 0; j < plen; j++)
                {
                    Set(paths[j]);
                }
            }
            ProgressBarUtil.Clear();
            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 设置资源包名称
        /// </summary>
        /// <param name="path">资源路径</param>
        public static void Set(string path, bool force = true)
        {
            string sfx = Path.GetExtension(path);
            if (!AssetUtil.IsValidSfx(sfx)) return;
            string name = Path.GetFileName(path);
            if (name == LightingDataUtil.LightingDataName) return;
            AssetImporter ai = AssetImporter.GetAtPath(path);
            if (ai == null) return;
            name = name.ToLower();
            if (sfx == Suffix.Bytes)
            {
                var aName = Path.GetFileNameWithoutExtension(name);
                var aSfx = Path.GetExtension(aName);
                if (aSfx == Suffix.Lua)
                {
                    SetNoABSfx(ai, luaName);
                }
                else if (name == CSHotfixUtil.fileName)
                {
                    SetNoABSfx(ai, CSHotfixUtil.fileName);
                }
                else
                {
                    SetUnique(ai, name);
                }
            }
            else if (sfx == Suffix.Shader)
            {
                if (oneShader)
                {
                    Set(ai, shaderName);
                }
                else
                {
                    SetUnique(ai, name);
                }
            }
            else if (force)
            {
                SetUnique(ai, name);
            }
            else
            {
                if (sfx == Suffix.Prefab)
                {
                    SetUnique(ai, name);
                }
                else if (string.IsNullOrEmpty(ai.assetBundleName))
                {
                    SetUnique(ai, name);
                }
            }
        }

        /// <summary>
        /// 设置指定路径shader的包名
        /// </summary>
        /// <param name="path"></param>
        public static void SetShader(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            string sfx = Path.GetExtension(path);
            if (sfx != Suffix.Shader) return;
            AssetImporter import = AssetImporter.GetAtPath(path);
            Set(import, shaderName);
        }

        /// <summary>
        /// 设置指定路径资源为指定包名
        /// </summary>
        /// <param name="path">资源路径</param>
        /// <param name="name">包名</param>
        public static void Set(string path, string name)
        {
            var ai = AssetImporter.GetAtPath(path);
            Set(ai, name);
        }

        /// <summary>
        /// 设置指定名称
        /// </summary>
        /// <param name="ai">资源</param>
        /// <param name="name">AB名称</param>
        public static void Set(AssetImporter ai, string name)
        {
            if (ai == null) return;
            if (ai.assetBundleName != name)
            {
                ai.assetBundleName = name;
            }
            if (ai.assetBundleVariant != variant)
            {
                ai.assetBundleVariant = variant;
            }
        }

        /// <summary>
        /// 设置指定名称/无AB后缀
        /// </summary>
        /// <param name="ai"></param>
        /// <param name="name">AB名称</param>
        public static void SetNoABSfx(AssetImporter ai, string name)
        {
            if (ai == null) return;
            if (ai.assetBundleName != name)
            {
                ai.assetBundleName = name;
            }
            ai.assetBundleVariant = null;
        }

        /// <summary>
        /// 设置唯一名称/和文件名一致(包含后缀名)
        /// </summary>
        /// <param name="ai"></param>
        /// <param name="name"></param>
        public static void SetUnique(AssetImporter ai, string name)
        {
            if (ai.assetBundleName != name)
            {
                if (CheckUnique(name))
                {
                    ai.assetBundleName = name;
                }
                else
                {
                    string tip = string.Format("导入的文件:{0},和其它文件重名", ai.assetPath);
                    iTrace.Error("Loong", tip);
                }
            }
            if (ai.assetBundleVariant != variant)
            {
                ai.assetBundleVariant = variant;
            }
        }



        /// <summary>
        /// 设置所有选择对象的包名
        /// </summary>
        /// <param name="name">包名</param>
        public static void SetSelect(string name, SelectionMode mode = SelectionMode.Assets)
        {
            var objs = SelectUtil.Get<Object>(mode);
            if (objs == null) return;
            float length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                if (string.IsNullOrEmpty(path)) continue;
                var sfx = Path.GetExtension(path);
                if (AssetUtil.IsValidSfx(sfx))
                {
                    Set(path, name);
                }
            }
            RefreshAssets();
        }

        /// <summary>
        /// 设置指定资源列表为同一包名
        /// </summary>
        /// <param name="paths">资源路径列表</param>
        /// <param name="name">包名</param>
        public static void Set(List<string> paths, string name)
        {
            if (paths == null) return;
            if (string.IsNullOrEmpty(name)) return;
            float length = paths.Count;
            var title = string.Format("设置包名:{0}", name);
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                ProgressBarUtil.Show(title, path, i / length);
                Set(path, name);
            }

            ProgressBarUtil.Clear();
            RefreshAssets();
        }

        /// <summary>
        /// 检查是否唯一名称
        /// </summary>
        /// <param name="name">资源包名称</param>
        public static bool CheckUnique(string name)
        {
            string[] paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1) return true;
            return false;
        }

        /// <summary>
        /// 获取无AB名的资源路径列表
        /// </summary>
        /// <param name="dirs"></param>
        /// <returns></returns>
        public static List<string> GetPathsNone(List<string> dirs)
        {
            if (dirs == null || dirs.Count < 1) return null;
            var sets = new HashSet<string>();
            var curLen = dirs.Count;
            var cur = Directory.GetCurrentDirectory();
            for (int i = 0; i < curLen; i++)
            {
                var dir = dirs[i];
                var fullDir = Path.Combine(cur, dir);
                if (!Directory.Exists(fullDir)) continue;
                var files = Directory.GetFiles(fullDir, "*.*", SearchOption.AllDirectories);
                if (files == null || files.Length < 1) continue;
                float fileLen = files.Length;
                for (int j = 0; j < fileLen; j++)
                {
                    var file = files[j];
                    var sfx = Path.GetExtension(file);
                    if (sfx == Suffix.Meta) continue;
                    if (sfx == Suffix.CS) continue;
                    if (sfx == Suffix.Js) continue;
                    var name = Path.GetFileName(file);
                    if (name == LightingDataUtil.LightingDataName) continue;
                    file = file.Replace('\\', '/');
                    var rPath = FileUtil.GetProjectRelativePath(file);
                    var ai = AssetImporter.GetAtPath(rPath);
                    if (ai == null) continue;
                    if (!string.IsNullOrEmpty(ai.assetBundleName)) continue;
                    if (sets.Contains(rPath)) continue;
                    sets.Add(rPath);
                    ProgressBarUtil.Show(dir, file, j / fileLen);
                }
            }
            if (sets.Count < 1) return null;
            ProgressBarUtil.Clear();
            var lst = new List<string>();
            var em = sets.GetEnumerator();
            while (em.MoveNext())
            {
                lst.Add(em.Current);
            }
            EditorUtility.UnloadUnusedAssetsImmediate();
            return lst;
        }


        /// <summary>
        /// 获取字典,k:ab名称,v:资源名称(小写)列表
        /// </summary>
        /// <returns></returns>
        public static NameDic GetDic()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var abnames = AssetDatabase.GetAllAssetBundleNames();
            var dic = new NameDic();
            float len = abnames.Length;
            var title = "获取资源包名";
            for (int i = 0; i < len; i++)
            {
                var an = abnames[i];
                ProgressBarUtil.Show(title, an, i / len);
                var paths = AssetDatabase.GetAssetPathsFromAssetBundle(an);

                if (paths == null || paths.Length < 1) continue;
                List<string> lst = null;
                if (dic.ContainsKey(an))
                {
                    lst = dic[an];
                }
                else
                {
                    lst = new List<string>();
                    dic.Add(an, lst);
                }
                int nameLen = paths.Length;
                for (int j = 0; j < nameLen; j++)
                {
                    var path = paths[j];
                    var name = Path.GetFileName(path);
                    lst.Add(name.ToLower());
                }
            }
            ProgressBarUtil.Clear();
            return dic;
        }



        public static void SearchNotSame(AssetType type)
        {
            var dir = SelectUtil.GetDir();
            if (string.IsNullOrEmpty(dir))
            {
                UIEditTip.Warning("未选择目录"); return;
            }
            var lst = AssetQueryUtil.Search(dir, type);
            if (lst == null || lst.Count == 0)
            {
                UIEditTip.Warning("未查询到:{0}", type); return;
            }

            var difs = new List<string>();
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var path = lst[i];
                var ai = AssetImporter.GetAtPath(path);
                var abName = ai.assetBundleName;
                if (string.IsNullOrEmpty(abName)) continue;
                var finame = Path.GetFileName(path);
                finame = finame.ToLower();
                if (finame != abName)
                {
                    difs.Add(path);
                }
            }

            if (difs.Count < 0)
            {
                UIEditTip.Warning("未查询到");
            }
            else
            {
                ObjsWin.Open(difs);
            }
        }

        public static void SearchSame()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            var dic = new Dictionary<string, List<string>>();
            var title = "搜索同名";
            var objs = new List<string>();
            float length = names.Length;
            for (int i = 0; i < length; i++)
            {
                var abname = names[i];
                ProgressBarUtil.Show(title, abname, i / length);
                var paths = AssetDatabase.GetAssetPathsFromAssetBundle(abname);
                var pathLen = paths.Length;
                for (int j = 0; j < pathLen; j++)
                {
                    var path = paths[j];
                    var name = Path.GetFileName(path);
                    name = name.ToLower();
                    if (dic.ContainsKey(name))
                    {
                        dic[name].Add(path);
                    }
                    else
                    {
                        var lst = new List<string>();
                        lst.Add(path);
                        dic.Add(name, lst);
                    }
                }
            }
            foreach (var it in dic.Values)
            {
                if (it.Count < 2) continue;
                objs.AddRange(it);
            }

            ProgressBarUtil.Clear();
            ObjsWin.Open(objs);
        }


        public static void SearchNo()
        {
            var allAB = AssetDatabase.GetAllAssetBundleNames();
            var title = "请稍候";
            var names = new List<string>();
            float length = allAB.Length;
            for (int i = 0; i < length; i++)
            {
                var abName = allAB[i];
                var arr = AssetDatabase.GetAssetPathsFromAssetBundle(abName);
                names.AddRange(arr);
                ProgressBarUtil.Show(title, abName, i / length);
            }
            title += ",可能耗时较长";
            ProgressBarUtil.Show(title, "");
            var depends = AssetDatabase.GetDependencies(names.ToArray());
            title = "检查未设置AB名称资源";
            var lst = new List<string>();
            length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                var assetPath = depends[i];
                var assetName = Path.GetFileName(assetPath);
                ProgressBarUtil.Show(title, assetPath, i / length);
                if (assetName == LightingDataUtil.LightingDataName) continue;
                var sfx = Path.GetExtension(assetName);
                if (sfx == Suffix.CS) continue;
                if (sfx == Suffix.Js) continue;

                var ai = AssetImporter.GetAtPath(assetPath);
                if (ai == null) continue;
                if (string.IsNullOrEmpty(ai.assetBundleName))
                {
                    lst.Add(assetPath);
                }
            }
            ProgressBarUtil.Clear();
            ObjsWin.Open(lst);
        }


        [MenuItem(ABTool.menu + "搜索AB名和文件名不一致/材质", false, Pri)]
        [MenuItem(ABTool.AMenu + "搜索AB名和文件名不一致/材质", false, Pri)]
        public static void SearchMatNotSame()
        {
            SearchNotSame(AssetType.Mat);
        }


        [MenuItem(ABTool.menu + "搜索文件名AB名相同", false, Pri + 1)]
        [MenuItem(ABTool.AMenu + "搜索文件名AB名相同", false, Pri + 1)]
        public static void SearchSameDialog()
        {
            DialogUtil.Show("", "检查?", SearchSame);
        }


        [MenuItem(ABTool.menu + "搜索未设置AB资源", false, Pri + 1)]
        [MenuItem(ABTool.AMenu + "搜索未设置AB资源", false, Pri + 1)]
        public static void SearchNoDialog()
        {
            DialogUtil.Show("", "搜索未设置AB资源?", SearchNo);
        }

        #endregion
    }
}