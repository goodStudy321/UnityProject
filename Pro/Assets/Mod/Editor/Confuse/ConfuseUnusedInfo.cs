//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 22:01:15
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseUnusedCount
    /// </summary>
    public class ConfuseUnusedInfo
    {
        #region 字段
        private int idx = 0;

        public int max = 0;

        public int fileCount = 0;

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
        public bool IsMax()
        {
            return (idx >= max);
        }

        public void AddIdx()
        {
            ++idx;
        }
        #endregion
    }
}