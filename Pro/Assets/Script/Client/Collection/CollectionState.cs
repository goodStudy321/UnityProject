using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        1dd7cf56-34eb-4f8a-925d-3e6d7bcd825b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/12 15:18:01
    /// BG:采集状态
    /// </summary>
    public enum CollectionState
    {
        /// <summary>
        /// 无
        /// </summary>
        None,

        /// <summary>
        /// 等待
        /// </summary>
        Wait,

        /// <summary>
        /// 请求中
        /// </summary>
        Req,

        /// <summary>
        /// 采集倒计时中
        /// </summary>
        Run,

        /// <summary>
        /// 中断
        /// </summary>
        Interupt,
    }
}