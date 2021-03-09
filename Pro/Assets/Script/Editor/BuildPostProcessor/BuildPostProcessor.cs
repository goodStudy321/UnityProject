using System;
using Loong.Edit;
using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using System.Collections.Generic;

namespace Loong.Post
{
    using BuildDic = Dictionary<BuildTarget, BuildPostProcessorBase>;
    /// <summary>
    /// AU:Loong
    /// TM:2016.4.10
    /// BG:发布后处理器
    /// </summary>
    public class BuildPostprocessor
    {
        #region 字段
        /*private static BuildDic dic = new BuildDic();*/
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static BuildPostprocessor()
        {
            /*dic.Clear();
            dic.Add(BuildTarget.iOS, new IosBuildPostprocessor());
            dic.Add(BuildTarget.Android, new AndroidBuildPostProcessor());*/
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 发布后回调
        /// </summary>
        /// <param name="target">发布平台</param>
        /// <param name="buildPath">发布路径</param>
        [PostProcessBuild(88)]
        private static void OnPostprocessBuild(BuildTarget target, string buildPath)
        {
            /*if (dic.ContainsKey(target)) dic[target].Execute(target, buildPath);*/
#if LOONG_ENABLE_SDK
            EditSdkMgr.Instance.End(CmdArgs.Dic, buildPath);
#endif
#if CS_HOTFIX_ENABLE
            CSHotfixUtil.MoveFromEditor();
#else
            ToLuaMenu.ClearLuaWraps();
#endif
        }
#endregion
    }
}