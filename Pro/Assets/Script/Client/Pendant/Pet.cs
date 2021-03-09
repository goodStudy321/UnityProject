using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class Pet : PendantBase
{
    #region 私有字段
    /// <summary>
    /// 跟随距离
    /// </summary>
    private float mFollowDistance = 3f;
    /// <summary>
    /// 跟随距离平方
    /// </summary>
    private float mFollowDistanceSqr = 9f;
    /// <summary>
    /// 移动到角色的距离
    /// </summary>
    private float mMoveToDistanceSqr = 3f;
    /// <summary>
    /// 是否在跟随中
    /// </summary>
    private bool bFollowing = false;
    /// <summary>
    /// 帧率
    /// </summary>
    private int mFrame = 8;
    /// <summary>
    /// 自由行走计时器
    /// </summary>
    private Timer mFreedomWalkTimers;
    /// <summary>
    /// 计时结束
    /// </summary>
    private bool mTimeOut = false;
    /// <summary>
    /// 当前目标
    /// </summary>
    private Unit mCurTarget = null;
    /// <summary>
    /// 目标列表
    /// </summary>
    private List<Unit> mTargetList = new List<Unit>();
    /// <summary>
    /// 当前自由移动点
    /// </summary>
    private Vector3 mCurFreedomPoint = Vector3.zero;
    #endregion

    #region 属性
    /// <summary>
    /// 目标列表
    /// </summary>
    public List<Unit> TargetList
    {
        get { return mTargetList; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        PetInfo petInfo = PetInfoManager.instance.Find(mBaseId);
        if (petInfo == null)
            return null;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit pet = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, petInfo.name, BackPos, angle, mtpParent.Camp, (unit) =>
              {
                  mOwner = unit;
                  unit.MoveSpeed = mtpParent.MoveSpeed;
                  if(UnitHelper.instance.IsOwner(mtpParent))
                      UnitMgr.instance.SetUnitAllAssetsPersist(unit);
                  UnitMgr.instance.AddSkill(unit);
                  InitPetData();
                  SetShowState(PendantSystemEnum.Pet);
                  Assemble();
                  if (mtpParent.UnitUID != User.instance.MapData.UID)
                      return;
                  AddSkills(User.instance.MapData.PetSkillInfoList);
              });
        mOwner = pet;
        pet.mPendant = this;
        mtpParent.AddChildUnit(pet);
        mtpParent.Pet = pet;
        UnitShadowMgr.instance.SetShadow(pet);
        return pet;
    }

    public override void TakeOff(ActorData data)
    {
        base.TakeOff(data);
        UnAssemble();
    }

    /// <summary>
    /// 更新
    /// </summary>
    public override void Update()
    {
        if (!PreCondition(PendantSystemEnum.Pet))
            return;
        if (CheckSkillState())
        {
            if (mCurTarget != null && mCurTarget.UnitTrans != null)
            {
                Vector3 forward = GetForward(mOwner.Position, mCurTarget.Position);
                ExecuteRotation(forward);
            }
                return;
        }
        if (PlaySkill())
            return;
        Follow();
        if (bFollowing)
            return;
        FreedomMove();
    }
    #endregion

    #region 私有变量
    /// <summary>
    /// 初始化宠物数据
    /// </summary>
    private void InitPetData()
    {
        SetFreedomWalkTime();
        SetFreedomMovePoints();
        SetFightType();
    }

    /// <summary>
    /// 检查技能状态
    /// </summary>
    /// <returns></returns>
    private bool CheckSkillState()
    {
        if (mOwner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Attack)
            return true;
        if (mOwner.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Skill)
            return true;
        return false;
    }

    /// <summary>
    /// 施放技能
    /// </summary>
    /// <returns></returns>
    private bool PlaySkill()
    {
        if (mMtpParent.UnitUID != User.instance.MapData.UID)
            return false;
        if (bFollowing)
            return false;
        GameSkill skill = SkillHelper.instance.GetCanPlaySkill(mOwner);
        if (skill == null)
            return false;
        string actionID = SkillHelper.instance.GetItrptActID(mOwner, skill);
        if (string.IsNullOrEmpty(actionID))
            return false;
        float skillDis = skill.SkillLevelAttrTable.maxDistance * 0.01f;
        mCurTarget = FightModMgr.instance.LockSatify(mOwner, skillDis);
        if (mCurTarget == null || mCurTarget.Dead)
            return false;
        if (PlayAndSendSkill(actionID, skill))
            return true;
        return false;
    }

    /// <summary>
    /// 释放及发送技能
    /// </summary>
    /// <param name="actionID"></param>
    /// <param name="skill"></param>
    private bool PlayAndSendSkill(string actionID,GameSkill skill)
    {
        if (mCurTarget != null && mCurTarget.UnitTrans != null)
        {
            Vector3 forward = GetForward(mOwner.Position, mCurTarget.Position);
            mOwner.SetOrientation(Mathf.Atan2(forward.x,forward.z));
            mOwner.ActionStatus.FTtarget = mCurTarget;
        }
        if (!mOwner.ActionStatus.ChangeAction(actionID, 0))
            return false;
        mOwner.ActionStatus.SetSkill(skill.SkillLevelID,skill.AddTarNum);
        if (Global.Mode == PlayMode.Local)
            return false;
        int actionId = int.Parse(actionID.Remove(0, 1));
        NetSkill.RequestPrepareSkill(mOwner, skill.SkillLevelID, actionId);
        ResetFreedomMove();
        return true;
    }
    
    /// <summary>
    /// 跟随
    /// </summary>
    private void Follow()
    {
        Vector3 followPos = mMtpParent.Position;
        if (bFollowing)
        {
            if (!mTimeOut)
            {
                if (mFreedomWalkTimers.Running)
                    ResetFreedomMove(false);
            }
            Vector3 moveForward = GetForward(mOwner.Position, followPos);
            ExecuteRotation(moveForward);
            ExecuteMove(moveForward,followPos);
            if (!FrameCountDone())
                return;
            if (!InFollowDistance(followPos, mMoveToDistanceSqr))
                return;
            bFollowing = false;
            ResetFreedomMove();
            mOwner.ActionStatus.ChangeIdleAction();
        }
        else
        {
            if (!FrameCountDone())
                return;
            if (!InFollowDistance(followPos, mFollowDistanceSqr))
                bFollowing = true;
        }
    }

    /// <summary>
    /// 自由移动
    /// </summary>
    private void FreedomMove()
    {
        if (!mTimeOut) return;
        MoveNextPoint();
    }

    /// <summary>
    /// 向下一点移动
    /// </summary>
    private void MoveNextPoint()
    {
        Vector3 pos = GetFreedomMovePos();
        Vector3 moveForward = GetForward(mOwner.Position, pos);
        if (moveForward == Vector3.zero)
        {
            ResetFreedomMove();
            mOwner.ActionStatus.ChangeIdleAction();
            return;
        }
        Vector3 desPos = mOwner.Position + moveForward * mOwner.MoveSpeed * Time.deltaTime;
        Vector3 nextForward = GetForward(pos, desPos);
        if(Vector3.Dot(moveForward, nextForward) > 0)
        {
            mOwner.Position = pos;
            ResetFreedomMove();
            mOwner.ActionStatus.ChangeIdleAction();
        }
        else
        {
            ExecuteRotation(moveForward);
            ExecuteMove(moveForward, pos, true);
        }
    }

    /// <summary>
    /// 重置自由移动
    /// </summary>
    private void ResetFreedomMove(bool bRestart = true)
    {
        mFreedomWalkTimers.Reset();
        if (bRestart)
            mFreedomWalkTimers.Start();
        else
            mFreedomWalkTimers.Pause();
        ResetFreedomParams();
    }

    /// <summary>
    /// 重置自由移动参数
    /// </summary>
    private void ResetFreedomParams()
    {
        mCurFreedomPoint = Vector3.zero;
        mTimeOut = false;
    }
    
    /// <summary>
    /// 设置自由移动点
    /// </summary>
    private void SetFreedomMovePoints()
    {
        float moveDis = mFollowDistance - 1;
        mMovePosList.Add(new Vector3(0, 0, moveDis));
        mMovePosList.Add(new Vector3(0, 0, -moveDis));
        mMovePosList.Add(new Vector3(moveDis, 0, 0));
        mMovePosList.Add(new Vector3(-moveDis, 0, 0));
    }

    /// <summary>
    /// 获取自由移动位置
    /// </summary>
    private Vector3 GetFreedomMovePos()
    {
        if (mCurFreedomPoint != Vector3.zero)
            return mCurFreedomPoint;
        if (mMtpParent == null)
            return Vector3.zero;
        if (mMtpParent.UnitTrans == null)
            return Vector3.zero;
        int index = GetMoveIndex();
        Vector3 delPos = mMovePosList[index];
        mCurFreedomPoint = mMtpParent.UnitTrans.TransformPoint(delPos);
        RaycastHit hit;
        Vector3 orgin = mCurFreedomPoint + new Vector3(0, 0.5f, 0);
        Ray rayObsta = new Ray(orgin, Vector3.down);
        if (Physics.Raycast(rayObsta, out hit, 20, 1 << LayerTool.Ground))
        {
            mCurFreedomPoint.y = hit.point.y;
        }
        return mCurFreedomPoint;
    }

    /// <summary>
    /// 设置自由移动时间
    /// </summary>
    private void SetFreedomWalkTime()
    {
        if (mFreedomWalkTimers == null)
            mFreedomWalkTimers = ObjPool.Instance.Get<Timer>();
        if (mFreedomWalkTimers.Running)
            return;
        mTimeOut = false;
        mFreedomWalkTimers.Seconds = 10f;
        mFreedomWalkTimers.complete += FreedomWalkTimeOut;
        mFreedomWalkTimers.Start();
    }

    /// <summary>
    /// 自由移动计时结束
    /// </summary>
    private void FreedomWalkTimeOut()
    {
        mTimeOut = true;
    }
    
    /// <summary>
    /// 帧率判断
    /// </summary>
    /// <returns></returns>
    private bool FrameCountDone()
    {
        if (mFrame > 0)
        {
            mFrame--;
            return false;
        }
        mFrame = 8;
        return true;
    }

    /// <summary>
    /// 执行移动
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteMove(Vector3 forward, Vector3 fwPos, bool bFreeMove = false)
    {
        if (mOwner.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Move)
            if (!mOwner.ActionStatus.CheckInterrupt("N0020"))
                return;
        float moveSpeed = mOwner.MoveSpeed;
        Vector3 delPos = forward * moveSpeed * Time.deltaTime;
        if(bFreeMove)
        {
            RaycastHit hit;
            Vector3 orgin = mOwner.Position + new Vector3(0, 0.5f, 0);
            Ray rayObsta = new Ray(orgin, forward);
            float lengths = delPos.magnitude;
            lengths += mOwner.ActionStatus.Bounding.z;
            if (Physics.Raycast(rayObsta, out hit, delPos.magnitude, 1 << LayerTool.Wall))
            {
                ResetFreedomMove();
                mOwner.ActionStatus.ChangeIdleAction();
                return;
            }
        }
        Vector3 desPos = mOwner.Position + delPos;
        Vector3 fwd = GetForward(desPos, fwPos);
        if (Vector3.Dot(forward, fwd) < 0)
        {
            mOwner.ActionStatus.ChangeIdleAction();
            return;
        }
        mOwner.Position = desPos;
        mOwner.ActionStatus.ChangeMoveAction();
    }
    
    /// <summary>
    /// 执行旋转
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteRotation(Vector3 forward)
    {
        float fowardSqr = Vector3.SqrMagnitude(mOwner.UnitTrans.forward - forward);
        if (fowardSqr < 0.01f)
            return;
        float rotateSpeed = mOwner.ActionStatus.ActiveAction.RotateSpeed;
        mOwner.SetOrientation(Mathf.Atan2(forward.x, forward.z), rotateSpeed);
    }

    /// <summary>
    /// 组装
    /// </summary>
    private void Assemble()
    {
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        PetMount petMount = mMtpParent.mPetMount;
        if (petMount == null)
            return;
        petMount.Assemble(mOwner);
    }

    /// <summary>
    /// 拆装
    /// </summary>
    private void UnAssemble()
    {
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        PetMount petMount = mMtpParent.mPetMount;
        if (petMount == null)
            return;
        petMount.UnAssemble();
    }
    #endregion
}
