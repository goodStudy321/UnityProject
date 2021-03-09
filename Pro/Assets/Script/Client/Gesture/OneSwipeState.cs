using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:一个手势状态
    /// </summary>
    public enum OneSwipeState
    {
        
        None,

        /// <summary>
        /// 上滑
        /// </summary>
        Up,

        /// <summary>
        /// 下滑
        /// </summary>
        Down,

        /// <summary>
        /// 左滑
        /// </summary>
        Left,

        /// <summary>
        /// 右滑
        /// </summary>
        Right,
    }
}