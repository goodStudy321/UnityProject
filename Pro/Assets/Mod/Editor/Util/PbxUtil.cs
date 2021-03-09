/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/17 2:58:33
 ============================================================================*/

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;

using System.Collections.Generic;

#if UNITY_XCODE_API_BUILD
using UnityEditor.iOS.Xcode;
#else
using UnityEditor.iOS.Xcode.Custom;
using UnityEditor.iOS.Xcode.Custom.Extensions;
#endif

namespace Loong.Edit
{
    /// <summary>
    /// ios xcode工程工具
    /// </summary>
    public static class PbxUtil
    {
        #region 字段
        public const string InfoPlistName = "Info.plist";

        public const string UnityIPhoneName = "Unity-iPhone";

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
        public static string GetTargetGuid(PBXProject pbx)
        {
            return pbx.TargetGuidByName(UnityIPhoneName);
        }

        /// <summary>
        /// 关闭BitCode
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        public static void DisableBitCode(PBXProject pbx, string guid)
        {
            pbx.SetBuildProperty(guid, "ENABLE_BITCODE", "NO");
        }

        /// <summary>
        /// 添加ObjC
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        public static void AddObjC(PBXProject pbx, string guid)
        {
            pbx.AddBuildProperty(guid, "OTHER_LDFLAGS", "-ObjC");
        }


        /// <summary>
        /// 添加-fobjc-arc
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        public static void Addfobjc_arc(PBXProject pbx, string guid)
        {
            pbx.AddBuildProperty(guid, "OTHER_LDFLAGS", "-fobjc-arc");
        }

        /// <summary>
        /// 添加系统tbd
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        /// <param name="name"></param>
        /// <param name="weak"></param>
        public static void AddTbd(PBXProject pbx, string guid, string name, bool weak = false)
        {
            pbx.AddFrameworkToProject(guid, name + ".tbd", weak);
        }

        public static void AddDylib(PBXProject pbx, string guid, string name, bool weak = false)
        {
            pbx.AddFrameworkToProject(guid, name + ".dylib", weak);
        }

        /// <summary>
        /// 添加系统framework
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        /// <param name="name"></param>
        /// <param name="weak"></param>
        public static void AddFramework(PBXProject pbx, string guid, string name, bool weak = false)
        {
            pbx.AddFrameworkToProject(guid, name + ".framework", weak);
        }


        public static void AddEmbedFramework(PBXProject pbx, string guid, string targetGUID)
        {
            PBXProjectExtensions.AddFileToEmbedFrameworks(pbx, targetGUID, guid);
        }

        /// <summary>
        /// 添加文件
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        /// <param name="src"></param>
        /// <param name="dest"></param>
        /// <param name="tree"></param>
        public static void AddFile(PBXProject pbx, string guid, string src, string dest, PBXSourceTree tree = PBXSourceTree.Source)
        {
            if (File.Exists(src) || Directory.Exists(src))
            {
                var fguid = pbx.AddFile(src, dest, tree);
                pbx.AddFileToBuild(guid, fguid);
            }
        }

        /// <summary>
        /// 开启能力
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        public static void AddCapabilities(PBXProject pbx, string guid, string name)
        {
            var fullName = "{" + name + " = {enabled = 1;};}";
            Debug.LogFormat("Loong AddCapabilities:{0}", fullName);
            pbx.AddBuildProperty(guid, "SystemCapabilities", fullName);
        }

        /// <summary>
        /// 开启通知
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        /// <param name=""></param>
        public static void AddPushNotifications(PBXProject pbx, string guid)
        {
            AddCapabilities(pbx, guid, "com.apple.Push");
        }

        /// <summary>
        /// 设置证书和pp
        /// </summary>
        /// <param name="pbx">Pbx.</param>
        /// <param name="guid">GUID.</param>
        /// <param name="cert">Cert.</param>
        /// <param name="pp">Pp.</param>
        public static void SetCertPP(PBXProject pbx, string guid, string cert, string pp)
        {
            var debugCfg = pbx.BuildConfigByName(guid, "Debug");
            var releaseCfg = pbx.BuildConfigByName(guid, "Release");
            var rForRunning = pbx.BuildConfigByName(guid, "ReleaseForRunning");
            var rForProfiling = pbx.BuildConfigByName(guid, "ReleaseForProfiling");

            var certKey = "CODE_SIGN_IDENTITY";
            pbx.SetBuildPropertyForConfig(debugCfg, certKey, cert);
            pbx.SetBuildPropertyForConfig(releaseCfg, certKey, cert);
            pbx.SetBuildPropertyForConfig(rForRunning, certKey, cert);
            pbx.SetBuildPropertyForConfig(rForProfiling, certKey, cert);

            var ppkey = "PROVISIONING_PROFILE_SPECIFIER";
            pbx.SetBuildPropertyForConfig(debugCfg, ppkey, pp);
            pbx.SetBuildPropertyForConfig(releaseCfg, ppkey, pp);
            pbx.SetBuildPropertyForConfig(rForRunning, ppkey, pp);
            pbx.SetBuildPropertyForConfig(rForProfiling, ppkey, pp);

        }

        /// <summary>
        /// 设置teamID
        /// </summary>
        /// <param name="pbx">Pbx.</param>
        /// <param name="guid">GUID.</param>
        /// <param name="id">Identifier.</param>
        public static void SetTeamID(PBXProject pbx, string guid, string id)
        {
            pbx.SetBuildProperty(guid, "DEVELOPMENT_TEAM", id);
        }


        public static void SetFrameworkSearch(PBXProject pbx, string guid, string path)
        {
            pbx.SetBuildProperty(guid, "FRAMEWORK_SEARCH_PATHS", path);
        }

        /// <summary>
        /// 添加framework搜索路径
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        /// <param name="path"></param>
        public static void AddFrameworkSearch(PBXProject pbx, string guid, string path)
        {
            pbx.AddBuildProperty(guid, "FRAMEWORK_SEARCH_PATHS", path);
        }


        public static void AddHeaderSearch(PBXProject pbx, string guid, string path)
        {
            pbx.AddBuildProperty(guid, "HEADER_SEARCH_PATHS", path);
        }

        public static void AddLibSearch(PBXProject pbx, string guid, string path)
        {
            pbx.AddBuildProperty(guid, "LIBRARY_SEARCH_PATHS", path);
        }
        #endregion
    }
}