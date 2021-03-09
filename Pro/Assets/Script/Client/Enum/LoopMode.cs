using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.1.5
    /// BG:循环模式
    /// </summary>
    public enum LoopMode
    {
        /// <summary>
        /// 一次
        /// </summary>
        Once,

        /// <summary>
        /// 循环,在结束时重新开始
        /// </summary>
        Loop,

        /// <summary>
        /// 来回,在结束位置倒回
        /// </summary>
        PingPong
    }
}