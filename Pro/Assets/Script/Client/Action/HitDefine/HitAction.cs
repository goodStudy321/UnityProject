using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ProtoBuf;
using Loong.Game;

public class HitAction
{
    public enum HitDamageType
    {
        LightDamageType = 0,            //轻击
        MediumDamageType = 1,            //中击
        HeavyDamageType = 2,            //重击
        KillShotDamageType = 3,            //绝招
    }
    
    public CurSkillInfo SkInfo { get { return mSkInfo; } }
    public AttackDefData AttackData
    {
        get { return mData; }
    }

    protected AttackDefData mData = null;
    protected Unit mOwner = null;
    protected SkillLevelAttr mSkill;
    protected CurSkillInfo mSkInfo;

    protected Vector3 mInitPos = Vector3.zero;
    protected Vector3 mPos = Vector3.zero;
    protected float mOrientation = 0;

    protected string mAction = string.Empty;

    protected Vector3 mCubeHitDefSize = Vector3.zero;
    Vector3 mCylinderSize = Vector3.zero;
    Vector3 mRingSize = Vector3.zero;
    Vector3 mFanSize = Vector3.zero;
    Vector2 mFanAngle = Vector2.zero;

    protected float mDelayTime = 0.0f;
    protected float mLifeTime = 0.0f;
    protected int mHitSucessCount = 0;
    protected int mLastHitCount = 0;

    protected GameObject mSelfEffectGo = null;
    protected bool mPlayedSelfEffect = false;
    protected bool mPlayedSelfSound = false;
    protected float mSelfEffectStartupTime = 0f;
    protected float mSelfSoundStartupTime = 0f;

    protected bool mOutofDate = false;
    protected bool mIsDestroyEffect = false;
    public bool mIsEffectLoaded = false;

    //抓取
    protected Matrix4x4 mAttackDefMatrix = Matrix4x4.identity;
    protected Quaternion mAttackDefQuat = Quaternion.identity;
    protected Vector3 mForward = Vector3.zero;
    protected List<Unit> mCaptureTargets = null;

    protected float mMultiplyOrient = 0;

    protected Vector3 mFrameFactor = Vector3.one;
    protected Vector3 mFrameFinalFactor = Vector3.zero;

    protected Unit mTarUnit; //子弹攻击的目标
    protected Vector3 mTarUnitOriginalPosition = Vector3.zero;
    protected float mTarUnitOriginalOrientation = Mathf.Infinity;
    protected Vector3 mTarUnitLastTrackPosision = Vector3.zero;
    protected Vector3 mTarUnitBounding = Vector3.one;
    protected ActionData mTarUnitActionData;

    //目标同步(目前只用攻击框和移动攻击框)--间隔100毫秒发送一次
    protected int mHarmSection = 0;
    protected float mSendTimeCount = 0.1f;
    protected float mCountTime = 0.1f;
    protected bool mCanSendHitedList = true;
    protected List<long> mSendHitedTargetList = new List<long>();

    /// <summary>
    /// 目标位置
    /// </summary>
    protected Vector3 mTarUnitPosition
    {
        get
        {
            if (!mData.IsTrackTarget)
                return mTarUnitOriginalPosition;
            if (mTarUnit != null)
            {
                mTarUnitLastTrackPosision = mTarUnit.Position;
                return mTarUnit.Position;
            }
            else //目标已经死亡被移除，返回最后记录的位置
            {
                return mTarUnitLastTrackPosision;
            }
        }
    }

    protected void GetCaptureMatrix(out Matrix4x4 matCapture)
    {
        if (mData.AttachUnitKeepLocal == 1 || mData.AttachUnitRotate)
        {
            matCapture = mAttackDefMatrix;
        }
        else
        {
            matCapture = Matrix4x4.TRS(mPos, Quaternion.Euler(0, mOrientation * Mathf.Rad2Deg, 0), Vector3.one);
        }
    }

    protected virtual void MakeAttackMatrix()
    {
        mAttackDefQuat = Quaternion.Euler(0, (mOrientation + mMultiplyOrient) * Mathf.Rad2Deg, 0);
        mAttackDefMatrix = Matrix4x4.TRS(mPos, mAttackDefQuat, Vector3.one);
    }

    public bool OutDate
    {
        get { return mOutofDate; }
        set { mOutofDate = value; }
    }

    protected GameObject mAttackFrame = null;

    protected float mDuration = 0;

    protected Dictionary<GameObject, HitedData> mHitedPassedMap = new Dictionary<GameObject, HitedData>();

