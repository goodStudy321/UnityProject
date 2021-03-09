//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 17:07:24
//*****************************************************************************

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// EditSdkSlAnd
    /// </summary>
    public class EditSdkSlAnd : EditAndroidSdk
    {
        #region 字段

        #endregion

        #region 属性
        public override string Des
        {
            get { return "sl"; }
        }

        public override string BundleID
        {
            get { return "com.ShenLong.SLRPGA"; }
        }

        public override string AppName => "天道问情";

        public override string StoreName => null;

        public override string StorePass => null;

        public override string AliasName => null;

        public override string AliasPass => null;
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

        #endregion
    }
}