using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FightModMgr
{
    public static readonly FightModMgr instance = new FightModMgr();

    private FightModMgr() { }
    #region 字段
    /// <summary>
    /// 战斗模式字典
    /// </summary>
    Dictionary<FightType, FightModBase> mFtModDic = new Dictionary<FightType, FightModBase>();
    #endregion

    #region 公有方法
    public void Init()
    {
        mFtModDic.Clear();
        Array keys = Enum.GetValues(typeof(FightType));
        int len = keys.Length;
        for(int i = 0; i < len; i++)
        {
            FightType type = (FightType)keys.GetValue(i);
            FightModBase ftMod = FightModFty.Create(type);
            mFtModDic.Add(type, ftMod);
        }
    }
    /// <summary>
    /// 获取目标
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="distance"></param>
    /// <returns></returns>
    public Unit GetTarget(Unit attacker, float distance)
    {
        FightModBase ftMod = GetFightMod(attacker);
        if (ftMod == null)
            return null;
        Unit target = LockSatify(attacker, distance);
        if (target != null)
            return target;
        SkillHelper.instance.SetLockTarget(attacker, null);
        target = ftMod.GetTarget(attacker,distance);
        return target;
    }

    /// <summary>
    /// 获取战斗模式
    /// </summary>
    /// <param name="attacker"></param>
    /// <returns></returns>
    public FightModBase GetFightMod(Unit attacker)
    {
        FightType fightType = (FightType)attacker.FightType;
        if (!mFtModDic.ContainsKey(fightType))
            return null;
        FightModBase ftMod = mFtModDic[fightType];
        return ftMod;
    }

    /// <summary>
    /// 锁定目标是否满足
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="dis"></param>
    /// <returns></returns>
    public Unit LockSatify(Unit attacker, float dis)
    {
        FightModBase ftMod = GetFightMod(attacker);
        if (ftMod == null)
            return null;
        Unit target = InputMgr.instance.mLockTarget;
        bool stfy = ftMod.StfCdt(attacker, target);
        if (stfy == false)
            return null;
        bool bInDis = SkillHelper.instance.IsInDistance(attacker, target, dis);
        if (bInDis == false)
            return null;
        attacker.ActionStatus.FTtarget = target;
        return target;
    }

    /// <summary>
    /// 获取目标列表
    /// </summary>
    /// <param name="bHited"></param>
    /// <returns></returns>
    public List<Unit> GetTarList(bool bHited)
    {
        List<Unit> list = null;
        if (bHited)
            list = InputMgr.instance.mHitedList;
        else
            list = UnitMgr.instance.UnitList;
        return list;
    }

    /// <summary>
    /// 满足条件
    /// </summary>
    /// <returns></returns>
    public bool StfCndt(Unit attacker, Unit target)
    {
        UnitHelper uHp = UnitHelper.instance;
        if (uHp.RelativesUnit(attacker, target))
            return false;
        TaskTarHelper ttHp = TaskTarHelper.instance;
        if (ttHp.TaskTarKill())
        {
            if (!ttHp.IsTaskTar(target))
                return false;
        }
        UnitType unitType = target.mUnitAttInfo.UnitType;
        SkillHelper skHp = SkillHelper.instance;
        if (!skHp.CannotHitUnitType(unitType))
            return false;
        if (!skHp.InViewDis(attacker, target))
            return false;
        if (!skHp.CanHit(target))
            return false;
        return true;
    }

    /// <summary>
    /// 替换
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="lastTarget"></param>
    /// <param name="curTarget"></param>
    /// <param name="distance"></param>
    public void Replace(Unit attacker, ref Unit lastTarget, Unit curTarget, ref float distance)
    {
        lastTarget = curTarget;
        distance = SkillHelper.instance.GetDistance(attacker, lastTarget);
    }

    /// <summary>
    /// 设置强制模式目标
    /// </summary>
    public void SetFMAutoTargets(Unit attacker, UnitType unitType = UnitType.None)
    {
        InputMgr.instance.mLockTarget = null;
        FightType fightType = (FightType)attacker.FightType;
        if (fightType != FightType.ForceMode)
            return;
        SkillHelper skHp = SkillHelper.instance;
        List<Unit> list = UnitMgr.instance.UnitList;
        List<Unit> tarList = InputMgr.instance.mHgupList;
        tarList.Clear();
        for (int i = 0; i < list.Count; i++)
        {
            Unit target = list[i];
            if (UnitHelper.instance.RelativesUnit(attacker, target))
                continue;
            if (unitType == UnitType.Monster)
            {
                UnitType tarType = UnitHelper.instance.GetUnitType(target.TypeId);
                if (tarType != UnitType.Monster)
                    continue;
            }
            UnitType targetType = target.mUnitAttInfo.UnitType;
            if (!skHp.CannotHitUnitType(targetType))
                continue;
            if (!skHp.InViewDis(attacker, target))
                continue;
            FightModBase fmBase = GetFightMod(attacker);
            if (!fmBase.StfCdt(attacker, target))
                continue;
            tarList.Add(target);
        }
    }

    /// <summary>
    /// 清除强制模式目标列表
    /// </summary>
    /// <param name="unit"></param>
    public void ClearFMAutoTargets()
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        FightType fightType = (FightType)unit.FightType;
        if (fightType != FightType.ForceMode)
            return;
        InputMgr.instance.mLockTarget = null;
        InputMgr.instance.mHgupList.Clear();
    }
    #endregion
}
