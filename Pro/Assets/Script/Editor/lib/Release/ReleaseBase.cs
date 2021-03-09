/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 19:35:00
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Diagnostics;
using System.Collections.Generic;
using UnityEditor.Build.Reporting;

namespace Loong.Edit
{
    /// <summary>
    /// 发布基类
    /// </summary>
    public abstract class ReleaseBase
    {
        #region 字段

        private ReleaseView data = null;

        private List<EditorBuildSettingsScene> scenes = new List<EditorBuildSettingsScene>();
        #endregion

        #region 属性
        /// <summary>
        /// 发布数据
        /// </summary>
        public ReleaseView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<ReleaseView>();
                }
                return data;
            }
        }


        /// <summary>
        /// 后缀
        /// </summary>
        public virtual string Suffix { get { return ".exe"; } }

        #endregion

        #region 构造方法
        /// <summary>
        /// 显式构造方法
        /// </summary>
        public ReleaseBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        /// <summary>
        /// 发布结果日志
        /// </summary>
        /// <param name="err">错误信息</param>
        protected void SaveLog(string err)
        {
            if (string.IsNullOrEmpty(err)) return;
            string logPath = ReleaseUtil.GetLogPath();
            FileTool.Save(logPath, err, true);
        }

        /// <summary>
        /// 上传文件
        /// </summary>
        /// <param name="path">源文件路径</param>
        protected virtual void Upload(string path)
        {
            /*var data = AssetDataUtil.Get<ReleaseView>();
            if (!data.UseFtp) return;
            FtpTool.Upload(data.FtpSetting, path, UploadCb);*/
        }

        /// <summary>
        /// 设置发布路径
        /// </summary>
        /// <param name="path">发布路径</param>
        protected abstract void SetPath(string path);

        /// <summary>
        /// 设置
        /// </summary>
        protected virtual void Setting()
        {

        }

        /// <summary>
        /// 获取发布目录
        /// </summary>
        protected virtual string GetDir()
        {
            return ReleaseUtil.GetDir();
        }

        /// <summary>
        /// 保存版本号
        /// </summary>
        protected virtual void SaveVersion()
        {
            AssetUpgUtil.SaveInternalVer();
        }

        /// <summary>
        /// 获取版本号
        /// </summary>
        /// <returns></returns>
        protected virtual string GetShortBundle()
        {
            return PlayerSettings.bundleVersion.ToString();
        }

        /// <summary>
        /// 获取发布后包名
        /// </summary>
        /// <returns></returns>
        protected virtual string GetPackageName()
        {
            var sb = new StringBuilder();
            sb.Append(EditApp.CompanyPinyin).Append("_");
            sb.Append(EditApp.ProName).Append("_");
            var difDefHG = GetDifDesHG();
            sb.Append(difDefHG).Append("_");
            var debug = GetDebug();
            sb.Append(debug);
            var targetVer = GetTargetVer();
            if (!string.IsNullOrEmpty(targetVer))
            {
                sb.Append("_").Append(targetVer);
            }
            sb.Append("_").Append(PlayerSettings.bundleVersion);
            var verCode = GetShortBundle();
            if (!string.IsNullOrEmpty(verCode)) sb.Append(".").Append(verCode);
            var dt = DateTime.Now.ToString("yyyy.MM.dd_HH.mm.ss");
            sb.Append("_").Append(dt).Append(Suffix);
            return sb.ToString();
        }

        protected virtual string GetDebug()
        {
            if (BuildArgs.IsReleaseDebug) return "releasedebug";
            return ((Data.Debug || App.IsDebug) ? "debug" : "release");
        }

        /// <summary>
        /// 韩国 google  oneStore 包名区分
        /// </summary>
        /// <returns></returns>
        protected virtual string GetDifDesHG()
        {
#if SDK_ANDROID_HG
            return "Google";
#elif SDK_ONESTORE_HG
            return "OneStore";
#elif SDK_SAMSUNG_HG
            return "Samsung";
#else
            return "";
#endif
        }

        /// <summary>
        /// 获取目标系统版本号
        /// </summary>
        /// <returns></returns>
        protected virtual string GetTargetVer()
        {
            return "";
        }

        /// <summary>
        /// 发布之前处理路径
        /// </summary>
        /// <param name="path">发布路径</param>
        protected virtual void PreProcessPath(string path)
        {
            AddScenes("Assets/Main.Unity");
        }

        protected void BegScenes()
        {
            scenes.Clear();
        }

        protected void AddScenes(string scenePath)
        {
            var scene = new EditorBuildSettingsScene(scenePath, true);
            scenes.Add(scene);
        }

        protected void EndScenes()
        {
            AddScenes("Assets/Clear.Unity");
            EditorBuildSettings.scenes = scenes.ToArray();
        }

        /// <summary>
        /// 设置场景
        /// </summary>
        protected void SetScenes()
        {
            BegScenes();
            AddScenes();
            EndScenes();
        }

        /// <summary>
        /// 添加场景
        /// </summary>
        protected virtual void AddScenes()
        {
            AddScenes("Assets/Main.Unity");
        }


        /// <summary>
        /// 获取打包设置
        /// </summary>
        /// <returns></returns>
        protected BuildOptions GetBuildOptions()
        {
            BuildOptions options = BuildOptions.None;

            //if (Data.Debug) options = options | BuildOptions.AllowDebugging;
            if (Data.Development) options = options | BuildOptions.Development;
            if (Data.ConnectProfiler) options = options | BuildOptions.ConnectWithProfiler;
            return options;
        }

        /// <summary>
        /// 设置开发者模式
        /// </summary>
        protected void SetDevelopment()
        {
            var debug = false;
#if GAME_DEBUG
            debug = true;
#endif
            Data.Debug = debug;
            Data.Development = debug;
        }

        protected void SetApiCpLv(BuildTarget buildTar)
        {
            BuildTargetGroup btGrop = BuildTargetGroup.Android;
            if (buildTar == BuildTarget.Android)
                btGrop = BuildTargetGroup.Android;
            else if (buildTar == BuildTarget.iOS)
                btGrop = BuildTargetGroup.iOS;
            else if (buildTar == BuildTarget.StandaloneWindows64 || buildTar == BuildTarget.StandaloneWindows)
                btGrop = BuildTargetGroup.Standalone;
            PlayerSettings.SetApiCompatibilityLevel(btGrop, ApiCompatibilityLevel.NET_4_6);
        }
