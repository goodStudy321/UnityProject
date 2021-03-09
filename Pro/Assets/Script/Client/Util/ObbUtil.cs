//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/9 10:34:30
//*****************************************************************************

using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// ObbUtil
    /// </summary>
    public static class ObbUtil
    {
        #region 字段
        public const string MainFlag = "main.";

        public const string PatchFlag = "patch.";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static string GetBundleID()
        {
            var bundleID = App.BundleID;
            if (string.IsNullOrEmpty(bundleID))
            {
                bundleID = Application.identifier;
            }
            return bundleID;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取obb扩展文件名称
        /// </summary>
        /// <param name="flag"></param>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetName(string flag, int ver)
        {
            var pkgName = GetBundleID();
            var name = string.Format("{0}{1}.{2}.obb", flag, ver, pkgName);
            return name;
        }

        /// <summary>
        /// 获取主扩展文件名称
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetMainName(int ver)
        {
            return GetName(MainFlag, ver);
        }

        /// <summary>
        /// 获取补丁扩展文件名称
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetPatchName(int ver)
        {
            return GetName(PatchFlag, ver);
        }

        /// <summary>
        /// 获取APP对应外部目录
        /// </summary>
        /// <returns></returns>
        public static string GetExter(string root)
        {
            var exter = string.Format("Android/obb/{0}/", GetBundleID());
            exter = Path.Combine(root, exter);
            return exter;
        }

        /// <summary>
        /// 获取扩展文件路径
        /// </summary>
        /// <param name="flag"></param>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetExterPath(string flag, int ver, string root)
        {
            root = root ?? GetExterRoot();
            var exter = GetExter(root);
            var name = GetName(flag, ver);
            var path = exter + name;
            return path;
        }

        /// <summary>
        /// 获取主扩展文件外部路径
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public static string GetExterMain(int ver)
        {
            string root = null;
            if (App.IsEditor)
            {
                root = AssetPath.Cache;
            }
            else if (App.IsDebug && !App.IsReleaseDebug)
            {
                root = AssetPath.Streaming;
            }
            else
            {
                root = GetExterRoot();
            }
            return GetMainPath(ver, root);
        }

        /// <summary>
        /// 获取主扩展文件路径
        /// </summary>
        /// <param name="ver"></param>
        /// <param name="root"></param>
        /// <returns></returns>
        public static string GetMainPath(int ver, string root = null)
        {
            return GetExterPath(MainFlag, ver, root);
        }

        /// <summary>
        /// 获取补丁扩展文件路径
        /// </summary>
        /// <param name="ver"></param>
        /// <param name="root"></param>
        /// <returns></returns>
        public static string GetPatchPath(int ver, string root = null)
        {
            return GetExterPath(PatchFlag, ver, root);
        }

        /// <summary>
        /// 获取外部目录
        /// </summary>
        /// <returns></returns>
        public static string GetExterRoot()
        {
            var ujo = JavaUtil.GetUnityPlayer();
            if (ujo == null) return null;
            return JavaUtil.CallGenneric<string>(ujo, "getExterDir", string.Empty);
        }


        #endregion
    }
}