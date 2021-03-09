/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/9 17:54:28
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 校验结果
    /// </summary>
    public enum AssetValidResult
    {
        Suc,

        /// <summary>
        /// 无包名
        /// </summary>
        NoAB,

        /// <summary>
        /// 不存在
        /// </summary>
        NotExist,

    }
}