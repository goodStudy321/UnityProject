using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ProtoBuf;

public class SkillHelper
{

    public static readonly SkillHelper instance = new SkillHelper();

    private SkillHelper()
    {

    }
    #region 私有变量
    //长方体攻击框大小
    Vector3 mCubeHitDefSize = Vector3.zero;
    //圆柱体攻击框大小
    Vector3 mCylinderSize = Vector3.zero;
    //圆环攻击框大小
    Vector3 mRingSize = Vector3.zero;
    //扇形攻击框大小
    Vector3 mFanSize = Vector3.zero;
    //扇形攻击狂角度
    Vector2 mFanAngle = Vector2.zero;
    //攻击框缩放
    Vector3 mFrameFactor = Vector3.one;
    #endregion
    #region 公有方法
    /// <summary>
    /// 获取技能表动作ID
    /// </summary>
    /// <param name="skillLvId"></param>
    /// <returns></returns>
    public string GetActIDFTbl(uint skillLvId)
    {
        SkillLevelAttr attr = SkillLevelAttrManager.instance.Find(skillLvId);
        if (attr == null)
            return null;
        return attr.actionId.ToString();
    }
    /// <summary>
    /// 获取技能
    /// </summary>
    /// <returns></returns>
    public GameSkill GetCanPlaySkill(Unit attacker)
    {
        GameSkill norSkill = null;
        for (int i = 0; i < attacker.mUnitSkill.Skills.Count; i++)
        {
            GameSkill skill = attacker.mUnitSkill.Skills[i];
            if (skill == null)
                continue;
            if (AutoFbSkills.instance.CheckFb(attacker, skill.SkillLevelID))
                continue;
            SkillEnum skillType = (SkillEnum)skill.SkillLevelAttrTable.type;
            if (skillType == SkillEnum.passtive)
                continue;
            if (skill.isCding)
                continue;
            if (skillType == SkillEnum.NormalAtk)
            {
                if (attacker.mUnitBuffStateInfo.IsForbitNormalAttack)
                    continue;
                norSkill = skill;
                continue;
            }
            if (attacker.mUnitBuffStateInfo.IsForbitSkillAttack)
                continue;
            return skill;
        }
        return norSkill;
    }

    /// <summary>
    /// 获取中断动作ID
    /// </summary>
    /// <returns></returns>
    public string GetItrptActID(Unit unit,GameSkill skill)
    {
        if (unit == null)
            return string.Empty;
        if (skill == null)
            return string.Empty;
        string actID = string.Empty;
        actID = unit.ActionStatus.CheckSkill((int)skill.SkillID);
        return actID;
    }

    /// <summary>
    /// 获取技能击中目标列表
    /// </summary>
    /// <returns></returns>
    public List<long> GetSkillHitTargetList(Unit attacker, string actionID, int hitdefIndex)
    {
        List<long> targetList = new List<long>();
        ActionData actionData = attacker.ActionStatus.GetActionByID(actionID);
        if (actionData == null)
            return targetList;
        AttackDefData attackDefData = ActionHelper.GetAttackDefDataByIndex(actionData, hitdefIndex);
        if (attackDefData == null)
            return targetList;
        for (int i = 0; i < UnitMgr.instance.UnitList.Count; i++)
        {
            Unit target = UnitMgr.instance.UnitList[i];
            if (target == null || target.DestroyState || target.Dead || !CanHit(attacker, target, attackDefData))
                continue;

            if (!CheckHitTarget(attacker, target, attackDefData))
                continue;
            targetList.Add(target.UnitUID);
        }
        return targetList;
    }

    /// <summary>
    /// 获取视野距离目标
    /// </summary>
    /// <param name="finder"></param>
    /// <returns></returns>
    public Unit GetViewDisTarget(Unit finder, UnitCamp unitCamp)
    {
        Unit target = null;
        float viewDis = GetViewDis(finder);
        target = GetNearestTarget(finder, unitCamp, viewDis);
        return target;
    }

