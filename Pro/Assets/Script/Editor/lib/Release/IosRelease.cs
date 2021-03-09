using System.IO;
using Loong.Game;
using UnityEngine;
using System.Text;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2013-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        82dbaede-71ee-4a8d-b7b0-89e07a51c3f2
    */

    /// <summary>
    /// AU:Loong
    /// TM:2013/5/10 19:35:33
    /// BG:
    /// </summary>
    public class IosRelease : ReleaseBase
    {
        #region 字段

        #endregion

        #region 属性
        /// <summary>
        /// 后缀
        /// </summary>
        public override string Suffix
        {
            get
            {
                return ".ipa";
            }
        }
        #endregion

        #region 构造方法
        /// <summary>
        /// 显示构造方法
        /// </summary>
        public IosRelease()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// Ios设置
        /// </summary>
        protected override void Setting()
        {
            PlayerSettings.SetApiCompatibilityLevel(BuildTargetGroup.iOS, ApiCompatibilityLevel.NET_2_0_Subset);

            
        }

        /// <summary>
        /// 获取IOS短版本号
        /// </summary>
        /// <returns></returns>
        protected override string GetShortBundle()
        {
            return PlayerSettings.iOS.buildNumber;
        }

        /// <summary>
        /// IOS发布成功后,设置成功路径
        /// </summary>
        /// <param name="path">成功路径</param>
        protected override void SetPath(string path)
        {
            ReleaseView view = AssetDataUtil.Get<ReleaseView>();
            view.IosSuccessPath = path;
            EditUtil.SetDirty(view);
        }

        /// <summary>
        /// 获取IOS包名
        /// </summary>
        /// <returns></returns>
        protected override string GetPackageName()
        {
            var target = EditorUserBuildSettings.activeBuildTarget;
            if (target == BuildTarget.iOS)
            {
                var sb = new StringBuilder();
                sb.Append(EditApp.CompanyPinyin).Append("_");
                sb.Append(EditApp.ProName).Append("_");
                sb.Append(PlayerSettings.bundleVersion);
                var verCode = GetShortBundle();
                if (!string.IsNullOrEmpty(verCode)) sb.Append(".").Append(verCode);
                return sb.ToString();
            }
            else
            {
                return base.GetPackageName();
            }
        }

        /// <summary>
        /// 预处理IOS的发布路径
        /// </summary>
        /// <param name="path"></param>
        protected override void PreProcessPath(string path)
        {
            if (Directory.Exists(path))
            {
                Directory.Delete(path, true);
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}