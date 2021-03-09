//*****************************************************************************
// Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2014/5/29 12:12:46
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Threading;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Loong.Edit
{
    /// <summary>
    /// 包内资源工具
    /// </summary>
    public static class AssetPkgUtil
    {
        #region 字段

        #region 菜单
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = AssetTool.Pri + 25;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUtil.menu + "包内资源/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUtil.AMenu + "包内资源/";
        #endregion

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

        #endregion

        #region 公开方法
        public static void Delete()
        {
            var output = ABTool.Data.Output;
            var dirs = Directory.GetDirectories(output);
            var streaming = Application.streamingAssetsPath;
            var length = dirs.Length;
            for (int i = 0; i < length; i++)
            {
                var dir = dirs[i];
                var name = Path.GetFileName(dir);
                var destDir = Path.Combine(streaming, name);
                if (Directory.Exists(destDir)) Directory.Delete(destDir, true);
            }
            AssetDatabase.Refresh();
        }


        [MenuItem(menu + "开始多线程处理 %#&r", false, Pri + 2)]
        [MenuItem(AMenu + "开始多线程处理", false, Pri + 2)]
        public static void StartMultiDialog()
        {
            DialogUtil.Show("", "开始多线程处理?", StartMulti);
        }


        [MenuItem(menu + "开始单线程处理", false, Pri + 3)]
        [MenuItem(AMenu + "开始单线程处理", false, Pri + 3)]
        public static void StartDialog()
        {
            DialogUtil.Show("", "开始单线程处理?", StartAll);
        }


        [MenuItem(menu + "开始单线程处理所有文件1个包", false, Pri + 4)]
        [MenuItem(AMenu + "开始单线程处理所有文件1个包", false, Pri + 4)]
        public static void StartSingleDialog()
        {
            DialogUtil.Show("", "开始单线程处理所有文件1个包?", StartSingle);
        }


        [MenuItem(menu + "删除流目录内资源", false, Pri + 5)]
        [MenuItem(AMenu + "删除流目录内资源", false, Pri + 5)]
        public static void DeleteDialog()
        {
            DialogUtil.Show("", "删除流目录内资源?", Delete);
        }


        public static void StartSingle()
        {
            var pkg = Create(PkgKind.Single);
            pkg.Start();
        }

        /// <summary>
        /// 开始
        /// </summary>
        public static void Start()
        {
            Create().Start(BuildArgs.AssetVer, BuildArgs.ContainAllUpgs);
        }

        /// <summary>
        /// 开始/多线程
        /// </summary>
        public static void StartMulti()
        {
            UIEditTip.Error("批处理模式下,Unity后台进程会莫名死亡,暂时此功能无效");
        }

        public static void CompAll()
        {

        }

        /// <summary>
        /// 搜集压缩0版本资源
        /// </summary>
        public static void StartAll()
        {
            var pkg = Create();
        }

        /// <summary>
        /// 创建包处理实例
        /// </summary>
        /// <returns></returns>
        public static EditPkg Create()
        {
            var kind = BuildArgs.Pkg;
            return Create(kind);
        }


        /// <summary>
        /// 创建包处理实例
        /// </summary>
        /// <param name="kind">类型</param>
        /// <returns></returns>
        public static EditPkg Create(PkgKind kind)
        {
            EditPkg pkg = null;
            switch (kind)
            {
                case PkgKind.Single:
                    pkg = new EditPkgSingle();
                    break;
                case PkgKind.Gradule:
                    pkg = new EditPkgGranule();
                    break;
                default:
                    break;
            }
            return pkg;
        }

        #endregion
    }
}