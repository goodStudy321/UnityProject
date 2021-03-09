/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/9/17
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    /// <summary>
    /// 预制件工具
    /// </summary>
    public static class PrefabUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 80;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "预制件工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "预制件工具/";

        /// <summary>
        /// 使用自动更新菜单路径
        /// </summary>
        public const string UseUpdatePath = menu + "使用自动更新";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        [MenuItem(UseUpdatePath, false, Pri)]
        private static void SetUse()
        {
            bool val = EditPrefsTool.GetBool(typeof(PrefabUtil), "UseUpdate", false);
            val = !val;
            EditPrefsTool.SetBool(typeof(PrefabUtil), "UseUpdate", val);
        }

        [MenuItem(UseUpdatePath, true, Pri)]
        private static bool GetUse()
        {
            bool val = EditPrefsTool.GetBool(typeof(PrefabUtil), "UseUpdate");
            Menu.SetChecked(UseUpdatePath, val);
            return true;
        }

        [InitializeOnLoadMethod]
        private static void SetAutoSave()
        {
            PrefabUtility.prefabInstanceUpdated += AutoSave;
        }

        /// <summary>
        /// 自动保存
        /// </summary>
        private static void AutoSave(GameObject instance)
        {
            if (!EditPrefsTool.GetBool(typeof(PrefabUtil), "UseUpdate", true)) return;
            EditUtil.SaveAssets();
            UIEditTip.Log("检测到Prefab:{0}实例更新,已保存到原始Prefab", instance.name);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}