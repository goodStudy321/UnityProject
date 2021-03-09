//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/13 17:45:28
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ReleaseTableUtil
    /// </summary>
    public static class ReleaseTableUtil
    {
        #region 字段
        public const string Tmp = "Tmp";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static string GetSrcPath(string name)
        {
            var home = FileLoader.Home;
            var path = Path.Combine(ABTool.Data.Output, home);
            path = Path.Combine(path, name);
            return path;
        }

        private static string GetDestPath(string name)
        {
            var home = FileLoader.Home;
            var path = Path.Combine(Application.streamingAssetsPath, Tmp);
            path = Path.Combine(path, home);
            if (!Directory.Exists(path)) Directory.CreateDirectory(path);
            path = Path.Combine(path, name);
            return path;
        }

        private static void Copy(string name)
        {
            var src = GetSrcPath(name);
            var dest = GetDestPath(name);
            File.Copy(src, dest, true);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute()
        {
            Copy(LocalCfgManager.instance.source);
            Copy(InitDesCfgManager.instance.source);
        }
        #endregion
    }
}