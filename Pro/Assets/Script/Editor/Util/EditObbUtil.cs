//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/10 20:36:01
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Threading;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Loong.Edit
{
    /// <summary>
    /// EditObbUtil
    /// </summary>
    public static class EditObbUtil
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
        /// 获取主扩展路径
        /// </summary>
        /// <returns></returns>
        public static string GetMainPath(string dir)
        {

            int ver = PlayerSettings.Android.bundleVersionCode;
            var mainName = ObbUtil.GetMainName(ver);
            var mainPath = Path.Combine(dir, mainName);
            return mainPath;
        }

        /// <summary>
        /// 获取发布目录主扩展路径
        /// </summary>
        /// <returns></returns>
        public static string GetBuildMainPath()
        {
            var root = ReleaseUtil.GetDir(null);
            return GetMainPath(root);
        }

        /// <summary>
        /// 获取流目录主扩展路径
        /// </summary>
        /// <returns></returns>
        public static string GetStreamMainPath()
        {
            var streaming = Application.streamingAssetsPath;
            return GetMainPath(streaming);
        }



        public static void Delete()
        {
            var path = GetStreamMainPath();
            if (File.Exists(path)) File.Delete(path);
        }
        #endregion
    }
}