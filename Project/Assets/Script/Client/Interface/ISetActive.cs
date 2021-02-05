/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015.3.20 20:38:52
 ============================================================================*/

using System;

namespace Hello.Game
{

    /// <summary>
    /// 激活/关闭接口
    /// </summary>
    public interface ISetActive : IDisposable
    {
        #region 属性

        #endregion

        #region 方法
        void Open();

        void Close();
        #endregion

        #region 事件

        #endregion

        #region 索引器

        #endregion
    }
}