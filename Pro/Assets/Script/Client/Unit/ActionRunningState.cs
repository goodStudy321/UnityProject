using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public enum ActionRunningState
{
    /// <summary>
    /// 完成
    /// </summary>
    Finish = 0,

    /// <summary>
    /// 打断
    /// </summary>
    Interrupt,

    /// <summary>
    /// 受伤
    /// </summary>
    Hurt,
}