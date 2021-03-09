/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/2/15 00:00:00
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 预处理指令窗口
    /// </summary>
    public class PreprocessCmdWin : EditWinBase
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 1;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "预处理指令工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "预处理指令工具/";


        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        [MenuItem(menu + "窗口 #&d", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        private static void Open()
        {
            WinUtil.Open<PreprocessCmdWin, PreprocessCmdView>("预处理指令", 600, 700);
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        #endregion
    }

}