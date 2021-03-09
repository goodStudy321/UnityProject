using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BossExclusive : FightModBase
{
    #region 字段

    #endregion

    #region 私有方法

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
        Unit target = BossBatMgr.instance.GetTarget();
        if (target == null)
            return null;
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
        if (!BossBatMgr.instance.BossExclCndt(target))
            return false;
        return true;
    }
    #endregion
}
