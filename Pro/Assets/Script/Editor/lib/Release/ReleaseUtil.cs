/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/5/10 12:06:14
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    using BuildDic = Dictionary<BuildTarget, ReleaseBase>;

    /// <summary>
    /// 发布工具
    /// </summary>
    public static class ReleaseUtil
    {
        #region 字段
        private static BuildDic dic = new BuildDic();

        private static ElapsedTime et = new ElapsedTime();

        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 30;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "发布工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "发布工具/";

        #endregion

        #region 属性

        #endregion

        #region 构造函数
        static ReleaseUtil()
        {
            dic.Add(BuildTarget.iOS, new IosRelease());
            dic.Add(BuildTarget.Android, new AndroidRelease());
            var windowRelease = new WindowRelease();
            dic.Add(BuildTarget.StandaloneWindows, windowRelease);
            dic.Add(BuildTarget.StandaloneWindows64, windowRelease);
        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 通用设置
        /// </summary>
        private static void Setting()
        {
            var appID = PlayerSettings.applicationIdentifier;
            appID = appID.Replace(".Company.", ".Game.");
            var group = BuildTargetGroup.Android |
                BuildTargetGroup.iOS |
                BuildTargetGroup.Standalone;
            PlayerSettings.SetApplicationIdentifier(group, appID);
        }

        /// <summary>
        /// 编辑器内调用执行执行发布
        /// </summary>
        [MenuItem(menu + "直接发布 #&B", false, Pri)]
        [MenuItem(AMenu + "直接发布", false, Pri)]
        private static void ExeWithDialog()
        {
            DialogUtil.Show("", "确定使用自定义打包吗", Execute);
        }

        /// <summary>
        /// 获取发布目录
        /// </summary>
        /// <param name="prefix">前缀目录</param>
        /// <returns></returns>
        public static string GetDir(string prefix)
        {
#if UNITY_IOS || UNITY_IPHONE
            var plat = EditUtil.GetPlatform();
            var dir = Path.Combine(prefix, "XCode/" + plat);
#elif UNITY_ANDROID
            var name = PlayerSettings.companyName;
            var dir = "E:/Share/SLRPGA/" + name;
#else
            var plat = EditUtil.GetPlatform();
            var name = PlayerSettings.productName;
            var dir = string.Format("{0}Release/{1}/{2}", prefix, plat, name);
#endif
            return dir;
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 发布
        /// </summary>
        public static void Execute()
        {
            et.Beg();
            Setting();
            var target = EditorUserBuildSettings.activeBuildTarget;
            if (dic.ContainsKey(target))
            {
                dic[target].Execute();
            }
            else
            {
                Debug.LogErrorFormat("Loong, 没有对{0}平台进行设置!", target);
            }
            et.End("build apk or ipa");
        }

        /// <summary>
        /// 获取发布日志路径
        /// </summary>
        /// <returns></returns>
        public static string GetLogPath()
        {
            var folder = GetDir();
            var logPath = string.Format("{0}/Log.txt", folder);
            return logPath;
        }

        /// <summary>
        /// 获取发布目录/自动区分平台
        /// </summary>
        /// <returns></returns>
        public static string GetDir()
        {
            var view = AssetDataUtil.Get<ReleaseView>();
            if (string.IsNullOrEmpty(view.Output))
            {
                return GetRelativeDir();
            }

            var plat = EditUtil.GetPlatform();
            var output = string.Format("{0}/{1}", view.Output, plat);
            if (!Directory.Exists(output)) Directory.CreateDirectory(output);
            return output;
        }

        /// <summary>
        /// 获取相对路径下目录
        /// </summary>
        public static string GetRelativeDir()
        {
            var dir = GetDir("../");
            var fullDir = Path.GetFullPath(dir);
            if (!Directory.Exists(fullDir)) Directory.CreateDirectory(fullDir);
            return fullDir;
        }

        /// <summary>
        /// 获取Window下发布目录
        /// </summary>
        public static string GetWindowDir()
        {
            string folder = null;
            var drives = new List<string>(Directory.GetLogicalDrives());
            if (drives.Count == 1) folder = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            else if (drives.Contains(@"E:\")) folder = @"E:\";
            else if (drives.Contains(@"D:\")) folder = @"D:\";
            var dir = GetDir(folder);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            return dir;
        }

        /// <summary>
        /// 保存版本号
        /// </summary>
        /// <param name="dir">保存目录</param>
        public static void SaveVer(string dir)
        {
            var curDir = Directory.GetCurrentDirectory();
            if (string.IsNullOrEmpty(dir)) dir = curDir;
            if (!Directory.Exists(dir)) dir = curDir;
            var verPath = Path.Combine(dir, UpgUtil.PkgVerFile);
            var verText = PlayerSettings.bundleVersion;
            FileTool.Save(verPath, verText);
        }
        #endregion
    }
}