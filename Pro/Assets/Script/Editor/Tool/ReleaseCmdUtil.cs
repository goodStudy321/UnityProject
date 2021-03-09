/*=============================================================================
 * Copyright (C) 2013, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 14:24:42
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;
    /// <summary>
    /// 发布时命令行工具
    /// </summary>
    public static class ReleaseCmdUtil
    {
        #region 字段

        #endregion


        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void SetNecessary()
        {
            PreprocessCmdUtil.Add("LOONG_ENABLE_UPG");
            PreprocessCmdUtil.Add("LOONG_ENABLE_SDK");
        }


        private static void SetSdk(StrDic dic)
        {
            var asm = Assembly.GetAssembly(typeof(ReleaseCmdUtil));
            var flags = BindingFlags.Static | BindingFlags.Public;
            ReflectionTool.Call(asm, "Loong.Edit.EditSdkMgr", "SetPreprocess", flags, dic);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 设置预处理指令
        /// </summary>
        public static void SetPreprocess()
        {
            var dic = CmdArgs.Dic;

            PreprocessCmdUtil.Init();

            SetNecessary();

            ReleasePreprocessUtil.Execute(dic);

            SetSdk(dic);

            PreprocessCmdUtil.Apply();
        }


        /// <summary>
        /// 解析系统命令行参数
        /// </summary>
        public static void Execute()
        {
            CmdArgs.Save();
            var dic = CmdArgs.Dic;
            LuaCmdUtil.Execute(dic);
            CmdSettingMgr.Instance.Execute(dic);
#if LOONG_ENABLE_SDK
            Debug.LogFormat("SDKType beg {0}",EditSdkMgr.Instance.GetType().Name);
            
            EditSdkMgr.Instance.Beg(dic);
#endif
        }
        #endregion
    }
}