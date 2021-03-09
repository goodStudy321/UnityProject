/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 10:52:06
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// android设置
    /// </summary>
    public class AndroidSetting : CmdSetting
    {
        #region 字段
        /// <summary>
        /// 目标sdk版本键 value:数字
        /// </summary>
        public const string TargetSDKVerKey = "-androidTargetSDKVer";

        #endregion

        #region 属性
        public override VerData Data
        {
            get
            {
                return WinUtil.Get<VerData, AndroidVerWin>();
            }
        }
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
        private void SetTargetVer(Dictionary<string, string> dic)
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

        protected override void SetVerCode(int ver)
        {
            PlayerSettings.Android.bundleVersionCode = ver;
        }

        protected override string GetVerCode()
        {
            return PlayerSettings.Android.bundleVersionCode.ToString();
        }

        protected override void SetBackend()
        {
            base.SetBackend();
            if (BuildArgs.Backend == ScriptingImplementation.IL2CPP)
            {
                PlayerSettings.Android.targetArchitectures = AndroidArchitecture.All;
            }
        }

        #endregion

        #region 公开方法
        public override void Execute(StrDic dic)
        {
            base.Execute(dic);
            SetTargetVer(dic);
        }
        #endregion
    }
}