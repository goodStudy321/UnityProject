/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.6.13 12:34:17
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;

namespace Loong.Edit
{

    /// <summary>
    /// 编译工具
    /// </summary>
    public static class CompileUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 55;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "编译/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "编译/";

        #endregion

        #region 属性

        #endregion

        #region 事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        [MenuItem(menu + "刷新", false, Pri)]
        [MenuItem(AMenu + "刷新", false, Pri)]
        public static void Refresh()
        {
            MonoScript[] arr = MonoImporter.GetAllRuntimeMonoScripts();
            if (arr == null) return;
            if (arr.Length == 0) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                MonoScript mono = arr[i];
                string str = mono.ToString();
                if (string.IsNullOrEmpty(str)) continue;
                int order = MonoImporter.GetExecutionOrder(mono);
                MonoImporter.SetExecutionOrder(mono, order);
                return;
            }

        }

        /// <summary>
        /// 刷新指定脚本
        /// </summary>
        /// <param name="scriptName">脚本名</param>
        public static void Refresh(string scriptName)
        {
            if (string.IsNullOrEmpty(scriptName)) return;
            MonoScript[] arr = MonoImporter.GetAllRuntimeMonoScripts();
            if (arr == null || arr.Length < 1) return;
            MonoScript target = null;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                MonoScript mono = arr[i];
                string monoName = mono.name;
                if (mono.name == scriptName)
                {
                    target = mono;
                    break;
                }
            }
            if (target == null)
            {
                UIEditTip.Warning("Loong,未发现名为:{0}的脚本", scriptName);
            }
            else
            {
                iTrace.Log("Loong", "开始刷新");
                int order = MonoImporter.GetExecutionOrder(target);
                MonoImporter.SetExecutionOrder(target, order);
            }

        }
        #endregion
    }
}