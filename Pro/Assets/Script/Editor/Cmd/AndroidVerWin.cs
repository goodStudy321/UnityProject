/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 19:58:51
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
    /// Android版本号查阅窗口
    /// </summary>
    public class AndroidVerWin : EditWinBase
    {
        #region 字段
        public const string Menu = MenuTool.Loong + "缓存版本号/";

        public const string AMenu = MenuTool.ALoong + "缓存版本号/";
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

        public override void Init()
        {
            Add<VerData>();
            Open<VerData>();
        }
        [MenuItem(Menu + "安卓")]
        [MenuItem(AMenu + "安卓")]
        public static void Open()
        {
            WinUtil.Open<AndroidVerWin>(400, 400);
        }
        #endregion
    }
}