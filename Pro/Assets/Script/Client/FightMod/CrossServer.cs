using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CrossServer : FightModBase
{
    #region 字段

    #endregion

    #region 私有方法
    /// <summary>
    /// 获取视野内目标
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="bHited"></param>
    /// <returns></returns>
    private Unit GetViewTar(Unit attacker, bool bHited)
    {
        if (attacker == null)
            return null;
        Unit lastTarget = null;
        float distance = 0;
        FightModMgr fmMgr = FightModMgr.instance;
        SkillHelper skHp = SkillHelper.instance;
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
            if (!StfCdt(attacker, target))
            {
                if (bHited)
                    list.Remove(target);
                continue;
            }
            if (lastTarget == null)
            {
                fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
                continue;
            }
            UnitType curType = target.mUnitAttInfo.UnitType;
            UnitType lstType = lastTarget.mUnitAttInfo.UnitType;
            if (curType == UnitType.Role)
            {
                if (lstType == UnitType.Role)
                {
                    if (!skHp.CheckNearestDistance(attacker, target, distance))
                        continue;
                    fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
                    continue;
                }
                else
                    fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
            }
            else
            {
                if (lstType == UnitType.Role)
                    continue;
                else
                {
                    if (!skHp.CheckNearestDistance(attacker, target, distance))
                        continue;
                    fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
                    continue;
                }
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
        SkillHelper skHp = SkillHelper.instance;
        bool canUse = uHp.CanUseUnit(target);
        if (canUse == false)
            return false;
        if (uHp.RelativesUnit(attacker, target))
            return false;
        if (skHp.BossTie(attacker, target))
            return false;
        UnitType unitType = UnitHelper.instance.GetUnitType(target.TypeId);
        if (unitType == UnitType.Monster)
        {
            if (!skHp.CanHitSafeMons(target))
                return false;
            if (skHp.CompaireCamp(attacker, target, UnitCamp.Enemy))
                return true;
            return false;
        }
        else if (unitType == UnitType.Role)
        {
            if (attacker.ServerId == target.ServerId)
                return false;
            if (MapPathMgr.instance.IsSaveZone(target.Position))
                return false;
            return true;
        }
        return false;
    }
    #endregion
}
