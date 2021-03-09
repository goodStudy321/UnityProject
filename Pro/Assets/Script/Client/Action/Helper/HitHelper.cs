using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;

public class HitHelper 
{
    public static readonly HitHelper instance = new HitHelper();

    private HitHelper()
    {

    }
    /// <summary>
    /// 攻击判断
    /// </summary>
    /// <param name="self"></param>
    /// <param name="target"></param>
    /// <param name="actionData"></param>
    /// <returns></returns>
    public bool CanHitTarget(Unit self, Unit target, ActionData actionData)
    {
        if (self == null) return false;
        if (self.Dead) return false;
        if (target == null) return false;
        if (target.Dead) return false;
        if (target.DestroyState) return false;

        ActionStatus actionstatus = target.ActionStatus;
        if (target.ActionStatus == null)
            return false;

        if (!target.ActionStatus.CanBehit)
            return false;

        // 如果当前动作不接受受伤攻击，停止击中判定。
        if (actionstatus.ActiveAction == null || !actionstatus.ActiveAction.CanHurt)
            return false;

        if (actionData.AttackDefList.Count <= 0)
            return false;

        AttackDefData data = actionData.AttackDefList[0];
        RaceType race = (RaceType)data.Race;//data.Race-->动作编辑器里面的“阵营”字段
        if (race == RaceType.Self && self == target)
            return true;

        UnitType unitType = target.mUnitAttInfo.UnitType;

        if (unitType == UnitType.Summon)
            return false;

        if (unitType == UnitType.VirtualSummon)
            return false;

        CampType campSelf = self.Camp;
        CampType campTarget = target.Camp;
        if (race == RaceType.Enemy && campSelf == campTarget) //攻击定义“阵营”选择的目标类型是enemy，如果阵营相同则不能开始行为
            return false;

        if (race == RaceType.Friend && campSelf != campTarget) //攻击定义“阵营”选择的目标类型是TeamMember（队友），如果阵营不同则不能开始行为
            return false;

        // 如果攻击高度不符合要求，停止击中判定
        //if ((data.HeightStatusHitMask & (1 << target.ActionStatus.ActiveAction.HeightStatus)) == 0)
        //    return false;

        return true;
    }

    /// <summary>
    /// 攻击判断
    /// </summary>
    /// <param name="self"></param>
    /// <param name="target"></param>
    /// <param name="actionData"></param>
    /// <returns></returns>
    public bool CanHitTarget(Unit self, Unit target, int raceType)//RaceType
    {
        if (self == null) return false;
        if (self.Dead) return false;
        if (target == null) return false;
        if (target.Dead) return false;
        if (target.DestroyState) return false;

        ActionStatus actionstatus = target.ActionStatus;

        if (target.ActionStatus == null)
            return false;

        if (!target.ActionStatus.CanBehit)
            return false;

        // 如果当前动作不接受受伤攻击，停止击中判定。
        if (actionstatus.ActiveAction == null || !actionstatus.ActiveAction.CanHurt)
            return false;

        UnitType unitType = target.mUnitAttInfo.UnitType;

        if (unitType == UnitType.Summon)
            return false;

        if (unitType == UnitType.VirtualSummon)
            return false;

        RaceType camp = (RaceType)raceType;

        if (camp == RaceType.Self)//自身
        {
            if (self == target)
                return true;
            else
                return false;
        }
        else if (camp == RaceType.Friend)//友方
        {
            if (self == target)
                return false;
            if (self.Camp == target.Camp)
                return true;
            else
                return false;
        }
        else if (camp == RaceType.Enemy)//敌方
        {
            if (self == target)
                return false;
            if (self.Camp != target.Camp)
                return true;
            else
                return false;
        }
        return true;
    }

    /// <summary>
    /// 清除之前拖尾效果
    /// </summary>
    /// <param name="go"></param>
    public void ClearTrailEffect(GameObject go)
    {
        if (go == null)
            return;
        TrailRenderer[] tr = go.GetComponentsInChildren<TrailRenderer>();
        if (tr == null)
            return;
        int lengh = tr.Length;
        for (int i = 0; i < lengh; i++)
        {
            tr[i].Clear();
        }
    }
}
