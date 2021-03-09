using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Text;
using System.Collections;
using System.Collections.Generic;
namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2013-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        9e44aca2-e328-4b9d-a099-23fdddfd619c
    */

    /// <summary>
    /// AU:Loong
    /// TM:2013/5/10 19:35:46
    /// BG:Windows发布
    /// </summary>
    public class WindowRelease : ReleaseBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        /// <summary>
        /// 显式构造方法
        /// </summary>
        public WindowRelease()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// window发布设置
        /// </summary>
        protected override void Setting()
        {
            PlayerSettings.SetApiCompatibilityLevel(BuildTargetGroup.Standalone, ApiCompatibilityLevel.NET_2_0_Subset);
        }

        /// <summary>
        /// 获取Window发布目录
        /// </summary>
        /// <returns></returns>
        protected override string GetDir()
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(base.GetDir()).Append("/");
            sb.Append("[").Append(PlayerSettings.productName).Append("]");
            sb.Append("[").Append(PlayerSettings.bundleVersion);
            string shortBundle = GetShortBundle();
            if (string.IsNullOrEmpty(shortBundle)) sb.Append("]");
            else sb.Append(".").Append(shortBundle).Append("]");
            sb.Append("[").Append(DateTime.Now.ToString("yyyy.MM.dd HH.mm.ss")).Append("]");
            return sb.ToString();
        }

        /// <summary>
        /// 获取Window包名
        /// </summary>
        /// <returns></returns>
        protected override string GetPackageName()
        {
            return PlayerSettings.productName + Suffix;
        }

        /// <summary>
        /// Window设置发布成功路径
        /// </summary>
        /// <param name="path"></param>
        protected override void SetPath(string path)
        {
            ReleaseView view = AssetDataUtil.Get<ReleaseView>();
            view.WindowSuccessPath = path;
            EditUtil.SetDirty(view);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}