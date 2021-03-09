//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/1 23:42:53
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AssetUtil
    /// </summary>
    public static class AssetBridge
    {
        #region 字段
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        /// <summary>
        /// 释放事件
        /// </summary>
        public static event Action<string, string> unload = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Unload(string name, string sfx)
        {
            if (unload != null) unload(name, sfx);
        }
        #endregion
    }
}