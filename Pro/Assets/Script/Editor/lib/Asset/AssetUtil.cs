using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    public static partial class AssetUtil
    {
        public const int Pri = MenuTool.AssetPri + 30;

        public const string menu = MenuTool.Hello + "资源工具/";

        public const string AMenu = MenuTool.AHello + "资源工具/";

        private static void SetValidName(bool delete)
        {
            Object[] objs = GetFiltered();
            if (objs == null || objs.Length == 0) return;
            float len = objs.Length;
            bool hasInvalid = false;
            string curDir = Directory.GetCurrentDirectory();
            for (int i = 0; i < len; i++)
            {
                string path = AssetDatabase.GetAssetPath(objs[i]);
                ProgressBarUtil.Show("", "正在玩命检查中...", i / len);
                if (objs[i] == null)
                {
                    iTrace.Log("检查名称有效性: ", string.Format("这是一个无效资源: {0}", path));
                    continue;
                }
                string suffix = Suffix.Get(path);
                if (!IsValidSfx(suffix)) continue;
                string fileName = Path.GetFileNameWithoutExtension(path);

                string newName = GetValidName(fileName);
                if (fileName == newName) continue;
                hasInvalid = true;
                string dir = Path.GetDirectoryName(path);
                string newPath = string.Format("{0}/{1}{2}", dir, newName, suffix);
                string newFullPath = string.Format("{0}/{1}", curDir, newPath);
                if (delete)
                {
                    if (File.Exists(newFullPath))
                    {
                        AssetDatabase.DeleteAsset(path);
                        iTrace.Log("检查资源名称有效性", string.Format("资源:{0},合法化后资源:{1},已经存在，删除原始资源:{2}", fileName, newName, path));
                    }
                }
                else
                {
                    AssetDatabase.RenameAsset(path, newName);
                    iTrace.Log("检查资源名称有效性", string.Format("路径为:{0}的资源名称中包含无效字符 '空格!@#$%^&—' ,已自动命名为:{1}", path, newName));
                }
            }
            if (hasInvalid)
            {
                UIEditTip.Warning("检查完成,可以通过白色输出查看详细内容");
            }
            else
            {
                UIEditTip.Log("检查完成,资源名称全部是有效的");
            }
            EditorUtility.UnloadUnusedAssetsImmediate();
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        public static bool IsValidSfx(string sfx)
        {
            if (string.IsNullOrEmpty(sfx)) return false;
            if (sfx == Suffix.CS) return false;
            if (sfx == Suffix.Js) return false;
            if (sfx == Suffix.Lua) return false;
            if (sfx == Suffix.Zip) return false;
            if (sfx == Suffix.AB) return false;
            if (sfx == Suffix.Meta) return false;
            if (sfx == Suffix.Manifest) return false;
            if (sfx == Suffix.Psd) return false;
            if (sfx == ".tbl") return false;
            if (sfx == ".dll") return false;
            return true;
        }

        public static string GetValidName(string name)
        {
            string newName = name.Replace(" ", "");
            newName = newName.Replace("!", "");
            newName = newName.Replace("#", "");
            newName = newName.Replace("@", "");
            newName = newName.Replace("$", "");
            newName = newName.Replace("%", "");
            newName = newName.Replace("^", "");
            newName = newName.Replace("&", "");
            newName = newName.Replace("—", "");
            return newName;
        }

        public static bool IsValidNameNoEx(string name)
        {
            int length = name.Length;
            for (int i = 0; i < length; i++)
            {
                var c = name[i];
                int a = c;
                if (c == '_') continue;
                if (c == '-') continue;
                if (c == '@') continue;
                if (a > 96 && a < 123) continue;
                if (a > 64 && a < 91) continue;
                if (a > 47 && a < 58) continue;
                return false;
            }
            return true;
        }

        public static void IsValidName(string[] paths)
        {
            if (paths == null) return;
            int length = paths.Length;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                if((!path.StartsWith(EditSceneView.prefix))&& (!path.StartsWith(EditSceneView.packPrefix)))
                {
                    continue;
                }
                var sfx = Path.GetExtension(path);
                var name = Path.GetFileNameWithoutExtension(path);
                string err = null;
                if(sfx == Suffix.Psd)
                {
                    err = string.Format("非法后缀:{0}", path);
                }
                else if (!IsValidNameNoEx(name))
                {
                    err = string.Format("非法字符:{0}", path);
                }
                if (err == null) continue;
                iTrace.Error("Hello", err);
                DialogUtil.Show("", err);
            }
        }

        public static Object[] GetFiltered()
        {
            float pro = UnityEngine.Random.Range(0.1f, 0.8f);
            ProgressBarUtil.Show("请稍候", "收集资源中···", pro);
            Object[] objs = Selection.GetFiltered(typeof(Object), SelectionMode.DeepAssets);
            ProgressBarUtil.Clear();
            if (objs == null || objs.Length == 0)
            {
                string tip = "请选择文件夹或者文件";
                EditorUtility.DisplayDialog("", tip, "确定");
            }
            return objs;
        }

        public static string[] GetSelectDepends()
        {
            Object[] objs = Selection.GetFiltered<Object>(SelectionMode.DeepAssets);
            if (objs == null || objs.Length == 0)
            {
                UIEditTip.Error("请选择资源"); return null;
            }
            return GetDepends(objs);
        }

        public static string[] GetDepends(Object[] objs)
        {
            if (objs == null) return null;
            if (objs.Length == 0) return null;
            List<string> paths = null;
            int length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                Object obj = objs[i];
                if (obj == null) continue;
                string path = AssetDatabase.GetAssetPath(obj);
                if (string.IsNullOrEmpty(path)) continue;
                if (paths == null) paths = new List<string>();
                if (paths.Contains(path)) continue;
                paths.Add(path);
            }
            string[] pathArr = paths.ToArray();
            string[] depends = AssetDatabase.GetDependencies(pathArr);
            return depends;
        }

        public static void Delete(List<string> paths)
        {
            if (paths == null || paths.Count < 1)
            {
                UIEditTip.Warning("无资源"); return;
            }
            float length = paths.Count;
            var title = "删除";
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                ProgressBarUtil.Show(title, path, i / length);
                AssetDatabase.DeleteAsset(path);
            }
            paths.Clear();
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        public static void Delete(Object o)
        {
            if (o == null) return;
            var path = AssetDatabase.GetAssetPath(o);
            if (string.IsNullOrEmpty(path))
            {
                Object.DestroyImmediate(o, true);
            }
            else
            {
                AssetDatabase.DeleteAsset(path);
            }
        }

        public static void Delete(List<Object> objs)
        {
            if (objs == null) return;
            int length = objs.Count;
            for (int i = 0; i < length; i++)
            {
                Delete(objs[i]);
            }
            objs.Clear();
        }

        public static List<String> Search(string dir, string filePath)
        {
            if (!File.Exists(filePath)) return null;
            if (!Directory.Exists(dir)) return null;
            var sets = new HashSet<string>();
            string line = null;
            var title = "读取配置文件";
            var lineLen = 100f;
            var lineIdx = 0;
            using (StreamReader sr = new StreamReader(filePath))
            {
                while ((line = sr.ReadLine()) != null)
                {
                    line = line.Trim();
                    ProgressBarUtil.Show(title, line, lineIdx / lineLen);
                    ++lineIdx;
                    if (sets.Contains(line)) continue;
                    sets.Add(line);
                }
            }
            title = "搜索文件";
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            float fileLen = files.Length;
            var lst = new List<string>();
            for (int i = 0; i < fileLen; i++)
            {
                var fp = files[i];
                var sfx = Path.GetExtension(fp);
                if (sfx == Suffix.Meta) continue;
                var name = Path.GetFileName(fp);
                ProgressBarUtil.Show(title, name, i / fileLen);
                if (!sets.Contains(name)) continue;
                fp = Path.GetFullPath(fp);
                fp = fp.Replace('\\', '/');
                var rPath = FileUtil.GetProjectRelativePath(fp);
                lst.Add(rPath);
            }
            EditorUtility.UnloadUnusedAssetsImmediate();
            ProgressBarUtil.Clear();
            return lst;
        }

        public static List<string> GetInvalidName(string dir, List<string> res = null)
        {
            if (!Directory.Exists(dir)) return null;
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return null;
            float length = files.Length;
            var cur = Directory.GetCurrentDirectory();
            var curLen = cur.Length + 1;
            var lst = (res == null ? new List<string>() : res);
            var title = "检查中···";
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                ProgressBarUtil.Show(title, path, i / length);
                var sfx = Path.GetExtension(path);
                if (!IsValidSfx(sfx)) continue;
                var name = Path.GetFileNameWithoutExtension(path);
                if (IsValidNameNoEx(name) && (sfx != Suffix.Psd)) continue;
                var rPath = path.Substring(curLen);
                rPath = rPath.Replace('\\', '/');
                lst.Add(rPath);
            }
            ProgressBarUtil.Clear();
            return lst;
        }

        public static List<string> GetInvalidName(List<string> dirs)
        {
            if (dirs == null) return null;
            var lst = new List<string>();
            int length = dirs.Count;
            for (int i = 0; i < length; i++)
            {
                var dir = dirs[i];
                GetInvalidName(dir, lst);
            }
            EditorUtility.UnloadUnusedAssetsImmediate();
            GC.Collect();
            return lst;
        }

        [MenuItem(menu + "检查非法字符", false, Pri + 7)]
        [MenuItem(AMenu + "检查非法字符", false, Pri + 7)]
        public static void ChkValidName()
        {
            var dirs = SelectUtil.GetDirs();
            if (dirs == null || dirs.Count < 1)
            {
                UIEditTip.Error("未选择文件夹"); return;
            }
            var lst = GetInvalidName(dirs);
            if (lst == null || lst.Count < 1)
            {
                UIEditTip.Log("名称合法");
            }
            else
            {
                ObjsWin.Open(lst);
            }
        }

        [MenuItem(menu + "检查名称有效性/直接合法命名", false, Pri + 8)]
        [MenuItem(AMenu + "检查名称有效性/直接合法命名", false, Pri + 8)]
        public static void DirectSetValidName()
        {
            SetValidName(false);
        }

        [MenuItem(menu + "检查名称有效性/将要命名的名称如果已经存在,删除当前资源", false, Pri + 9)]
        [MenuItem(AMenu + "检查名称有效性/将要命名的名称如果已经存在,删除当前资源", false, Pri + 9)]
        public static void SetUniqueValidName()
        {
            SetValidName(true);
        }

    }
}