#endregion

#region 公开方法
        /// <summary>
        /// 执行
        /// </summary>
        public virtual void Execute()
        {
            SetScenes();
            SetDevelopment();
            var dir = GetDir();
            var pkgName = GetPackageName();
            var localPath = string.Format("{0}/{1}", dir, pkgName);
            PreProcessPath(localPath);
            var target = EditorUserBuildSettings.activeBuildTarget;
            var options = GetBuildOptions();
            Setting();
            SetApiCpLv(target);
            PlayerSettings.graphicsJobMode = GraphicsJobMode.Native;
            var report = BuildPipeline.BuildPlayer(scenes.ToArray(), localPath, target, options);
            bool exist = false;
#if UNITY_ANDROID
            exist = File.Exists(localPath);
#else
            exist = Directory.Exists(localPath);
#endif
            if (exist)
            {
#if !UNITY_IOS
                string newName = GetPackageName();
                string newPath = string.Format("{0}/{1}", dir, newName);
                SetPath(newPath);
                FileInfo fi = new FileInfo(localPath);
                fi.MoveTo(newPath);
                UIEditTip.Warning("Loong,build suc,path:{0}", localPath);
#else
                string newPath = localPath;
#endif
                AssetDatabase.SaveAssets();
                
                Process.Start(dir);
                Upload(newPath);
            }
            else
            {
                UIEditTip.Error("loong,build fail, no package:{0}", localPath);
                var summary = report.summary;
                switch (summary.result)
                {
                    case BuildResult.Failed:
                        string msg = string.Format("Player build failed. ({0} errors:  {1})", summary.totalErrors, summary.ToString());
                        UIEditTip.Error("Build Error", msg);
                        break;
                    case BuildResult.Cancelled:
                        UIEditTip.Error("Build Error", "Build Cancel");
                        break;
                    case BuildResult.Unknown:
                        UIEditTip.Error("Build Error", "Unknow Error");
                        break;
                }
            }

        }
#endregion
    }
}