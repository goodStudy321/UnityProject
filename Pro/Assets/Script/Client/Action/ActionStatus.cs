using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ProtoBuf;
using System.Text;

/// <summary>
/// 行动状态机
/// </summary>
public class ActionStatus
{
    public enum EActionStatus
    {
        EAS_Idle = 0,			//待机
        EAS_Move = 1,			//移动
        EAS_Attack = 2,			//普攻
        EAS_BeHit = 3,			//受击
        EAS_Skill = 4,			//技能
        EAS_Defense = 5,		//防御
        EAS_Born = 6,			//出生
        EAS_Dead = 7,			//死亡
        EAS_KnockDown = 8,		//击倒
        EAS_KnockBack = 9,		//击退
        EAS_KnockOut = 10,		//击飞
        EAS_Deformation = 11,   //变身
    }

    /// <summary>
    /// 技能表现类型
    /// </summary>
    public enum ESkillShowType
    {
        ESST_Normal = 0,//移动攻击框,点对点子弹技能[轨迹都可以在动作编辑器调]
        ESST_LaserLight = 1,//扩展的激光技能
        ESST_ChainLightning = 2,//扩展的闪电链技能
    };

    /// <summary>
    /// 攻击定义类型
    /// </summary>
    public enum Attack_Def_Type
    {
        MovingFrame = 0,            //移动框
        PointToPointBullet = 1,     //点对点子弹
        LaserLight = 2,             //激光
        ChainLighting = 3,          //闪电链
    }

    /// <summary>
    /// 全局屏蔽重力，主要用于UI界面，和mIgnoreGravity是不一样的两个属性
    /// </summary>
    public bool ignoreGravityGlobal { get; set; }

    Unit mOwner;
    float mTotalTime = 0;
    int mActionTime = 0;
    public int ActionTime { get { return mActionTime; } }
    int mStraightTime = 0;//硬直时间
    int mSlowTime = 0;//减速时间
    int mHitDefIndex = 0;
    int mEventIndex = 0;
    int mActionKey = -1;
    private bool[] mHitDefActvied;
    ActionData mActiveAction;

    int mQueuedInterruptTime = 0;
    ActionInterruptData mQueuedInterrupt;
    public bool HasQueuedAction { get { return mQueuedInterrupt != null; } }

    Vector3 mBounding = Vector3.one;

    /// <summary>
    /// 冲击速度
    /// </summary>
    Vector2 mRushVelocity = Vector2.zero;

    /// <summary>
    /// 冲击方向
    /// </summary>
    Vector2 mRushDirection = Vector2.zero;
    Vector2 mEventRushDirection = Vector2.zero;
    Vector3 mMoveVelocity = Vector3.zero;

    /// <summary>
    /// 冲击力量
    /// </summary>
    float mRushStrange = 0;
    float mVelocityY = 0;

    float mDirectSpeed = 0;
    /// <summary>
    /// 当前动作组
    /// </summary>
    int mCurrentGroupIdx;
    
    public float DirectSpeed
    {
        get{ return mDirectSpeed; }
    }

    /// <summary>
    /// 外力速度
    /// </summary>
    public class ExternVelocity
    {
        public Vector3 mVelocity = Vector3.zero;
        public Vector3 mForward = Vector3.zero;
        float mTotalTime = 0;
        float mCurrentTime = 0;

        public float TotalTime
        {
            set
            {
                mCurrentTime = 0;
                mTotalTime = value;
            }
            get
            {
                return mTotalTime;
            }
        }

        public void Init()
        {
            mVelocity = Vector3.zero;
            mTotalTime = mCurrentTime = 0;
        }

        public Vector3 GetMove(float DeltaTime)
        {
            if (mCurrentTime >= mTotalTime)
                return Vector3.zero;

            mCurrentTime += DeltaTime;
            Vector3 offset = Vector3.zero;
            offset = mVelocity.z * mForward * DeltaTime;//算击退位移时直接按攻击者与受击者的方向算位移
            offset.y = mVelocity.y * DeltaTime;
            return offset;
        }
    }

    ExternVelocity mExternVelocity = new ExternVelocity();

    public void SetRushVelocity(float x, float y, float z, bool bEvent)
    {
        if (x == 0 && y == 0 && z == 0)
        {
            return;
        }

        mRushVelocity.x += x;
        mRushVelocity.y += z;

        mVelocityY += y;
        mRushStrange = Vector2.Distance(mRushVelocity, Vector2.zero);
        mRushDirection = mRushVelocity.normalized;
        if (bEvent)
            mEventRushDirection += mRushDirection;
    }

    public void SetForceStopEvent()
    {
        if (mRushStrange <= 0)
            return;

        Vector2 vCurDir = mEventRushDirection - mRushDirection;
        mEventRushDirection = vCurDir;
        if (vCurDir.sqrMagnitude <= 0.00001f)
        {
            ResetRush();
            return;
        }

        Vector2 vCurVel = mRushDirection * mRushStrange;
        mRushVelocity = vCurDir * Vector2.Dot(vCurVel, vCurDir); //获得投影
        mRushStrange = Vector2.Distance(mRushVelocity, Vector2.zero);
        mRushDirection = mRushVelocity.normalized;
    }

    void ResetRush()
    {
        mRushVelocity = Vector2.zero;
        mRushDirection = Vector2.zero;
        mEventRushDirection = Vector2.zero;
        mRushStrange = 0;
        mVelocityY = 0;
    }

    /// <summary>
    /// 高度状态
    /// </summary>
    ActionCommon.HeightStatusFlag mHeightState = ActionCommon.HeightStatusFlag.None;
    public ActionCommon.HeightStatusFlag HeightState
    {
        get { return mHeightState; }
    }
    /// <summary>
    /// 动作状态
    /// </summary>
    EActionStatus mActionState = EActionStatus.EAS_Idle;
    public EActionStatus ActionState
    {
        get { return mActionState; }
        set { mActionState = value; }
    }

    ActionGroupData mActionGroupData;
    float mGravity = 0.0f;
    float mXZAttenuation = 0;
    
    bool mIgnoreMove = false;
    bool mIgnoreGravity = false;
    bool mCanRotate = false;
    bool mCanMove = false;
    bool mCanHurt = false;
    bool mCanControl = false;
    bool mIsGod = false;
    bool mFaceTarget = false;
    bool mCanBehit = true;
    CurSkillInfo mCurSkInfo = new CurSkillInfo();



    GameObject mDebugBounding = null;

    public static bool SHOW_BOUNDING = false;

    public ActionGroupData ActionGroupData
    {
        get { return mActionGroupData; }
        set { mActionGroupData = value; }
    }

    public ActionData ActiveAction { get { return mActiveAction; } set { mActiveAction = value; } } 
    public Vector3 Bounding { get { return mBounding; } }
    public bool RotateOnHit { get { return (mActiveAction != null && mActiveAction.RotateOnHit != 2); } }
    public bool CanRotate { get { return mCanRotate; } }
    public bool CanMove { get { return mCanMove; } }
    public bool CanHurt { get { return mCanHurt; } }
    public bool CanConTrol { get { return mCanControl; } }
    public bool IsGod { get { return mIsGod; } }
    public bool FaceTarget { get { return mFaceTarget; } }
    public bool CanBehit { get { return mCanBehit; } set { mCanBehit = value; } }
    public int ActionLevel
    {
        get
        {
            if (mActiveAction.ActionLevel != 0)
                return mActiveAction.ActionLevel;
            else
                return ActionGroupData.DefaultActionLevel;
        }
    }

