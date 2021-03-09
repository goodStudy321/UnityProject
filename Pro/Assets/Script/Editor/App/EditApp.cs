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
    /// 编辑器下App信息
    /// </summary>
    public static class EditApp
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 100;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string Menu = MenuTool.Loong + "App/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "App/";

        /// <summary>
        /// 产品名
        /// </summary>
        public const string ProName = "xyjgx";

        /// <summary>
        /// 公司名缩写
        /// </summary>
        public const string CompanyAbbr = "Phantom";

        /// <summary>
        /// 公司名拼音
        /// </summary>
        public const string CompanyPinyin = "shenlong";

        /// <summary>
        /// 公司名全称
        /// </summary>
        public const string CompanyFullName = "Phantom Game Design Co,. Ltd.";
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
        /// 退出编辑器
        /// </summary>
        /// <param name="code"></param>
        /// <param name="quit"></param>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void Exit(ExitCode code, bool quit, string fmt, params object[] args)
        {
            string msg = null;
            if (fmt == null)
            {
                msg = "";
            }
            else if (args == null)
            {
                msg = fmt;
            }
            else
            {
                msg = string.Format(fmt, args);
            }
            iTrace.Error("Loong", "exit code {0}, {1}", code, msg);
            if (!quit) return;
            var exitCode = (int)code;
            EditorApplication.Exit(exitCode);
        }

        /// <summary>
        /// 批处理模式下退出编辑器
        /// </summary>
        /// <param name="code">退出吗</param>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void ExitBatch(ExitCode code, string fmt, params object[] args)
        {
            Exit(code, Application.isBatchMode, fmt, args);
        }
        #endregion
    }
}