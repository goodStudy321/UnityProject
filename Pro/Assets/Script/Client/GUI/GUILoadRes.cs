//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 20:22:53
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// UILoadRes
    /// </summary>
    public class GUILoadRes : GUIBase
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
        private void SetLoadMode(LoadResMode mode)
        {
            AssetMgr.Mode = mode;
            Enable = false;
        }
        #endregion

        #region 保护方法
        protected override void OnGUISelf()
        {
            if (Btn("本地资源"))
            {
                SetLoadMode(LoadResMode.Asset);
            }
            else if (Btn("AssetBundle"))
            {
                SetLoadMode(LoadResMode.AB);
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