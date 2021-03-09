using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// </summary>
public enum RaceType
{
    /// <summary>
    /// 敌方
    /// </summary>
    Enemy = 0,

    /// <summary>
    /// 友方
    /// </summary>
    Friend = 1,

    /// <summary>
    /// 自身
    /// </summary>
    Self = 2,

    /// <summary>
    /// 父体
    /// </summary>
    Parent = 3,

    /// <summary>
    /// 子体
    /// </summary>
    Child = 4,

    /// <summary>
    /// NPC
    /// </summary>
    NPC = 5,
}