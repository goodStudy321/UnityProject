/*=============================================================================
 * Copyright (C) 2016, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 11:58:13
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 命令行设置工厂
    /// </summary>
    public static class CmdSettingMgr
    {
        #region 字段
        private static CmdSetting instance = null;
        #endregion

        #region 属性
        public static CmdSetting Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = Create();
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
        public static CmdSetting Create()
        {
            var target = EditorUserBuildSettings.activeBuildTarget;
            switch (target)
            {
                case BuildTarget.iOS:
                    return new iOSSetting();
                case BuildTarget.Android:
                    return new AndroidSetting();
                default:
                    return new AndroidSetting();
            }
        }
        #endregion
    }
}