//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/11/8 12:23:21
//=============================================================================

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// UILocalLblChkView
    /// </summary>
    public class UILocalLblChkView : EditViewBase
    {
        #region 字段
        public UILocalLblChkPage page = new UILocalLblChkPage();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Check()
        {
            var lst = NGUIUtil.CheckTextLbl();
            page.SetLst(lst);
        }

        private void ClearText()
        {
            int len = page.lst.Count;
            for (int i = 0; i < len; i++)
            {
                var it = page.lst[i];
                it.ClearText();
            }
            UIEditTip.Log("已清除");
        }
        #endregion

        #region 保护方法
        protected override void Help()
        {
            UIEditTip.Log("查阅文档:客户端获取所有非数字UILabel.docx");
        }

        protected override void OnGUICustom()
        {


            page.OnGUI(this);
        }

        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("检查"))
            {
                DialogUtil.Show("", "检查UI Root下所有UI?", Check);
            }
            if (TitleBtn("一键清除"))
            {
                DialogUtil.Show("", "一键清除所有标签的文本内容?", ClearText);
            }

            EndTitle();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}