using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AllMode : FightModBase
{
    #region 字段

    #endregion

    #region 私有方法
    private Unit GetViewTar(Unit attacker, bool bHited)
    {
        if (attacker == null)
            return null;
        FightModMgr fmMgr = FightModMgr.instance;
        SkillHelper skHp = SkillHelper.instance;
        float viewDis = skHp.GetViewDis(attacker);
        float minDis = viewDis * viewDis;
        Unit lastTarget = null;
        List<Unit> list = fmMgr.GetTarList(bHited);
        for (int i = 0; i < list.Count; i++)
        {
            Unit target = list[i];
            if (!fmMgr.StfCndt(attacker, target))
            {
                if (bHited)
                    list.Remove(target);
                continue;
            }
            if (skHp.BossTie(attacker, target))
            {
                if (bHited)
                    list.Remove(target);
                continue;
            }
            if (lastTarget == null)
            {
                fmMgr.Replace(attacker, ref lastTarget, target, ref minDis);
                continue;
            }
            UnitType unitType = target.mUnitAttInfo.UnitType;
            if (lastTarget.mUnitAttInfo.UnitType == UnitType.Role)
            {
                if (unitType != UnitType.Role)
                    continue;
                if (!skHp.CheckNearestDistance(attacker, target, minDis))
                    continue;
                fmMgr.Replace(attacker, ref lastTarget, target, ref minDis);
                continue;
            }
            else
            {
                if (target.mUnitAttInfo.UnitType == UnitType.Role)
                {
                    fmMgr.Replace(attacker, ref lastTarget, target, ref minDis);
                    continue;
                }
                if (!skHp.CheckNearestDistance(attacker, target, minDis))
                    continue;
                fmMgr.Replace(attacker, ref lastTarget, target, ref minDis);
                continue;
            }
        }
        return lastTarget;
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 获取目标
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="dis"></param>
    /// <returns></returns>
    public Unit GetTarget(Unit attacker, float dis)
    {
        Unit target = GetViewTar(attacker, true);
        if (target == null)
            target = GetViewTar(attacker, false);
        SkillHelper skHp = SkillHelper.instance;
        if (!skHp.IsInDistance(attacker, target, dis))
            return null;
        return target;
    }

    /// <summary>
    /// 满足条件
    /// </summary>
    /// <returns></returns>
    public bool StfCdt(Unit attacker, Unit target)
    {
        UnitHelper uHp = UnitHelper.instance;
        bool canUse = uHp.CanUseUnit(target);
        if (canUse == false)
            return false;
        SkillHelper skHp = SkillHelper.instance;
        UnitType unitType = target.mUnitAttInfo.UnitType;
        if (!skHp.CannotHitUnitType(unitType))
            return false;
        if (skHp.BossTie(attacker, target))
            return false;
        return true;
    }
    #endregion
}
