//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/1 15:32:57
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AppInfoUtil
    /// </summary>
    public static class AppInfoUtil
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
        private static void SetVerCode(AppInfo info)
        {
#if UNITY_ANDROID
            info.VerCode = PlayerSettings.Android.bundleVersionCode;
#elif UNITY_IOS
            info.VerCode = int.Parse(PlayerSettings.iOS.buildNumber);
#endif
        }

        private static void SetChannel(AppInfo info)
        {
#if SDK_IOS_IQIYI
            SetChannel(info, "1476244039", "10654", "112063", 2);
#elif SDK_IOS_JUNHAI
            SetChannel(info, "1392207083", "0", "107035", 1);
#elif SDK_IOS_GAT
            SetChannel(info, "1509164168", "20003", "500003", 19);
#elif SDK_ANDROID_GAT
            SetChannel(info, "0", "20004", "500004", 19);
#elif SDK_ANDROID_JUNHAI
            SetChannel(info, "0", "0", "0", 1);
#elif SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
            SetChannel(info, "0", "20009", "500009", 25);
#else
            SetChannel(info, "0", "0", "0", 0);
#endif
        }

        private static void SetChannel(AppInfo info, string aid, string cid, string gcid, int flag)
        {
            info.AID = aid;
            info.CID = cid;
            info.GCID = gcid;
            info.GFlag = flag;
        }


        private static void Save(AppInfo info)
        {
            var path = Application.streamingAssetsPath + "/AppInfo.xml";
            XmlTool.Serializer<AppInfo>(path, info);
        }


        private static void SetInAssetVer(AppInfo info)
        {
            info.InAssetVer = BuildArgs.AssetVer;
        }

        private static void SetEnableFps(AppInfo info)
        {
#if GAME_DEBUG
            info.EnableFps = true;
#else
            if (App.IsDebug) info.EnableFps = true;
#endif
        }

        private static void SetReleaseDebug(AppInfo info)
        {
            info.IsReleaseDebug = BuildArgs.IsReleaseDebug;
        }

        private static void SetPkg(AppInfo info)
        {
            info.Pkg = BuildArgs.Pkg;

            if (info.Pkg == PkgKind.Single)
            {
                var buildPath = EditObbUtil.GetBuildMainPath();
                if (File.Exists(buildPath))
                {
                    var fi = new FileInfo(buildPath);
                    info.PkgSz = fi.Length;
                    var md5 = Md5Crypto.GenFileFast(buildPath);
                    info.PkgMD5 = md5;
                    iTrace.Log("Loong", "{0} size:{1}, md5:{2}", buildPath, fi.Length, md5);
                }
                else
                {
                    EditApp.ExitBatch(ExitCode.MainObbNotExist, "main obb:{0} not exist", buildPath);
                }
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute()
        {
            var info = new AppInfo();
            SetVerCode(info);
            SetInAssetVer(info);
            SetChannel(info);
            SetEnableFps(info);
            SetReleaseDebug(info);
            SetPkg(info);
            Save(info);
            AssetDatabase.Refresh();
        }
        #endregion
    }
}