/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/23 22:16:37
 ============================================================================*/

using System;

namespace Loong
{
    /// <summary>
    /// 切场景接口
    /// </summary>
    public interface IOnChgScene
    {
        #region 属性

        #endregion

        #region 方法

        /// <summary>
        /// 开始切换场景
        /// </summary>
        void BegChgScene();

        /// <summary>
        /// 结束切换场景
        /// </summary>
        void EndChgScene();
        #endregion

        #region 索引器

        #endregion

        #region 事件
        #endregion
    }
}