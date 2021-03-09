/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/5/30 23:17:46
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using AT = AssetType;
    using ST = AssetSortType;
    using Object = UnityEngine.Object;
    using StDic = Dictionary<string, AssetType>;

    /// <summary>
    /// 资源类型
    /// </summary>
    public enum AssetType
    {
        /// <summary>
        /// 贴图
        /// </summary>
        Tex,

        /// <summary>
        /// 材质球
        /// </summary>
        Mat,

        /// <summary>
        /// Shader
        /// </summary>
        Shader,

        /// <summary>
        /// 音效
        /// </summary>
        Audio,

        /// <summary>
        /// 动画
        /// </summary>
        Anim,

        /// <summary>
        /// 动画控制球
        /// </summary>
        Animator,

        /// <summary>
        /// 模型
        /// </summary>
        Model,

        /// <summary>
        /// 预设
        /// </summary>
        Prefab,

        /// <summary>
        /// 场景
        /// </summary>
        Scene,

        /// <summary>
        /// 所有资源类型
        /// </summary>
        All,
    }

    /// <summary>
    /// 资源排序类型
    /// </summary>
    public enum AssetSortType
    {
        /// <summary>
        /// 内存占用
        /// </summary>
        Mem,

        /// <summary>
        /// 磁盘占用
        /// </summary>
        Disk,

        /// <summary>
        /// 名称
        /// </summary>
        Name
    }

    /// <summary>
    /// 资源查询工具
    /// </summary>
    public static class AssetQueryUtil
    {
        #region 字段
        public const int Pri = AssetUtil.Pri + 70;

        public const string Menu = AssetUtil.menu + "查询工具/";

        public const string AMenu = AssetUtil.AMenu + "查询工具/";

        public static readonly string[] typeNames = {
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

        /// <summary>
        /// k:后缀名,v:资源类型
        /// </summary>
        private static StDic sfxDic = new StDic();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
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
        #endregion

        #region 私有方法

        private static void Add(List<AssetDetailInfo> infos, string path)
        {
            Object obj = AssetDatabase.LoadAssetAtPath<Object>(path);
            var info = Add(infos, obj, path);
            if (info == null) return;
            info.Sfx = Path.GetExtension(path);
            info.Path = path;
        }
        /// <summary>
        /// 添加资源对象到资源详细列表中
        /// </summary>
        /// <param name="infos">详细列表</param>
        /// <param name="obj">资源对象</param>
        /// <param name="path">资源路径</param>
        private static AssetDetailInfo Add(List<AssetDetailInfo> infos, Object obj, string path)
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

        /// <summary>
        /// 添加指定资源类型到路径列表中
        /// </summary>
        /// <param name="lst">路径列表</param>
        /// <param name="path">路径</param>
        /// <param name="type">类型</param>
        private static void Add(List<string> lst, string path, AT type)
        {
            if (lst == null) return;
            string sfx = Path.GetExtension(path);
            if (sfx != null) sfx = sfx.ToLower();

            if (type == AssetType.All)
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
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 搜索指定目录指定类型组件的列表
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static List<T> GetComponents<T>(string dir, bool includeChild) where T : Component
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

        /// <summary>
        /// 搜索指定目录内的指定类型的资源
        /// </summary>
        /// <param name="dir">目录</param>
        /// <param name="type">资源类型</param>
        /// <param name="inPro">工程内资源,默认true</param>
        /// <returns></returns>
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

        /// <summary>
        /// 搜索指定目录列表内的指定类型的资源
        /// </summary>
        /// <param name="dirs"></param>
        /// <param name="type"></param>
        /// <param name="inPro">工程内资源,默认true</param>
        /// <returns></returns>
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

        /// <summary>
        /// 搜索指定类型资源的资源路径列表
        /// </summary>
        /// <param name="type">资源类型</param>
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




        /// <summary>
        /// 搜索指定类型的资源详细信息
        /// </summary>
        /// <param name="type">资源类型</param>
        /// <param name="sortType">排序类型</param>
        /// <returns></returns>
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

        /// <summary>
        /// 判断type是否包含target
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="target">被包含类型</param>
        /// <returns></returns>
        public static bool Contains(AT type, AT target)
        {
            var res = ((int)type & (1 << (int)target));
            return (res != 0);
        }


        /// <summary>
        /// 判断制定后缀名资源是否属于类型type
        /// </summary>
        /// <param name="type">类型</param>
        /// <param name="sfx">后缀名</param>
        /// <returns></returns>
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

        #endregion
    }
}