using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public enum UnitType
{
    None = 0,

    /// <summary>
    /// 人物
    /// </summary>
    Role = 1,

    /// <summary>
    /// 怪物
    /// </summary>
    Monster = 2,

    /// <summary>
    /// 采集物
    /// </summary>
    Collection = 3,

    /// <summary>
    /// PNC
    /// </summary>
    NPC = 4,

    /// <summary>
    /// 召唤体
    /// </summary>
    Summon = 6,

    /// <summary>
    /// 虚拟体
    /// </summary>
    VirtualSummon = 7,

    /// <summary>
    /// 神兵
    /// </summary>
    Artifact = 8,

    /// <summary>
    /// 法宝
    /// </summary>
    MagicWeapon = 9,

    /// <summary>
    /// 翅膀
    /// </summary>
    Wing = 10,

    /// <summary>
    /// 坐骑
    /// </summary>
    Mount = 11,

    /// <summary>
    /// 宠物
    /// </summary>
    Pet = 12,

    /// <summary>
    /// 掉落物
    /// </summary>
    DropItem = 13,

    /// <summary>
    /// 宠物坐骑
    /// </summary>
    PetMount = 15,

    /// <summary>
    /// 脚下光环
    /// </summary>
    Aperture = 16,

    /// <summary>
    /// 足迹
    /// </summary>
    FootPrint = 31,

    /// <summary>
    /// boss
    /// </summary>
    Boss = 20,
}