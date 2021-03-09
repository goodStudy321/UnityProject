//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/25 12:11:20
//=============================================================================

#if CS_HOTFIX_ENABLE

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// MainEntry
/// </summary>
public class MainEntry
{
    #region 字段

    #endregion

    #region 属性

    #endregion

    #region 委托事件

    #endregion

    #region 构造方法
    public MainEntry()
    {

    }
    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    public void Start()
    {
        var go = new GameObject();
        go.AddComponent<Main>();
    }
    #endregion
}

#endif