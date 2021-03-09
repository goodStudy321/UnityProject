//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/3/12 21:27:00
//*****************************************************************************

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
    /// EditSdkGat
    /// </summary>
    public class EditSdkGat : EditiOSSdk
    {
        #region 字段
        public override string PP
        {
            get { return "originmood.hyxl.dev"; }
        }

        public override string Des
        {
            get { return "gat"; }
        }

        public override string Cert
        {
            get { return "iPhone Developer: chung lai cheung (2BK5ZN86FZ)"; }
        }

        public override string TeamID
        {
            get { return "2YH6AG45P9"; }
        }

        public override string BundleID
        {
            get { return "com.originmood.hyxl"; }
        }

        public override string AppName => "花語仙戀";
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
        protected override void SetPbx(string proPath, string guid, string projPath, string targetName)
        {
            AddFile(guid, proPath, "GamedreamerResources.bundle");

            var fguid1 = AddFile(guid, proPath, "Gamedreamer.framework");
            var targetGUID = pbx.TargetGuidByName(targetName);
            AddEmbedFramework(pbx, fguid1, targetGUID);

            var res = SdkUtil.GetResDir(Des);
            AddOnlyFile(guid, proPath, res, "GoogleService-Info.plist");

            pbx.SetBuildProperty(targetGUID, "LD_RUNPATH_SEARCH_PATHS", "$(inherited) @executable_path/Frameworks");
        }

        protected override void SetPlist(PlistDocument plist)
        {
            base.SetPlist(plist);
            var root = plist.root;
            var urlTypeArr = root.CreateArray("CFBundleURLTypes");
            var urlDic = urlTypeArr.AddDict();
            var arr0 = urlDic.CreateArray("CFBundleURLSchemes");


            root.Remove("UIApplicationExitsOnSuspend");

            #region Facebook

            string fbID = "335351587095392";
            arr0.AddString("fb" + fbID);

            root.SetString("FacebookAppID", fbID);
            #endregion


            #region Line
            var lineDic = root.CreateDict("LineSDKConfig");
            lineDic.SetString("ChannelID", "1653886901");

            var urlDic2 = urlTypeArr.AddDict();
            var arr2 = urlDic2.CreateArray("CFBundleURLSchemes");
            arr2.AddString("line3rdp.$(PRODUCT_BUNDLE_IDENTIFIER)");


            var urlDic3 = urlTypeArr.AddDict();
            var arr3 = urlDic3.CreateArray("CFBundleURLSchemes");
            var lineurl3 = "line3rdp." + BundleID;
            arr3.AddString(lineurl3);

            var urlDic4 = urlTypeArr.AddDict();
            var arr4 = urlDic4.CreateArray("CFBundleURLSchemes");
            arr4.AddString("cydia");
            #endregion


            #region 权限
            var schemeArr = root.CreateArray("LSApplicationQueriesSchemes");
            schemeArr.AddString("fbauth2");
            schemeArr.AddString("line3rdp.$(PRODUCT_BUNDLE_IDENTIFIER)");
            schemeArr.AddString(lineurl3);
            schemeArr.AddString("lineauth");
            schemeArr.AddString("fbshareextension");
            schemeArr.AddString("fbapi");
            schemeArr.AddString("cydia");


            root.SetString("NSPhotoLibraryUsageDescription", "將您的遊客安全資料存儲到手機相冊");
            root.SetString("NSPhotoLibraryAddUsageDescription", "將您的遊客安全資料存儲到手機相冊");
            root.SetString("NSLocationWhenInUseUsageDescription", "app需要您的同意，才能使用位置權限");

            #endregion
        }

        protected override void SetCapabilities(string proPath, string guid)
        {
            var entiPath = "gat.entitlements";
            var cap = new ProjectCapabilityManager(proPath, entiPath, guid);
            cap.AddPushNotifications(true);
            cap.WriteToFile();
        }

        protected override XClass Modify(string proPath, string header, string initBlock = "\t[[Sdk instance] Init:application options:launchOptions];")
        {
            var uappCtrl = base.Modify(proPath, header, initBlock);
            if (uappCtrl == null) return null;

            var b1 = "AppController_SendNotificationWithArg(kUnityOnOpenURL, notifData);\n    return YES;";
            var t1 = "AppController_SendNotificationWithArg(kUnityOnOpenURL, notifData);\n\treturn [[GamedreamerManager shareInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];";
            uappCtrl.Replace(b1, t1);


            var b2 = "- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions";
            var t2 = "- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {\n\treturn [[GamedreamerManager shareInstance] application: application continueUserActivity:userActivity restorationHandler:restorationHandler];\n}\n\n- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {\n\treturn [[GamedreamerManager shareInstance] application: application handleOpenURL:url];\n}\n\n- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {\n\tNSString* sourceApplication = [options objectForKey: UIApplicationOpenURLOptionsSourceApplicationKey];\n\tid annotation = [options objectForKey: UIApplicationOpenURLOptionsAnnotationKey];\n\treturn [[GamedreamerManager shareInstance] application: app openURL:url sourceApplication:sourceApplication annotation:annotation];\n}\n\n- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions";
            uappCtrl.Replace(b2, t2);

            var b3 = "::printf(\"-> applicationWillResignActive()\\n\");";
            var t3 = "\t[[GamedreamerManager shareInstance] applicationWillResignActive:application];";

            uappCtrl.Write(b3, t3);


            var b4 = "::printf(\"-> applicationDidEnterBackground()\\n\");";
            var t4 = "\t[[GamedreamerManager shareInstance] applicationDidEnterBackground:application];";
            uappCtrl.Write(b4, t4);

            var b5 = "::printf(\"-> applicationWillEnterForeground()\\n\");";
            var t5 = "\t[[GamedreamerManager shareInstance] applicationWillEnterForeground:application];";
            uappCtrl.Write(b5, t5);


            var b6 = "::printf(\"-> applicationDidBecomeActive()\\n\");";
            var t6 = "\t[[GamedreamerManager shareInstance] applicationDidBecomeActive:application];";
            uappCtrl.Write(b6, t6);

            var b7 = "::printf(\"-> applicationWillTerminate()\\n\");";
            var t7 = "\t[[GamedreamerManager shareInstance] applicationWillTerminate:application];";
            uappCtrl.Write(b7, t7);


            var b8 = "UnitySendDeviceToken(deviceToken);";
            var t8 = "\t[[GamedreamerManager shareInstance] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];";
            uappCtrl.Write(b8, t8);


            var b9 = "UnitySendRemoteNotificationError(error);";
            var t9 = "\t[[GamedreamerManager shareInstance] application:application didFailToRegisterForRemoteNotificationsWithError:error];";
            uappCtrl.Write(b9, t9);

            var b10 = "[KeyboardDelegate Initialize];";
            var t10 = "\t[[Sdk instance] Init:application options:launchOptions];";
            uappCtrl.Write(b10, t10);


            return uappCtrl;

        }
        #endregion

        #region 公开方法


        public override void End(StrDic dic, string proPath)
        {
            base.End(dic, proPath);

            Modify(proPath, "<Gamedreamer/Gamedreamer.h>", null);
        }
        #endregion
    }
}