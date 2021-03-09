//*****************************************************************************
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2018/10/3 10:13:48
//*****************************************************************************

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 退出码
    /// </summary>
    public enum ExitCode
    {
        /// <summary>
        /// 正常退出
        /// </summary>
        None = 0,

        /// <summary>
        /// 主扩展文件不存在
        /// </summary>
        MainObbNotExist,

        /// <summary>
        /// 升级目录压缩文件不存在
        /// </summary>
        UpgCompFileNotExist,
    }
}