using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        5b4cf835-16be-4a99-9765-d11ec0084859
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/8/10 10:22:25
    /// BG:android设置工具
    /// </summary>
    public static class AndroidSettingTool
    {
        #region 字段

        /// <summary>
        /// android 目标sdk版本键值 value:数字
        /// </summary>
        public const string TargetSDKVerKey = "-androidTargetSDKVer";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置目标SDK版本
        /// </summary>
        /// <param name="dic"></param>
        private static void SetTargetVer(Dictionary<string, string> dic)
        {
            if (!dic.ContainsKey(TargetSDKVerKey)) return;
            string verStr = dic[TargetSDKVerKey];
            string enumStr = "AndroidApiLevel" + verStr;
            AndroidSdkVersions sdkVer = AndroidSdkVersions.AndroidApiLevelAuto;
            Type type = typeof(AndroidSdkVersions);
            if (Enum.IsDefined(type, enumStr))
            {
                sdkVer = (AndroidSdkVersions)Enum.Parse(type, enumStr);
            }
            PlayerSettings.Android.targetSdkVersion = sdkVer;

        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 解析
        /// </summary>
        /// <param name="dic"></param>
        public static void Execute(Dictionary<string, string> dic)
        {
            SetTargetVer(dic);
        }
        #endregion
    }
}