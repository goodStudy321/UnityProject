using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class MagicWeapon : PendantBase
{
    #region 私有字段
    /// <summary>
    /// 跟随距离
    /// </summary>
    private float mFollowDistance = 1f;
    /// <summary>
    /// 跟随距离平方
    /// </summary>
    private float mFollowDistanceSqr = 1f;
    /// <summary>
    /// 移动到角色的距离
    /// </summary>
    private float mMoveToDistanceSqr = 1f;
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
    /// 当前自由移动点
    /// </summary>
    private Vector3 mCurFreedomPoint = Vector3.zero;
    /// <summary>
    /// 显示模型
    /// </summary>
    private Transform mModel = null;
    #endregion

    #region 属性
    public float DeltaY
    {
        get
        {
            if (mMtpParent == null)
                return 0;
            Transform head = mMtpParent.mUnitBoneInfo.BoneHead;
            if (head == null)
                return 0;
            return head.position.y;
        }
    }
    /// <summary>
    /// 法宝相对出生位置
    /// </summary>
    public Vector3 MwBornPos
    {
        get
        {
            Vector3 pos = mMtpParent.Position + mMtpParent.UnitTrans.forward * (-1f);
            pos.y = DeltaY;
            return pos;
        }
    }
    #endregion

    #region 保护方法
    protected override bool PreCondition(PendantSystemEnum pdsEnum)
    {
        if (mMtpParent == null)
            return false;
        if (mMtpParent.UnitTrans == null)
            return false;
        if (mOwner == null)
            return false;
        if (mOwner.UnitTrans == null)
            return false;
        if (mMtpParent.Dead)
        {
            UnitMgr.instance.SetUnitActive(mOwner, false);
            return false;
        }
        if (mOwner.ActionStatus == null)
            return false;
        return true;
    }
    #endregion

    #region 公有方法
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        mBaseId = unitTypeId / 1000;
        MagicWeaponInfo mwInfo = MagicWeaponInfoManager.instance.Find(mBaseId);
        if (mwInfo == null)
            return null;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit magicweapon = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, mwInfo.name, MwBornPos, angle, mtpParent.Camp, (unit) =>
        {
            mOwner = unit;
            unit.MoveSpeed = mtpParent.MoveSpeed;
            if (UnitHelper.instance.IsOwner(mtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(unit);
            UnitMgr.instance.AddSkill(unit);
            InitMagicWeaponData();
            CloneModel();
            SetShowState(PendantSystemEnum.MagicWeapon);
            if (mtpParent.UnitUID != User.instance.MapData.UID)
                return;
            AddSkills(User.instance.MapData.MgwpSkillInfoList);
        });
        mOwner = magicweapon;
        magicweapon.mPendant = this;
        mtpParent.AddChildUnit(magicweapon);
        mtpParent.MagicWeapon = magicweapon;
        return magicweapon;
    }

    /// <summary>
    /// 脱下
    /// </summary>
    public override void TakeOff(ActorData data)
    {
        base.TakeOff(data);
        if (mModel == null)
            return;
        GbjPool.Instance.Add(mModel.gameObject);
    }

    /// <summary>
    /// 设置法宝显示状态
    /// </summary>
    /// <param name="sEnum"></param>
    public override void SetShowState(PendantSystemEnum sEnum)
    {
        if (mMtpParent == null)
            return;
        if (mMtpParent.UnitTrans == null)
            return;
        if (mMtpParent.UnitTrans.gameObject.activeSelf)
            return;
        SetModelShowSate(false);
    }

    /// <summary>
    /// 设置模型显示状态
    /// </summary>
    /// <param name="isShow"></param>
    public void SetModelShowSate(bool isShow)
    {
        if (mModel == null)
            return;
        mModel.gameObject.SetActive(isShow);
    }

    /// <summary>
    /// 设置模型位置
    /// </summary>
    public void SetModelPosition(Vector3 pos)
    {
        mOwner.Position = pos;
        if (mModel == null)
            return;
        mModel.position = pos;
    }

    /// <summary>
    /// 更新
    /// </summary>
    public override void Update()
    {
        if (!PreCondition(PendantSystemEnum.MagicWeapon))
            return;
        PlaySkill();
        Follow();
        if (bFollowing)
            return;
        FreedomMove();
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置模型
    /// </summary>
    private void CloneModel()
    {
        if (mOwner.UnitTrans == null)
            return;
        mModel = GameObject.Instantiate<Transform>(mOwner.UnitTrans);
        SetModelPosition(mOwner.Position);
        SetModelActive(mOwner.UnitTrans, false);
        Object.DontDestroyOnLoad(mModel);
        if (mOwner.mUnitAttInfo.RoleBaseTable == null)
            return;
        mModel.name = mOwner.mUnitAttInfo.RoleBaseTable.modelPath;
    }

    /// <summary>
    /// 设置模型状态
    /// </summary>
    /// <param name="go"></param>
    /// <param name="bActive"></param>
    private void SetModelActive(Transform go, bool bActive)
    {
        int count = go.childCount;
        for (int i = 0; i < count; i++)
        {
            Transform trans = go.GetChild(i);
            if (trans == null)
                continue;
            trans.gameObject.SetActive(bActive);
        }
    }

    /// <summary>
    /// 初始化宠物数据
    /// </summary>
    private void InitMagicWeaponData()
    {
        SetFreedomWalkTime();
        SetFreedomMovePoints();
        SetFightType();
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
    /// 设置自由移动点
    /// </summary>
    private void SetFreedomMovePoints()
    {
        float moveDis = mFollowDistance - 1;
        mMovePosList.Add(new Vector3(0, 0, -moveDis));
        mMovePosList.Add(new Vector3(moveDis, 0, 0));
        mMovePosList.Add(new Vector3(-moveDis, 0, 0));
    }

    /// <summary>
    /// 自由移动计时结束
    /// </summary>
    private void FreedomWalkTimeOut()
    {
        mTimeOut = true;
    }

    /// <summary>
    /// 施放技能
    /// </summary>
    /// <returns></returns>
    private bool PlaySkill()
    {
        if (mMtpParent.UnitUID != User.instance.MapData.UID)
            return false;
        ActionStatus.EActionStatus ownerActionState = mOwner.ActionStatus.ActionState;
        if (ownerActionState == ActionStatus.EActionStatus.EAS_Attack)
            return true;
        if (ownerActionState == ActionStatus.EActionStatus.EAS_Skill)
            return true;
        ActionStatus.EActionStatus parentActionState = mMtpParent.ActionStatus.ActionState;
        if (parentActionState != ActionStatus.EActionStatus.EAS_Attack
            && parentActionState != ActionStatus.EActionStatus.EAS_Skill)
            return false;
        GameSkill skill = SkillHelper.instance.GetCanPlaySkill(mOwner);
        if (skill == null)
            return false;
        string actionID = SkillHelper.instance.GetItrptActID(mOwner, skill);
        if (string.IsNullOrEmpty(actionID))
            return false;
        mCurTarget = InputMgr.instance.mLockTarget;
        if (mCurTarget == null || mCurTarget.Dead)
            return false;
        if (PlayAndSendSkill(actionID, skill))
            return true;
        return false;
    }

    /// <summary>
    /// 跟随
    /// </summary>
    private void Follow()
    {
        Vector3 followPos = mMtpParent.Position;
        if (bFollowing)
        {
            if(!mTimeOut)
            {
                if(mFreedomWalkTimers.Running)
                    ResetFreedomMove(false);
            }
            Vector3 moveForward = GetForward(mOwner.Position, followPos);
            ExecuteRotation(moveForward);
            ExecuteMove(moveForward,followPos);
            UpdateHeight();
            if (!FrameCountDone())
                return;
            if (!InFollowDistance(followPos, mMoveToDistanceSqr))
                return;
            bFollowing = false;
            mOwner.ActionStatus.ChangeIdleAction();
            ResetFreedomMove();
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
    /// 更新高度
    /// </summary>
    private void UpdateHeight()
    {
        Vector3 pos = mOwner.Position;
        pos.y = DeltaY;
        Vector3 desPos = Vector3.Slerp(mOwner.Position, pos, Time.deltaTime * 5);
        SetModelPosition(desPos);
    }

    /// <summary>
    /// 执行移动
    /// </summary>
    /// <param name="forward"></param>
    private void ExecuteMove(Vector3 forward, Vector3 fwPos, bool bFreeMove = false)
    {
        float moveSpeed = mOwner.MoveSpeed;
        Vector3 delPos = forward * moveSpeed * Time.deltaTime;
        if (bFreeMove)
        {
            RaycastHit hit;
            Vector3 orgin = mOwner.Position + new Vector3(0, 0.5f, 0);
            Ray rayObsta = new Ray(orgin, forward);
            float lengths = delPos.magnitude;
            lengths += mOwner.ActionStatus.Bounding.z;
            if (Physics.Raycast(rayObsta, out hit, delPos.magnitude, 1 << LayerTool.Wall))
            {
                PlayAnimation("N0000");
                ResetFreedomMove();
                return;
            }
        }
        Vector3 desPos = mOwner.Position + delPos;
        Vector3 fwd = GetForward(desPos, fwPos);
        if (Vector3.Dot(forward, fwd) < 0)
            return;
        SetModelPosition(desPos);
        PlayAnimation("N0020");
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
        if (mOwner.ActionStatus.ActiveAction == null)
            return;
        float rotateSpeed = mOwner.ActionStatus.ActiveAction.RotateSpeed;
        mOwner.SetOrientation(Mathf.Atan2(forward.x, forward.z), rotateSpeed);
    }

    /// <summary>
    /// 播放动画
    /// </summary>
    /// <param name="animID"></param>
    private void PlayAnimation(string animID)
    {
        ActionStatus actionstatus = mOwner.ActionStatus;
        if (actionstatus == null)
            return;
        ProtoBuf.ActionData activeAction = actionstatus.ActiveAction;
        if (activeAction == null)
            return;
        if (actionstatus.ActionState == ActionStatus.EActionStatus.EAS_Attack)
            return;
        if (actionstatus.ActionState == ActionStatus.EActionStatus.EAS_Skill)
            return;
        if (actionstatus.ActionState == ActionStatus.EActionStatus.EAS_Move)
            return;
        if (actionstatus.ActionState == ActionStatus.EActionStatus.EAS_Idle)
            return;
        actionstatus.ChangeAction(animID, 0);
    }

    /// <summary>
    /// 释放及发送技能
    /// </summary>
    /// <param name="actionID"></param>
    /// <param name="skill"></param>
    private bool PlayAndSendSkill(string actionID, GameSkill skill)
    {
        if (mCurTarget != null && mCurTarget.UnitTrans != null)
        {
            Vector3 forward = GetForward(mOwner.Position, mCurTarget.Position);
            mOwner.SetOrientation(Mathf.Atan2(forward.x, forward.z));
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
            return;
        }
        UpdateHeight();
        Vector3 desPos = mOwner.Position + moveForward * mOwner.MoveSpeed * Time.deltaTime;
        Vector3 nextForward = GetForward(pos, desPos);
        if (Vector3.Dot(moveForward, nextForward) > 0)
        {
            SetModelPosition(pos);
            mOwner.ActionStatus.ChangeIdleAction();
            ResetFreedomMove();
        }
        else
        {
            ExecuteRotation(moveForward);
            ExecuteMove(moveForward, pos, true);
        }
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
        mCurFreedomPoint.y = DeltaY;
        return mCurFreedomPoint;
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
    #endregion
}
