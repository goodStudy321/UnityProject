using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.8.19
    /// BG:运行时工具
    /// </summary>
    public static class RTTool
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 120;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "运行时/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "运行时/";

        /// <summary>
        /// 禁止输入
        /// </summary>
        public const string BanInput = menu + "禁止输入";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        [MenuItem(BanInput, false, Pri)]
        private static void SetInput()
        {
            bool val = InputMgr.instance.CanInput;
            InputMgr.instance.CanInput = !val;
        }

        [MenuItem(BanInput, true, Pri)]
        private static bool GetInput()
        {
            if (EditorApplication.isPlaying)
            {
                bool val = InputMgr.instance.CanInput;
                Menu.SetChecked(BanInput, !val);
            }
            return true;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}