    /// <summary>
    /// 是否可攻击
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool CanHit(Unit target)
    {
        if (target == null)
            return false;
        if (target.ActionStatus == null)
            return false;
        if (target.ActionStatus.ActiveAction == null)
            return false;
        return target.ActionStatus.ActiveAction.CanHurt;
    }

    /// <summary>
    /// 是否在视野范围内
    /// </summary>
    /// <param name="finder"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool InViewDis(Unit finder, Unit target)
    {
        if (target == null)
            return false;
        if (target.Dead)
            return false;
        float viewDis = GetViewDis(finder);
        viewDis *= viewDis;
        Vector3 forward = finder.Position - target.Position;
        float distance = Vector3.SqrMagnitude(forward);
        if (distance > viewDis)
            return false;
        return true;
    }

    /// <summary>
    /// 是否红名
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool IsRedName(Unit target)
    {
        if (target == null)
            return false;
        if (!target.mUnitRedNameInfo.IsRedName)
            return false;
        return true;
    }

    public bool CheckNearestDistance(Unit attacker, Unit target, float distance)
    {
        float dis = Vector3.SqrMagnitude(attacker.Position - target.Position);
        if (dis > distance)
            return false;
        return true;
    }

    /// <summary>
    /// 获取距离平方
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    public float GetDistance(Unit attacker, Unit target)
    {
        return Vector3.SqrMagnitude(attacker.Position - target.Position);
    }

    /// <summary>
    /// Boss疲劳
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool BossTie(Unit attacker, Unit target)
    {
        if (attacker == null)
            return true;
        if (target == null)
            return true;
        UnitType unitType = target.mUnitAttInfo.UnitType;
        if (unitType != UnitType.Boss)
            return false;
        if (attacker.mUnitBuffStateInfo.ForbidAtkBoss)
            return true;
        return false;
    }

    /// <summary>
    /// 切换锁定目标
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    public void SetLockTarget(Unit attacker, Unit target)
    {
        attacker.ActionStatus.FTtarget = target;
        InputMgr.instance.mLockTarget = target;

        QualityMgr.instance.DisplayCtrl.ForceAddShowUnit(target);
    }

    /// <summary>
    /// 根据typeId获取最近目标
    /// </summary>
    /// <param name="finder"></param>
    /// <param name="typeId"></param>
    /// <returns></returns>
    public Unit GetNTarByTypeId(Unit finder, uint typeId)
    {
        float minDis = 1000;
        Unit minDisTarget = null;
        for (int i = 0; i < UnitMgr.instance.UnitList.Count; i++)
        {
            Unit target = UnitMgr.instance.UnitList[i];
            if (target.Dead)
                continue;
            if (target.TypeId != typeId)
                continue;
            float targetDis = Vector3.Distance(target.Position, finder.Position);
            float viewDis = GetViewDis(finder);
            if (viewDis < targetDis)
                continue;
            if (targetDis > minDis)
                continue;
            minDisTarget = target;
            minDis = targetDis;
        }
        return minDisTarget;
    }

    /// <summary>
    /// 根据单位类型获取目标
    /// </summary>
    /// <param name="finder"></param>
    /// <param name="unitType"></param>
    /// <returns></returns>
    public Unit GetNTarByType(Unit finder, UnitType unitType)
    {
        float minDis = 1000;
        Unit minDisTarget = null;
        for (int i = 0; i < UnitMgr.instance.UnitList.Count; i++)
        {
            Unit target = UnitMgr.instance.UnitList[i];
            if (target.Dead)
                continue;
            if (target.mUnitAttInfo.UnitType != unitType)
                continue;
            float targetDis = Vector3.Distance(target.Position, finder.Position);
            float viewDis = GetViewDis(finder);
            if (viewDis < targetDis)
                continue;
            if (targetDis > minDis)
                continue;
            minDisTarget = target;
            minDis = targetDis;
        }
        return minDisTarget;
    }
    
