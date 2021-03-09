/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 14:30:41
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;
    /// <summary>
    /// SDK管理
    /// </summary>
    public static class EditSdkMgr
    {
        #region 字段

        #endregion

        #region 属性
        private static EditSdkBase instance;

        public static EditSdkBase Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = Create();
                    Debug.LogFormat("SDKType create:{0}", instance.GetType().Name);
                }
                return instance;
            }
        }

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
        public static EditSdkBase Create()
        {
            var target = EditorUserBuildSettings.activeBuildTarget;
            switch (target)
            {
                case BuildTarget.iOS:
#if SDK_IOS_HW_SGMY
                    return new EditiOSSgmy();
#elif SDK_IOS_GAT
                    return new EditSdkGat();
#else
                    return new EditSLiOS();
#endif
                case BuildTarget.Android:
#if SDK_ANDROID_GAT
                    return new EditSdkGatAnd();
#elif SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
                    return new EditSdkAndHG();
#else
                    return new EditSdkSlAnd();
#endif
                default:
                    return new EditSdkSlAnd();
            }
        }


        public static void SetPreprocess(StrDic dic)
        {
            var target = EditorUserBuildSettings.activeBuildTarget;
            switch (target)
            {
                case BuildTarget.iOS:
                    EditiOSSdk.SetPreprocess(dic);
                    return;
                case BuildTarget.Android:
                    EditAndroidSdk.SetPreprocess(dic);
                    return;
                default:
                    return;
            }
        }
        #endregion
    }
}