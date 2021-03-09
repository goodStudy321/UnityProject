//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/2 1:13:15
// 发布流程接口
// 执行顺序,预处理→处理资源
//=============================================================================

using System;

namespace Loong.Edit
{
    /// <summary>
    /// 
    /// </summary>
    public interface IReleaseProcess
    {
        #region 属性

        #endregion

        #region 方法

        /// <summary>
        /// 预处理
        /// </summary>
        void Preprocess();


        /// <summary>
        /// 处理资源
        /// </summary>
        void HandleAssets();


        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}