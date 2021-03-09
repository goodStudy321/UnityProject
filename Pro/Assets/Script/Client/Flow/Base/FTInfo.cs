//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/1/17 10:20:36
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Phantom
{
    /// <summary>
    /// FTInfo
    /// </summary>
    [Serializable]
    public class FTInfo
    {
        #region 字段
        public string name = null;

        public string startName = null;

        public List<FTNInfo> infos = new List<FTNInfo>();

        public List<FlowChartLink> links = new List<FlowChartLink>();
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

        #endregion
    }
}