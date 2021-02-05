using System;
using System.IO;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    using NameDic = Dictionary<string, List<string>>;

    public static class ABNameUtil
    {
        public const int Pri = ABTool.Pri + 20;

        public static bool oneShader = true;

        public const string shaderName = "shader";

        public const string luaName = "lua.bytes";

        public static readonly string variant = Suffix.AB.Replace(".", string.Empty);

        private static void RefreshAssets()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            AssetDatabase.Refresh();
        }

        private static void Add(List<string> all,string name)
        {
            var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1) return;
            int length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                all.Add(paths[i]);
            }
        }

        public static void Search(string name)
        {
            if (string.IsNullOrEmpty(name))
            {
                UIEditTip.Error("名称为空");
                return;
            }
            name = name.ToLower();
            var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if(paths == null || paths.Length < 1)
            {
                UIEditTip.Log("无");
                return;
            }
            ObjsWin.Open(paths);
        }

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

        public static void Refresh()
        {
            AssetDatabase.RemoveUnusedAssetBundleNames();
            var names = AssetDatabase.GetAllAssetBundleNames();
            if(names == null || names.Length < 1)
            {
                iTrace.Log("Hello", " 无 AB");
                return;
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

        public static void SetShader(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            string sfx = Path.GetExtension(path);
            if (sfx != Suffix.Shader) return;
            AssetImporter import = AssetImporter.GetAtPath(path);
            Set(import, shaderName);
        }

        public static void Set(string path,string name)
        {
            var ai = AssetImporter.GetAtPath(path);
            Set(ai, name);
        }

        public static void Set(AssetImporter ai,string name)
        {
            if (ai == null) return;
            if(ai.assetBundleName != name)
            {
                ai.assetBundleName = name;
            }
            if(ai.assetBundleVariant != variant)
            {
                ai.assetBundleVariant = variant;
            }
        }

        public static void SetNoABSfx(AssetImporter ai,string name)
        {
            if (ai == null) return;
            if(ai.assetBundleName != name)
            {
                ai.assetBundleName = name;
            }
            ai.assetBundleVariant = null;
        }

        public static void SetUnique(AssetImporter ai,string name)
        {
            if(ai.assetBundleName != name)
            {
                if (CheckUnique(name))
                {
                    ai.assetBundleName = name;
                }
                else
                {
                    string tip = string.Format("导入的文件:{0}，和其他文件重名", ai.assetPath);
                    iTrace.Error("Hello", tip);
                }
            }
            if(ai.assetBundleVariant != variant)
            {
                ai.assetBundleVariant = variant;
            }
        }

        public static void SetSelect(string name,SelectionMode mode = SelectionMode.Assets)
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

        public static bool CheckUnique(string name)
        {
            string[] paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1) return true;
            return false;
        }

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

    }
}