    private Unit mFTtarget = null;
    public Unit FTtarget{
        set
        {
            mFTtarget = value;
            if (mOwner != null && mOwner.UnitUID == User.instance.MapData.UID)
            {
                long uid = mFTtarget != null ? mFTtarget.UnitUID : 0;
                EventMgr.Trigger(EventKey.OnChangeFTtarget, uid);
            }
        }
        get
        {         
            return mFTtarget;
        }
    }//朝向的目标
    
    public CurSkillInfo GetCurSkInfo() { return mCurSkInfo; }

    public ActionStatus(Unit unit)
    {
        mOwner = unit;
    }

    /// <summary>
    /// 重置动作
    /// </summary>
    public void Reset()
    {
        mEventIndex = 0;
        mActionTime = 0;
        mQueuedInterrupt = null;
        mActionKey = -1;
        mHitDefIndex = 0;
        mHitDefActvied = null;
        mDirectSpeed = 0;

        mGravity = mActiveAction != null ? ActionGroupData.Gravtity * 0.01f : 9.8f;

        mXZAttenuation = ActionGroupData.XZAttenuation * 0.01f;

        mIgnoreGravity = mActiveAction != null ? mActiveAction.IgnoreGravity : false;
        
        mMoveVelocity = Vector3.zero;

        if (mActiveAction != null)
        {
            float sizeModifiy = 0.01f * 0.01f;
            float w = ActionGroupData.BoundingWidth * mActiveAction.BoundingWidthRadio * sizeModifiy;
            float h = ActionGroupData.BoundingHeight * mActiveAction.BoundingHeightRadio * sizeModifiy;
            float l = ActionGroupData.BoundingLength * mActiveAction.BoundingLengthRadio * sizeModifiy;

            if (mActiveAction.UseCommonBound)
            {
                mBounding.x = w;
                mBounding.y = h;
                mBounding.z = l;
            }
            else
            {
                mBounding.x = ActionGroupData.BoundingWidth * mActiveAction.CollisionWidthRadio * sizeModifiy;
                mBounding.y = ActionGroupData.BoundingHeight * mActiveAction.CollisionHeightRadio * sizeModifiy;
                mBounding.z = ActionGroupData.BoundingLength * mActiveAction.CollisionLengthRadio * sizeModifiy;
            }


            if (mOwner.Collider != null)
            {
                mOwner.Collider.radius = mOwner.Collider.radius * mActiveAction.BoundingWidthRadio * 0.01f;
                mOwner.Collider.height = mOwner.Collider.height * mActiveAction.BoundingHeightRadio * 0.01f;
            }

            SetActionState();
            mHeightState = (ActionCommon.HeightStatusFlag)(1 << mActiveAction.HeightStatus);
            mCanRotate = mActiveAction.CanRotate;
            mOwner.ProcessActiveAnimation(ActiveAction);
            ResetSpeed();
        }
    }

    /// <summary>
    /// 重设动画速度
    /// </summary>
    private void ResetSpeed()
    {
        if(mStraightTime > 0)
        {
            mOwner.SetAnimationSpeed(0.001f);
            return;
        }
        if(mSlowTime > 0)
            mOwner.SetAnimationSpeed(mOwner.mUnitAnimation.SlowAnimationSpeed);
    }

    /// <summary>
    /// 设置动作状态
    /// </summary>
    private void SetActionState()
    {
        if (mActiveAction.AnimID == "N9100")
        {
            mActionState = EActionStatus.EAS_Born;
        }
        else if (mActiveAction.AnimID == "H0000" || mActiveAction.AnimID == "H0001")
        {
            mActionState = EActionStatus.EAS_Dead;
        }
        else if (mActiveAction.AnimID.Contains("W"))
        {
            string str = mActiveAction.AnimID.Remove(0, 1);
            int num = int.Parse(str);
            if (num >= 11000)
                mActionState = EActionStatus.EAS_Skill;
            else
                mActionState = (EActionStatus)mActiveAction.ActionStatus;
        }
        else if (mActiveAction.AnimID == "H0020")
        {
            mActionState = EActionStatus.EAS_KnockBack;
        }
        else if (mActiveAction.AnimID == "H0030")
        {
            mActionState = EActionStatus.EAS_KnockOut;
        }
        else if (mActiveAction.AnimID == "D0000")
        {
            mActionState = EActionStatus.EAS_Deformation;
        }
        else
        {
            mActionState = (EActionStatus)mActiveAction.ActionStatus;
        }
    }
    
    float mListFrameLifeTime = 0;
    public void Update(float deltaTime)
    {
        int preTime = (int)mTotalTime;
        mTotalTime = (mTotalTime + (deltaTime * 1000)) % 9000000;
        if (preTime > mTotalTime)
            preTime = 0;

        int curTime = (int)mTotalTime;

        if (mActiveAction != null)
        {
            TickAction(curTime - preTime);
        }

        if (mListFrame != null)
        {
            if (mListFrameLifeTime > 1.0)
            {
                Object.Destroy(mListFrame);
                mListFrame = null;
            }

            mListFrameLifeTime += deltaTime;
        }

        //ShowBounding();
    }

    /// <summary>
    /// 显示包围框
    /// </summary>
    private void ShowBounding()
    {
        if (SHOW_BOUNDING)
        {
            if (mDebugBounding == null)
            {
                mDebugBounding = Object.Instantiate(Resources.Load("Bounding")) as GameObject;
            }
            if (mDebugBounding != null)
            {
                float BoundOffsetX = mActiveAction.CollisionOffsetX;
                float BoundOffsetY = mActiveAction.CollisionOffsetY;
                float BoundOffsetZ = mActiveAction.CollisionOffsetZ;

                if (!mActiveAction.UseCommonBound)
                {
                    BoundOffsetX = mActiveAction.BoundingOffsetX;
                    BoundOffsetY = mActiveAction.BoundingOffsetY;
                    BoundOffsetZ = mActiveAction.BoundingOffsetZ;
                }

                Utility.Rotate(ref BoundOffsetX, ref BoundOffsetZ, mOwner.Orientation);

                Vector3 Pos = mOwner.Position + new Vector3(
                    BoundOffsetX, BoundOffsetY, BoundOffsetZ) * 0.01f;

                Vector3 cubesize = new Vector3(Bounding.x, Bounding.y, Bounding.z);
                Vector3 eulerAngles = mOwner.UnitTrans.eulerAngles;

                eulerAngles.y = (mOwner.Orientation ) * Mathf.Rad2Deg;


                mDebugBounding.transform.localScale = cubesize;

                mDebugBounding.transform.localPosition = new Vector3(
                Pos.x,
                Pos.y + cubesize.y / 2.0f,
                Pos.z);

                mDebugBounding.transform.localEulerAngles = eulerAngles;
            }
        }
        else
        {
            GameObject.Destroy(mDebugBounding);
        }
    }