    public virtual void ReInit()
    {
        mData = null;
        mOwner = null;
        mSkInfo = null;

        mInitPos = Vector3.zero;
        mPos = Vector3.zero;
        mOrientation = 0;

        mAction = string.Empty;

        mCubeHitDefSize = Vector3.zero;
        mCylinderSize = Vector3.zero;
        mRingSize = Vector3.zero;
        mFanSize = Vector3.zero;
        mFanAngle = Vector2.zero;

        mDelayTime = 0.0f;
        mLifeTime = 0.0f;
        mHitSucessCount = 0;
        mLastHitCount = 0;

        mSelfEffectGo = null;
        mPlayedSelfEffect = false;
        mPlayedSelfSound = false;
        mSelfEffectStartupTime = 0f;
        mSelfSoundStartupTime = 0f;

        mOutofDate = false;
        mIsDestroyEffect = false;

        mAttackFrame = null;
        mDuration = 0;

        mMultiplyOrient = 0;
        mCaptureTargets = null;

        mHitedPassedMap.Clear();
        mSendHitedTargetList.Clear();
        mCanSendHitedList = true;
        mSendTimeCount = mCountTime;
        mHarmSection = 0;
    }

    public class HitedData
    {
        public int hitedCount = 0;
        public float cd = 0f;
    }

    public static bool ShowAttackFrame = false;
    public static bool DestroyShowAttackFrame = false;

    public virtual void Init(AttackDefData data, Unit owner, string action, int harmSection)
    {
        mData = data;
        mOwner = owner;
        mAction = action;
        mPos = mInitPos = owner.Position;
        Vector3 forward = owner.UnitTrans.forward;
        mOrientation = Mathf.Atan2(forward.x, forward.z);
        mSkInfo = owner.ActionStatus.GetCurSkInfo();
        mHarmSection = harmSection;

        Utility.Vector3_Copy(mData.FrameFinalFactor, ref mFrameFinalFactor);

        mDuration = Utility.MilliSecToSec(mData.Duration);

        mDelayTime = Utility.MilliSecToSec(mData.Delay);
        // 本体特效
        mSelfEffectStartupTime = Utility.MilliSecToSec(mData.EffectTriggerTime);
        // 本体音效
        mSelfSoundStartupTime = Utility.MilliSecToSec(mData.SoundTriggerTime);

        mForward = mOwner.UnitTrans.forward;
        
        InitTargetData();
        UpdatePosition(0);
        ResetAttackFram();
        MakeAttackMatrix();
        CheckSelfEffect(0);
        UpdateEffectPosition(mSelfEffectGo);
    }

    /// <summary>
    /// 销毁自身特效
    /// </summary>
    /// <param name="resName"></param>
    /// <param name="gameObj"></param>
    public void DestroySelfEffect(GameObject gameObj, long unitUID)
    {
        if (mIsDestroyEffect) return;
        ShowEffectMgr.instance.RemoveShowEffect(gameObj);
        ShowEffectMgr.instance.AddToPool(gameObj);
        mIsDestroyEffect = true;
        mIsEffectLoaded = false;
    }

    /// <summary>
    /// 销毁攻击定义
    /// </summary>
    public void Destroy()
    {
        mOutofDate = true;
        if (mSelfEffectGo != null)
        {
            DestroySelfEffect(mSelfEffectGo, mOwner.UnitUID);
            mSelfEffectGo = null;
        }

        if (ShowAttackFrame && DestroyShowAttackFrame)
        {
            if (mAttackFrame == null)
                return;
            GameObject.Destroy(mAttackFrame);
        }
    }

    public virtual void Update()
    {
        float deltaTime = Time.deltaTime;
        mLifeTime += deltaTime;
        if (UpdateDelayTime(deltaTime))
            return;

        //MaxCountOuteDate 达到最大次数后消失，MaxHitCount 最大穿透次数，HitCount 攻击频率
        if (mOwner == null || mLifeTime >= mDuration || MaxCountOutDate() || ChangeActionOutDate())
        {
            mOutofDate = true;
        }

        if (mOutofDate)
            return;

        UpdatePosition(mLifeTime * 100.0f / mDuration);

        MakeAttackMatrix();

        UpdateEffectPosition(mSelfEffectGo);

        CheckSelfEffect(deltaTime);
        
        while (mLastHitCount < mData.HitCount)
        {
            float checkTime = mLastHitCount * mDuration / mData.HitCount;
            if (checkTime > mLifeTime + deltaTime)
                break;

            CheckHit(mOwner);
            mLastHitCount++;
        }

        SendHitActionTargets();
        
        UpdateHitCD(deltaTime);

        if (ShowAttackFrame)
            UpdateDebugFrame();
    }

    /// <summary>
    /// 更新延迟
    /// </summary>
    /// <param name="deltaTime"></param>
    /// <returns></returns>
    protected bool UpdateDelayTime(float deltaTime)
    {
        if (mDelayTime <= deltaTime)
            return false;
        mDelayTime -= deltaTime;
        return true;
    }

    /// <summary>
    /// 初始化目标数据
    /// </summary>
    protected virtual void InitTargetData()
    {
        mTarUnit = mOwner.ActionStatus.FTtarget;
        if (mTarUnit == null)
            return;
        mTarUnitOriginalPosition = mTarUnit.Position;
        mTarUnitOriginalOrientation = mTarUnit.Orientation;
        mTarUnitLastTrackPosision = mTarUnit.Position;
        if (mTarUnit.ActionStatus == null)
            return;
        mTarUnitBounding = mTarUnit.ActionStatus.Bounding;
        mTarUnitActionData = mTarUnit.ActionStatus.ActiveAction;
        if (mTarUnitActionData == null)
            mOutofDate = true;
    }

