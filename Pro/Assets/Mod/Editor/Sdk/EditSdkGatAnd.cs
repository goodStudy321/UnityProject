//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 16:36:29
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// EditSdkGatAnd
    /// </summary>
    public class EditSdkGatAnd : EditAndroidSdk
    {
        #region 字段

        #endregion

        #region 属性
        public override string Des
        {
            get { return "gat"; }
        }

        public override string BundleID
        {
            get { return "com.originmood.tdwq"; }
        }

        public override string AppName => "花語仙戀";

        public override string StoreName
        {
            get { return SdkUtil.GetCfgPath(Des, "gdsdk.keystore"); }
        }

        public override string StorePass => "gamedreamer";

        public override string AliasName => "gd";

        public override string AliasPass => "gamedreamer";
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Beg(Dictionary<string, string> dic)
        {
            base.Beg(dic);

            if (BuildArgs.Pkg == PkgKind.Gradule)
            {
                var src = SdkUtil.GetCfgPath(Des, "lib_jingqi-release-third.aar");
                var dest = Path.Combine(SdkUtil.GetPluginDir(Plat), "lib_jingqi-release.aar");
                if (File.Exists(src))
                {
                    File.Copy(src, dest, true);
                    iTrace.Log("Loong", "copy google-third lib, src:{0}, dest:{1}", src, dest);
                }
            }
        }
        #endregion
    }
}