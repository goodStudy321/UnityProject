//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/7 10:03:09
// 微软软件工具
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using Microsoft.Win32;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using iTrace = Loong.Game.iTrace;

    public static class MicroSoftUtil
    {
        #region 字段
        private static string unityDir = null;

        private static string unityPath = null;
        #endregion

        #region 属性
        public static string UnityDir
        {
            get
            {
                if (unityDir == null) SetUnity();
                return unityDir;
            }
        }

        public static string UnityPath
        {
            get
            {
                if (unityDir == null) SetUnity();
                return unityPath;
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void SetUnity()
        {
            unityPath = Process.GetCurrentProcess().MainModule.FileName;
            unityDir = Path.GetDirectoryName(unityPath);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取软件安装路径
        /// </summary>
        /// <param name="name">软件名称,不包含后缀</param>
        /// <param name="path">路径</param>
        /// <returns>true:获取成功</returns>
        public static bool TryGetPath(string name, out string path)
        {
            var key = string.Empty;
            string result = null;
            object obj = null;
            RegistryKey regKey = null;
            RegistryKey subKey = null;
            try
            {
                var subKeyPath = @"SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" + name + ".exe";
                regKey = Registry.LocalMachine;
                subKey = regKey.OpenSubKey(subKeyPath);
                obj = subKey.GetValue(key);
                result = obj.ToString();
                if (!File.Exists(result)) result = null;

            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "TryGetPath:{0}, err:{1}", name, e.Message);

            }
            finally
            {
                if (regKey != null) regKey.Close();
                if (subKey != null) subKey.Close();
                path = result;
            }
            return path != null;
        }

        #endregion
    }
}