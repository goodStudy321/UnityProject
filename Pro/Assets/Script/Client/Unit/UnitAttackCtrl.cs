using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitAttackCtrl 
{
    public static readonly UnitAttackCtrl instance = new UnitAttackCtrl();

    private UnitAttackCtrl()
    {
        //mTimer = ObjPool.Instance.Get<Timer>();
    }
    #region 私有变量
    /// <summary>
    /// 攻击者
    /// </summary>
    private Unit mAttacker;
    /// <summary>
    /// 目标者
    /// </summary>
    private Unit mTarget;
    /// <summary>
    /// 技能
    /// </summary>
    private GameSkill mSkill;
    /// <summary>
    /// 动作ID
    /// </summary>
    private string mActionID;
    /// <summary>
    /// 技能距离
    /// </summary>
    private float mSkillDis = 0;
    /// <summary>
    /// 是否在执行中
    /// </summary>
    private bool isExecuting = false;
    /// <summary>
    /// 是否开始移动
    /// </summary>
    private bool isBeginMoving = false;
    /// <summary>
    /// 是否开始冲刺
    /// </summary>
    private bool isBeginRushing = false;
    /// <summary>
    /// 冲刺距离
    /// </summary>
    private float mMaxRushDis = 7f;
    /// <summary>
    /// 移动最小平方距离
    /// </summary>
    private float mWalkMinSqrDis;
    /// <summary>
    /// 冲刺目标点
    /// </summary>
    private Vector3 mRushDesPos = Vector3.zero;
    /// <summary>
    /// 冲刺速度
    /// </summary>
    private float mRushSpeed = 0;
    ///// <summary>
    ///// 是否自动释放
    ///// </summary>
    //private bool isAutoPlay = false;
    ///// <summary>
    ///// 技能延迟计时
    ///// </summary>
    //private Timer mTimer = null;
    #endregion

    #region 属性
    ///// <summary>
    ///// 延迟计时器
    ///// </summary>
    //public Timer DelayTimer
    //{
    //    get { return mTimer; }
    //}
    #endregion

    #region 私有方法
    /// <summary>
    /// 清除所有移动状态
    /// </summary>
    private void ClearMovingState()
    {
        isExecuting = false;
        //EndMove();
        EndRush();
        UnitAutoFight.instance.IsMoving = false;
    }

    /// <summary>
    /// 冲刺和旋转
    /// </summary>
    private bool RushAndRotate()
    {
        if (!isBeginRushing)
            return false;
        Vector3 rushForward = GetRushForward();
        Rotate(rushForward.normalized);

        float speed = mRushSpeed * Time.deltaTime;
        Vector3 rushDelta = rushForward.normalized * speed;
        if(ChkHit(rushForward,rushDelta))
        {
            EndRush();
            mAttacker.ActionStatus.ChangeIdleAction();
            return true;
        }
        Vector3 nxtPos = mAttacker.Position + rushDelta;
        if (ChkNxtRshPos(nxtPos, rushForward))
        {
            EndRush();
            NetMove.RequestMoveRush(mAttacker, mRushDesPos, rushForward);
            mAttacker.Position = mRushDesPos;
            mAttacker.ActionStatus.ChangeIdleAction();
            return true;
        }
        NetMove.RequestMoveRush(mAttacker, nxtPos, rushForward);
        mAttacker.ActionStatus.ChangeMoveAction();
        mAttacker.Position = nxtPos;
        return true;
    }

    /// <summary>
    /// 旋转
    /// </summary>
    /// <param name="rshFwd">旋转方向</param>
    private void Rotate(Vector3 rshFwd)
    {
        float fowardSqr = Vector3.SqrMagnitude(mAttacker.UnitTrans.forward - rshFwd);
        if (fowardSqr < 0.01f)
            return;
        mAttacker.SetOrientation(Mathf.Atan2(rshFwd.x, rshFwd.z), 40);
    }

    /// <summary>
    /// 检查碰撞
    /// </summary>
    /// <param name="rshFwd">冲刺方向</param>
    /// <param name="rshDelta">冲刺距离</param>
    /// <returns></returns>
    private bool ChkHit(Vector3 rshFwd,Vector3 rshDelta)
    {
        RaycastHit hit;
        Vector3 origin = mAttacker.Position + new Vector3(0, 0.5f, 0);
        Ray rayObsta = new Ray(origin, rshFwd);
        float rayDis = rshDelta.magnitude + mAttacker.ActionStatus.Bounding.z;
        if (!Physics.Raycast(rayObsta, out hit, rayDis, (1 << LayerTool.Wall) | (1 << LayerTool.Unit) | (1 << LayerTool.NPC)))
            return false;
        if (hit.collider.gameObject.layer != LayerTool.Wall &&
            hit.collider.gameObject.tag != TagTool.ObstacleUnit)
            return false;
        return true;
    }

    /// <summary>
    /// 检查冲刺点
    /// </summary>
    /// <param name="nxtPos">下一冲刺位置</param>
    /// <param name="rshFwd">冲刺方向</param>
    /// <returns></returns>
    private bool ChkNxtRshPos(Vector3 nxtPos,Vector3 rshFwd)
    {
        Vector3 forward = mRushDesPos - nxtPos;
        forward.y = 0;
        float dot = Vector3.Dot(rshFwd, forward);
        if (dot > 0)
            return false;
        return true;
    }

    /// <summary>
    /// 获取冲刺方向
    /// </summary>
    /// <returns></returns>
    private Vector3 GetRushForward()
    {
        if (mAttacker == null)
            return Vector3.zero;
        if (mAttacker.UnitTrans == null)
            return Vector3.zero;
        if (mTarget == null)
            return mAttacker.UnitTrans.forward;
        Vector3 forward = mTarget.Position - mAttacker.Position;
        forward.y = 0;
        return forward;
    }

    ///// <summary>
    ///// 重置时间
    ///// </summary>
    //private void ReSetTime()
    //{
    //    if (mTimer == null)
    //        return;
    //    if (!isAutoPlay)
    //    {
    //        mTimer.Stop();
    //        return;
    //    }
    //    if (mSkill == null)
    //        return;
    //    if (mAttacker.ActionStatus == null)
    //        return;
    //    ProtoBuf.ActionData actionData = ActionHelper.GetActionByID(mAttacker.ActionStatus.ActionGroupData, mActionID);
    //    if (actionData == null)
    //        return;
    //    float actionTime = actionData.AnimTime * 0.001f;
    //    mTimer.Seconds = actionTime + 0.2f;
    //    mTimer.Start();
    //}

    /// <summary>
    /// 寻路完成
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="PRType"></param>
    private void NavCom(Unit unit, AsPathfinding.PathResultType PRType)
    {
        UnitHelper.instance.ResetUnitData(unit);
        EndMove();
    }

    /// <summary>
    /// 设置冲刺信息
    /// </summary>
    /// <param name="rshfwd">冲刺反方向</param>
    private void SetRushInfo(Vector3 rshfwd)
    {
        mRushSpeed = MoveSpeed.instance.MoveDic[MoveType.Rush];
        float dis = mSkillDis - 1 + SkillHelper.instance.GetUnitModelRadius(mTarget);
        Vector3 delpos = dis * rshfwd;
        mRushDesPos = mTarget.Position + delpos;
    }

    /// <summary>
    /// 开始冲刺
    /// </summary>
    /// <returns></returns>
    private bool BegRush()
    {
        Vector3 rushForward = GetRushForward();
        if (ChkHit(rushForward.normalized, rushForward))
            return false;
        float sqrDis = Vector3.SqrMagnitude(rushForward);
        if (sqrDis > mWalkMinSqrDis)
            return false;
        //EndMove();
        bool isDis = SkillHelper.instance.IsInDistance(mAttacker, mTarget, mSkillDis);
        if (isDis)
            return false;
        isBeginRushing = true;
        RushEffect.instance.ShowEffect(mAttacker);
        SetRushInfo(-rushForward.normalized);
        mAttacker.mUnitMove.StopNav(false);
        AutoMountMgr.instance.StopTimer(mAttacker);
        NavMoveBuff.instance.StopMoveBuff(mAttacker);
        PendantMgr.instance.TakeOffMount(mAttacker);
        mAttacker.ActionStatus.ChangeMoveAction();
        return true;
    }

    /// <summary>
    /// 结束冲刺
    /// </summary>
    private void EndRush()
    {
        isBeginRushing = false;
        RushEffect.instance.HideEffect();
    }

    /// <summary>
    /// 开始移动
    /// </summary>
    private void BegMove()
    {
        if (isBeginMoving)
            return;
        isBeginMoving = true;
        Unit unit = InputVectorMove.instance.MoveUnit;
        unit.mUnitMove.StartNav(mTarget.Position, -1f, 0, NavCom, false);
    }

    /// <summary>
    /// 结束移动
    /// </summary>
    private void EndMove()
    {
        isBeginMoving = false;
    }

    /// <summary>
    /// 施放技能
    /// </summary>
    /// <returns></returns>
    private bool PlaySkill()
    {
        bool isDistance = SkillHelper.instance.IsInDistance(mAttacker, mTarget, mSkillDis);
        if (!isDistance)
            return false;
        //ReSetTime();
        //EndMove();
        EndRush();
        UISkill.instance.PlayAndSendSkill(mAttacker, mTarget, mActionID, mSkill);
        return true;
    }

    /// <summary>
    /// 重新检查单位有效性
    /// </summary>
    /// <returns></returns>
    private bool ReChkTarEftv()
    {
        if (mTarget != null && !mTarget.Dead)
        {
            if (SkillHelper.instance.CanHitSafeMons(mTarget))
                return true;
        }
        mAttacker.mUnitMove.StopNav();
        AutoMountMgr.instance.StopTimer(mAttacker);
        NavMoveBuff.instance.StopMoveBuff(mAttacker);
        if (mAttacker.ActionStatus != null)
            mAttacker.ActionStatus.ChangeIdleAction();
        Clear();
        return false;
    }

    /// <summary>
    /// 检查行为条件
    /// </summary>
    /// <returns></returns>
    private bool ChkActCon()
    {
        if (!isExecuting)
            return false;
        if (mAttacker == null)
            return false;
        if (mSkill == null)
            return false;
        if (mAttacker.mUnitMove == null)
            return false;
        if (mAttacker.mUnitMove.IsJumping)
            return false;
        return true;
    }
    #endregion

    #region 公有方法
    public void BeginAttackCtrl(Unit attacker, Unit target, GameSkill skill, string actionID, bool autoPlay)
    {
        mAttacker = attacker;
        mTarget = target;
        //isAutoPlay = autoPlay;
        mSkill = skill;
        if (mSkill == null)
            return;
        if (mSkill.SkillLevelAttrTable == null)
            return;
        mActionID = actionID;
        mSkillDis = mSkill.SkillLevelAttrTable.maxDistance * 0.01f;
        float walkMinDis = mSkillDis + mMaxRushDis;
        walkMinDis *= walkMinDis;
        mWalkMinSqrDis = walkMinDis;
        isExecuting = true;
        //EndMove();
        EndRush();
    }

    /// <summary>
    /// 清除
    /// </summary>
    public void Clear()
    {
        //HideEffect();
        if (!isExecuting)
            return;
        mAttacker = null;
        mTarget = null;
        mSkill = null;
        mActionID = null;
        mSkillDis = 0;
        mWalkMinSqrDis = 0;
        mRushDesPos = Vector3.zero;
        mRushSpeed = 0;
        ClearMovingState();
    }

    /// <summary>
    /// 更新普通攻击行为
    /// </summary>
    public void UpdateAttackAction()
    {
        if (!ChkActCon())
            return;
        if (!ReChkTarEftv())
            return;
        if (PlaySkill())
            return;
        if (!UnitHelper.instance.CanMove(mAttacker))
            return;
        if (RushAndRotate())
            return;
        if (BegRush())
            return;
        BegMove();
    }
    #endregion
}
