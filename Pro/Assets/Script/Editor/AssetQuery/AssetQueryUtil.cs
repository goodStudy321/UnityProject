using System;
using System.IO;
using Hello.Game;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using System.Collections;
using System.Collections.Generic;


namespace Hello.Edit
{
    using AT = AssetType;
    using ST = AssetSortType;
    using Object = UnityEngine.Object;
    using StDic = Dictionary<string, AssetType>;

    public enum AssetType
    {
        Tex,

        Mat,

        Shader,

        Audio,

        Anim,

        Animator,

        Model,

        Prefab,

        Scene,

        All,
    }

    public enum AssetSortType
    {
        Mem,

        Disk,

        Name,
    }

    public static class AssetQueryUtil
    {
        public const int Pri = AssetUtil.Pri + 70;

        public const string Menu = AssetUtil.menu + "查询工具/";

        public const string AMenu = AssetUtil.AMenu + "查询工具/";

        public static readonly string[] typeNames =
        {
            "贴图",
            "材质",
            "着色器",
            "音效片段",
            "动画片段",
            "动画控制器",
            "模型",
            "预设",
            "场景",
            "所有"
        };

        private static StDic sfxDic = new StDic();

        static AssetQueryUtil()
        {
            sfxDic.Add(Suffix.Jpg, AT.Tex);
            sfxDic.Add(Suffix.Png, AT.Tex);
            sfxDic.Add(Suffix.Tga, AT.Tex);
            sfxDic.Add(Suffix.Exr, AT.Tex);
            sfxDic.Add(".tif", AT.Tex);
            sfxDic.Add(".hdr", AT.Tex);
            sfxDic.Add(Suffix.Mat, AT.Mat);
            sfxDic.Add(Suffix.Shader, AT.Shader);
            sfxDic.Add(Suffix.Wav, AT.Audio);
            sfxDic.Add(Suffix.Mp3, AT.Audio);
            sfxDic.Add(Suffix.Ogg, AT.Audio);
            sfxDic.Add(Suffix.Fbx, AT.Model);
            sfxDic.Add(Suffix.Prefab, AT.Prefab);
            sfxDic.Add(Suffix.Animation, AT.Anim);
            sfxDic.Add(Suffix.Animator, AT.Animator);
            sfxDic.Add(Suffix.Scene, AT.Scene);
        }

        private static void Add(List<AssetDetailInfo> infos,string path)
        {
            Object obj = AssetDatabase.LoadAssetAtPath<Object>(path);
            var info = Add(infos, obj, path);
            if (info == null) return;
            info.Sfx = Path.GetExtension(path);
            info.Path = path;
        }

        private static AssetDetailInfo Add(List<AssetDetailInfo> infos,Object obj,string path)
        {
            if (obj == null) return null;
            if (infos == null) return null;
            if (string.IsNullOrEmpty(path)) return null;
            string curDir = Directory.GetCurrentDirectory();
            string fullPath = Path.Combine(curDir, path);
            if (!File.Exists(fullPath)) return null;
            FileInfo fi = new FileInfo(fullPath);
            AssetDetailInfo ai = new AssetDetailInfo();
            var import = AssetImporter.GetAtPath(path);
            ai.IsAB = (string.IsNullOrEmpty(import.assetBundleName) ? false : true);
            ai.DiskUsage = fi.Length;
            ai.MemUsage = AssetMemUtil.GetMemSize(obj);
            ai.Asset = obj;
            infos.Add(ai);
            return ai;
        }

        private static void Add(List<string> lst,string path,AT type)
        {
            if (lst == null) return;
            string sfx = Path.GetExtension(path);
            if (sfx != null) sfx = sfx.ToLower();
            if(type == AssetType.All)
            {
                if (sfx == Suffix.CS) return;
                if (sfx == Suffix.Js) return;
                if (sfx == Suffix.Meta) return;
                lst.Add(path);
            }
            else if (sfxDic.ContainsKey(sfx))
            {
                var ty = sfxDic[sfx];
                if (Contains(type, ty))
                {
                    lst.Add(path);
                }
            }
        }

