//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/6 11:39:54
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Diagnostics;
using System.Collections;
using UnityEditor.Callbacks;
using System.Collections.Generic;

namespace Loong.Edit
{
    using PT = EditPrefsTool;
    using iTrace = Loong.Game.iTrace;
    /// <summary>
    /// ReleaseCSHotfix
    /// </summary>
    public static class ReleaseCSHotfix
    {
        #region 字段

        private static StringBuilder sb = new StringBuilder();

        private static List<string> moduleDlls = new List<string>();

        public const string isPreprocess = "IsPreprocess";

        //public const string CSC = @"C:\Windows\Microsoft.NET\Framework64\v2.0.50727\csc.exe";

        public const string CSC = @"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe";

        public const int Pri = CSHotfixUtil.Pri + 10;

        public const string menu = CSHotfixUtil.menu + "生成/";

        public const string AMenu = CSHotfixUtil.AMenu + "生成/";

        /// <summary>
        /// 必须的符号
        /// </summary>
        public const string preDefines = "UNITY_5_3_OR_NEWER;UNITY_5_4_OR_NEWER;UNITY_5_5_OR_NEWER;UNITY_5_6_OR_NEWER;UNITY_5_6_6;UNITY_5_6;UNITY_5;UNITY_ANDROID;NET_2_0_SUBSET;CROSS_PLATFORM_INPUT;MOBILE_INPUT;LOONG_USE_ZIP;LOONG_SPLIT_ZIP;AMPLIFY_SHADER_EDITOR;GAME_GUIDE;ENABLE_POSTPROCESS;LOONG_AB_SYNC;CS_HOTFIX_ENABLE;LOONG_ENABLE_UPG;LOONG_ENABLE_LUA;";

        public const string EnableSubAssetPath = menu + "激活分包";
        #endregion

        #region 属性
        public static bool IsPreprocess
        {
            get { return PT.GetBool(typeof(ReleaseCSHotfix), isPreprocess); }
            set { PT.SetBool(typeof(ReleaseCSHotfix), isPreprocess, value); }
        }

        public static bool EnableSubAsset
        {
            get { return PT.GetBool(typeof(ReleaseCSHotfix), "EnableSubAsset", true); }
            set { PT.SetBool(typeof(ReleaseCSHotfix), "EnableSubAsset", value); }
        }

