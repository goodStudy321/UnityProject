//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 11:14:18
//=============================================================================

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// StrWin
    /// </summary>
    public class StrWin : PageWin<StrPage, string>
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public StrWin()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Open(List<string> objs)
        {
            var win = GetWindow<StrWin>();
            win.Init(objs);
        }
        #endregion
    }
}