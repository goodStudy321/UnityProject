/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 21:16:24
 ============================================================================*/

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;
    /// <summary>
    /// SDK工具
    /// </summary>
    public static class SdkUtil
    {
        #region 字段
        private static string platform = null;
        #endregion

        #region 属性
        public static string Platform
        {
            get
            {
                if (platform == null) platform = EditorUserBuildSettings.activeBuildTarget.ToString();
                return platform;
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置预处理指令
        /// </summary>
        /// <param name="dic">命令行参数字典</param>
        /// <param name="arr">预处理指令数组</param>
        /// <param name="key">目标预处理指令键值</param>
        private static void SetPreprocess(StrDic dic, String[] arr, string key)
        {
            if (!dic.ContainsKey(key)) return;
            string preCmd = dic[key];

            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                string it = arr[i];
                if (it == preCmd)
                {
                    PreprocessCmdUtil.Add(it);
                }
                else
                {
                    PreprocessCmdUtil.Remove(it);
                }
            }
        }


        /// <summary>
        /// 获取源目录
        /// </summary>
        /// <param name="platform"></param>
        /// <param name="sdkName"></param>
        /// <returns></returns>
        private static string GetSrcDir(string platform, string sdkName)
        {
            if (string.IsNullOrEmpty(platform)) return null;
            if (string.IsNullOrEmpty(sdkName)) return null;
            string relDir = "../sdk_root/" + platform + "/" + sdkName;
            string srcDir = Path.GetFullPath(relDir);
            return srcDir;
        }

        /// <summary>
        /// 获取代码目录
        /// </summary>
        /// <param name="platform"></param>
        /// <param name="sdkName"></param>
        /// <returns></returns>
        public static string GetMMDir(string platform, string sdkName)
        {
            return GetChildName(platform, sdkName, "mm");
        }

        /// <summary>
        /// 获取配置目录
        /// </summary>
        /// <param name="platform"></param>
        /// <param name="sdkName"></param>
        /// <returns></returns>
        public static string GetCfgDir(string platform, string sdkName)
        {
            return GetChildName(platform, sdkName, "cfg");
        }

        /// <summary>
        /// 获取资源目录
        /// </summary>
        /// <param name="platform"></param>
        /// <param name="sdkName"></param>
        /// <returns></returns>
        private static string GetResDir(string platform, string sdkName)
        {
            return GetChildName(platform, sdkName, "res");
        }

        private static string GetSplashDir(string platform, string sdkName)
        {
            return GetChildName(platform, sdkName, "splash");
        }

        private static string GetChildName(string platform, string sdkName, string child)
        {
            string relDir = GetSrcDir(platform, sdkName);
            if (relDir == null) return null;
            relDir = Path.Combine(relDir, child);
            string dir = Path.GetFullPath(relDir);
            return dir;
        }

        private static string GetChildName(string sdkName, string child)
        {
            var plat = EditorUserBuildSettings.activeBuildTarget.ToString();
            return GetChildName(plat, sdkName, child);
        }

        /// <summary>
        /// 获取插件目录
        /// </summary>
        /// <param name="platform"></param>
        /// <returns></returns>
        public static string GetPluginDir(string platform)
        {
            string dir = Application.dataPath + "/Plugins/" + platform;
            return dir;
        }


        /// <summary>
        /// 获取Sdk名
        /// </summary>
        /// <param name="dic">命令行参数字典</param>
        /// <param name="preDic">预处理指令字典</param>
        /// <param name="key">目标预处理指令</param>
        /// <returns></returns>
        private static string GetSdkName(StrDic dic, StrDic preDic, string key)
        {
            if (!dic.ContainsKey(key)) return null;
            string preCmd = dic[key];
            if (!preDic.ContainsKey(preCmd)) return null;
            string sdkName = preDic[preCmd];
            return sdkName;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        /// <summary>
        /// 获取资源文件目录
        /// </summary>
        /// <param name="des"></param>
        /// <returns></returns>
        public static string GetResDir(string des)
        {
            return GetResDir(Platform, des);
        }


        /// <summary>
        /// 获取配置目录
        /// </summary>
        /// <param name="des"></param>
        /// <returns></returns>
        public static string GetCfgDir(string des)
        {
            return GetCfgDir(Platform, des);
        }

        /// <summary>
        /// 获取配置路径
        /// </summary>
        /// <param name="des"></param>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetCfgPath(string des, string name)
        {
            return Path.Combine(GetCfgDir(des), name);
        }

        /// <summary>
        /// 获取源码目录
        /// </summary>
        /// <param name="des"></param>
        /// <returns></returns>
        public static string GetSrcDir(string des)
        {
            return GetSrcDir(Platform, des);
        }

        /// <summary>
        /// 获取闪屏目录
        /// </summary>
        /// <param name="des"></param>
        /// <returns></returns>
        public static string GetSplashDir(string des)
        {
            return GetChildName(des, "splash");
        }

        /// <summary>
        /// 获取loading目录
        /// </summary>
        /// <param name="des"></param>
        /// <returns></returns>
        public static string GetLoadingDir(string des)
        {
            return GetChildName(des, "loading");
        }

        /// <summary>
        /// 往工程内添加SDK文件
        /// </summary>
        /// <param name="platform">平台名</param>
        /// <param name="des">sdk名</param>
        public static void Add(string platform, string des)
        {
            string srcDir = GetMMDir(platform, des);
            if (string.IsNullOrEmpty(srcDir) || !Directory.Exists(srcDir))
            {
                Debug.LogError("添加SDK文件时,未发现源目录:" + srcDir);
                return;
            }
            string[] files = Directory.GetFiles(srcDir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return;
            string pluginDir = GetPluginDir(platform);
            int srcDicLen = srcDir.Length;
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                string path = files[i];
                string relPath = path.Substring(srcDicLen);
                string desPath = pluginDir + relPath;
                string desDir = Path.GetDirectoryName(desPath);
                if (!Directory.Exists(desDir)) Directory.CreateDirectory(desDir);
                File.Copy(path, desPath, true);
                ProgressBarUtil.Show("添加SDK", relPath, i / length);
            }
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 将工程内SDK文件移除
        /// </summary>
        /// <param name="platform">平台名</param>
        /// <param name="des">sdk名</param>
        public static void Remove(string platform, string des)
        {
            string srcDir = GetMMDir(platform, des);
            if (!Directory.Exists(srcDir)) return;
            string[] files = Directory.GetFiles(srcDir, "*.*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1) return;
            string pluginDir = GetPluginDir(platform);
            int srcDicLen = srcDir.Length;
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                string path = files[i];
                string relPath = path.Substring(srcDicLen);
                relPath = relPath.Replace("\\", "/");
                string desPath = pluginDir + relPath;//Path.Combine(pluginDir, relPath);
                if (!File.Exists(desPath)) continue;
                string assetPath = FileUtil.GetProjectRelativePath(desPath);
                AssetDatabase.DeleteAsset(assetPath);
                ProgressBarUtil.Show("移除SDK", assetPath, i / length);
            }
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 往工程内添加SDK文件
        /// </summary>
        /// <param name="dic">命令行参数</param>
        /// <param name="preDic">预处理指令文件夹字典</param>
        /// <param name="platform">平台名</param>
        /// <param name="key">目标预处理指令键值</param>
        public static void Add(StrDic dic, StrDic preDic, string platform, string key)
        {
            string sdkName = GetSdkName(dic, preDic, key);
            if (string.IsNullOrEmpty(sdkName)) return;
            Add(platform, sdkName);
        }

        /// <summary>
        /// 将工程内SDK文件移除
        /// </summary>
        /// <param name="dic">命令行参数</param>
        /// <param name="preDic">预处理指令文件夹字典</param>
        /// <param name="platform">平台名</param>
        /// <param name="key">目标预处理指令键值</param>
        public static void Remove(StrDic dic, StrDic preDic, string platform, string key)
        {
            string sdkName = GetSdkName(dic, preDic, key);
            if (string.IsNullOrEmpty(sdkName)) return;
            Remove(platform, sdkName);
        }

        #endregion
    }
}