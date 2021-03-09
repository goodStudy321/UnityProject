/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/7 23:12:13
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// DecompFty
    /// </summary>
    public static class DecompFty
    {
        #region 字段

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
        /// <summary>
        /// 创建解压实例
        /// </summary>
        /// <returns></returns>
        public static DecompBase Create()
        {
#if LOONG_ENABLE_UPG
            return new UnLzmaU();
#else
            return null;
#endif
        }
        #endregion
    }
}