        public static List<T> GetComponents<T>(string dir,bool includeChild) where T : Component
        {
            if (!Directory.Exists(dir)) return null;
            var type = (AssetType)(1 << (int)AssetType.Prefab);
            var paths = AssetQueryUtil.Search(dir, type);
            if (paths == null) return null;
            List<T> lst = null;
            int length = paths.Count;
            for (int i = 0; i < length; i++)
            {
                var path = paths[i];
                var go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (go == null) continue;
                T t = null;
                if (includeChild)
                {

                    t = go.GetComponentInChildren<T>(true);
                }
                else
                {
                    t = go.GetComponent<T>();
                }
                if (t == null) continue;
                if (lst == null) lst = new List<T>();
                lst.Add(t);
            }
            return lst;
        }

        public static List<string> Search(string dir, AT type, List<string> res = null, bool inPro = true)
        {
            if (string.IsNullOrEmpty(dir)) return null;
            if (!Directory.Exists(dir)) return null;
            var files = Directory.GetFiles(dir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return null;
            float length = files.Length;
            var lst = (res == null ? new List<string>() : res);
            var tip = "搜集中···";
            var curLen = Directory.GetCurrentDirectory().Length + 1;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                ProgressBarUtil.Show("", tip, i / length);
                var rPath = inPro ? path.Substring(curLen) : path;
                Add(lst, rPath, type);
            }
            ProgressBarUtil.Clear();
            return lst;
        }

        public static List<string> Search(List<string> dirs, AT type, bool inPro = true)
        {
            if (dirs == null) return null;
            int length = dirs.Count;
            var res = new List<string>();
            for (int i = 0; i < length; i++)
            {
                var dir = dirs[i];
                Search(dir, type, res);
            }
            return res;
        }

        public static List<string> Search(AT type, SelectionMode mode = SelectionMode.DeepAssets)
        {
            if (!SelectUtil.CheckObjs()) return null;
            var objs = SelectUtil.Get<Object>(mode);

            int objLen = objs.Length;
            var paths = new string[objLen];
            for (int i = 0; i < objLen; i++)
            {
                paths[i] = AssetDatabase.GetAssetPath(objs[i]);
            }
            var tip = "搜集中···";
            ProgressBarUtil.Show("", tip);
            string[] all = null;
            if ((mode & SelectionMode.DeepAssets) != 0)
            {
                all = AssetDatabase.GetDependencies(paths);
            }
            else
            {
                all = paths;
            }
            var lst = new List<string>();
            float deLen = all.Length;
            for (int i = 0; i < deLen; i++)
            {
                var path = all[i];
                ProgressBarUtil.Show("", tip, i / deLen);
                Add(lst, path, type);

            }
            ProgressBarUtil.Clear();
            return lst;
        }

        public static List<AssetDetailInfo> SearchDetail(AT type, ST sortType, SelectionMode mode = SelectionMode.DeepAssets)
        {
            List<string> paths = Search(type, mode);
            if (paths == null || paths.Count < 1) return null;
            var details = new List<AssetDetailInfo>();
            int length = paths.Count;
            for (int i = 0; i < length; i++)
            {
                string path = paths[i];
                Add(details, path);
            }

            if (sortType == ST.Disk)
            {
                details.Sort(AssetDetailInfo.CompareDisk);
            }
            else if (sortType == ST.Mem)
            {
                details.Sort();
            }
            else if (sortType == ST.Name)
            {
                details.Sort(AssetDetailInfo.CompareName);
            }
            return details;
        }

        public static bool Contains(AT type, AT target)
        {
            var res = ((int)type & (1 << (int)target));
            return (res != 0);
        }

        public static bool Contains(AT type, string sfx)
        {
            if (Contains(type, AT.All))
            {
                return true;
            }

            if (sfxDic.ContainsKey(sfx))
            {
                var ty = sfxDic[sfx];
                return Contains(type, ty);
            }
            return false;
        }
    }
}

