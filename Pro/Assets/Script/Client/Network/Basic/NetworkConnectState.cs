using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.11
    /// BG:客户端连接状态
    /// </summary>
    public enum NetworkConnectState
    {
        /// <summary>
        /// 无
        /// </summary>
        None,

        /// <summary>
        /// 连接中
        /// </summary>
        Connecting,

        /// <summary>
        /// 连接失败
        /// </summary>
        ConnectFailed,

        /// <summary>
        /// 连接成功
        /// </summary>
        ConnectSuccess,

        /// <summary>
        /// 断开失败
        /// </summary>
        DisconnectFailed,

        /// <summary>
        /// 断开成功
        /// </summary>
        DisconnectSuccess,

        /// <summary>
        /// 正在断开中
        /// </summary>
        Disconnecting,
    }
}