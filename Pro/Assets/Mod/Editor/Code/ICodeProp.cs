//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 17:07:02
//=============================================================================

using System;
using System.Text;

namespace Loong.Edit
{
    /// <summary>
    /// ICodeProp
    /// </summary>
    public interface ICodeProp : IDisposable
    {
        #region 属性
        /// <summary>
        /// 名称
        /// </summary>
        string Name { get; set; }

        /// <summary>
        /// 类型
        /// </summary>
        string Type { get; set; }

        /// <summary>
        /// true:是列表
        /// </summary>
        bool IsList { get; set; }

        CSPropType PropType { get; set; }

        /// <summary>
        /// 访问等级
        /// </summary>
        CSAccessType AccessType { get; set; }


        #endregion

        #region 方法
        /// <summary>
        /// 获取字段字符串
        /// </summary>
        /// <returns></returns>
        void ApdField(StringBuilder sb, int tap);

        /// <summary>
        /// 获取属性字符串
        /// </summary>
        /// <returns></returns>
        void ApdProp(StringBuilder sb, int tap);
        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}