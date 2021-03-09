//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/10 10:53:30
//=============================================================================
using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// UICopyInfoMainOffNode
    /// </summary>
    public class UICopyInfoMainOffNode : FlowChartNode
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
        protected override void ReadyCustom()
        {
            UICopyInfoMain.Instance.Close();
            Complete();
        }
        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

#endif
    }
}