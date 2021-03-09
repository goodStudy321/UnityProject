using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/*
 * 如有改动需求,请联系Loong
 * 如果必须改动,请知会Loong
*/

/// <summary>
/// AU:Loong
/// TM:2016.08.27
/// CO:EyesBlackGames.星战世界
/// BG:单位事件管理
/// </summary>
public static class UnitEventMgr
{

    #region 字段

    #endregion

    #region 属性

    #endregion

    #region 委托事件
    /// <summary>
    /// 创建单位完成全局事件
    /// </summary>
    public static event Action<Unit> create = null;

    /// <summary>
    /// 单位出生完成全局事件
    /// </summary>
    public static event Action<Unit> born = null;

    /// <summary>
    /// 死亡全局事件
    /// </summary>
    public static event Action<Unit> die = null;

    /// <summary>
    /// 血量改变全局事件
    /// </summary>
    public static event Action<Unit, long> hpChange = null;

    /// <summary>
    /// 受击全局事件
    /// </summary>
    public static event Action<Unit, Unit, Vector3> hit = null;
    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    /// <summary>
    /// 执行 创建完成全局事件
    /// </summary>
    public static void ExecuteCreateDone(Unit unit)
    {
        if (create != null) create(unit);
    }

    /// <summary>
    /// 执行 出生完成全局事件
    /// </summary>
    public static void ExecuteBornDone(Unit unit)
    {
        if (born != null) born(unit);
    }

    /// <summary>
    /// 执行 死亡全局事件
    /// </summary>
    public static void ExecuteDie(Unit unit)
    {
        if (die != null) die(unit);
    }

    /// <summary>
    /// 执行 血量改变全局事件
    /// </summary>
    /// <param name="unit">单位</param>
    /// <param name="value">形参2:负值代表减血,正值代表加血</param>
    public static void ExecuteChange(Unit unit, long value)
    {
        if (hpChange != null)
        {
            hpChange(unit, value);
        }
    }

    /// <summary>
    /// 执行 受击全局事件/形参1:被攻击者,形参2:攻击者,形参3:未知
    /// </summary>
    public static void ExecuteHit(Unit self, Unit atker, Vector3 pos)
    {
        if (hit != null) hit(self, atker, pos);
    }
    #endregion
}