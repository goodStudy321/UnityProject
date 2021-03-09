/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/27 11:43:01
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 资源处理选项
    /// </summary>
    public enum AssetOp
    {

        None,
        /// <summary>
        /// 已下载
        /// </summary>
        Download,
        /// <summary>
        /// 已解压
        /// </summary>
        Decompress,

        /// <summary>
        /// 已校验
        /// </summary>
        Verify
    }
}