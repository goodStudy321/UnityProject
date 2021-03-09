using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitOfflBat
{
    #region 私有变量
    /// <summary>
    /// 冲刺距离
    /// </summary>
    private float mMaxRushDis = 2f;
    #endregion

    #region 属性
    public Unit mUnit;
    #endregion

    #region 私有方法
    /// <summary>
    /// 检查单位条件
    /// </summary>
    /// <returns></returns>
    private bool CheckUnitCon()
    {
        if (mUnit == null)
            return false;
        if (mUnit.Dead)
            return false;
        if (mUnit.ActionStatus == null)
            return false;
        return true;
    }

    /// <summary>
    /// 检查动作状态
    /// </summary>
    /// <returns></returns>
    private bool CheckActionState()
    {
        ActionStatus.EActionStatus actionState = mUnit.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Idle)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Move)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return true;
        return false;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void Init(Unit unit)
    {
        if (Global.Mode != PlayMode.Local)
            Global.Mode = PlayMode.Local;
        mUnit = unit;
        //把单位设置成阵营模式
        mUnit.FightType = 4;
        if (unit.ActionStatus != null)
            unit.ActionStatus.ChangeIdleAction();
    }
    public void Update()
    {
        if (!CheckUnitCon())
            return;
        if (!CheckActionState())
            return;
        GameSkill skill = SkillHelper.instance.GetCanPlaySkill(mUnit);
        if (skill == null)
            return;
        if (skill.SkillLevelAttrTable == null)
            return;
        string actionID = SkillHelper.instance.GetItrptActID(mUnit, skill);
        if (string.IsNullOrEmpty(actionID))
            return;
        float skillDis = skill.SkillLevelAttrTable.maxDistance * 0.01f;
        float walkMinDis = skillDis + mMaxRushDis;
        float walkMinSqrDis = walkMinDis * walkMinDis;
        float distance = SkillHelper.instance.GetViewDis(mUnit);
        Unit target = FightModMgr.instance.GetTarget(mUnit, distance);
        if (target == null)
            return;
        bool inDis = SkillHelper.instance.IsInDistance(mUnit, target, skillDis);
        if(inDis)
        {
            SkillHelper.instance.SetLockTarget(mUnit,target);
            Vector3 forward = target.Position - mUnit.Position;
            mUnit.SetOrientation(Mathf.Atan2(forward.x, forward.z));
            mUnit.mUnitMove.StopNav(false);
            UnitAttackCtrl.instance.Clear();
            if (!mUnit.ActionStatus.ChangeAction(actionID, 0))
                return;
            mUnit.ActionStatus.SetSkill(skill.SkillLevelID,skill.AddTarNum);
            return;
        }
        if (!UnitHelper.instance.CanMove(mUnit))
            return;
        Vector3 rushForward = target.Position - mUnit.Position;
        float sqrDis = Vector3.SqrMagnitude(rushForward);
        if (sqrDis <= walkMinSqrDis)
        {
            mUnit.mUnitMove.StopNav(false);
            float fowardSqr = Vector3.SqrMagnitude(mUnit.UnitTrans.forward - rushForward);
            if (fowardSqr > 0.01f)
                mUnit.SetOrientation(Mathf.Atan2(rushForward.x, rushForward.z), 40);

            float rushSpeed = MoveSpeed.instance.MoveDic[MoveType.Rush];
            float speed = rushSpeed * Time.deltaTime;
            Vector3 pos = mUnit.Position + rushForward.normalized * speed;
            mUnit.Position = pos;
            return;
        }
        if (mUnit.mUnitMove.InPathFinding)
            return;
        mUnit.mUnitMove.StartNav(target.Position, -1f, 0, null, false);
    }
    #endregion
}