    /// <summary>
    /// 获取最近目标
    /// </summary>
    /// <param name="finder">获取者</param>
    /// <param name="unitCamp">获取目标阵型</param>
    /// <param name="distance">距离</param>
    /// <returns></returns>
    public Unit GetNearestTarget(Unit finder, UnitCamp unitCamp, float distance)
    {
        float minDis = distance * distance;
        Unit minDisTarget = null;
        for(int i = 0; i < UnitMgr.instance.UnitList.Count; i++)
        {
            Unit target = UnitMgr.instance.UnitList[i];
            if (target.Dead)
                continue;
            UnitType unitType = target.mUnitAttInfo.UnitType;
            if(!CannotHitUnitType(unitType))
                continue;
            if (!CompaireCamp(finder, target, unitCamp))
                continue;
            float targetDis = Vector3.SqrMagnitude(target.Position - finder.Position);
            if (targetDis > minDis)
                continue;
            minDisTarget = target;
            minDis = targetDis;
        }
        return minDisTarget;
    }

    /// <summary>
    /// 目标是否在指定距离范围内
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <param name="distance"></param>
    /// <returns></returns>
    public bool IsInDistance(Unit attacker, Unit target, float distance)
    {
        if (attacker == null)
            return false;
        if (target == null)
            return false;
        if (target.Dead)
            return false;
        float targetRadius = GetUnitModelRadius(target);
        float dis = Vector3.Distance(attacker.Position, target.Position);
        float realDis = dis - targetRadius;
        //两单位的距离 < 两单位半径之和,说明在其中一个单位的半径包围框内
        if (realDis <= 0)
            return true;
        if (realDis <= distance)
            return true;
        return false;
    }

    /// <summary>
    /// 获取单位模型半径
    /// </summary>
    /// <param name="unit"></param>
    public float GetUnitModelRadius(Unit unit)
    {
        float radius = 0;
        if (unit == null)
            return 0;
        if (unit.ActionStatus != null)
        {
            radius = unit.ActionStatus.Bounding.z * 0.5f;
            return radius;
        }
        if (unit.Collider != null)
        {
            radius = unit.Collider.bounds.size.z * 0.5f;
            return radius;
        }
        return radius;
    }

