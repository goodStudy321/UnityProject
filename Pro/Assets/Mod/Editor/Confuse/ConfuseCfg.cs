//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 16:57:46
//=============================================================================

using System;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseCfg
    /// </summary>
    [Serializable]
    public class ConfuseCfg
    {
        #region 字段
        /// <summary>
        /// 混肴次数
        /// </summary>
        public int freq = 1;


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
        public void OnGUI(Object o)
        {
            if (!UIEditTool.DrawHeader("基本属性", "ConfuseUnusedFile", StyleTool.Host)) return;

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.IntField("混肴次数:", ref freq, o);

            EditorGUILayout.EndVertical();

        }
        #endregion
    }
}