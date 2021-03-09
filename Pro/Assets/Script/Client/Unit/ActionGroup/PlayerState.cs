#if UNITY_EDITOR
using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:玩家状态
    /// </summary>
    public enum PlayerState
    {
        /// <summary>
        /// 无
        /// </summary>
        None,

        /// <summary>
        /// 待机
        /// </summary>
        Idle,

        /// <summary>
        /// 移动
        /// </summary>
        Move,

        /// <summary>
        /// 技能
        /// </summary>
        Skill,
    }
}
#endif