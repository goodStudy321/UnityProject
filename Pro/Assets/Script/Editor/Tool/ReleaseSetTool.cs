/*=============================================================================
 * Copyright (C) 2013, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 14:24:42
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using Loong.Edit.Confuse;
using UnityEditor.Callbacks;
using UnityEditor.Compilation;

namespace Loong.Edit
{

    /// <summary>
    /// 发布资源工具集
    /// </summary>
    public static class ReleaseSetTool
    {
        #region 字段

        private const string isBuildName = "IsBuild";

        private const string isMoveRuntime = "IsMoveRuntime";

        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = ReleaseUtil.Pri + 40;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = ReleaseUtil.menu;

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = ReleaseUtil.AMenu;
        #endregion

        #region 属性
        public static bool IsBuild
        {
            get { return EditPrefsTool.GetBool(typeof(ReleaseSetTool), isBuildName); }
            set { EditPrefsTool.SetBool(typeof(ReleaseSetTool), isBuildName, value); }
        }


        /// <summary>
        /// true:仅仅Build,不进行拷贝和AB操作
        /// </summary>
        public static bool OnlyBuild
        {
            get { return CmdArgs.GetBool("ONLYBUILD", false); }
        }

        public static bool IsCompiling
        {
            get { return EditorApplication.isCompiling; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 处理命令行参数和打包AB
        /// </summary>
        private static void CmdAB()
        {
            var dic = CmdArgs.Dic;
            ReleaseCmdUtil.Execute();
#if !CS_HOTFIX_ENABLE
            ToLuaMenu.DeleteAndGenerate();
#endif
            if (OnlyBuild)
            {
                ReleaseUtil.Execute();
            }
            else
            {
                ABCmdMgr.Execute();
                CopyBuild();
            }
        }

        [DidReloadScripts]
        private static void CmdABAfterCompile()
        {
            if (!IsBuild) return;
            IsBuild = false;
            CmdAB();
        }


        private static void Build(object o)
        {
            CompilationPipeline.compilationFinished -= Build;

            ReleaseUtil.Execute();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 拷贝资源并发布
        /// </summary>
        [MenuItem(menu + "拷贝资源并发布", false, Pri)]
        [MenuItem(AMenu + "拷贝资源并发布", false, Pri)]
        public static void CopyBuild()
        {
            CSHotfixUtil.Ready();
            ReleaseTableUtil.Execute();
            if (BuildArgs.EnableAssetOpt)
            {
                AssetUpgCmdMgr.Execute();
                AssetTool.DeleteAssetsFromStreaming();
                AssetPkgUtil.Start();
            }
            AppInfoUtil.Execute();
            CSHotfixUtil.Move();
            ConfuseMgr.BatchApply();
            CompileUtil.Refresh();
            if (IsCompiling)
            {
                CompilationPipeline.compilationFinished += Build;
            }
            else
            {
                ReleaseUtil.Execute();
            }
        }

        /// <summary>
        /// 打包AB 拷贝并发布
        /// </summary>
        [MenuItem(menu + "打包AB 拷贝并发布", false, Pri + 1)]
        [MenuItem(AMenu + "打包AB 拷贝并发布", false, Pri + 1)]
        public static void ABCopyAssetsBuild()
        {
            Reset();
            ProgressBarUtil.IsShow = false;
            ReleaseCmdUtil.SetPreprocess();
            CompileUtil.Refresh();
            if (IsCompiling)
            {
                IsBuild = true;
            }
            else
            {
                CmdAB();
            }
        }

        /// <summary>
        /// 编译配置 拷贝并发布
        /// </summary>
        [MenuItem(menu + "编译配置 拷贝并发布", false, Pri + 2)]
        [MenuItem(AMenu + "编译配置 拷贝并发布", false, Pri + 2)]
        public static void MakeTableCopyAssetsBuild()
        {
            DataTool.MakeTable();
            CopyBuild();
        }



        /// <summary>
        /// 编译配置 打包AB 拷贝并发布
        /// </summary>
        [MenuItem(menu + "编译配置 打包AB 拷贝并发布", false, Pri + 3)]
        [MenuItem(AMenu + "编译配置 打包AB 拷贝并发布", false, Pri + 3)]
        public static void MakeTableABCopyAssetsBuild()
        {
            DataTool.MakeTable();
            ABTool.BuildUserSettings();
            CopyBuild();
        }

        /// <summary>
        /// 编译配置 打包AB 拷贝并发布
        /// </summary>
        [MenuItem(menu + "重置状态", false, Pri + 3)]
        [MenuItem(AMenu + "重置状态", false, Pri + 3)]
        public static void Reset()
        {
            IsBuild = false;
        }
        #endregion
    }
}