    /// <summary>
    /// 发送HitAction类型技能击中目标
    /// </summary>
    protected virtual void SendHitActionTargets()
    {
        if (Global.Mode == PlayMode.Local)
            return;
        if (mOwner == null)
            return;
        if (mOwner.UnitUID != User.instance.MapData.UID)
        {
            if (mOwner.ParentUnit == null)
                return;
            if (mOwner.ParentUnit.UnitUID != User.instance.MapData.UID)
                return;
        }
        UpdateSendTimeCount();
        if (!mCanSendHitedList)
            return;
        if (mSendHitedTargetList.Count == 0)
            return;
        if(SkInfo != null)
            NetSkill.RequestPlaySkill(mOwner, SkInfo.SkLvId, mSendHitedTargetList, mOwner.Position, mOwner.UnitTrans.localEulerAngles.y);
        mCanSendHitedList = false;
        mSendHitedTargetList.Clear();
    }

    /// <summary>
    /// 更新发送伤害时间
    /// </summary>
    protected void UpdateSendTimeCount()
    {
        if (mSendTimeCount > 0)
        {
            mSendTimeCount -= Time.deltaTime;
            return;
        }
        mCanSendHitedList = true;
        mSendTimeCount = mCountTime;
    }

    /// <summary>
    /// 发送中目标,如果是HitAction技能类时，用SendHitActionTargets()
    /// </summary>
    /// <param name="target"></param>
    protected virtual void SendHitedTarget(Unit target)
    {
        if (mOwner.UnitUID != User.instance.MapData.UID)
        {
            if (mOwner.ParentUnit == null)
                return;
            if (mOwner.ParentUnit.UnitUID != User.instance.MapData.UID)
                return;
            PendantHelper.instance.AddPetHitTarget(mOwner, target);
        }
        if (target == null)
            return;
        mSendHitedTargetList.Add(target.UnitUID);
        AddToHitedLst(target);
        SendBulletHit();
        SendLaserHit();
    }

    /// <summary>
    /// 添加到被击列表
    /// </summary>
    /// <param name="target"></param>
    protected void AddToHitedLst(Unit target)
    {
        if (mOwner == null)
            return;
        if (mOwner.mUnitMove.InPathFinding)
            return;
        InputMgr.instance.mHitedList.Add(target);
    }

    /// <summary>
    /// 发送子弹攻击目标
    /// </summary>
    protected void SendBulletHit()
    {
        if (!(this is BulletHit))
            return;
        SendTargets();
    }

    /// <summary>
    /// 发送一对一伤害子弹
    /// </summary>
    protected void SendLaserHit()
    {
        if (!(this is LaserLightHit))
            return;
        if (mData.PathList.Count != 0)
            return;
        SendTargets();
    }

    /// <summary>
    /// 发送目标
    /// </summary>
    protected void SendTargets()
    {
        if(SkInfo != null)
            NetSkill.RequestPlaySkill(mOwner, SkInfo.SkLvId, mSendHitedTargetList, mOwner.Position, mOwner.UnitTrans.localEulerAngles.y);
        mSendHitedTargetList.Clear();
    }

