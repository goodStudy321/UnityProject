using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6633f834-d0e4-4711-8cdc-72804f5644d5
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/2/5 10:05:26
    /// BG:
    /// </summary>
    public class TranPropWin : EditWinBase
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.PlanPri + 10;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Plan + "变换组件/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.Plan + "变换组件/";
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
        /// <summary>
        /// 打开窗口
        /// </summary>
        [MenuItem(menu + "窗口", false, Pri)]
        [MenuItem(AMenu + "窗口", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<TranPropWin, TranPropView>("变换组件", 360, 660);
        }
        #endregion
    }
}