    /// <summary>
    /// 设置特效
    /// </summary>
    /// <param name="data"></param>
    /// <param name="bStopMode"></param>
    private void SetEffect(EventData data, bool bStopMode = false)
    {
        if (string.IsNullOrEmpty(data.EffectName))
            return;
        if (UnitHelper.instance.IsUnitShield(mOwner))
            return;
        if (!ShowEffectMgr.instance.CheckAtkEff(mOwner))
            return;
        string effName = ShowEffectMgr.instance.GetEffName(data.EffectName);
        if (effName == "FX_jiaoyin")
        {
            FootPrint fp = FootPrint.GetPlayEff(mOwner);
            if (fp == null)
                return;
            effName = fp.ModName;
        }
        else
        {
            if (!ShowEffectMgr.instance.AddShowEffect(effName, mOwner))
                return;
            effName = data.EffectName;
        }
        if (string.IsNullOrEmpty(effName))
            return;
        Vector3 offset = new Vector3(data.OffsetX * 0.01f, data.OffsetY * 0.01f, data.OffsetZ * 0.01f);
        Vector3 scale = Vector3.one * data.Scale;
        int bindMode = data.BindMode;
        int stopMode = data.StopMode;
        if (bStopMode)
            stopMode = 0x10;
        Vector3 foward = mOwner.UnitTrans != null ? mOwner.UnitTrans.forward : Vector3.zero;
        GameEventManager.instance.EnQueue(
            new PlayEffectEvent(effName, mOwner, offset, scale, foward, bindMode, stopMode), true);
    }

    /// <summary>
    /// 重置动作组
    /// </summary>
    /// <returns></returns>
    public bool ResetActionGroup()
    {
        uint actionId = mOwner.ModelId;
        ActionGroupData = ActionHelper.GetGroupData(actionId, mCurrentGroupIdx);

        if (ActionGroupData == null)
            return false;

        if (string.IsNullOrEmpty(ActionGroupData.StartupAction))
            ActionGroupData.StartupAction = "N0000";

        ChangeAction(ActionGroupData.StartupAction, 0);

        return true;
    }

    /// <summary>
    /// 改变动作组
    /// </summary>
    /// <param name="groupIndex"></param>
    /// <param name="bornAction"></param>
    /// <returns></returns>
    public bool ChangeActionGroup(int groupIndex, string bornAction = null)
    {
        mCurrentGroupIdx = groupIndex;

        uint actionId = mOwner.ActGroupId;
        ActionGroupData = ActionHelper.GetGroupData(actionId, groupIndex);

        if (ActionGroupData == null)
        {
#if UNITY_EDITOR
            Loong.Game.iTrace.eLog("actionGroupData is null ", mOwner.ActGroupId.ToString());
#endif
            return false;
        }

        if (!string.IsNullOrEmpty(bornAction))
            ActionGroupData.StartupAction = bornAction;
        if (string.IsNullOrEmpty(ActionGroupData.StartupAction))
            ActionGroupData.StartupAction = "N9100";

        mOwner.mUnitTransScale.SetScale(ActionGroupData.Scale / 100.0f, false);
        mOwner.OnActionCheck(ActionRunningState.Interrupt);
        ChangeAction(ActionGroupData.StartupAction, 0);

        return true;
    }

    /// <summary>
    /// 只切换动作组数据
    /// </summary>
    public void ChangeActionGroupOnly(int groupIndex)
    {
        mCurrentGroupIdx = groupIndex;
        ActionGroupData = ActionHelper.GetGroupData(mOwner.ModelId, groupIndex);
        if (ActionGroupData == null)
        {
#if UNITY_EDITOR
            Debug.Log("actionGroupData is null " + mOwner.ModelId);
#endif
        }
    }

    /// <summary>
    /// 检查当前中断是否包含指定转生技能的中断
    /// </summary>
    /// <param name="sklvId">技能等级Id</param>
    /// <returns></returns>
    public string CheckRbSkill(int sklvId)
    {
        return CheckSkill(sklvId);
    }

    /// <summary>
    /// 检查当前动作中断中是否包含指定技能的中断
    /// </summary>
    /// <param name="id"></param>
    public string CheckSkill(int id)
    {
        int count = mActiveAction.InterruptList.Count;
        if (count == 0) return string.Empty;
        for (int j = 0; j < count; j++)
        {
            ActionInterruptData actionInterruptData = mActiveAction.InterruptList[j];
            if (actionInterruptData.SkillID != id)
                continue;
            return actionInterruptData.ActionID;
        }
        return string.Empty;
    }

    /// <summary>
    /// 根据动作名检测中断
    /// </summary>
    /// <param name="actionID"></param>
    /// <returns></returns>
    public bool CheckInterrupt(string actionID)
    {
        int count = mActiveAction.InterruptList.Count;
        if (count == 0) return false;
        for (int j = 0; j < count; j++)
        {
            ActionInterruptData actionInterruptData = mActiveAction.InterruptList[j];
            if (actionInterruptData.ActionID != actionID)
                continue;
            return true;
        }
        return false;
    }

    /// <summary>
    /// 获取 ActionData 根据 ID
    /// </summary>
    /// <param name="ID"></param>
    /// <returns></returns>
    public ActionData GetActionByID(string ID)
    {
        return ActionHelper.GetActionByID(mActionGroupData, ID);
    }


    /// <summary>
    /// 检测当前的中断条件是否达成
    /// </summary>
    /// <param name="interrupt"></param>
    /// <returns></returns>
    public bool CheckActionInterrupt(ActionInterruptData interrupt)
    {
        bool ret = false;
        if (interrupt.CheckAllCondition)
        {
            ret = true;
            ret = ret && (!interrupt.TouchGround || mOwner.mUnitMove.OnGround);
            ret = ret && (!interrupt.Fall || mOwner.OnFall);
            ret = ret && (!interrupt.ReachHighest || mOwner.OnHighest);
            ret = ret && (!interrupt.DetectVariable || DetectVariable(interrupt));
            ret = ret && (interrupt.CheckSkillID == 0 || (mCurSkInfo.SkBaseId == interrupt.CheckSkillID));
        }
        else
        {
            ret = false;
            ret = ret || (interrupt.TouchGround && mOwner.mUnitMove.OnGround);
            ret = ret || (interrupt.Fall && mOwner.OnFall);
            ret = ret || (interrupt.ReachHighest && mOwner.OnHighest);
            ret = ret || (interrupt.DetectVariable && DetectVariable(interrupt));
            ret = ret || (interrupt.CheckSkillID != 0 && mCurSkInfo.SkBaseId == interrupt.CheckSkillID);
        }

        return ret;
    }

    /// <summary>
    /// 切换到死亡动画
    /// </summary>
    public void ChangeDeadAction()
    {
        if (mActiveAction != null && ActionState == EActionStatus.EAS_Dead)
            return;
        if (HeightState == ActionCommon.HeightStatusFlag.Stand)
        {
            ChangeAction(ActionGroupData.StandDeath, 0);
        }
        else
        {
            ChangeAction(ActionGroupData.StandDeath, 0);
        }
    }

    /// <summary>
    /// 切换到死亡最后一帧
    /// </summary>
    public void ChangeDeathAction()
    {
        if (mActiveAction != null && ActionState == EActionStatus.EAS_Dead)
            return;
        ChangeAction("H0001", 0);
    }

    /// <summary>
    /// 切换到待机动画
    /// </summary>
    public void ChangeIdleAction()
    {
        if (mActiveAction != null && ActionState == EActionStatus.EAS_Idle)
            return;
        ChangeAction("N0000", 0);
        ActionHelper.PlayRidingAnim(mOwner, false);
    }

    /// <summary>
    /// 切换到移动动画
    /// </summary>
    public void ChangeMoveAction()
    {
        if (mActiveAction != null && ActionState == EActionStatus.EAS_Move)
            return;
        ChangeAction("N0020", 0);
        ActionHelper.PlayRidingAnim(mOwner, true);
    }

