using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PeaceMode : FightModBase
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
    private Unit GetViewTar(Unit attacker,bool bHited)
    {
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
            if (skHp.IsRedName(target))
            {
                if (!skHp.IsRedName(lastTarget))
                {
                    fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
                    continue;
                }
                if (!skHp.CheckNearestDistance(attacker, target, distance))
                    continue;
                fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
                continue;
            }
            if (skHp.IsRedName(lastTarget))
                continue;
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
            if (!skHp.CheckNearestDistance(attacker, target, distance))
                continue;
            fmMgr.Replace(attacker, ref lastTarget, target, ref distance);
            continue;
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
    public Unit GetTarget(Unit attacker,float dis)
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
        bool bossTie = skHp.BossTie(attacker, target);
        if (bossTie == true)
            return false;
        bool redName = skHp.IsRedName(target);
        if (redName == true)
            return true;
        UnitType unitType = uHp.GetUnitType(target.TypeId);
        if (unitType != UnitType.Monster)
            return false;
        bool stfCamp = skHp.CompaireCamp(attacker, target, UnitCamp.Enemy);
        if (stfCamp == true)
            return true;
        return false;
    }
    #endregion
}
