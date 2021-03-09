/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/6/5 14:29:28
 ============================================================================*/

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 资源路径工具
    /// </summary>
    public static class AssetPathUtil
    {
        #region 字段
        private static string temp = null;
        private static string curDir = null;
        private static string streaming = null;
        private static string bSlashCurDir = null;

        /// <summary>
        /// 资源根目录名称
        /// </summary>
        public const string AssetRootFolder = "Assets";

        #endregion

        #region 属性
        /// <summary>
        /// 当前目录/正斜杠
        /// </summary>
        public static string CurDir
        {
            get
            {
                if (string.IsNullOrEmpty(curDir))
                {
                    curDir = Directory.GetCurrentDirectory();
                    curDir = curDir.Replace('\\', '/');
                    curDir += "/";
                }
                return curDir;
            }
        }

        /// <summary>
        /// 当前目录/反斜杠
        /// </summary>
        public static string BSlashCuDir
        {
            get
            {
                if (string.IsNullOrEmpty(bSlashCurDir))
                {
                    bSlashCurDir = Directory.GetCurrentDirectory();
                    bSlashCurDir += "\\";
                }
                return bSlashCurDir;
            }
        }

        /// <summary>
        /// 流目录
        /// </summary>
        public static string Streaming
        {
            get
            {
                if (string.IsNullOrEmpty(streaming))
                {
                    streaming = CurDir + "Assets/StreamingAssets/";
                }
                return streaming;
            }
        }

        /// <summary>
        /// 临时目录
        /// </summary>
        public static string Temp
        {
            get
            {
                if (string.IsNullOrEmpty(temp))
                {
                    temp = Path.GetFullPath("../Temp/");
                    if (!Directory.Exists(temp)) Directory.CreateDirectory(temp);
                }
                return temp;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取相对于工程的路径
        /// </summary>
        /// <param name="fullPath">完整路径</param>
        /// <returns></returns>
        public static string GetRelativePath(string fullPath)
        {
            if (string.IsNullOrEmpty(fullPath)) return null;
            fullPath = fullPath.Replace('\\', '/');
            string rPath = FileUtil.GetProjectRelativePath(fullPath);
            return rPath;
        }

        /// <summary>
        /// 获取资源路径的完整路径
        /// </summary>
        /// <param name="rPath">相对路径/资源路径</param>
        /// <returns></returns>
        public static string GetFullPath(string rPath)
        {
            if (rPath.StartsWith(CurDir)) return rPath;
            if (!rPath.StartsWith(AssetRootFolder)) return rPath;
            string fullPath = string.Format("{0}{1}", CurDir, rPath);
            return fullPath;
        }

        /// <summary>
        /// 获取临时路径
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetTempPath(string name)
        {
            return Temp + name;
        }

        /// <summary>
        /// 获取当前时间戳名称
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static string GetNowName(string name)
        {
            name = Path.GetFileNameWithoutExtension(name);
            var newName = name + "_" + DateTime.Now.Ticks;
            return newName;
        }
        #endregion
    }
}