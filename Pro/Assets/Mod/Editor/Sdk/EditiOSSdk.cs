/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 14:30:30
 ============================================================================*/

using System;
using Loong.iOS;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

#if UNITY_XCODE_API_BUILD
using UnityEditor.iOS.Xcode;
#else
using UnityEditor.iOS.Xcode.Custom;
#endif

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;
    /// <summary>
    /// iOS SDK处理
    /// </summary>
    public class EditiOSSdk : EditSdkBase
    {
        #region 字段
        protected PBXProject pbx = null;

        protected PlistDocument plist = null;

        protected HashSet<string> tbdSet = new HashSet<string>();

        protected HashSet<string> dylibSet = new HashSet<string>();

        protected HashSet<string> frameworkSet = new HashSet<string>();


        public const string key = "-sdk_ios";

        /// <summary>
        /// ios sdk预处理指令字典 k:预处理指令字符 v:sdk文件夹名
        /// </summary>
        public static readonly StrDic cmdDic = new StrDic()
        {
            { "SDK_IOS_NONE",null },
            { "SDK_IOS_GAT","gat" },
            { "SDK_IOS_HW_SGMY","symy" },
        };


        #endregion

        #region 属性
        public override string Plat
        {
            get { return "iOS"; }
        }
        /// <summary>
        /// ios SDK预处理指令键值
        /// </summary>
        public override string SdkKey
        {
            get { return key; }
        }

        public override StrDic CmdDic
        {
            get { return cmdDic; }
        }
        public virtual string PP
        {
            get { return "SLRPGA1.0_DEV"; }
        }

        public virtual string Cert
        {
            get { return "Apple Development: Li Zha (N6896H53XQ)"; }
        }

        public virtual string TeamID
        {
            get { return "3P7J3D5T66"; }
        }



        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void BegPlist(string proPath)
        {
            var pListPath = Path.Combine(proPath, PbxUtil.InfoPlistName);
            if (File.Exists(pListPath))
            {
                plist = new PlistDocument();
                plist.ReadFromFile(pListPath);
            }
            else
            {
                Debug.LogErrorFormat("Loong, {0} not exist", pListPath);
            }
        }


        private void EndPlist(string proPath)
        {
            var pListPath = Path.Combine(proPath, PbxUtil.InfoPlistName);
            if (File.Exists(pListPath))
            {
                plist.WriteToFile(pListPath);
            }
        }
        #endregion

        #region 保护方法
        protected void Clear()
        {
            tbdSet.Clear();
            frameworkSet.Clear();
        }

        /// <summary>
        /// 添加动态库到集合中
        /// </summary>
        /// <param name="name"></param>
        protected void AddTbd(string name)
        {
            if (tbdSet.Contains(name)) return;
            tbdSet.Add(name);
        }

        protected void AddDylib(string name)
        {
            if (dylibSet.Contains(name)) return;
            dylibSet.Add(name);
        }

        /// <summary>
        /// 添加框架到集合中
        /// </summary>
        /// <param name="name"></param>
        protected void AddFramework(string name)
        {
            if (frameworkSet.Contains(name)) return;
            frameworkSet.Add(name);
        }

        /// <summary>
        /// 将集合中的动态库添加
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        protected void AddTbd(PBXProject pbx, string guid)
        {
            var em = tbdSet.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                PbxUtil.AddTbd(pbx, guid, it);
            }
        }

        protected void AddDylib(PBXProject pbx, string guid)
        {
            var em = dylibSet.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                PbxUtil.AddDylib(pbx, guid, it);
            }
        }

        /// <summary>
        /// 将集合中的框架添加
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        protected void AddFramework(PBXProject pbx, string guid)
        {
            var em = frameworkSet.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                PbxUtil.AddFramework(pbx, guid, it);
            }
        }

        protected void AddEmbedFramework(PBXProject pbx, string guid, string targetGUID)
        {
            PbxUtil.AddEmbedFramework(pbx, guid, targetGUID);
        }

        /// <summary>
        /// 将集合中的动态库和框架添加
        /// </summary>
        /// <param name="pbx"></param>
        /// <param name="guid"></param>
        protected void AddTbdFramework(PBXProject pbx, string guid)
        {
            AddTbd(pbx, guid);
            AddDylib(pbx, guid);
            AddFramework(pbx, guid);
        }

        /// <summary>
        /// 设置bugly需要的框架
        /// </summary>
        protected void SetBuglyFramework()
        {
            AddTbd("libz");
            AddTbd("libc++");
            AddFramework("Security");
            AddFramework("JavaScriptCore");
            AddFramework("SystemConfiguration");
        }

        /// <summary>
        /// 设置呀呀云语音SDK框架
        /// </summary>
        protected void SetCloudVoiceFramework()
        {
            AddTbd("libz");
            AddTbd("libc++");
            AddFramework("ImageIO");
            AddFramework("Security");
            AddFramework("SafariServices");
        }


        protected string AddFile(string guid, string proPath, string name)
        {
            var path = GetPath(Des, name);
            return AddFile(guid, proPath, path, name);
        }

        /// <summary>
        /// 添加目录
        /// </summary>
        /// <param name="guid"></param>
        /// <param name="proPath">build路径</param>
        /// <param name="srcPath">添加文件路径</param>
        /// <param name="name">名称</param>
        protected string AddFile(string guid, string proPath, string srcPath, string name)
        {
            var dest = proPath + "/" + name;
            EditDirUtil.Copy(srcPath, dest);
            var fguid = pbx.AddFile(name, name, PBXSourceTree.Source);
            pbx.AddFileToBuild(guid, fguid);
            return fguid;
        }

        /// <summary>
        /// 添加文件
        /// </summary>
        /// <param name="guid"></param>
        /// <param name="proPath"></param>
        /// <param name="name"></param>
        protected void AddOnlyFile(string guid, string proPath, string srcDir, string name)
        {
            var src = Path.Combine(srcDir, name);
            var dest = proPath + "/" + name;
            File.Copy(src, dest, true);
            var fguid = pbx.AddFile(name, name, PBXSourceTree.Source);
            pbx.AddFileToBuild(guid, fguid);
        }

        /// <summary>
        /// 添加bugly.framework
        /// </summary>
        /// <param name="guid"></param>
        /// <param name="proPath"></param>
        protected void AddBuglyFramework(string guid, string proPath)
        {
            var buglyFw = "../sdk_root/Bugly/bugly_plugin_v1.5.3/BuglySDK/iOS/Bugly.framework";
            if (!Directory.Exists(buglyFw)) return;
            var name = "Bugly.framework";

            AddFile(guid, proPath, buglyFw, name);
        }


        /// <summary>
        /// 清理WWW缓存
        /// </summary>
        protected void ClearWWWCache(string proPath)
        {
            var wwwConnectPath = proPath + "/Classes/Unity/WWWConnection.mm";
            if (File.Exists(wwwConnectPath))
            {
                var wwwConnectMM = new XClass(wwwConnectPath);
                var src = "    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];";
                var dest = "\trequest.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;\n\t[request setHTTPShouldHandleCookies: NO]; ";
                wwwConnectMM.Write(src, dest);
            }
            else
            {
                Debug.LogErrorFormat("Loong, 清理WWW not exist:{0}", wwwConnectPath);
            }
        }

        /// <summary>
        /// 设置语言
        /// </summary>
        protected virtual void SetPlist(PlistDocument plist)
        {
            if (plist == null) return;
            var root = plist.root;
            var lang = BuildArgs.Language;
            root.SetString("CFBundleDevelopmentRegion", lang);


            //语音SDK权限
            root.SetString("NSMicrophoneUsageDescription", "请求获取此设备的访问麦克风权限以启用语音聊天");
            //相册SDK摄像头权限
            root.SetString("NSCameraUsageDescription", "App需要您的同意,才能访问摄像头,从而使您有更好的游戏体验");
        }

        protected virtual void SetIcon(string name)
        {
            var path = string.Format("Assets/Icon/{0}", name);
            var icon = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            if (icon == null) return;
            int length = 19;
            var icons = new Texture2D[length];
            for (int i = 0; i < length; i++)
            {
                icons[i] = icon;
            }
            PlayerSettings.SetIconsForTargetGroup(BuildTargetGroup.iOS, icons);
            AssetDatabase.SaveAssets();
        }

        protected virtual void SetLogo(string name)
        {
            var src = string.Format("./Assets/Icon/{0}", name);
            var to = string.Format("./Assets/StreamingAssets/chg/logo.png");
            File.Copy(src, to, true);
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 设置闪屏
        /// </summary>
        /// <param name="proPath"></param>
        protected virtual void SetSplash(string proPath)
        {
            var srcDir = SdkUtil.GetSplashDir(Des);
            var destDir = proPath + "/Unity-iPhone/Images.xcassets/LaunchImage.launchimage/";
            Copy(srcDir, destDir);
        }

        /// <summary>
        /// 设置解压进度条
        /// </summary>
        /// <param name="proPath"></param>
        protected void SetLoading(string proPath)
        {
            var srcDir = SdkUtil.GetLoadingDir(Des);
            var destDir = proPath + "/Data/Raw/chg/";
            Copy(srcDir, destDir);
        }

        protected void Copy(string srcDir, string destDir)
        {
            if (!Directory.Exists(srcDir))
            {
                iTrace.Error("Loong", "srcDir:{0} not exist", srcDir);
                return;
            }
            if (!Directory.Exists(destDir))
            {
                iTrace.Error("Loong", "destDir:{0} not exist", destDir);
                return;
            }
            var files = Directory.GetFiles(srcDir);
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var src = files[i];
                var name = Path.GetFileName(src);
                var dest = destDir + name;
                File.Copy(src, dest, true);
            }
        }

        protected void SetPbx(string proPath)
        {
            //Beg
            var projPath = PBXProject.GetPBXProjectPath(proPath);
            pbx = new PBXProject();
            pbx.ReadFromString(File.ReadAllText(projPath));
            var guid = PbxUtil.GetTargetGuid(pbx);
            PbxUtil.AddObjC(pbx, guid);
            PbxUtil.DisableBitCode(pbx, guid);
            var targetName = PBXProject.GetUnityTargetName();

            AddFramework("AdSupport");
            AddFramework("CoreTelephony");

            SetPbx(proPath, guid, projPath, targetName);

            //End
            AddBuglyFramework(guid, proPath);

            AddTbdFramework(pbx, guid);

            //设置库搜索路径
            PbxUtil.SetFrameworkSearch(pbx, guid, "$(inherited)");
            PbxUtil.AddFrameworkSearch(pbx, guid, "$(PROJECT_DIR)");

            PbxUtil.SetCertPP(pbx, guid, Cert, PP);
            PbxUtil.SetTeamID(pbx, guid, TeamID);

            File.WriteAllText(projPath, pbx.WriteToString());

            SetCapabilities(projPath, targetName);
        }

        protected virtual void SetPbx(string proPath, string guid, string projPath, string targetName)
        {

        }

        protected virtual XClass Modify(string proPath, string header, string initBlock = "\t[[Sdk instance] Init];")
        {
            var uappCtrlPath = proPath + "/Classes/UnityAppController.mm";
            if (!File.Exists(uappCtrlPath))
            {
                Debug.LogErrorFormat("Loong,{0} not exist");
                return null;
            }
            var uappCtrl = new XClass(uappCtrlPath);
            var headerBlow = "#import \"UnityAppController.h\"";
            string headerBlock = null;
            if (string.IsNullOrEmpty(header))
            {
                headerBlock = "\n#import \"Sdk.h\"";
            }
            else
            {
                headerBlock = string.Format("#import {0}\n#import \"Sdk.h\"", header);
            }

            uappCtrl.Write(headerBlow, headerBlock);

            if (!string.IsNullOrEmpty(initBlock))
            {
                var didFinish = "::printf(\"-> applicationDidFinishLaunching()\\n\");";
                uappCtrl.Write(didFinish, initBlock);
            }
            return uappCtrl;
        }

        protected virtual void SetCapabilities(string proPath, string guid)
        {

        }

        #endregion

        #region 公开方法
        public static void SetPreprocess(StrDic dic)
        {
            ReleasePreprocessUtil.Switch(dic, cmdDic, key);
        }

        public override void Beg(StrDic dic)
        {
            base.Beg(dic);
            SetBundleID(BuildTargetGroup.iOS, BundleID);
        }

        public override void End(StrDic dic, string proPath)
        {
            base.End(dic, proPath);
            Clear();
            ClearWWWCache(proPath);
            SetBuglyFramework();
            SetCloudVoiceFramework();
            BegPlist(proPath);
            SetPlist(plist);
            EndPlist(proPath);
            SetPbx(proPath);

            SetSplash(proPath);
            SetLoading(proPath);
        }
        #endregion
    }
}