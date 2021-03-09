/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/17 2:41:25
 ============================================================================*/

using System;
using System.IO;
using Loong.iOS;
using Loong.Game;
using UnityEditor;
using UnityEngine;
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
    /// JH_IOS_SDK_Processor
    /// </summary>
    public class EditJHiOSSdk : EditiOSSdk
    {
        #region 字段

        #endregion

        #region 属性
        public override string PP
        {
            get { return "tdwq.dev"; }
        }

        public override string Des
        {
            get { return "junhai"; }
        }

        public override string Cert
        {
            get { return "iPhone Developer: Zhilun Deng (XGCE9BE2MP)"; }
        }

        public override string TeamID
        {
            get { return "NFTVSJ4FK7"; }
        }

        public override string BundleID
        {
            get { return "com.junhai.xyjgx.appstore"; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        protected override void SetPbx(string proPath, string guid, string projPath, string targetName)
        {

            //添加系统库
            AddTbd("libz");
            AddTbd("libsqlite3");

            AddFramework("WebKit");
            AddFramework("StoreKit");
            AddFramework("Security");
            AddFramework("EventKit");
            AddFramework("MessageUI");
            AddFramework("AdSupport");
            AddFramework("CFNetwork");
            AddFramework("EventKitUI");
            AddFramework("MediaPlayer");
            AddFramework("AudioToolbox");
            AddFramework("AVFoundation");
            AddFramework("CoreGraphics");

            AddFramework("CoreLocation");
            AddFramework("CoreTelephony");
            AddFramework("JavaScriptCore");
            AddFramework("MobileCoreServices");
            AddFramework("SystemConfiguration");


            //添加第三方库
            var fmName = "LokiUnionSDK.framework";
            var bdName = "LokiUnionSDKSrc.bundle";
            AddFile(guid, proPath, fmName);
            AddFile(guid, proPath, bdName);


        }

        protected override void SetPlist(PlistDocument plist)
        {
            base.SetPlist(plist);
            var root = plist.root;

            root.SetString("NSPhotoLibraryAddUsageDescription", "App需要您的同意,才能访问媒体资料库，从而把账号和密码保存到相册中，当您忘记账号密码可在相册中找回");
            root.SetString("NSPhotoLibraryUsageDescription", "App需要您的同意,才能访问相册，从而把账号和密码保存到相册中，当您忘记账号密码可在相册中找回");
            root.SetString("NSCalendarsUsageDescription", "App需要您的同意,才能访问日历");
        }

        protected override void SetCapabilities(string proPath, string guid)
        {
            var entiPath = "junhai.entitlements";
            var cap = new ProjectCapabilityManager(proPath, entiPath, guid);
            cap.AddPushNotifications(true);
            cap.WriteToFile();
        }

        private void Modify(string proPath)
        {
            var uappCtrlPath = proPath + "/Classes/UnityAppController.mm";
            if (!File.Exists(uappCtrlPath))
            {
                Debug.LogErrorFormat("Loong,{0} not exist");
                return;
            }
            var uappCtrl = new XClass(uappCtrlPath);
            var header = "#import \"UnityAppController.h\"";
            var headerBlock = "#import <LokiUnionSDK/LokiUnionSDK.h>";

            var didBecameActive = "- (void)applicationDidBecomeActive:(UIApplication*)application\n{\n";
            var didBecameActiveBlock = "\t[[SDKCenter sharedSDKCenter]applicationDidBecomeActive:application];";
            var willTerminate = "- (void)applicationWillTerminate:(UIApplication*)application\n{\n";
            var willTerminateBlock = "\t[[SDKCenter sharedSDKCenter]applicationWillTerminate:application];";
            uappCtrl.Write(header, headerBlock);
            uappCtrl.Write(didBecameActive, didBecameActiveBlock);
            uappCtrl.Write(willTerminate, willTerminateBlock);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void End(StrDic dic, string proPath)
        {
            base.End(dic, proPath);
            Modify(proPath);
        }
        #endregion
    }
}