    /// <summary>
    /// 改变动作
    /// </summary>
    /// <param name="id"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    public bool ChangeAction(string id, int deltaTime)
    {
        if (mActionGroupData == null)
            return false;

        int idx = ActionHelper.GetActionIndex(mActionGroupData, id);
        if (idx < 0)
        {
            return false;
        }
        mOwner.OnActionCheck(ActionRunningState.Interrupt);
        ChangeAction(idx, deltaTime);
        return true;
    }

    /// <summary>
    /// 处理队列动画
    /// </summary>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    bool ProcessQueuedAction(int deltaTime)
    {
        if (mQueuedInterrupt == null)
            return false;

        if (!CheckTime(deltaTime))
            return false;

        //Debug.Log("ExecuteActionState: " + mQueuedInterrupt.ActionID);

        // get the new action tick time.
        int nextActionTime = mActionTime + deltaTime - mQueuedInterruptTime;

        // change to the queued actions.
        ChangeAction(mQueuedInterrupt.ActionID, nextActionTime);

        // trun off queued actions.
        mQueuedInterrupt = null;

        return true;
    }

    /// <summary>
    /// 检查时间
    /// </summary>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    bool CheckTime(int deltaTime)
    {
        if (mActiveAction == null)
            return false;

        return (mActionTime == 0 && mQueuedInterruptTime == 0) || (mActionTime < mQueuedInterruptTime && mActionTime + deltaTime >= mQueuedInterruptTime);
    }

    /// <summary>
    /// 检测中断
    /// </summary>
    /// <param name="interrupt"></param>
    /// <returns></returns>
    public bool LinkAction(ActionInterruptData interrupt)
    {
        if (GetActionByID(interrupt.ActionID) == null)
        {
#if UNITY_EDITOR
            Debug.LogError(string.Format("{0}:LinkAction {1} failed!", mOwner.ModelId, interrupt.ActionID));
#endif
            return false;
        }

        if (interrupt.ConnectMode == 2)
        {
        }
        else
        {
            bool connectImmediately = (interrupt.ConnectMode == 0);
            int actualQueuedTime = 0;
            if (!connectImmediately && ActiveAction != null)
            {
                // check the queued time.
                actualQueuedTime = (interrupt.ConnectTime <= 100) ?
                    ActiveAction.AnimTime * interrupt.ConnectTime / 100 :	// [0-100] AnimTime
                    ActiveAction.AnimTime + ActiveAction.PoseTime * (interrupt.ConnectTime - 100) / 100; // [100-200] PoseTime

                // if the time already passed, do it immediately.
                if (actualQueuedTime <= mActionTime)
                    connectImmediately = true;
            }

            // do it immediately if the request is this.
            mQueuedInterrupt = null;
            if (!connectImmediately)
            {
                mQueuedInterruptTime = actualQueuedTime;
                mQueuedInterrupt = interrupt;
            }
            else
            {
                if (!ChangeAction(interrupt.ActionID, 0))
                    return false;
            }
        }


        return true;
    }
    
    /// <summary>
    /// 获取角色当前动作事件列表中触发时间等于1000的AddUnit事件，用于导弹类型爆炸
    /// </summary>
    /// <returns></returns>
    public EventData GetAddUnitEventData()
    {
        EventData eventData = null;
        for (int i = 0; i < ActiveAction.EventList.Count; i++)
        {
            if (ActiveAction.EventList[i].TriggerTime != 1000)
                continue;
            if (ActiveAction.EventList[i].EventDetailData.EventType != (int)ActionCommon.EventType.AddUnit)
                continue;
            eventData = ActiveAction.EventList[i].EventDetailData;
            break;
        }
        return eventData;
    }

    /// <summary>
    /// 获取动作数据
    /// </summary>
    /// <param name="actionId"></param>
    /// <returns></returns>
    public ActionData GetActionData(string actionId)
    {
        int idx = ActionHelper.GetActionIndex(mActionGroupData, actionId);
        if (idx < 0)
        {
            return null;
        }

        if (idx < 0 || idx >= mActionGroupData.ActionDataList.Count)
            return null;

        return mActionGroupData.ActionDataList[idx];
    }

    /// <summary>
    /// 处理单位旋转
    /// </summary>
    void RotateAction()
    {
        if (mOwner == null)
            return;

        float rotateSpeed = ActiveAction.RotateSpeed * Time.deltaTime;

        Unit targetUnit = null;
        if (mOwner.ActionStatus.FTtarget != null && !mOwner.ActionStatus.FTtarget.Dead)
        {
            targetUnit = mOwner.ActionStatus.FTtarget;
        }

        if (targetUnit == null)
        {
            if (mOwner.ParentUnit == null)
                return;
            if (mOwner.ParentUnit.Dead)
                return;
            if (!mOwner.FollowParent)
                return;
            
            Quaternion rotation = Quaternion.Lerp(mOwner.UnitTrans.rotation, mOwner.ParentUnit.UnitTrans.rotation, rotateSpeed);
            mOwner.UnitTrans.rotation = rotation;
            mOwner.DirectlySetOrientation();
            return;
        }

        //单位向目标旋转
        Vector3 targetForward = targetUnit.Position - mOwner.Position;
        targetForward.y = 0;
        if (targetForward != Vector3.zero && mOwner.UnitTrans != null)
        {
            Quaternion rotation = Quaternion.Lerp(mOwner.UnitTrans.rotation, Quaternion.LookRotation(targetForward), rotateSpeed);
            mOwner.UnitTrans.rotation = rotation;
            mOwner.DirectlySetOrientation();
        }
    }

    /// <summary>
    /// 改变动画
    /// </summary>
    /// <param name="actionIdx"></param>
    /// <param name="deltaTime"></param>
    void ChangeAction(int actionIdx, int deltaTime)
    {
        ActionData oldAction = mActiveAction;
        ActionData action = mActionGroupData.ActionDataList[actionIdx];
        if (action.ResetVelocity)
        {
            mExternVelocity.Init();
            ResetRush();
        }
        if (mActionState == EActionStatus.EAS_Born)
            UnitEventMgr.ExecuteBornDone(mOwner);

        mActiveAction = action;
        mActiveAction.EventList.Sort(delegate(ActionEventData a, ActionEventData b) { return a.TriggerTime.CompareTo(b.TriggerTime); });

        Reset();
        
        // tick action now.
        if (deltaTime > 0)
            TickAction(deltaTime);

        //if (mActiveAction.RotateSpeed != 0)
        //    RotateAction();

        if (InputMgr.instance.mOwner == null)
            return;
        if (mOwner != InputMgr.instance.mOwner)
            return;
        InputVectorMove.instance.ResetMoveKeyDown(oldAction);
    }
    
