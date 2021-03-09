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
     * GUID:        c3546cc8-01fb-4147-94bd-7ae9fa6c15bf
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/2/4 14:54:50
    /// BG:
    /// </summary>
    public class ABExWin : EditWinBase
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 60;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "资源包扩展/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源包扩展/";
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
            WinUtil.Open<ABExWin, ABExView>("资源包扩展", 600, 800);
        }
        #endregion
    }
}