    /// <summary>
    /// 获取视野距离
    /// </summary>
    /// <param name="finder">获取者</param>
    /// <returns></returns>
    public float GetViewDis(Unit finder)
    {
        if (finder == null)
            return 0;
        if (TaskTarHelper.instance.IsSelectRole())
            return 200;
        UnitType actorType = UnitHelper.instance.GetUnitType(finder.TypeId);
        if(actorType == UnitType.Role)
        {
            SceneInfo sceneInfo = GameSceneManager.instance.SceneInfo;
            if (sceneInfo != null && sceneInfo.sceneView > 0)
            {
                return sceneInfo.sceneView * 0.01f;
            }
            RoleAtt roleAtt = RoleAttManager.instance.Find(finder.TypeId);
            if (roleAtt == null)
                return 0;
            return roleAtt.viewDistance * 0.01f;
        }
        else if(actorType == UnitType.Monster)
        {
            MonsterAtt monsterAtt = MonsterAttManager.instance.Find(finder.TypeId);
            if (monsterAtt == null)
                return 0;
            return monsterAtt.viewDistance * 0.01f;
        }
        //其他的给默认,现在主要单机用到
        return 7f;
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 判断是否可被攻击
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    private bool CanHit(Unit attacker, Unit target, AttackDefData attackDefData)
    {
        UnitType unitType = target.mUnitAttInfo.UnitType;
        if (unitType == UnitType.Summon || unitType == UnitType.VirtualSummon)
            return false;

        if (attacker == null)
            return true;

        RaceType type = (RaceType)attackDefData.Race;
        if (!ComparieCampByRaceType(attacker, target, type))
            return false;
        
        if (target.ActionStatus == null) return false;
        // 如果攻击高度不符合要求，停止击中判定
        if ((attackDefData.HeightStatusHitMask & (1 << target.ActionStatus.ActiveAction.HeightStatus)) == 0)
            return false;

        // 如果当前动作不接受受伤攻击，停止击中判定。
        if (!target.ActionStatus.ActiveAction.CanHurt)
            return false;
        return true;
    }

    /// <summary>
    /// 是否增益技能
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <param name="type"></param>
    /// <returns></returns>
    public bool IsGainSk(Unit attacker, Unit target, RaceType type)
    {
        if (attacker == null)
            return false;
        if (target == null)
            return false;

        if (type == RaceType.Self)//自身
        {
            if (attacker == target)
                return true;
        }
        else if (type == RaceType.Friend)//友方
        {
            if (attacker == target)
                return false;
            if (attacker.Camp == target.Camp)
                return true;
        }
        else if (type == RaceType.Enemy)//敌方
            return false;
        return false;
    }

    /// <summary>
    /// 根据类型比较阵营
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <param name="type"></param>
    /// <returns></returns>
    public bool ComparieCampByRaceType(Unit attacker, Unit target, RaceType type)
    {
        if (attacker == null)
            return false;
        if (target == null)
            return false;

        if (type == RaceType.Self)//自身
        {
            if (attacker != target)
                return false;
        }
        else if (type == RaceType.Friend)//友方
        {
            if (attacker == target)
                return false;
            if (attacker.Camp != target.Camp)
                return false;
        }
        else if (type == RaceType.Enemy)//敌方
        {
            if (attacker == target)
                return false;
            if (attacker.Camp == target.Camp)
                return false;
        }
        return true;
    }

    /// <summary>
    /// 比较击中条件
    /// </summary>
    /// <param name="fightType"></param>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool CompaireHitCondiction(Unit attacker, Unit target)
    {
        bool isNull = UnitHelper.instance.UnitIsNull(attacker);
        if (isNull == true)
            return false;
        isNull = UnitHelper.instance.UnitIsNull(target);
        if (isNull == true)
            return false;
        if (attacker == target)
            return false;
        FightModMgr fmMgr = FightModMgr.instance;
        FightModBase fmBase = fmMgr.GetFightMod(attacker);
        if (fmBase == null)
            return false;
        return fmBase.StfCdt(attacker, target);
    }

    /// <summary>
    /// 不能攻击单位类型
    /// </summary>
    /// <param name="unitType"></param>
    /// <returns></returns>
    public bool CannotHitUnitType(UnitType unitType)
    {
        if (unitType == UnitType.Role)
            return true;
        if (unitType == UnitType.Boss)
            return true;
        if (unitType == UnitType.Monster)
            return true;
        return false;
    }

    /// <summary>
    /// 比较阵营
    /// </summary>
    /// <param name="attacker"></param>
    /// <param name="target"></param>
    /// <param name="camp"></param>
    /// <returns></returns>
    public bool CompaireCamp(Unit attacker, Unit target, UnitCamp camp)
    {
        if (attacker == null)
            return false;
        if (target == null)
            return false;
        if (target.Camp == CampType.CampType5)
            return false;
        if (camp == UnitCamp.Friend)
        {
            if (attacker.Camp != target.Camp)
                return false;
        }
        else if(camp == UnitCamp.Enemy)
        {
            if (attacker.Camp == target.Camp)
                return false;
        }
        return true;
    }

    /// <summary>
    /// 检查是否击中目标
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool CheckHitTarget(Unit attacker, Unit target, AttackDefData attackDefData)
    {
        ResetAttackFram(attacker, attackDefData);
        ActionStatus targetActionStatus = target.ActionStatus;
        ActionData targetAction = targetActionStatus.ActiveAction;

        float BoundOffsetX = targetAction.CollisionOffsetX;
        float BoundOffsetY = targetAction.CollisionOffsetY;
        float BoundOffsetZ = targetAction.CollisionOffsetZ;

        if (!targetAction.UseCommonBound)
        {
            BoundOffsetX = targetAction.BoundingOffsetX;
            BoundOffsetY = targetAction.BoundingOffsetY;
            BoundOffsetZ = targetAction.BoundingOffsetZ;
        }

        Vector3 attackFramePos = attacker.Position;
        Vector3 offset = Vector3.zero;
        if (attackDefData.PathList.Count == 1)
            Utility.Vector3_Copy(attackDefData.PathList[0].Pos, ref offset);
        float x = offset.x, z = offset.z;
        Utility.Rotate(ref x, ref z, attacker.Orientation);
        offset.x = x;
        offset.z = z;
        attackFramePos += (offset * 0.01f);

        float orientation = target.Orientation;
        Utility.Rotate(ref BoundOffsetX, ref BoundOffsetZ, orientation);

        Vector3 targetPos = target.Position;
        Vector3 attackeePos = targetPos + new Vector3(BoundOffsetX, BoundOffsetY, BoundOffsetZ) * 0.01f;

        bool hitSuccess = false;
        switch ((ActionCommon.HitDefnitionFramType)attackDefData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    Vector3 vBounding = targetActionStatus.Bounding;
                    if (Utility.RectangleHitDefineCollision(
                         attackFramePos, attacker.Orientation,
                         mCubeHitDefSize,
                         attackeePos, orientation,
                         vBounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.CylinderType:
                {
                    // 圆柱求交
                    if (Utility.CylinderHitDefineCollision(
                        attackFramePos, attacker.Orientation,
                        mCylinderSize.x, mCylinderSize.y,
                        attackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    if (Utility.RingHitDefineCollision(
                        attackFramePos, attacker.Orientation,
                        mRingSize.x, mRingSize.y, mRingSize.z,
                        attackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    if (Utility.FanHitDefineCollision(
                        attackFramePos, attacker.Orientation,
                        mFanSize.x, mFanSize.y,
                        mFanAngle.x, mFanAngle.y,
                        attackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
        }
        return hitSuccess;
    }

    /// <summary>
    /// 重置攻击框
    /// </summary>
    protected virtual void ResetAttackFram(Unit attacker, AttackDefData attackDefData)
    {
        switch ((ActionCommon.HitDefnitionFramType)attackDefData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
                {
                    Utility.Vector3_Copy(attackDefData.FrameSize, ref mCubeHitDefSize);
                    mCubeHitDefSize = Vector3.Scale(mCubeHitDefSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.CylinderType:
                {
                    Utility.Vector3_Copy(attackDefData.FrameSize, ref mCylinderSize);
                    mCylinderSize = Vector3.Scale(mCylinderSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    Utility.Vector3_Copy(attackDefData.FrameSize, ref mRingSize);
                    mRingSize = Vector3.Scale(mRingSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    mCubeHitDefSize = attacker.ActionStatus.Bounding;
                }
                break;
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    Utility.Vector3_Copy(attackDefData.FrameSize, ref mFanSize);
                    mFanSize = Vector3.Scale(mFanSize, mFrameFactor) * 0.01f;

                    mFanAngle.x = attackDefData.FrameSize.Vector3Data_Z;
                    mFanAngle.y = attackDefData.FrameFinalFactor.Vector3Data_X;
                }
                break;
        }
    }

    /// <summary>
    /// 是否可攻击安全区怪物
    /// </summary>
    /// <returns></returns>
    public bool CanHitSafeMons(Unit target)
    {
        if (target == null)
            return false;
        if (!MapPathMgr.instance.IsSaveZone(target.Position))
            return true;
        UnitType type = UnitHelper.instance.GetUnitType(target.TypeId);
        if (type != UnitType.Monster)
            return false;
        SceneInfo info = GameSceneManager.instance.SceneInfo;
        if (info == null)
            return false;
        if (info.canHitSafeMons == 1)
            return true;
        return false;
    }
    #endregion
}
