using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

namespace Loong.Edit
{
    public class PostGradleHG : PostGradle
    {
        protected override void OnPostGradle()
        {

            #region rootGradlePro 处理
            var rootModifierPro = new TextModifier();
            rootModifierPro.Read(RootGradlePro);
            rootModifierPro.WriteLast("\nandroid.useAndroidX = true\nandroid.enableJetifier = true"); //\nandroid.enableBuildCache=false
            rootModifierPro.Save(RootGradlePro);
            #endregion

            #region 拷贝文件
            var google_service = "google-services.json";
#if SDK_ANDROID_HG
            var srcGoogleJson = SdkUtil.GetCfgPath("hg_google", google_service);
#endif

#if SDK_ONESTORE_HG
            var srcGoogleJson = SdkUtil.GetCfgPath("hg_onestore", google_service);
#endif

#if SDK_SAMSUNG_HG
            var srcGoogleJson = SdkUtil.GetCfgPath("hg_samsung", google_service);
#endif
            var destGoogleJson = Path.Combine(LaunchDir, google_service);
#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
            File.Copy(srcGoogleJson, destGoogleJson, true);
#endif
#endregion

#region rootGradle 处理
            var rootModifier = new TextModifier();
            rootModifier.Read(RootGradle);
            rootModifier.Remove(0);

            rootModifier.WriteBlow("classpath", "\t\t\tclasspath 'com.google.gms:google-services:4.3.3'");
            //新增
            //rootModifier.WriteBlow("classpath", "\t\t\tclasspath 'com.google.firebase:firebase-crashlytics-gradle:2.4.1'");

            //Google adbrix sdk
#if SDK_ANDROID_HG
            rootModifier.WriteBlow("flatDir", "\t\tmaven { url 'https://dl.bintray.com/igaworks/AdbrixRmSDK' }",false,true,3);
#endif

            rootModifier.Save(RootGradle);
#endregion

#region launcherGradle 处理
            var launchModifier = new TextModifier();
            launchModifier.Read(LaunchGradle);
            launchModifier.Remove(0);

#if SDK_ANDROID_HG
            var keystore = SdkUtil.GetCfgPath("hg_google", "PhantomSLRPGA.jks");
            keystore = keystore.Replace("\\", "/");
            var signs = "\tsigningConfigs {" +
                "\n\t\trelease {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t\tdebug {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t}";
            launchModifier.WriteBlow(GradleKey.versionName, signs, false, true, 2);
            launchModifier.WriteLast("apply plugin: 'com.google.gms.google-services'");
            //launchModifier.WriteLast("apply plugin: 'com.google.firebase.crashlytics'"); //新增
            //launchModifier.Save(LaunchGradle);
#endif

#if SDK_ONESTORE_HG
            var keystore = SdkUtil.GetCfgPath("hg_onestore", "PhantomSLRPGA.jks");
            keystore = keystore.Replace("\\", "/");
            var signs = "\tsigningConfigs {" +
                "\n\t\trelease {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t\tdebug {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t}";
            launchModifier.WriteBlow(GradleKey.versionName, signs, false, true, 2);
            launchModifier.WriteLast("apply plugin: 'com.google.gms.google-services'");
            //launchModifier.WriteLast("apply plugin: 'com.google.firebase.crashlytics'"); //新增
            //launchModifier.Save(LaunchGradle);
#endif

#if SDK_SAMSUNG_HG
            var keystore = SdkUtil.GetCfgPath("hg_samsung", "PhantomSLRPGA.jks");
            keystore = keystore.Replace("\\", "/");
            var signs = "\tsigningConfigs {" +
                "\n\t\trelease {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t\tdebug {" +
                "\n\t\t\tstoreFile file('" + keystore + "')" +
                "\n\t\t\tstorePassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t\tkeyAlias 'PhantomSLARPGA'" +
                "\n\t\t\tkeyPassword 'Phantom2017forever86SLRPGA'" +
                "\n\t\t}" +
                "\n\t}";
            launchModifier.WriteBlow(GradleKey.versionName, signs, false, true, 2);
            launchModifier.WriteLast("apply plugin: 'com.google.gms.google-services'");
            //launchModifier.WriteLast("apply plugin: 'com.google.firebase.crashlytics'"); //新增
            //launchModifier.Save(LaunchGradle);
#endif

            var depends = "\timplementation  'com.google.firebase:firebase-core:17.4.4'" +
                "\n\timplementation 'com.google.firebase:firebase-auth:19.3.2'" +
                "\n\timplementation 'com.google.android.gms:play-services-auth:18.1.0'" +
                "\n\timplementation 'com.facebook.android:facebook-login:5.15.3'" +
                "\n\timplementation 'com.android.billingclient:billing:3.0.0'" +
                "\n\timplementation 'com.google.firebase:firebase-messaging-directboot:20.2.4'" +
                //"\n\timplementation 'com.google.firebase:firebase-crashlytics:17.3.0'" + //新增
                "\n\timplementation 'com.google.firebase:firebase-analytics:18.0.0'" +
                "\n\timplementation 'com.google.firebase:firebase-messaging:20.2.4'";

            //Google adbrix sdk
#if SDK_ANDROID_HG
            depends = depends +
                "\n\timplementation 'com.google.android.gms:play-services-ads:15.0.0'" +
                "\n\timplementation 'com.android.installreferrer:installreferrer:1.0'" +
                "\n\timplementation 'com.igaworks.adbrix:abx-common-rm:+'";
#endif


            launchModifier.WriteBlow(GradleKey.dependencies, depends);
            launchModifier.Save(LaunchGradle);
#endregion



#region UnityGradle 处理
            //var unityModifier = new TextModifier();
            //unityModifier.Read(UnityGradle);
            //var depends = "\timplementation  'com.google.firebase:firebase-core:17.4.4'" +
            //    "\n\timplementation  'com.google.firebase:firebase-auth:19.3.2'" +
            //    "\n\timplementation  'com.google.android.gms:play-services-auth:18.1.0'" +
            //    "\n\timplementation 'com.facebook.android:facebook-login:5.15.3'"+
            //    "\n\timplementation 'com.android.billingclient:billing:3.0.0'"+
            //    "\n\timplementation 'com.google.firebase:firebase-analytics:17.4.4'" +
            //    "\n\timplementation 'com.google.firebase:firebase-messaging:20.2.4'";

            //unityModifier.WriteBlow(GradleKey.dependencies, depends);
            //unityModifier.Save(UnityGradle);
#endregion

        }
    }
}