    /// <summary>
    /// 重置攻击框
    /// </summary>
    protected virtual void ResetAttackFram()
    {
        switch ((ActionCommon.HitDefnitionFramType)mData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
                {
                    Utility.Vector3_Copy(mData.FrameSize, ref mCubeHitDefSize);
                    mCubeHitDefSize = Vector3.Scale(mCubeHitDefSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.CylinderType:
                {
                    Utility.Vector3_Copy(mData.FrameSize, ref mCylinderSize);
                    mCylinderSize = Vector3.Scale(mCylinderSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    Utility.Vector3_Copy(mData.FrameSize, ref mRingSize);
                    mRingSize = Vector3.Scale(mRingSize, mFrameFactor) * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    mCubeHitDefSize = mOwner.ActionStatus.Bounding;
                }
                break;
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    Utility.Vector3_Copy(mData.FrameSize, ref mFanSize);
                    mFanSize = Vector3.Scale(mFanSize, mFrameFactor) * 0.01f;

                    mFanAngle.x = mData.FrameSize.Vector3Data_Z;
                    mFanAngle.y = mData.FrameFinalFactor.Vector3Data_X;
                }
                break;
        }
    }

    /// <summary>
    /// 检查自身特效
    /// </summary>
    /// <param name="deltaTime"></param>
    protected void CheckSelfEffect(float deltaTime)
    {
        if (mPlayedSelfEffect)
            return;

        mSelfEffectStartupTime -= deltaTime;
        if (mSelfEffectStartupTime <= 0)
            PlaySelfEffect();

        mSelfSoundStartupTime -= deltaTime;
        if (mSelfSoundStartupTime <= 0)
            PlaySelfSound();
    }

    /// <summary>
    /// 更新特效位置
    /// </summary>
    /// <param name="effect"></param>
    protected void UpdateEffectPosition(GameObject effect)
    {
        if (effect == null)
            return;
        Vector3 localPos = new Vector3(
            mData.SelfEffectOffset.Vector3Data_X * 0.01f,
            mData.SelfEffectOffset.Vector3Data_Y * 0.01f,
            mData.SelfEffectOffset.Vector3Data_Z * 0.01f);
        effect.transform.position = mAttackDefMatrix.MultiplyPoint(localPos);
        effect.transform.rotation = mAttackDefQuat;
    }

    /// <summary>
    /// 播放攻击定义自身特效
    /// </summary>
    protected virtual void PlaySelfEffect()
    {
        if (mPlayedSelfEffect)
            return;

        mPlayedSelfEffect = true;
        if (UnitHelper.instance.IsUnitShield(mOwner))
            return;
        if (!ShowEffectMgr.instance.CheckAtkEff(mOwner))
            return;
        if (!ShowEffectMgr.instance.AddShowEffect(mData.SelfEffect, mOwner))
            return;
        if (!string.IsNullOrEmpty(mData.SelfEffect))
        {
            string effName = QualityMgr.instance.GetQuaEffName(mData.SelfEffect);
            AssetMgr.LoadPrefab(effName, (effect) =>
             {
                 mIsEffectLoaded = true;
                 if (effect == null)
                     OutDate = true;
                 effect.transform.parent = null;
                 effect.SetActive(true);
                 HitHelper.instance.ClearTrailEffect(effect);
                 UpdateEffectPosition(effect);
                 ShowEffectMgr.instance.ClearEffTrail(effect);
                 mSelfEffectGo = effect;
                 DelayDestroy delay = mSelfEffectGo.GetComponent<DelayDestroy>();
                 if (delay != null)
                 {
                     delay.onDestroy = DestroySelfEffect;
                 }
                 if (OutDate)
                     Destroy();
             });
        }
        else
            mIsEffectLoaded = true;
    }

    /// <summary>
    /// 播放攻击定义自身声音
    /// </summary>
    protected void PlaySelfSound()
    {
        if (mPlayedSelfSound)
            return;

        //// LY add begin ////
        if (mOwner.CanPlaySound() == false)
        {
            return;
        }
        //// LY add end ////

        mPlayedSelfSound = true;
        if (!string.IsNullOrEmpty(mData.SelfSound))
        {
            GameEventManager.instance.EnQueue(new PlaySound(mData.SelfSound, false));
        }
    }

    /// <summary>
    /// 路径插值
    /// </summary>
    /// <param name="ratio"></param>
    /// <param name="pos"></param>
    protected virtual void Interplate(float ratio, ref Vector3 pos)
    {
        if (mData.PathList.Count == 0)
            pos = Vector3.zero;
        else if (mData.PathList.Count == 1)
        {
            Utility.Vector3_Copy(mData.PathList[0].Pos, ref pos);
        }
        else
        {
            for (int i = 1; i < mData.PathList.Count; i++)
            {
                PathNode preNode = mData.PathList[i - 1];
                PathNode curNode = mData.PathList[i];
                if (ratio < curNode.Ratio)
                {
                    Vector3 vStart = Vector3.zero, vEnd = Vector3.zero;
                    Utility.Vector3_Copy(preNode.Pos, ref vStart);
                    Utility.Vector3_Copy(curNode.Pos, ref vEnd);

                    // 如果移动路径的Z相等，移动路径的距离根据目标的距离变化
                    if (vStart.z == vEnd.z)
                    {
                        float disZ = Vector3.Distance(mOwner.Position, mTarUnitPosition) * 100;
                        vStart = new Vector3(vStart.x, vStart.y, disZ);
                        vEnd = new Vector3(vEnd.x, vEnd.y, disZ);
                    }

                    //pos = vStart + (vEnd - vStart) * ((ratio - preNode.Ratio) / (curNode.Ratio - preNode.Ratio));
                    float t = (ratio - preNode.Ratio) / (curNode.Ratio - preNode.Ratio);
                    pos = BezierTool.GetLinearPoint(vStart, vEnd, t);
                    break;
                }

                if (curNode.Ratio == 0)
                {
                    Utility.Vector3_Copy(preNode.Pos, ref pos);

                    if (preNode.Pos.Vector3Data_Z == curNode.Pos.Vector3Data_Z)
                    {
                        float disZ = Vector3.Distance(mOwner.Position, mTarUnitPosition) * 100;
                        pos.z = disZ;
                    }
                    break;
                }
                else if (ratio > curNode.Ratio)
                {
                    Utility.Vector3_Copy(curNode.Pos, ref pos);

                    if (preNode.Pos.Vector3Data_Z == curNode.Pos.Vector3Data_Z)
                    {
                        float disZ = Vector3.Distance(mOwner.Position, mTarUnitPosition) * 100;
                        pos.z = disZ;
                    }
                    //break;
                }
            }
        }
    }

    /// <summary>
    /// 转换位置
    /// </summary>
    /// <param name="pos"></param>
    void RoatatePos(ref Vector3 pos)
    {
        float x = pos.x, z = pos.z;
        Utility.Rotate(ref x, ref z, mOrientation);
        pos.x = x;
        pos.z = z;
    }

    /// <summary>
    /// 更新攻击框位置
    /// </summary>
    /// <param name="ratio"></param>
    protected virtual void UpdatePosition(float ratio)
    {
        this.mMultiplyOrient += mData.RotateSpeed * 0.01f * Time.deltaTime;

        if (mData.FllowReleaser != 0 ||   //释放者动作改变
            mData.FramType == (int)ActionCommon.HitDefnitionFramType.SomatoType) //受击体类型
        {
            mOrientation = mOwner.Orientation;
            mInitPos = mOwner.Position;
        }

        Vector3 pos = Vector3.zero;
        Interplate(ratio, ref pos);

        RoatatePos(ref pos);

        mPos = mInitPos + pos * 0.01f;
    }


    #region CheckHit
    protected void UpdateHitCD(float deltaTime)
    {
        foreach (KeyValuePair<GameObject, HitedData> val in mHitedPassedMap)
        {
            val.Value.cd -= deltaTime;
        }
    }

    /// <summary>
    /// 检查达到最大次数后消失
    /// </summary>
    protected bool MaxCountOutDate()
    {
        if (mData.MaxCountOuteDate == 0)
            return false;
        return IsMaxCount();
    }

    /// <summary>
    /// 是否达到最大攻击次数
    /// </summary>
    /// <returns></returns>
    protected bool IsMaxCount()
    {
        int allMaxHitCount = mData.AllMaxHitCount;
        //最大穿透次数
        if (allMaxHitCount <= 0)
            return false;
        allMaxHitCount += mSkInfo.AddTarNum;
        if (mHitSucessCount < allMaxHitCount)
            return false;
        return true;
    }

    /// <summary>
    /// 释放者动作改变后消失
    /// </summary>
    /// <returns></returns>
    protected bool ChangeActionOutDate()
    {
        if (mData.OwnerActionChange != 1)
            return false;
        if (mAction == mOwner.ActionStatus.ActiveAction.AnimID)
            return false;
        return true;
    }

    /// <summary>
    /// 是否可攻击
    /// </summary>
    /// <param name="self"></param>
    /// <param name="target"></param>
    /// <returns></returns>
    protected virtual bool CanHit(Unit self, Unit target)
    {
        UnitType unitType = target.mUnitAttInfo.UnitType;
        if(!SkillHelper.instance.CannotHitUnitType(unitType))
            return false;

        RaceType type = (RaceType)mData.Race;
        //if (!SkillHelper.instance.ComparieCampByRaceType(self, target, type))
        //    return false;
        if (!SkillHelper.instance.IsGainSk(self, target, type))
        {
            if (!SkillHelper.instance.CompaireHitCondiction(self, target))
                return false;
        }
        // 如果攻击高度不符合要求，停止击中判定
        //if ((mData.HeightStatusHitMask & (1 << target.ActionStatus.ActiveAction.HeightStatus)) == 0)
        //    return false;

        if (target.ActionStatus == null)
            return false;
        if (target.ActionStatus.ActiveAction == null)
            return false;

        // 如果当前动作不接受受伤攻击，停止击中判定。
        if (!target.ActionStatus.ActiveAction.CanHurt)
            return false;

        //最大伤害次数为0，检查目标或目标点是否被击中，生成击中虚拟体
        if (mData.SingleMaxHitCount == 0)
        {
            bool hitSuccess = CheckHitTarget(target);
            if (hitSuccess)
            {
                Vector3 targetPos = mTarUnit != null ? mTarUnitPosition : target.Position;
                // 击中事件
                for (int i = 0; i < mData.AttackEventList.Count; ++i)
                {
                    EventData evtdata = mData.AttackEventList[i];
                    ProcessAttackEvent(evtdata, targetPos);
                }
            }
            return false;
        }

        HitedData hd = null;
        if (mData.SingleMaxHitCount > 0 && mHitedPassedMap.TryGetValue(target.UnitTrans.gameObject, out hd))
        {
            if (hd.hitedCount >= mData.SingleMaxHitCount || hd.cd > 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }

        return true;
    }

    /// <summary>
    /// 检测攻击
    /// </summary>
    /// <param name="self"></param>
    protected void CheckHit(Unit self)
    {
        if (self == null)
            return;

        for (int i = 0; i < UnitMgr.instance.UnitList.Count; ++i)
        {
            if (IsMaxCount())
                return;
            Unit target = UnitMgr.instance.UnitList[i];
            if (!UnitHelper.instance.CanUseUnit(target))
                continue;
            if (target.DestroyState)
                continue;
            if (!CanHit(self, target))
                continue;
            CheckHit(self, target);
        }
    }

    /// <summary>
    /// 对单个目标进行集中检测
    /// </summary>
    /// <param name="self"></param>
    /// <param name="target"></param>
    protected bool CheckTargetHit(Unit self, Unit target)
    {
        if (!UnitHelper.instance.CanUseUnit(target)
            || target.DestroyState)
        {
            bool hitSuccess = CheckHitTarget(self,target);
            if (!hitSuccess)
                return false;
            // 击中事件
            for (int i = 0; i < mData.AttackEventList.Count; ++i)
            {
                EventData evtdata = mData.AttackEventList[i];
                ProcessAttackEvent(evtdata, mTarUnitPosition);
            }
            mOutofDate = true;
            return true;
        }
        if (!CanHit(self, target))
            return false;
        return CheckHit(self, target);
    }

    /// <summary>
    /// 更新Debug框
    /// </summary>
    protected virtual void UpdateDebugFrame()
    {
        Vector3 InterplateValue = Vector3.one + (mFrameFinalFactor - Vector3.one) * (mLifeTime / mDuration);

        Vector3 eulerAngles = Vector3.zero;
        Vector3 scaler = Vector3.one;

        switch ((ActionCommon.HitDefnitionFramType)mData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
                {
                    if (mAttackFrame == null)
                        mAttackFrame = (GameObject)Utility.Instantiate(Resources.Load("HitFrame/HitDefinitionCube"));

                    if (mData.FllowReleaser != 0)
                        eulerAngles.y = mOwner.Orientation * Mathf.Rad2Deg;
                    else
                        eulerAngles.y = mOrientation * Mathf.Rad2Deg;

                    scaler = Vector3.Scale(mCubeHitDefSize, InterplateValue);
                }
                break;
            case ActionCommon.HitDefnitionFramType.CylinderType:
                {
                    Vector3 cubeDef = Vector3.Scale(mCylinderSize, InterplateValue);

                    if (mAttackFrame == null)
                        mAttackFrame = (GameObject)Utility.Instantiate(Resources.Load("HitFrame/HitDefinitionCylinder"));

                    if (mData.FllowReleaser != 0)
                        eulerAngles.y = (mOwner.Orientation) * Mathf.Rad2Deg;
                    else
                        eulerAngles.y = (mOrientation) * Mathf.Rad2Deg;

                    scaler = new Vector3(2 * cubeDef.x, cubeDef.y / 2.0f, 2 * cubeDef.x);
                }
                break;
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    mRingSize.x = mData.FrameSize.Vector3Data_X * mData.FrameFinalFactor.Vector3Data_X * 0.01f;
                    mRingSize.z = mData.FrameSize.Vector3Data_Y * mData.FrameFinalFactor.Vector3Data_Y * 0.01f;
                    mRingSize.y = mData.FrameSize.Vector3Data_Z * mData.FrameFinalFactor.Vector3Data_Z * 0.01f;
                }
                break;
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    mCubeHitDefSize = mOwner.ActionStatus.Bounding;
                }
                break;
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    mFanSize.x = mData.FrameSize.Vector3Data_X * mData.FrameFinalFactor.Vector3Data_Y * 0.01f;
                    mFanSize.y = mData.FrameSize.Vector3Data_Y * mData.FrameFinalFactor.Vector3Data_Z * 0.01f;

                    mFanAngle.x = mData.FrameSize.Vector3Data_Z;
                    mFanAngle.y = mData.FrameFinalFactor.Vector3Data_X;
                }
                break;
        }

        if (mAttackFrame != null)
        {
            GameObject go = GameObject.Find("AttackFrameRoot");
            if (go == null)
                go = new GameObject("AttackFrameRoot");
            mAttackFrame.transform.SetParent(go.transform);

            eulerAngles.y += mMultiplyOrient * Mathf.Rad2Deg;
            mAttackFrame.transform.position = new Vector3(mPos.x, mPos.y + mCubeHitDefSize.y / 2, mPos.z);
            mAttackFrame.transform.rotation = Quaternion.Euler(eulerAngles);
            mAttackFrame.transform.localScale = scaler;
        }
    }

