/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/1 15:15:47
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// SvnWin
    /// </summary>
    public class SvnWin : EditWinBase
    {
        #region 字段

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
        /// 设置窗口
        /// </summary>
        [MenuItem(SvnUtil.menu + "设置", false, SvnUtil.Pri)]
        [MenuItem(SvnUtil.AMenu + "设置", false, SvnUtil.Pri)]
        public static void Open()
        {
            WinUtil.Open<SvnWin, SvnView>("Svn设置", 600, 800);
        }

        #endregion
    }
}