/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/23 22:17:18
 ============================================================================*/

using System;

namespace Loong.Game
{
    /// <summary>
    /// 模块接口
    /// IInit:初始化时调用
    /// IClear:退出登陆时调用
    /// IOnChgScene:在切换场景时调用
    /// 如果继承IModule的模块同时继承了IUpdate,则此模块会在模块管理器中更新
    /// </summary>
    public interface IModule : IInit, IClear, IOnChgScene, ILocalization, IDisposable
    {
        #region 属性

        #endregion

        #region 方法

        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}