    /// <summary>
    /// 处理中断，事件，攻击定义列表
    /// </summary>
    /// <param name="deltaTime"></param>
    void TickAction(int deltaTime)
    {
        if (mActiveAction == null)
            return;

        if (ProcessInterruptEveryFrame())
            return;

        if (ProcessQueuedAction(deltaTime))
            return;

        ProcessMoving(deltaTime);
        //检测处于硬直状态。
        if (ProcessStraighting(ref deltaTime))
            return;

        //处理迟缓
        ProcessSlow(ref deltaTime);

        // check we are going to finished, tick current action to the end.
        int nextActionTime = 0;
        bool thisActionIsFinished = false;
        if ((mActionTime + deltaTime) > ActionHelper.GetActionTotalTime(mActiveAction))
        {
            // get the new action tick time.
            nextActionTime = deltaTime;

            deltaTime = ActionHelper.GetActionTotalTime(mActiveAction) - mActionTime;
            nextActionTime -= deltaTime;

            thisActionIsFinished = true;
        }

        // next action key.
        int nextActionKey = GetNextKey(deltaTime);

        if (nextActionKey > mActionKey)
        {
            ProcessEventList(nextActionKey, deltaTime);

            ProcessHitDefineList(nextActionKey);

            // check the interrupt list.
            if (ProcessActionInterruptList(mActionKey, nextActionKey))
                return;

            if (mActiveAction.PoseTime > 0 && mActionKey < 100 && nextActionKey >= 100)
                mOwner.mUnitAnimation.OnEnterPoseTime();

            // hack the event interrupts.
            mOwner.OnReachHighest(false);
        }

        //ProcessIgnoreCollider();

        //ProcessRotating(deltaTime);


        mActionTime += deltaTime;
        mActionKey = nextActionKey;

        // this action is done!!
        if (thisActionIsFinished)
        {
            ProcessTickFinish(nextActionTime);
        }
    }

    /// <summary>
    /// 处理碰撞忽略
    /// </summary>
    void ProcessIgnoreCollider()
    {
        Collider selfco = mOwner.Collider != null ? mOwner.Collider : null;
        if (selfco == null)
            return;

        for (int i = 0; i < UnitMgr.instance.UnitList.Count; ++i)
        {
            Unit u = UnitMgr.instance.UnitList[i];
            if (u == mOwner)
                continue;

            Collider co = u.Collider != null ? u.Collider : null;
            if (co == null)
                continue;

            bool ignore = u.ActionStatus.ActiveAction.IgnoreCollider || mActiveAction.IgnoreCollider;
            Physics.IgnoreCollision(selfco, co, ignore);
        }
    }

    /// <summary>
    /// 处理动作播放完成动作的切换，如果单位死亡，则切换到死亡动作
    /// </summary>
    /// <param name="nextActionTime"></param>
    void ProcessTickFinish(int nextActionTime)
    {
        string nextAction = mActiveAction.DefaultLinkActionID;
        if (mOwner.Dead)
        {
            if (mHeightState == ActionCommon.HeightStatusFlag.Stand)
                nextAction = mActionGroupData.StandDeath;
            else if (mHeightState == ActionCommon.HeightStatusFlag.Ground)
                nextAction = mActionGroupData.DownDeath;

            if (nextAction == mActiveAction.AnimID)
                nextAction = mActiveAction.DefaultLinkActionID;
            if (mActiveAction.AnimID == "H0001")
                nextAction = "H0001";
        }

        mOwner.OnActionCheck(ActionRunningState.Finish);
        ChangeAction(nextAction, nextActionTime);
    }

    bool DetectVariable(ActionInterruptData interrupt)
    {
        return true;
    }

    /// <summary>
    /// 检测有没有达成当前动作的中断条件,条件达成就中断，否则就不中断
    /// </summary>
    /// <returns></returns>
    bool ProcessInterruptEveryFrame()
    {
        if (mQueuedInterrupt != null)
            return false;

        // check the action interrupts
        if (mActiveAction.InterruptList.Count == 0)
            return false;

        int iCount = mActiveAction.InterruptList.Count;
        for (int i = 0; i < iCount; i++)
        {
            ActionInterruptData interrupt = mActiveAction.InterruptList[i];
            if (interrupt.ConditionInterrupte && ProcessActionInterrupt(interrupt))
                return true;

            if (interrupt.SkillID != 0 && mOwner.mUnitSkill.HasSkillInput(interrupt.SkillID))
            {
                return LinkAction(interrupt);
            }
        }
        return false;
    }
    
    /// <summary>
    /// 处理攻击中断
    /// </summary>
    /// <returns></returns>
    public bool ProcessHitInterrupt()
    {
        // check the action interrupts
        if (mActiveAction.InterruptList.Count == 0)
            return false;

        int iCount = mActiveAction.InterruptList.Count;
        for (int i = 0; i < iCount; i++)
        {
            ActionInterruptData interrupt = mActiveAction.InterruptList[i];

            if (interrupt.Hurted)
            {
                LinkAction(interrupt);
                return true;
            }
        }

        return false;
    }
    
    /// <summary>
    /// 处理中断列表
    /// </summary>
    /// <param name="preKey"></param>
    /// <param name="nextKey"></param>
    /// <returns></returns>
    bool ProcessActionInterruptList(int preKey, int nextKey)
    {
        if (mQueuedInterrupt != null)
            return false;

        // check the action interrupts
        if (mActiveAction.InterruptList.Count == 0)
            return false;

        int iCount = mActiveAction.InterruptList.Count;

        for (int i = 0; i < iCount; i++)
        {
            ActionInterruptData interrupt = mActiveAction.InterruptList[i];

            if (interrupt.SkillID != 0 && mOwner.mUnitSkill.HasSkillInput(interrupt.SkillID))
            {
                return LinkAction(interrupt);
            }

            if (interrupt.ConditionInterrupte)
            {
                if (ProcessActionInterrupt(interrupt))
                    return true;
            }
        }
        return false;
    }
    
    /// <summary>
    /// 处理动作中断
    /// </summary>
    /// <param name="interrupt"></param>
    /// <returns></returns>
    bool ProcessActionInterrupt(ActionInterruptData interrupt)
    {
        // the [interrupt.ConditionInterrupte] need user input.
        // do not process it here.
        if (interrupt.CheckAllCondition && interrupt.IsCheckInput1)
            return false;

        if (!CheckActionInterrupt(interrupt))
            return false;

        return LinkAction(interrupt);
    }
    
    /// <summary>
    /// 获取下一帧时间
    /// </summary>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    int GetNextKey(int deltaTime)
    {
        if (mActiveAction == null) return -1;

        int currentTime = mActionTime + deltaTime;
        int animTime = mActiveAction.AnimTime;
        if(animTime <= 0)
        {
            animTime = 1;
#if UNITY_EDITOR
            Debug.LogError("setup.act has config an animation's time is 0");
#endif
        }

        // [0-100]
        if (currentTime <= animTime)
            return currentTime * 100 / animTime;

        // [200-...]
        if (currentTime >= ActionHelper.GetActionTotalTime(mActiveAction))
            return 200;

        // [101-199]
        int leftTime = currentTime - animTime;
        return 100 + leftTime * 100 / mActiveAction.PoseTime;
    }
    
    /// <summary>
    /// 处理当前动作的事件列表
    /// </summary>
    /// <param name="nextKey"></param>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    bool ProcessEventList(int nextKey, int deltaTime)
    {
        if (mActiveAction.EventList.Count == 0 || mEventIndex >= mActiveAction.EventList.Count)
            return false;

        bool ret = false;
        while (mEventIndex < mActiveAction.EventList.Count)
        {
            ActionEventData actionEventData = mActiveAction.EventList[mEventIndex];
            if (actionEventData.TriggerTime > nextKey)
                break;

            TriggerEvent(actionEventData, deltaTime, mEventIndex);
            ret = true;
            mEventIndex++;
        }
        return ret;
    }
    
