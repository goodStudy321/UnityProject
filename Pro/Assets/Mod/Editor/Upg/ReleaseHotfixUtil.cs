//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/2 0:15:06
// 发布热更工具
// 流程：更新→预处理→处理资源→打包AB→搜集比对→上传CDN→上传SVN
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using UnityEditor.Callbacks;
using System.Collections.Generic;

namespace Loong.Edit
{
    using iTrace = Loong.Game.iTrace;
    public static class ReleaseHotfixUtil
    {
        #region 字段
        private const string isBegin = "IsBegin";

        #endregion

        #region 属性
        public static bool IsBegin
        {
            get { return EditPrefsTool.GetBool(typeof(ReleaseSetTool), isBegin); }
            set { EditPrefsTool.SetBool(typeof(ReleaseSetTool), isBegin, value); }
        }

        public static bool IsCompiling
        {
            get { return EditorApplication.isCompiling; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static void Preprocess()
        {
            PreprocessCmdUtil.Init();
            PreprocessCmdUtil.Add("LOONG_ENABLE_UPG");

            PreprocessCmdUtil.Apply();
            CompileUtil.Refresh();
        }

        /// <summary>
        /// 处理资源
        /// </summary>
        private static void HandlerAssets()
        {
            LuaCmdUtil.HandleOnHotfix();
        }

        /// <summary>
        /// 打包AB
        /// </summary>
        private static void BuildAB()
        {
            ABTool.DeleteUnused();
            ABTool.BuildUserSettings();
        }

        /// <summary>
        /// 搜集
        /// </summary>
        private static void Collect()
        {
            AssetUpgCmdMgr.HandleOnHotfix();
        }

        /// <summary>
        /// 上传CDN
        /// </summary>
        private static void UploadCDN()
        {
            var ver = BuildArgs.AssetVer;
            var cid = BuildArgs.ChannelUID;
            var cdnData = AssetCdnUtil.Data;
            var plat = EditUtil.GetPlatform();
            var pro = UpgUtil.URL.Replace(UpgUtil.Host, "");
            var local = AssetUpgUtil.Data.GetCompDir(ver);

            var remote = AssetCdnUtil.GetAssetUrl(cdnData.ftpUrl, pro, cid, BuildArgs.IsDebug, plat, ver);
            iTrace.Log("Loong", "UploadCDN beg, local:{0}, remote:{1}", local, remote);
            var ftp = new FTP();
            ftp.LocalPath = local;
            ftp.RemotePath = remote;
            ftp.UserName = cdnData.FtpUserName;
            ftp.Password = cdnData.FtpPassword;
            if (!ftp.Upload()) Application.Quit();
            iTrace.Log("Loong", "UploadCDN suc, local:{0}, remote:{1}", local, remote);
        }

        /// <summary>
        /// 上传SVN
        /// </summary>
        private static void UploadSVN()
        {
            var ver = BuildArgs.AssetVer;
            var srcDir = ABTool.Data.Output;
            var upgDir = AssetUpgUtil.Data.GetUpgDirRoot();
            srcDir = Path.GetFullPath(srcDir);
            upgDir = Path.GetFullPath(upgDir);
            var log = string.Format("Asset_Ver:{0}", ver);
            if (!SvnCmdUtil.Commit(srcDir, log)) Application.Quit();
            if (!SvnCmdUtil.Commit(upgDir, log)) Application.Quit();
            iTrace.Log("Loong", "UploadSVN suc, srcDir:{0}, upgDir:{1}", srcDir, upgDir);
        }


        [DidReloadScripts]
        private static void Begin()
        {
            if (!IsBegin) return;
            IsBegin = false;
            HandlerAssets();
            BuildAB();
            Collect();
            UploadCDN();
            UploadSVN();
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public static void Reset()
        {
            IsBegin = false;
        }

        /// <summary>
        /// 启动
        /// </summary>
        public static void Start()
        {
            Reset();
            Preprocess();
            ProgressBarUtil.IsShow = false;

            IsBegin = true;
            if (!IsCompiling) Begin();
        }

        #endregion
    }
}