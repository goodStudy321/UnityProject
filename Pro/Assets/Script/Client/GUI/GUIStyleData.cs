//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 20:59:57
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// GUIStyleData
    /// </summary>
    public class GUIStyleData
    {
        #region 字段
        public int fontSize;

        public Color normColor;

        public FontStyle fontStyle;

        public TextAnchor anchor;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public GUIStyleData()
        {

        }

        public GUIStyleData(int size, FontStyle fs, TextAnchor anchor)
        {
            this.fontSize = size;
            this.fontStyle = fs;
            this.anchor = anchor;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}