//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 14:36:23
//*****************************************************************************

using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// PostGradleJingQi
    /// </summary>
    public class PostGradleJingQi : PostGradle
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
        protected override void OnPostGradle()
        {
            #region rootGralde处理
            var rootModifier = new TextModifier();
            rootModifier.Read(RootGradle);

            rootModifier.Remove(0);

            var maven = "\t\tmaven{\n\t\t\turl \"http://repo.gamedreamer.com/bale/repo\"\n\t\t}";

            rootModifier.WriteBlow(GradleKey.jcenter, maven, false, false);
            rootModifier.WriteBlow(GradleKey.dependencies, "\t\t\tclasspath 'com.google.gms:google-services:4.3.3'");

            rootModifier.Save(RootGradle);
            #endregion


            #region launcherGradle处理
            var launchModifier = new TextModifier();
            launchModifier.Read(LaunchGradle);
            launchModifier.Remove(0);



            var keystore = SdkUtil.GetCfgPath("gat", "gdsdk.keystore");
            keystore = keystore.Replace("\\", "/");
            var signs = "\tsigningConfigs {" +
                "\n\t\trelease {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'gamedreamer'" +
                "\n\t\t\tkeyAlias 'gd'" +
                "\n\t\t\tkeyPassword 'gamedreamer'" +
                "\n\t\t}" +
                "\n\t\tdebug {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'gamedreamer'" +
                "\n\t\t\tkeyAlias 'gd'" +
                "\n\t\t\tkeyPassword 'gamedreamer'" +
                "\n\t\t}" +
                "\n\t}";

            launchModifier.WriteBlow(GradleKey.versionName, signs, false, true, 2);

            var depends = "\timplementation 'com.google.firebase:firebase-messaging:15.0.2'" +
                "\n\timplementation 'com.google.firebase:firebase-core:15.0.2'" +
                "\n\timplementation 'com.google.firebase:firebase-config:15.0.2'" +
                "\n\timplementation 'com.gd:gdsdk-TDWQ:1.6.6.1'";

            launchModifier.WriteBlow(GradleKey.dependencies, depends);
            launchModifier.WriteLast("apply plugin: 'com.google.gms.google-services'");
            launchModifier.Save(LaunchGradle);
            #endregion


            #region 拷贝文件
            var google_service = "google-services.json";
            var srcGoogleJson = SdkUtil.GetCfgPath("gat", google_service);
            var destGoogleJson = Path.Combine(LaunchDir, google_service);
            File.Copy(srcGoogleJson, destGoogleJson, true);
            #endregion
        }
        #endregion

        #region 公开方法

        #endregion
    }
}