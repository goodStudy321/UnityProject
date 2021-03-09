//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/29 22:28:01
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// EditDirUtil
    /// </summary>
    public static class EditDirUtil
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
        /// 拷贝文件夹
        /// </summary>
        /// <param name="srcDir">源目录</param>
        /// <param name="desDir">目标目录</param>
        /// <param name="filters">后缀过滤</param>
        /// <param name="reserveDir">true:保留相对路径</param>
        public static void Copy(string srcDir, string desDir, HashSet<string> filters = null, bool reserveDir = true)
        {
            srcDir = Path.GetFullPath(srcDir);
            if (!Directory.Exists(srcDir)) return;
            if (!Directory.Exists(desDir)) Directory.CreateDirectory(desDir);
            var files = Directory.GetFiles(srcDir, "*.*", SearchOption.AllDirectories);
            if (files == null) return;
            int srcLen = srcDir.Length;
            var c = srcDir[srcLen - 1];
            if (c != '/' && c != '\\') srcLen += 1;
            ProgressBarUtil.Max = 20;
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                string souPath = files[i];
                string sfx = Path.GetExtension(souPath);
                if (sfx.Equals(Suffix.Meta)) continue;
                if (sfx.Equals(Suffix.Manifest)) continue;
                if (filters != null) if (filters.Contains(sfx)) continue;
                ProgressBarUtil.Show("复制", souPath, i / length);
                string desPath = null;
                if (reserveDir)
                {
                    desPath = souPath.Substring(srcLen);
                    desPath = string.Format("{0}/{1}", desDir, desPath);
                }
                else
                {
                    string fileName = Path.GetFileName(souPath);
                    desPath = string.Format("{0}/{1}", desDir, fileName);
                }

                string dir = Path.GetDirectoryName(desPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(souPath, desPath, true);
            }
            ProgressBarUtil.Clear();
        }
        #endregion
    }
}