    /// <summary>
    /// 处理当前动作的攻击定义列表
    /// </summary>
    /// <param name="nextKey"></param>
    /// <returns></returns>
    bool ProcessHitDefineList(int nextKey)
    {
        if (mActiveAction.AttackDefList.Count == 0 || mHitDefIndex >= mActiveAction.AttackDefList.Count)
            return false;

        int skLv = mCurSkInfo.SkLv;


        ///执行所有到达时间段的攻击定义
        bool ret = false;
        if (mHitDefActvied == null)
        {
            mHitDefActvied = new bool[mActiveAction.AttackDefList.Count];
        }
        for (int i = 0, c = mActiveAction.AttackDefList.Count; i < c; i++)
        {
            //已经释放，跳过
            if (mHitDefActvied[i]) continue;

            //攻击定义
            AttackDefData hit_data = mActiveAction.AttackDefList[i];

            //时间段检测
            if (hit_data.TriggerTime > nextKey)
                continue;

            //技能等级检测
            if ((hit_data.StartSkillLevel != 0 || hit_data.EndSkillLevel != 0)
                && (hit_data.StartSkillLevel > skLv || hit_data.EndSkillLevel < skLv))
            {
                continue;
            }
            //创建攻击定义实体//{根据技能表里面胡显示技能类型创建攻击定义，原来技能是ESST_Normal，扩充的导弹和激光分别是ESST_Missile、ESST_LaserLight}
            if (mCurSkInfo.SkBaseId == 0) continue;
            int harmSection = i + 1;
            if (mOwner.ModelId == 40006)
            {
                CreateHitDefine(hit_data, Vector3.zero, mActiveAction.AnimID, harmSection);
            }
            else if(hit_data.AttackDefType == (int) Attack_Def_Type.MovingFrame)
            {
                CreateHitDefine(hit_data, Vector3.zero, mActiveAction.AnimID, harmSection);
            }
            else if(hit_data.AttackDefType == (int)Attack_Def_Type.PointToPointBullet)
            {
                CreateBullet(hit_data, Vector3.zero, mActiveAction.AnimID, harmSection, false);
            }
            else if(hit_data.AttackDefType == (int)Attack_Def_Type.LaserLight)
            {
                CreateLaserLight(hit_data, Vector3.zero, mActiveAction.AnimID, harmSection);
            }
            else if(hit_data.AttackDefType == (int)Attack_Def_Type.ChainLighting)
            {
                CreateChainLightning(hit_data, Vector3.zero, mActiveAction.AnimID, harmSection);
            }
            mHitDefActvied[i] = true;
            ret = true;
        }

        return ret;
    }
    
    /// <summary>
    /// 创建一般攻击
    /// </summary>
    /// <param name="hit_data"></param>
    /// <param name="position"></param>
    /// <param name="action"></param>
    /// <returns></returns>
    bool CreateHitDefine(AttackDefData hit_data, Vector3 position, string action, int harmSection)
    {
        mOwner.HitComponent.AddHit(hit_data, action, harmSection);

        return true;
    }
    
    /// <summary>
    /// 创建曲线子弹攻击实体
    /// </summary>
    /// <param name="hit_data"></param>
    /// <param name="position"></param>
    /// <param name="action"></param>
    /// <param name="heatEnergyHit"></param>
    /// <param name="isStraightBullet"></param>
    /// <returns></returns>
    bool CreateBullet(AttackDefData hit_data, Vector3 position, string action, int harmSection, bool isStraightBullet = false)
    {
        if (mOwner.UnitTrans == null)
            return false;
        mOwner.HitComponent.AddBulletHit(hit_data, action, isStraightBullet, harmSection);

        return true;
    }

    /// <summary>
    /// 添加激光
    /// </summary>
    /// <param name="hit_data"></param>
    /// <param name="position"></param>
    /// <param name="action"></param>
    /// /// <param name="harmSection">技能伤害段</param>
    /// <returns></returns>
    bool CreateLaserLight(AttackDefData hit_data, Vector3 position, string action, int harmSection)
    {
        mOwner.HitComponent.AddLaserLightHit(hit_data, action, harmSection);
        return true;
    }

    /// <summary>
    /// 添加闪电链
    /// </summary>
    /// <param name="hit_data"></param>
    /// <param name="position"></param>
    /// <param name="action"></param>
    /// <param name="harmSection">技能伤害段</param>
    /// <returns></returns>
    bool CreateChainLightning(AttackDefData hit_data, Vector3 position, string action, int harmSection)
    {
        if (mOwner.UnitTrans == null)
            return false;
        mOwner.HitComponent.AddChainLightning(hit_data, action, harmSection);

        return true;
    }
    
	//处理硬值
    bool ProcessStraighting(ref int deltaTime)
    {
        if (mStraightTime <= 0)
            return false;

        mStraightTime -= deltaTime;

        if (mStraightTime > 0)
            return true;

        Vector3 euler = mOwner.UnitTrans.eulerAngles;
        euler.x = euler.z = 0;
        mOwner.UnitTrans.eulerAngles = euler;

        mOwner.mUnitAnimation.EndStaight(this);
        deltaTime = -mStraightTime;

        return false;
    }

	//处理迟缓
    void ProcessSlow(ref int deltaTime)
    {
        if (mSlowTime <= 0)
            return;
        mSlowTime -= deltaTime;
        if (mSlowTime > 0)
            deltaTime = (int)(deltaTime * mOwner.mUnitAnimation.SlowAnimationSpeed / mOwner.mUnitAnimation.AnimationSpeed);
        else
            mOwner.mUnitAnimation.EndSlow(this);
    }
	//处理旋转
    void ProcessRotating(int deltaTime)
    {
        if (mActiveAction.RotateSpeed == 0 || ActionState == EActionStatus.EAS_Move)
            return;

        //处理有旋转速度单位的旋转，瞬间旋转的在动作事件列表的FaceTarget事件处理
        RotateAction();
    }
    
    /// <summary>
    /// 处理移动
    /// </summary>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    bool ProcessMoving(int deltaTime)
    {
        // do relative moving.
        if (mIgnoreMove)
        {
            mIgnoreMove = false;
            return true;
        }

        float dt = deltaTime * 0.001f;
        Vector3 MoveDistance = Vector3.zero;
        Vector3 LashMoveDistance = Vector3.zero;

        LashMoveDistance += mExternVelocity.GetMove(dt) + mMoveVelocity * dt;
        mOwner.mUnitMove.Move(LashMoveDistance);

        ProcessActionMove(ref MoveDistance, dt);

        float x = MoveDistance.x, z = MoveDistance.z;
        if (x != 0 || z != 0)
            Utility.Rotate(ref x, ref z, mOwner.Orientation);

        mOwner.mUnitMove.Move(new Vector3(x, MoveDistance.y, z));

        if (!mIgnoreGravity && !ignoreGravityGlobal)
        {
            float velocityModify = -mGravity * dt;
            if (mVelocityY > 0 && mVelocityY <= -velocityModify)
                mOwner.OnReachHighest(true);

            if (mOwner.mUnitMove.OnGround)
                mVelocityY = velocityModify;
            else
                mVelocityY += velocityModify;
        }

        return true;
    }
    void ProcessActionMove(ref Vector3 Distance, float dt)
    {
        Vector2 vMoveXZ = Vector2.zero;

        if (mRushStrange > 0)
        {
            float XZDis = mRushStrange * dt - mXZAttenuation * dt * dt * 0.5f;
            mRushStrange -= mXZAttenuation * dt;
            mRushStrange = mRushStrange < 0 ? 0 : mRushStrange;

            vMoveXZ = mRushDirection * XZDis;

            if (mRushStrange == 0)
            {
                ResetRush();
            }
        }

        Distance.x += vMoveXZ.x;
        Distance.z += vMoveXZ.y;

        if (mIgnoreGravity || ignoreGravityGlobal)
        {
            Distance.y += mVelocityY * dt;
        }
        else
        {
            Distance.y += mVelocityY * dt - mGravity * dt * dt * 0.5f;
        }
    }

