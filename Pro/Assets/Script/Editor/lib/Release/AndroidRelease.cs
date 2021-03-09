/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 19:35:20
 ============================================================================*/

using System;
using Loong.Game;
using System.Text;
using UnityEditor;

namespace Loong.Edit
{
    /// <summary>
    /// 安卓发布
    /// </summary>
    public class AndroidRelease : ReleaseBase
    {
        #region 字段

        #endregion

        #region 属性
        /// <summary>
        /// 后缀名
        /// </summary>
        public override string Suffix
        {
            get
            {
                return ".apk";
            }
        }
        #endregion

        #region 构造方法
        /// <summary>
        /// 显式构造方法
        /// </summary>
        public AndroidRelease()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 设置
        /// </summary>
        protected override void Setting()
        {
            PlayerSettings.Android.startInFullscreen = true;
            PlayerSettings.fullScreenMode = UnityEngine.FullScreenMode.FullScreenWindow;

            //PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel16;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel19;
            PlayerSettings.SetApiCompatibilityLevel(BuildTargetGroup.Android, ApiCompatibilityLevel.NET_2_0_Subset);
            ReleaseView view = AssetDataUtil.Get<ReleaseView>();
            if (view == null) return;
            view.AndroidSetting.Apply();
        }
        /// <summary>
        /// 获取短版本号
        /// </summary>
        /// <returns></returns>
        protected override string GetShortBundle()
        {
            return PlayerSettings.Android.bundleVersionCode.ToString();
        }


        protected override string GetTargetVer()
        {
            var api = (int)PlayerSettings.Android.targetSdkVersion;
            var str = "api" + api;
            return str;
        }

        /// <summary>
        /// 设置发布成功路径
        /// </summary>
        /// <param name="path"></param>
        protected override void SetPath(string path)
        {
            ReleaseView view = AssetDataUtil.Get<ReleaseView>();
            view.AndroidSuccessPath = path;
            EditUtil.SetDirty(view);
        }

#if CS_HOTFIX_ENABLE
        protected override void AddScenes()
        {
            AddScenes("Assets/Main_Android.Unity");
        }
#endif
        #endregion

        #region 公开方法

        #endregion
    }
}