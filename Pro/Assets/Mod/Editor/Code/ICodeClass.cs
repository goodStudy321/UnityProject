//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/24 17:24:32
//=============================================================================

using System;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ICodeClass
    /// </summary>
    public interface ICodeClass : IDisposable
    {
        #region 属性
        string Name { get; set; }

        string BaseClass { get; set; }

        List<ICodeProp> Props { get; set; }


        List<ICodeFunc> Funcs { get; set; }

        /// <summary>
        /// 访问等级
        /// </summary>
        CSAccessType AccessType { get; set; }
        #endregion

        #region 方法

        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}