    /// <summary>
    /// 设置硬直时间
    /// </summary>
    /// <param name="time"></param>
    public void SetStraightTime(int time)
    {
		if (time <= 0)
			return;

        if (mStraightTime > 0)
            mOwner.mUnitAnimation.EndStaight(this);

        mStraightTime = (int)((float)time * mActionGroupData.StraightModify);
        if (mStraightTime > 0)
            mOwner.mUnitAnimation.BeginStaight();
    }

    /// <summary>
    /// 设置迟缓
    /// </summary>
    /// <param name="time">迟缓时间</param>
    /// <param name="speed">迟缓速度</param>
    public void SetSlow(int time, float speedPersent)
    {
        if (time <= 0)
            return;

        if (mSlowTime > 0)
            mOwner.mUnitAnimation.EndSlow(this);

        mSlowTime = time;
        float nowSpeed = mOwner.mUnitAnimation.AnimationSpeed;
        nowSpeed += nowSpeed * speedPersent;
        mOwner.mUnitAnimation.BeginSlow(nowSpeed);
        mOwner.mUnitAnimation.SlowAnimationSpeed = nowSpeed;
    }

	/// <summary>
    /// 按百分比获取动画时间点
    /// </summary>
    /// <param name="checkRatio"></param>
    /// <returns></returns>
    public int GetCheckTime(int checkRatio)
    {
        if (mActiveAction == null) return -1;

        // check the queued time.
        return (checkRatio <= 100) ?
            mActiveAction.AnimTime * checkRatio / 100 :	// [0-100] AnimTime
            mActiveAction.AnimTime + mActiveAction.PoseTime * (checkRatio - 100) / 100; // [100-200] PoseTime
    }

    /// <summary>
    /// 设置方向
    /// </summary>
    /// <param name="angle">角度</param>
    /// <param name="local">是否相对于局部坐标系</param>
    void SetDirection(int angle, bool local)
    {
        float rad = Mathf.Deg2Rad * angle;
        mOwner.SetOrientation(local ? mOwner.Orientation + rad : rad);
    }

    void PlaySound(string soundName, bool checkMaterial)
    {
        //// LY add begin ////
        if (mOwner.CanPlaySound() == false)
        {
            return;
        }
        //// LY add end ////
        
        GameEventManager.instance.EnQueue(new PlaySound(soundName, checkMaterial), false);
    }

    void SwitchStatus(string name, bool checkStatus)
    {
        switch (name)
        {
            case "CanRotate":
                mCanRotate = checkStatus;
                break;
            case "IgnoreGravity":
                mIgnoreGravity = checkStatus;
                break;
            case "CanMove":
                mCanMove = checkStatus;
                break;
            case "CanHurt":
                mCanHurt = checkStatus;
                break;
            case "CanControl":
                mCanControl = checkStatus;
                break;
            case "IsGOD":
                mIsGod = checkStatus;
                break;
            case "FaceTarget":
                mFaceTarget = checkStatus;
                break;
        }
    }

    protected GameObject mListFrame = null;

    /// <summary>
    /// 面向目标
    /// </summary>
    /// <returns></returns>
    public bool FaceTargets()
    {
        if (FTtarget != null && !FTtarget.Dead)
        {
            float x = FTtarget.Position.x - mOwner.Position.x;
            float z = FTtarget.Position.z - mOwner.Position.z;
            float dir = Mathf.Atan2(x, z);
            mOwner.SetOrientation(dir);
            return true;
        }
        return false;
    }

    //目前SetVelocity事件和攻击/受击速度替换规则如下：
    //攻击/受击速度共用一个Extern速度，后面设置的替换前面的
    //SetVelocity事件优先级最高，一旦设置清掉攻击/受击速度
    public void SetExternVelocity(float x, float y, float z, float time, Vector3 forward)
    {
        if (mActionGroupData == null)
            return;
        Vector3 vModify = Vector3.zero;
        Utility.Vector3_Copy(mActionGroupData.LashModifier, ref vModify);
        mExternVelocity.mVelocity.Set(x, y, z);
        mExternVelocity.mVelocity.Scale(vModify);
        mExternVelocity.mForward = forward;
        mExternVelocity.TotalTime = time;
    }
    
    /// <summary>
    /// 设置角色移动速度
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    /// <param name="z"></param>
    public void SetVelocity(float x, float y, float z)
    {
        mExternVelocity.Init();
        mMoveVelocity.Set(x, y, z);
    }
    
