/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 14:30:22
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using StrDic = System.Collections.Generic.Dictionary<string, string>;

namespace Loong.Edit
{
    /// <summary>
    /// AndroidSdk处理
    /// </summary>
    public abstract class EditAndroidSdk : EditSdkBase
    {
        #region 字段
        public const string key = "-sdk_android";

        /// <summary>
        /// android sdk预处理指令字典 k:预处理指令字符 v:sdk文件夹名
        /// </summary>
        public static readonly StrDic cmdDic = new StrDic() {
            { "SDK_ANDROID_NONE",null },
            { "SDK_ANDROID_GAT","gat" },
            { "SDK_ANDROID_HG","hg_google" },
            { "SDK_ONESTORE_HG","hg_onestore" },
            { "SDK_SAMSUNG_HG","hg_samsung" },
        };
        #endregion

        #region 属性
        public override string Plat
        {
            get { return "Android"; }
        }
        /// <summary>
        /// ios SDK预处理指令键值
        /// </summary>
        public override string SdkKey
        {
            get { return key; }
        }

        public override StrDic CmdDic
        {
            get { return cmdDic; }
        }

        public abstract string StoreName { get; }

        public abstract string StorePass { get; }

        public abstract string AliasName { get; }

        public abstract string AliasPass { get; }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void SetKeyStore(string path, string pass, string alias, string aliasPass)
        {
            if (!File.Exists(path))
            {
                iTrace.Error("Loong", "{0} keyStore:{1} not exist!", Des, path);
                return;
            }
            if (string.IsNullOrEmpty(pass)) return;
            if (string.IsNullOrEmpty(alias)) return;
            if (string.IsNullOrEmpty(aliasPass)) return;

            PlayerSettings.Android.keystoreName = path;
            PlayerSettings.Android.keystorePass = pass;
            PlayerSettings.Android.keyaliasName = alias;
            PlayerSettings.Android.keyaliasPass = aliasPass;

            iTrace.Log("Loong", "{0} keystore:{1}", Des, path);
        }
        #endregion

        #region 公开方法
        public static void SetPreprocess(StrDic dic)
        {
            ReleasePreprocessUtil.Switch(dic, cmdDic, key);
        }


        public override void Beg(StrDic dic)
        {
            base.Beg(dic);
            SetBundleID(BuildTargetGroup.Android, BundleID);
            SetKeyStore(StoreName, StorePass, AliasName, AliasPass);
        }
        #endregion
    }
}