//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 16:58:05
//=============================================================================

using System;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseView
    /// </summary>
    public class ConfuseView : EditViewBase
    {
        #region 字段
        public ConfuseCfg cfg = new ConfuseCfg();

        public ConfuseCodeCfg codeCfg = new ConfuseCodeCfg();

        public ConfuseUnusedCfg unusedCfg = new ConfuseUnusedCfg();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ConfuseView()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("应用"))
            {
                ConfuseMgr.ApplyDialog();
            }
            else if (TitleBtn("混淆代码"))
            {
                ConfuseMgr.GenCodeDialog();
            }
            else if (TitleBtn("删除混淆代码"))
            {
                ConfuseMgr.DelCodeDialog();
            }
            else if (TitleBtn("生成无用代码"))
            {
                ConfuseMgr.GenUnuseCodeDialog();
            }
            else if (TitleBtn("删除无用代码"))
            {
                ConfuseMgr.DelUnuseCodeDialog();
            }
            else if (TitleBtn("混淆无用资源"))
            {
                ConfuseMgr.GenUnusedFilesDialog();
            }
            else if (TitleBtn("删除无用资源"))
            {
                ConfuseMgr.DelUnusedFilesDialog();
            }
            else if (TitleBtn("检查配置文件"))
            {
                ConfuseMgr.CheckFileDialog();
                UIEditTip.Log("请查看控制台");
            }
            EndTitle();
        }

        protected override void OnGUICustom()
        {
            cfg.OnGUI(this);
            codeCfg.OnGUI(this);
            unusedCfg.OnGUI(this);
        }
        #endregion
    }
}