    /// <summary>
    /// 处理动作事件列表
    /// </summary>
    /// <param name="actionEventData"></param>
    /// <param name="deltaTime"></param>
    /// <param name="eventIndex"></param>
    /// <returns></returns>
    bool TriggerEvent(ActionEventData actionEventData, int deltaTime, int eventIndex)
    {
        EventData data = actionEventData.EventDetailData;

        switch ((ActionCommon.EventType)data.EventType)
        {
            case ActionCommon.EventType.PlayEffect:
                {
                    SetEffect(data);
                }
                break;

            case ActionCommon.EventType.ShowEffect:
                {
                    SetEffect(data, true);
                    break;
                }

            case ActionCommon.EventType.HideEffect:
                {
                    if (string.IsNullOrEmpty(data.EffectName))
                        break;
                    string effName = ShowEffectMgr.instance.GetEffName(data.EffectName);
                    mOwner.RemoveActionCheck(effName);
                    break;
                }
            case ActionCommon.EventType.PlaySound:
                {
                    PlaySound(data.SoundName, data.CheckMatril);
                }
                break;
            case ActionCommon.EventType.StatusOn:
                {
                    SwitchStatus(data.StatusName, true);
                }
                break;
            case ActionCommon.EventType.StatusOff:
                {
                    SwitchStatus(data.StatusName, false);
                }
                break;

            case ActionCommon.EventType.SetVelocity:
                {
                    //return true;
                    SetVelocity(data.VelocityX * 0.01f, data.VelocityY * 0.01f, data.VelocityZ * 0.01f);
                }
                break;
            case ActionCommon.EventType.SetVelocity_X:
                {
                    //return true;
                    SetVelocity(data.VelocityX * 0.01f, mMoveVelocity.y, mMoveVelocity.z);
                }
                break;
            case ActionCommon.EventType.SetVelocity_Y:
                {
                    // return true;
                    SetVelocity(mMoveVelocity.x, data.VelocityY * 0.01f, mMoveVelocity.z);
                }
                break;
            case ActionCommon.EventType.SetVelocity_Z:
                {
                    // return true;
                    SetVelocity(mMoveVelocity.x, mMoveVelocity.y, data.VelocityZ * 0.01f);
                }
                break;
            case ActionCommon.EventType.SetDirection:
                {
                    // return true;
                    SetDirection(data.Angle, data.Local);
                }
                break;
            case ActionCommon.EventType.ExeScript:
                {
                    // return true;
                    ExeScript.instance.ExeScriptCmd(data.ScriptCmd, mOwner);
                }
                break;
            case ActionCommon.EventType.SetGravity:
                {
                    // return true;
                    mGravity = data.Gravity * 0.01f;
                }
                break;
            case ActionCommon.EventType.AddUnit:
                {
                    if(Global.Mode == PlayMode.Local)
                    {
                        if (data.UnitID == 0)
                            break;
                        Vector3 targetPos = mOwner.Position;
                        if (FTtarget != null)
                            targetPos = FTtarget.Position;
                        GameEventManager.instance.EnQueue(new SummonUnitEvent(data, targetPos, mOwner));
                        break;
                    }
                    if (mOwner.UnitUID != InputMgr.instance.mOwner.UnitUID)
                        break;
                    Vector3 skillPos = Vector3.zero;
                    float eulerAngle = 0;
                    if (data.Local)
                    {
                        Vector3 delPos = new Vector3(data.PosX, data.PosY, data.PosZ) * 0.01f;
                        skillPos = mOwner.UnitTrans.TransformPoint(delPos);
                        eulerAngle = mOwner.UnitTrans.localEulerAngles.y;
                    }
                    else
                    {
                        Unit target = InputMgr.instance.mLockTarget;
                        if (target == null || target.UnitTrans == null || target.Dead)
                        {
                            skillPos = mOwner.Position;
                            eulerAngle = mOwner.UnitTrans.localEulerAngles.y;
                        }
                        else
                        {
                            Vector3 delPos = new Vector3(data.PosX, data.PosY, data.PosZ) * 0.01f;
                            Vector3 forward = mOwner.Position - target.Position;
                            Quaternion quaternion = Quaternion.LookRotation(forward);
                            Matrix4x4 matri = Matrix4x4.TRS(target.Position, quaternion, Vector3.one);
                            skillPos = matri.MultiplyPoint(delPos);
                            eulerAngle = quaternion.eulerAngles.y;
                        }
                    }
                    
                    NetSkill.RequestPlaySkill(mOwner, mCurSkInfo.SkLvId, new List<long>(), skillPos, eulerAngle);
                    #region 单机使用
                    /*if (data.UnitID == 0)
                        break;
                    Vector3 targetPos = Vector3.zero;
                    targetPos = mOwner.Position;
                    if (FTtarget != null)
                        targetPos = FTtarget.Position;
                    if (mSelectPosition != Vector3.zero)
                        targetPos = mSelectPosition;
                    GameEventManager.instance.EnQueue(new SummonUnitEvent(data, targetPos, mOwner));
                    */
                    #endregion
                }
                break;
            case ActionCommon.EventType.ForceRushRange:
                {
                    float randX = Random.Range(data.MinRushVelocity.Vector3Data_X, data.MaxRushVelocity.Vector3Data_X) * 0.01f;
                    float randY = Random.Range(data.MinRushVelocity.Vector3Data_Y, data.MaxRushVelocity.Vector3Data_Y) * 0.01f;
                    float randZ = Random.Range(data.MinRushVelocity.Vector3Data_Z, data.MaxRushVelocity.Vector3Data_Z) * 0.01f;

                    Utility.Rotate(ref randX, ref randZ, Random.Range(0, 360.0f));
                    SetRushVelocity(randX, randY, randZ, true);
                    break;
                }
            case ActionCommon.EventType.RemoveMyself:
                {
                    mOwner.Destroy();
                }
                break;
            case ActionCommon.EventType.SetColor:
                {
                }
                break;
            case ActionCommon.EventType.PickUp:
                {
                }
                break;

            case ActionCommon.EventType.Scale:
                {
                    mOwner.mUnitTransScale.SetScale((float)data.ScaleModel / 100.0f, true);
                }
                break;
            case ActionCommon.EventType.CameraEffect:

                break;
            case ActionCommon.EventType.ListTargets:
                {
                }
                break;
            case ActionCommon.EventType.FaceTargets:
                {
                    FaceTargets();
                }
                break;
            case ActionCommon.EventType.Chat:
                {
                }
                break;
            case ActionCommon.EventType.SetMaterial:
                {
                }
                break;
            case ActionCommon.EventType.FollowParent:
                {
                }
                break;
            case ActionCommon.EventType.CameraShake:
                {
                    break;
                }
            case ActionCommon.EventType.SetOutlineSkin:
                {
                    ExeScript.instance.SetOutlineSkin(mOwner, data.ColorRed, data.ColorGreen, data.ColorBlue, data.OutlineWidth, data.Emission);
                    break;
                }
            case ActionCommon.EventType.ResetNormalSkin:
                {
                    ExeScript.instance.ResetNormalSkin(mOwner);
                    break;
                }
            case ActionCommon.EventType.ForceRush:
                {
                    SetRushVelocity(data.VelocityX * 0.01f, data.VelocityY * 0.01f, data.VelocityZ * 0.01f, true);
                }
                break;

            case ActionCommon.EventType.ForceStop:
                {
                    SetForceStopEvent();
                    NetMove.SendMove(mOwner, mOwner.Position, SendMoveType.SendMoveRoleWalk);
                    break;
                }

            case ActionCommon.EventType.NewListTarget:
                {
                }
                break;

            case ActionCommon.EventType.ShowSkin:
                {
                    Renderer[] renders = mOwner.UnitTrans.GetComponentsInChildren<Renderer>();
                    int len = renders.Length;
                    for (int i = 0; i < len; i++)
                    {
                        if (renders[i].gameObject.name == data.EventSkin)
                        {
                            renders[i].enabled = data.Show;
                            break;
                        }
                    }
                    break;
                }

            case ActionCommon.EventType.SetDirectSpeed:
                {

                }
                break;
        }
        return true;
    }

    /// <summary>
    /// 处理击中高度
    /// </summary>
    /// <param name="HitResult"></param>
    /// <param name="remoteAttacks"></param>
    /// <returns></returns>
    public bool OnHit(ActionCommon.HitResultType HitResult)
    {
        string changeAction = "";

        bool handled = true;
        switch (HitResult)
        {
            case ActionCommon.HitResultType.StandHit:
                {
                    changeAction = mActionGroupData.StandStandHit;
                    break;
                }
            case ActionCommon.HitResultType.KnockBack:
                {
                    changeAction = mActionGroupData.StandKnockBack;
                    break;
                }
            case ActionCommon.HitResultType.DiagUp:
                {
                    changeAction = mActionGroupData.StandDiagUp;
                    break;
                }
            case ActionCommon.HitResultType.KnockOut:
                {
                    changeAction = mActionGroupData.StandKnockOut;
                    break;
                }
        }


        if (!string.IsNullOrEmpty(changeAction))
        {
            mOwner.OnActionCheck(ActionRunningState.Hurt);
            if (!IsStraightState() && ActionHelper.CanPlayHitAction(mOwner))
            	ChangeAction(changeAction, 0);
        }
        else
        {
            if (!IsStraightState())
            {
            	if (ProcessHitInterrupt())
                	return false;
            }
        }
        return handled;
    }

    /// <summary>
    /// 设置当前技能
    /// </summary>
    /// <param name="skillId"></param>
    /// <param name="addTarNum">技能添加目标</param>
    public void SetSkill(uint skillId,int addTarNum)
    {
        if (skillId == 0)
            mCurSkInfo.ReSet();
        else
        {
            mCurSkInfo.Set(skillId,addTarNum);
            mOwner.mUnitSkill.ProcessSkill(mOwner, mCurSkInfo);
        }
    }

	//是否硬值状态
    public bool IsStraightState()
    {
        return mStraightTime > 0;
    }

    /// <summary>
    /// 是否迟缓状态
    /// </summary>
    /// <returns></returns>
    public bool IsSlowState()
    {
        return mSlowTime > 0;
    }
}
