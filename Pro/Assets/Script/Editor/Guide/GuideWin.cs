//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/29 19:31:43
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// GuideWin
    /// </summary>
    public class GuideWin : EditWinBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public GuideWin()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        [MenuItem(MenuTool.Plan + "引导", false, MenuTool.PlanPri + 1)]
        [MenuItem(MenuTool.APlan + "引导", false, MenuTool.PlanPri + 1)]

        private static void Open()
        {
            WinUtil.Open<GuideWin, GuideView>("引导", 300, 400);
        }
        #endregion
    }
}