        public static string Select
        {
            get { return PT.GetString(typeof(ReleaseCSHotfix), "Select"); }
            set { PT.SetString(typeof(ReleaseCSHotfix), "Select", value); }
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
        private static bool Check()
        {
            if (!File.Exists(CSC))
            {
                iTrace.Error("Loong", "未安装.Net4.0");
                return false;
            }
            return true;
        }

        [MenuItem(EnableSubAssetPath, false, Pri)]
        private static void SetEnableSubAsset()
        {
            EnableSubAsset = !EnableSubAsset;
        }

        [MenuItem(EnableSubAssetPath, true, Pri)]
        private static bool GetEnableSubAsset()
        {
            var val = EditPrefsTool.GetBool(typeof(ReleaseCSHotfix), "EnableSubAsset");
            Menu.SetChecked(EnableSubAssetPath, val);
            return true;
        }

        [DidReloadScripts]
        private static void GenOnPreprocess()
        {
            if (!IsPreprocess) return;
            IsPreprocess = false;
            ProgressBarUtil.Clear();
            ToLuaMenu.DeleteAndGenerate();
            Gen(Select);
        }

        /// <summary>
        /// 设置引用
        /// </summary>
        /// <param name="curDir"></param>
        private static bool SetReference(string curDir)
        {
            if (!SetModuleDllsRef()) return false;
            
            //var unityDir = MicroSoftUtil.UnityDir;
            //var unityEngine = unityDir + "/Data/Managed/UnityEngine.dll";
            //if (!AddReference(unityEngine)) return false;

            var firstPass = curDir + "/Library/ScriptAssemblies/Assembly-CSharp-firstpass.dll";
            if (!AddReference(firstPass)) return false;

            var uiDll = curDir + "/Library/ScriptAssemblies/UnityEngine.UI.dll";
            if (!AddReference(uiDll)) return false;


            var pluginDir = curDir + "/Assets/Plugins/";
            var csstring = pluginDir + "CString.dll";
            if (!AddReference(csstring)) return false;

            var debugger = pluginDir + "Debugger.dll";
            if (!AddReference(debugger)) return false;
            

            //var symCore = unityDir + "/Data/Mono/lib/mono/unity/System.Core.dll";
            //if (!AddReference(symCore)) return false;

            //var dotNet2Dir = @"C:\Windows\Microsoft.NET\Framework64\v2.0.50727\";
            //if (!Directory.Exists(dotNet2Dir))
            //{
            //    iTrace.Error("Loong", "未安装.net2.0"); return false;
            //}

            var dotNet4_5Dir = @"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\";
            if (!Directory.Exists(dotNet4_5Dir))
            {
                iTrace.Error("Loong", "未安装.net4.5"); return false;
            }

            //if (!AddReference(dotNet2Dir + "mscorlib.dll")) return false;

            //if (!AddReference(dotNet2Dir + "System.Data.dll ")) return false;

            if (!AddReference(dotNet4_5Dir + "mscorlib.dll")) return false;

            if (!AddReference(dotNet4_5Dir + "System.Core.dll ")) return false;

            if (!AddReference(dotNet4_5Dir + "System.Data.dll ")) return false;

            if (!AddReference(dotNet4_5Dir + "System.dll ")) return false;

            if (!AddReference(dotNet4_5Dir + "System.Xml.dll ")) return false;

            return true;
        }


        /// <summary>
        /// 设置模块dll
        /// </summary>
        /// <returns></returns>
        private static bool SetModuleDllsRef()
        {
            var unityDir = MicroSoftUtil.UnityDir;
            var unityDllDir = unityDir + "/Data/Managed/UnityEngine/";
            AddModuleDlls();
            string moduleDllPath = null;
            for(int i = 0; i < moduleDlls.Count; i++)
            {
                moduleDllPath = unityDllDir + moduleDlls[i];
                if (!AddReference(moduleDllPath)) return false;
            }
            return true;
        }

        /// <summary>
        /// 增加模块dll
        /// </summary>
        private static void AddModuleDlls()
        {
            if (moduleDlls.Count != 0)
                return;
            moduleDlls.Add("UnityEngine.AndroidJNIModule.dll");
            moduleDlls.Add("UnityEngine.AnimationModule.dll");
            moduleDlls.Add("UnityEngine.AssetBundleModule.dll");
            moduleDlls.Add("UnityEngine.AudioModule.dll");
            moduleDlls.Add("UnityEngine.CoreModule.dll");
            moduleDlls.Add("UnityEngine.IMGUIModule.dll");
            moduleDlls.Add("UnityEngine.InputLegacyModule.dll");
            moduleDlls.Add("UnityEngine.JSONSerializeModule.dll");
            moduleDlls.Add("UnityEngine.ParticleSystemModule.dll");
            moduleDlls.Add("UnityEngine.PhysicsModule.dll");
            moduleDlls.Add("UnityEngine.TextRenderingModule.dll");
            moduleDlls.Add("UnityEngine.UnityWebRequestAssetBundleModule.dll");
            moduleDlls.Add("UnityEngine.UnityWebRequestAudioModule.dll");
            moduleDlls.Add("UnityEngine.UnityWebRequestModule.dll");
            moduleDlls.Add("UnityEngine.UnityWebRequestTextureModule.dll");
            moduleDlls.Add("UnityEngine.UnityWebRequestWWWModule.dll");
            moduleDlls.Add("UnityEngine.UIModule.dll");
            moduleDlls.Add("UnityEngine.ImageConversionModule.dll");
            moduleDlls.Add("UnityEngine.VideoModule.dll");

        }

        /// <summary>
        /// 添加引用
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        private static bool AddReference(string path)
        {
            if (File.Exists(path))
            {
                sb.Append("/reference:").Append(path).Append(" ");
                return true;
            }
            else
            {
                iTrace.Error("Loong", "程序集:{0} 不存在!", path);
                return false;
            }
        }


        /// <summary>
        /// 设置预处理指令
        /// </summary>
        /// <param name="syms"></param>
        private static void SetPreprocess(params string[] syms)
        {
            if (syms == null || syms.Length < 1) return;
            sb.Append("/d:").Append(preDefines);
            int length = syms.Length;
            for (int i = 0; i < length; i++)
            {
                sb.Append(syms[i]);
                sb.Append(";");
            }
            if (EnableSubAsset) sb.Append(Preprocess.SUB_ASSET);
            sb.Append(" ");
        }

        private static void SetAppConfig(string curDir)
        {
            var appConfigPath = curDir + "/Assets/Mod/Script/Editor/Release/gen_cs_lib.config";
            sb.Append("/appconfig:").Append(appConfigPath).Append(" ");
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Gen(params string[] syms)
        {
            if (!Check()) return;
            var lastDir = Directory.GetCurrentDirectory();
            var outPath = Path.GetFullPath(CSHotfixUtil.GetCodePath());
            sb.Append("/out:").Append(outPath).Append(" ");
            sb.Append("/target:library ");
            sb.Append("/platform:anycpu ");
            sb.Append("/optimize+ ");
            sb.Append("/debug- ");
            sb.Append("/nostdlib ");
            sb.Append("/langversion:default ");
            sb.Append("/noconfig ");
            sb.Append("/utf8output ");

            //SetAppConfig(lastDir);

            //设置引用
            if (!SetReference(lastDir)) return;

            //添加预处理指令
            SetPreprocess(syms);

            sb.Append("/recurse:*.cs");
            CSHotfixUtil.DeleteFromLib();
            CSHotfixUtil.MoveToLib();
            var fullDir = Path.Combine(CSHotfixUtil.LibDir, "Assets");
            Directory.SetCurrentDirectory(fullDir);

            ProcessUtil.Start(CSC, sb.ToString(), "生成CS库", false);

            Directory.SetCurrentDirectory(lastDir);

        }

        public static void GenWrap(string symbol)
        {
            ProgressBarUtil.Show("请稍候", "生成Wrap中");
            Select = symbol;
            IsPreprocess = true;
            PreprocessCmdUtil.Init();
            PreprocessCmdUtil.Switch(EditAndroidSdk.cmdDic, symbol);
            PreprocessCmdUtil.Mutex(EnableSubAsset, Preprocess.SUB_ASSET);
            PreprocessCmdUtil.Apply();
            CompileUtil.Refresh();
        }


        public static void GenJH()
        {
#if SDK_ANDROID_HG
            Gen(Preprocess.SDK_ANDROID_HG);
#endif
#if SDK_ONESTORE_HG
            Gen(Preprocess.SDK_ONESTORE_HG);
#endif
#if SDK_SAMSUNG_HG
            Gen(Preprocess.SDK_SAMSUNG_HG);
#endif
        }

        public static void GenSL()
        {
            Gen(Preprocess.SDK_ANDROID_NONE);
        }

        public static void GenWrapJH()
        {
#if SDK_ANDROID_HG
            GenWrap(Preprocess.SDK_ANDROID_HG);
#endif
#if SDK_ONESTORE_HG
            GenWrap(Preprocess.SDK_ONESTORE_HG);
#endif

#if SDK_SAMSUNG_HG
            GenWrap(Preprocess.SDK_SAMSUNG_HG);
#endif
        }

        public static void GenWrapSL()
        {
            GenWrap(Preprocess.SDK_ANDROID_NONE);
        }

        [MenuItem(menu + "生成韩国库", false, Pri + 1)]
        [MenuItem(AMenu + "生成韩国库", false, Pri + 1)]
        public static void GenJHDialog()
        {
            DialogUtil.Show("", "生成君海库", GenJH);
        }

        [MenuItem(menu + "生成蜃龙库", false, Pri + 2)]
        [MenuItem(AMenu + "生成蜃龙库", false, Pri + 2)]
        public static void GenSLDialog()
        {
            DialogUtil.Show("", "生成蜃龙库", GenSL);
        }

        [MenuItem(menu + "生成韩国库LuaWrap", false, Pri + 3)]
        [MenuItem(AMenu + "生成韩国库LuaWrap", false, Pri + 4)]
        public static void GenWrapJHDialog()
        {
            DialogUtil.Show("", "生成君海库(并重新生成LuaWrap)", GenWrapJH);
        }

        [MenuItem(menu + "生成蜃龙库LuaWrap", false, Pri + 4)]
        [MenuItem(AMenu + "生成蜃龙库LuaWrap", false, Pri + 4)]
        public static void GenWrapSLDialog()
        {
            DialogUtil.Show("", "生成蜃龙库(并重新生成LuaWrap)", GenWrapSL);
        }
#endregion
    }
}