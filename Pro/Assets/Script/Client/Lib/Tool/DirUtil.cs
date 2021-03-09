/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/6/5 20:09:23
 ============================================================================*/

using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// 文件夹工具
    /// </summary>
    public static class DirUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 删除文件夹 
        /// </summary>
        /// <param name="dir">文件夹目录</param>
        /// <param name="recursive">是否递归</param>
        public static void Delete(string dir, bool recursive = true)
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive);
        }

        /// <summary>
        /// 删除子文件夹和子文件/保留目录
        /// </summary>
        /// <param name="dir">文件夹目录</param>
        public static void DeleteSub(string dir)
        {
            DeleteSubDirectory(dir);
            DeleteSubFile(dir);
        }

        /// <summary>
        /// 删除子文件
        /// </summary>
        /// <param name="dir">文件夹目录</param>
        public static void DeleteSubFile(string dir)
        {
            if (!Directory.Exists(dir)) return;
            string[] files = Directory.GetFiles(dir);
            if (files == null) return;
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                File.Delete(files[i]);
            }
        }

        /// <summary>
        /// 删除子文件夹/递归删除
        /// </summary>
        /// <param name="dir">文件夹目录</param>
        public static void DeleteSubDirectory(string dir)
        {
            if (!Directory.Exists(dir)) return;
            string[] dirs = Directory.GetDirectories(dir);
            if (dirs == null) return;
            int length = dirs.Length;
            for (int i = 0; i < length; i++)
            {
                Directory.Delete(dirs[i], true);
            }
        }


        /// <summary>
        /// 获取指定目录的上一级目录
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static string GetLast(string dir)
        {
            if (string.IsNullOrEmpty(dir)) return null;
            int last = dir.LastIndexOf("/");
            if (last == -1) last = dir.LastIndexOf("\\");
            dir = dir.Substring(0, last + 1);
            return dir;
        }

        /// <summary>
        /// 检查目录是否存在,如果不存在则创建
        /// </summary>
        /// <param name="dir"></param>
        public static void Check(string dir)
        {
            if (string.IsNullOrEmpty(dir)) return;
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
        }

        /// <summary>
        /// 获取目录大小
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static long GetSize(string dir)
        {
            if (!Directory.Exists(dir)) return 0;
            DirectoryInfo di = new DirectoryInfo(dir);
            FileInfo[] fis = di.GetFiles();
            long total = GetSize(fis);
            return total;
        }

        public static long GetSize(FileInfo[] fis)
        {
            if (fis == null) return 0;
            long total = 0;
            int length = fis.Length;
            for (int i = 0; i < length; i++)
            {
                FileInfo fi = fis[i];
                total += fi.Length;
            }
            return total;
        }


        /// <summary>
        /// 获取完整目录,尾部会加上'/'
        /// </summary>
        /// <param name="dir"></param>
        /// <returns></returns>
        public static string GetFull(string dir)
        {
            var full = Path.GetFullPath(dir);
            full = Path.GetFullPath(full);
            var c = full[full.Length - 1];
            if (c != '/' || c != '\\') full += '/';
            return full;
        }

        #endregion
    }
}