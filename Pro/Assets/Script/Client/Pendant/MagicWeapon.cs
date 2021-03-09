using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class MagicWeapon : PendantBase
{
    #region ˽���ֶ�
    /// <summary>
    /// �������
    /// </summary>
    private float mFollowDistance = 1f;
    /// <summary>
    /// �������ƽ��
    /// </summary>
    private float mFollowDistanceSqr = 1f;
    /// <summary>
    /// �ƶ�����ɫ�ľ���
    /// </summary>
    private float mMoveToDistanceSqr = 1f;
    /// <summary>
    /// �Ƿ��ڸ�����
    /// </summary>
    private bool bFollowing = false;
    /// <summary>
    /// ֡��
    /// </summary>
    private int mFrame = 8;
    /// <summary>
    /// �������߼�ʱ��
    /// </summary>
    private Timer mFreedomWalkTimers;
    /// <summary>
    /// ��ʱ����
    /// </summary>
    private bool mTimeOut = false;
    /// <summary>
    /// ��ǰĿ��
    /// </summary>
    private Unit mCurTarget = null;
    /// <summary>
    /// ��ǰ�����ƶ���
    /// </summary>
    private Vector3 mCurFreedomPoint = Vector3.zero;
    /// <summary>
    /// ��ʾģ��
    /// </summary>
    private Transform mModel = null;
    #endregion

    #region ����
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
    /// ������Գ���λ��
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

    #region ��������
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

    #region ���з���
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
    /// ����
    /// </summary>
    public override void TakeOff(ActorData data)
    {
        base.TakeOff(data);
        if (mModel == null)
            return;
        GbjPool.Instance.Add(mModel.gameObject);
    }

    /// <summary>
    /// ���÷�����ʾ״̬
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
    /// ����ģ����ʾ״̬
    /// </summary>
    /// <param name="isShow"></param>
    public void SetModelShowSate(bool isShow)
    {
        if (mModel == null)
            return;
        mModel.gameObject.SetActive(isShow);
    }

    /// <summary>
    /// ����ģ��λ��
    /// </summary>
    public void SetModelPosition(Vector3 pos)
    {
        mOwner.Position = pos;
        if (mModel == null)
            return;
        mModel.position = pos;
    }

    /// <summary>
    /// ����
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

    #region ˽�з���
    /// <summary>
    /// ����ģ��
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
    /// ����ģ��״̬
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
    /// ��ʼ����������
    /// </summary>
    private void InitMagicWeaponData()
    {
        SetFreedomWalkTime();
        SetFreedomMovePoints();
        SetFightType();
    }

    /// <summary>
    /// ���������ƶ�ʱ��
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
    /// ���������ƶ���
    /// </summary>
    private void SetFreedomMovePoints()
    {
        float moveDis = mFollowDistance - 1;
        mMovePosList.Add(new Vector3(0, 0, -moveDis));
        mMovePosList.Add(new Vector3(moveDis, 0, 0));
        mMovePosList.Add(new Vector3(-moveDis, 0, 0));
    }

    /// <summary>
    /// �����ƶ���ʱ����
    /// </summary>
    private void FreedomWalkTimeOut()
    {
        mTimeOut = true;
    }

    /// <summary>
    /// ʩ�ż���
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
    /// ����
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
    /// ֡���ж�
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
    /// ���¸߶�
    /// </summary>
    private void UpdateHeight()
    {
        Vector3 pos = mOwner.Position;
        pos.y = DeltaY;
        Vector3 desPos = Vector3.Slerp(mOwner.Position, pos, Time.deltaTime * 5);
        SetModelPosition(desPos);
    }

    /// <summary>
    /// ִ���ƶ�
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
    /// ִ����ת
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
    /// ���Ŷ���
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
    /// �ͷż����ͼ���
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
    /// �����ƶ�
    /// </summary>
    private void FreedomMove()
    {
        if (!mTimeOut) return;
        MoveNextPoint();
    }

    /// <summary>
    /// ����һ���ƶ�
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
    /// ��ȡ�����ƶ�λ��
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
    /// ���������ƶ�
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
    /// ���������ƶ�����
    /// </summary>
    private void ResetFreedomParams()
    {
        mCurFreedomPoint = Vector3.zero;
        mTimeOut = false;
    }
    #endregion
}
