//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/2 1:22:51
// 发布流程工具
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ReleaseProcessUtil
    /// </summary>
    public static class ReleaseProcessUtil
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
        public static void Preprocess<T>(List<T> processes) where T : IReleaseProcess
        {
            PreprocessCmdUtil.Init();
            int length = processes.Count;
            for (int i = 0; i < length; i++)
            {
                processes[i].Preprocess();
            }
            PreprocessCmdUtil.Apply();
        }

        public static void HandlerAssets<T>(List<T> processes) where T : IReleaseProcess
        {
            int length = processes.Count;
            for (int i = 0; i < length; i++)
            {
                processes[i].HandleAssets();
            }
        }
        #endregion
    }
}