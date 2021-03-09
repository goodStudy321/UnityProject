using System;
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
     * GUID:        f1dd76fa-e2e9-4796-8153-661a511d29d9
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/8/10 20:59:14
    /// BG:ios设置工具
    /// </summary>
    public static class iOSSettingTool
    {
        #region 字段
        /// <summary>
        /// 脚本后端 可选值Mono和IL2CPP
        /// </summary>
        public const string BackendKey = "-Backend";

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置脚本后端
        /// </summary>
        /// <param name="argDic"></param>
        private static void SetBackend(Dictionary<string, string> argDic)
        {
            if (!argDic.ContainsKey(BackendKey)) return;
            string backendVal = argDic[BackendKey];
            if (string.IsNullOrEmpty(backendVal)) return;
            backendVal = backendVal.ToLower();
            BuildTargetGroup target = BuildTargetGroup.iOS;
            if (backendVal == "mono")
            {
                PlayerSettings.SetScriptingBackend(target, ScriptingImplementation.Mono2x);
            }
            else if (backendVal == "il2cpp")
            {
                PlayerSettings.SetScriptingBackend(target, ScriptingImplementation.IL2CPP);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 解析
        /// </summary>
        /// <param name="argDic">参数字典</param>
        public static void Execute(Dictionary<string, string> argDic)
        {
            SetBackend(argDic);
        }
        #endregion
    }
}