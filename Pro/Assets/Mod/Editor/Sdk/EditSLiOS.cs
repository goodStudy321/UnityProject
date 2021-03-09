/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/18 3:33:00
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;

using System.Collections.Generic;

#if UNITY_XCODE_API_BUILD
using UnityEditor.iOS.Xcode;
#else
using UnityEditor.iOS.Xcode.Custom;
#endif

namespace Loong.Edit
{
    /// <summary>
    /// SLiOSProcessor
    /// </summary>
    public class EditSLiOS : EditiOSSdk
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        #endregion

        #region 保护方法
        protected override void SetPbx(string proPath, string guid, string projPath, string targetName)
        {
            AddFramework("AdSupport");
            AddFramework("CoreTelephony");
        }

        #endregion

        #region 公开方法

        #endregion
    }
}