    /// <summary>
    /// 击中目标判断
    /// </summary>
    /// <param name="target"></param>
    /// <returns></returns>
    public bool CheckHitTarget(Unit target)
    {
        ActionStatus targetActionStatus = target.ActionStatus;
        ActionData targetAction = targetActionStatus.ActiveAction;

        Vector3 InterplateValue = Vector3.one + (mFrameFinalFactor - Vector3.one) * (mLifeTime / mDuration);

        float BoundOffsetX = targetAction.CollisionOffsetX;
        float BoundOffsetY = targetAction.CollisionOffsetY;
        float BoundOffsetZ = targetAction.CollisionOffsetZ;

        if (!targetAction.UseCommonBound)
        {
            BoundOffsetX = targetAction.BoundingOffsetX;
            BoundOffsetY = targetAction.BoundingOffsetY;
            BoundOffsetZ = targetAction.BoundingOffsetZ;
        }

        float orientation = target.Orientation;
        Vector3 position = target.Position;
        Utility.Rotate(ref BoundOffsetX, ref BoundOffsetZ, orientation);

        Vector3 AttackeePos = position + new Vector3(BoundOffsetX, BoundOffsetY, BoundOffsetZ) * 0.01f;

        bool hitSuccess = false;
        switch ((ActionCommon.HitDefnitionFramType)mData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    Vector3 vBounding = targetActionStatus.Bounding;
                    Vector3 cubeDef = Vector3.Scale(mCubeHitDefSize, InterplateValue);
                    if (Utility.RectangleHitDefineCollision(
                         mPos, mOrientation,
                         cubeDef,
                         AttackeePos, orientation,
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
                        mPos, mOrientation,
                        mCylinderSize.x, mCylinderSize.y,
                        AttackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    if (Utility.RingHitDefineCollision(
                        mPos, mOrientation,
                        mRingSize.x, mRingSize.y, mRingSize.z,
                        AttackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    if (Utility.FanHitDefineCollision(
                        mPos, mOrientation,
                        mFanSize.x, mFanSize.y,
                        mFanAngle.x, mFanAngle.y,
                        AttackeePos, orientation,
                        targetActionStatus.Bounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
        }
        if (hitSuccess && mData.SingleMaxHitCount == 0)
        {
            target.mUnitEffects.CreateOnHitEffectAndSoundEvent(mOwner, target, mData, mTarUnitPosition);
            mOutofDate = true;
        }
        return hitSuccess;
    }

    /// <summary>
    /// 判断单体技能的目标为空时对目标原来坐标的击中
    /// </summary>
    /// <returns></returns>
    public bool CheckHitTarget(Unit self, Unit target)
    {
        if (mTarUnitActionData == null)
        {
            return false;
        }
        Vector3 InterplateValue = Vector3.one + (mFrameFinalFactor - Vector3.one) * (mLifeTime / mDuration);

        float BoundOffsetX = mTarUnitActionData.CollisionOffsetX;
        float BoundOffsetY = mTarUnitActionData.CollisionOffsetY;
        float BoundOffsetZ = mTarUnitActionData.CollisionOffsetZ;

        if (!mTarUnitActionData.UseCommonBound)
        {
            BoundOffsetX = mTarUnitActionData.BoundingOffsetX;
            BoundOffsetY = mTarUnitActionData.BoundingOffsetY;
            BoundOffsetZ = mTarUnitActionData.BoundingOffsetZ;
        }

        //判断技能时否跟随技能
        float orientation = mTarUnitOriginalOrientation;

        Utility.Rotate(ref BoundOffsetX, ref BoundOffsetZ, orientation/*target.Orientation*/);

        Vector3 AttackeePos = mTarUnitPosition + new Vector3(BoundOffsetX, BoundOffsetY, BoundOffsetZ) * 0.01f;

        bool hitSuccess = false;
        switch ((ActionCommon.HitDefnitionFramType)mData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    Vector3 vBounding = mTarUnitBounding;
                    Vector3 cubeDef = Vector3.Scale(mCubeHitDefSize, InterplateValue);
                    if (Utility.RectangleHitDefineCollision(
                         mPos, mOrientation,
                         cubeDef,
                         AttackeePos, orientation,
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
                        mPos, mOrientation,
                        mCylinderSize.x, mCylinderSize.y,
                        AttackeePos, orientation,
                        mTarUnitBounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.RingType:
                {
                    if (Utility.RingHitDefineCollision(
                        mPos, mOrientation,
                        mRingSize.x, mRingSize.y, mRingSize.z,
                        AttackeePos, orientation,
                        mTarUnitBounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
            case ActionCommon.HitDefnitionFramType.FanType:
                {
                    if (Utility.FanHitDefineCollision(
                        mPos, mOrientation,
                        mFanSize.x, mFanSize.y,
                        mFanAngle.x, mFanAngle.y,
                        AttackeePos, orientation,
                        mTarUnitBounding))
                    {
                        hitSuccess = true;
                    }
                    break;
                }
        }
        if (hitSuccess)
        {
            if (!ShowEffectMgr.instance.CheckHitedEff(self,target))
                return hitSuccess;
            if (!ShowEffectMgr.instance.AddShowEffect(mData.SelfEffect, self, target))
                return hitSuccess;
            if (!string.IsNullOrEmpty(mData.HitedEffect))
            {
                float s = mData.HitedEffectScale * 0.01f;
                Vector3 forward = (mPos - mTarUnitPosition).normalized;
                GameEventManager.instance.EnQueue(new PlayEffectEvent(mData.HitedEffect, null, mTarUnitPosition, new Vector3(s, s, s), forward, 0, 0), true);
            }

            //// LY edit begin ////
            // 击中音效
            if (mOwner.CanPlaySound() == true && !string.IsNullOrEmpty(mData.HitedSound))
            {
                GameEventManager.instance.EnQueue(new PlaySound(mData.HitedSound), false);
            }
            //// LY edit end ////
        }
        return hitSuccess;
    }

    /// <summary>
    /// 检查攻击
    /// </summary>
    /// <param name="self"></param>
    /// <param name="target"></param>
    bool CheckHit(Unit self, Unit target)
    {
        bool hitSuccess = false;
        hitSuccess = CheckHitTarget(target);

        if (!hitSuccess)
            return false;
        ProcessHit(target);
        return true;
    }

    /// <summary>
    /// 处理攻击
    /// </summary>
    /// <param name="target"></param>
    public virtual void ProcessHit(Unit target)
    {
        // 设置攻击者的冲击速度及冲击时间。
        float lashTime = mData.AttackerTime;
        if (lashTime > 0 && !mOwner.DestroyState)
        {
            float lashX = mData.AttackerLash.Vector3Data_X;
            float lashY = mData.AttackerLash.Vector3Data_Y;
            float lashZ = mData.AttackerLash.Vector3Data_Z;
            if (lashX != 0 || lashY != 0 || lashZ != 0)
            {
                lashX *= 0.01f;
                lashY *= 0.01f;
                lashZ *= 0.01f;
                lashTime *= 0.001f;
                Vector3 forward = (target.Position - mOwner.Position).normalized;
                mOwner.ActionStatus.SetExternVelocity(lashX, lashY, lashZ, lashTime, forward);
            }
        }

        // 设置穿透次数
        HitedData hd = null;
        if (mData.SingleMaxHitCount > 0)
        {
            if (mHitedPassedMap.TryGetValue(target.UnitTrans.gameObject, out hd))
            {
                hd.cd = Utility.MilliSecToSec(mData.CoolDownTime);
                hd.hitedCount++;
            }
            else
            {
                hd = new HitedData();
                hd.cd = Utility.MilliSecToSec(mData.CoolDownTime);
                hd.hitedCount++;
                mHitedPassedMap.Add(target.UnitTrans.gameObject, hd);
            }
        }

        // 累加击中次数。
        mHitSucessCount++;

        Hit(target);
    }

    /// <summary>
    /// 处理攻击脚本
    /// </summary>
    /// <param name="script"></param>
    /// <param name="target"></param>
    void ProcessHitScript(string script, Unit target)
    {
        if (script == string.Empty)
            return;

        ExeScript.instance.ExeScriptCmd(script, target);
    }

    /// <summary>
    /// 处理攻击事件
    /// </summary>
    /// <param name="data"></param>
    /// <param name="targetPosition"></param>
    void ProcessAttackEvent(EventData data, Vector3 targetPosition)
    {
        switch ((ActionCommon.AttackEventType)data.EventType)
        {
            case ActionCommon.AttackEventType.AddUnit:
                {
                    if (data.UnitID != 0)
                        GameEventManager.instance.EnQueue(new AttackSummonUnitEvent(data, mOwner, targetPosition));
                    break;
                }
        }
    }

    /// <summary>
    /// 攻击目标
    /// </summary>
    /// <param name="target"></param>
    protected void Hit(Unit target)
    {
        if (mOwner == null)
            return;

        ActionStatus targetActionStatus = target.ActionStatus;
        ActionData targetAction = targetActionStatus.ActiveAction;

        float HitRadio = 100;
        int iHit = 1;// Random.Range(1, 1001);
        if (iHit > HitRadio) //未命中
            return;

        if (string.IsNullOrEmpty(mData.Script))
        {
            ProcessHitScript(mOwner.ActionStatus.ActionGroupData.HitScript, mOwner);
        }
        else
        {
            // 击中脚本
            ProcessHitScript(mData.Script, mOwner);
        }

        // 击中事件
        for (int i = 0; i < mData.AttackEventList.Count; ++i)
        {
            EventData evtdata = mData.AttackEventList[i];
            ProcessAttackEvent(evtdata, mTarUnitPosition);
        }

        ActionCommon.HitData hitData = new ActionCommon.HitData();
        if (mData.AttackLevel < targetActionStatus.ActionLevel)
        {
            // 产生霸体
            hitData.StraightTime = 0;
            hitData.LashX = 0;
            hitData.LashY = 0;
            hitData.LashZ = 0;
            hitData.LashTime = 0;
            hitData.HitAction = string.Empty;
        }
        else if (targetActionStatus.OnHit((ActionCommon.HitResultType)mData.HitResult))
        {
            hitData.StraightTime = (short)mData.AttackeeStraightTime;
            hitData.LashX = (short)mData.AttackeeLash.Vector3Data_X;
            hitData.LashY = (short)mData.AttackeeLash.Vector3Data_Y;
            hitData.LashZ = (short)mData.AttackeeLash.Vector3Data_Z;
            hitData.LashTime = (short)mData.AttackeeTime;
            hitData.HitAction = targetActionStatus.ActiveAction.AnimID;
        }
        hitData.AttackLevel = (byte)mData.AttackLevel;

        SendHitedTarget(target);

        target.mUnitOnHit.OnHit(mOwner, target, this, hitData);
    }

    #endregion
}
