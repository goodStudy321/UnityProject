//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 22:18:38
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// GUIMain
    /// </summary>
    public class GUIMain : GUIBase
    {
        #region 字段
        public event Action selectSingle;

        public event Action selectServer;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void SelectSingle()
        {
            if (selectSingle != null) selectSingle();
            Enable = false;
        }

        private void SelectServer()
        {
            if (selectServer != null) selectServer();
            Enable = false;
        }
        #endregion

        #region 保护方法
        protected override void OnGUISelf()
        {
            if (Btn("单机"))
            {
                SelectSingle();
            }
            else if (Btn("服务器"))
            {
                SelectServer();
            }
        }

        protected override void SetBtnData()
        {
            SetStyle(skin.button, btnData, 120, Color.black);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}