//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/24 17:24:40
//=============================================================================

using System;
using System.Text;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// ICodeFunc
    /// </summary>
    public interface ICodeFunc : IDisposable
    {
        #region 属性
        /// <summary>
        /// 方法名称
        /// </summary>
        string Name { get; set; }
        /// <summary>
        /// 返回类型
        /// </summary>
        string ReturnType { get; set; }

        /// <summary>
        /// 参数类型
        /// </summary>
        List<CSArgInfo> Args { get; set; }

        /// <summary>
        /// 访问等级
        /// </summary>
        CSAccessType AccessType { get; set; }

        #endregion

        #region 方法
        void ApdFunc(StringBuilder sb, int tap);
        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}