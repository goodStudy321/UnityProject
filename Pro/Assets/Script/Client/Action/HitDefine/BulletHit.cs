using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Loong.Game;

public class BulletHit : HitAction
{
    /// <summary>
    /// 子弹速度
    /// </summary>
    private float mSpeed;
    /// <summary>
    /// 最大速度
    /// </summary>
    private float mMaxSpeed;
    /// <summary>
    /// 子弹加速度
    /// </summary>
    private float mAcceleration;
    /// <summary>
    /// 距离
    /// </summary>
    private float mDistance = 0;
    /// <summary>
    /// 正在改变位置
    /// </summary>
    private bool mChangingPos = false;
    /// <summary>
    /// 上一帧子弹位置（针对曲线子弹）
    /// </summary>
    private Vector3 mLastBulletPos = Vector3.zero;
    /// <summary>
    /// 中间位置路径
    /// </summary>
    private List<Vector3> mPosList = new List<Vector3>();

    /// <summary>
    /// 重置
    /// </summary>
    public override void ReInit()
    {
        base.ReInit();
        mSpeed = 0;
        mMaxSpeed = 0;
        mAcceleration = 0;
        mDistance = 0;
        mChangingPos = false;
        mLastBulletPos = Vector3.zero;
        mPosList.Clear();
    }

    /// <summary>
    /// 初始化
    /// </summary>
    public override void Init(ProtoBuf.AttackDefData data, Unit owner, string action, int harmSection)
    {
        mData = data;
        mOwner = owner;
        mAction = action;
        mPos = mOwner.Position;
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
        ResetAttackFram();

        mPos = mOwner.Position;
        float ox = mData.EmitterPos.Vector3Data_X * 0.01f;
        float oy = mData.EmitterPos.Vector3Data_Y * 0.01f;
        float oz = mData.EmitterPos.Vector3Data_Z * 0.01f;
        //初始化mAttackDefMatrix
        MakeAttackMatrix();
        Vector3 offset = new Vector3(ox, oy, oz);
        mInitPos = mAttackDefMatrix.MultiplyPoint(offset);
        mPos = mInitPos;
        //矫正mAttackDefMatrix
        MakeAttackMatrix();


        Vector3 targetPos = GetTargetHitPos();
        Vector3 preNextPos = GetBeZierPos(targetPos, 0.01f);
        mForward = preNextPos - mInitPos;
        CheckSelfEffect(0);
        UpdateEffectPosition(mSelfEffectGo);
        mLastBulletPos = mInitPos;
        mSpeed = mData.BulletSpeed * 0.01f;
        mMaxSpeed = mData.MaxSpeed * 0.01f;
        mAcceleration = mData.AccelerationSpeed * 0.01f;
        if (mTarUnit == null)
            mOutofDate = true;
        GetBezierMidPath();
        mDistance = CalculateDistance();
    }

    /// <summary>
    /// 生成矩阵
    /// </summary>
    protected override void MakeAttackMatrix()
    {
        mAttackDefQuat = Quaternion.LookRotation(mForward);
        mAttackDefMatrix = Matrix4x4.TRS(mPos, mAttackDefQuat, Vector3.one);
    }

    public override void Update()
    {
        float deltaTime = Time.deltaTime;
        if (UpdateDelayTime(deltaTime))
            return;

        if (mOwner == null || mLifeTime >= 6f || MaxCountOutDate())
            mOutofDate = true;

        if (mOutofDate)
            return;

        UpdatePosition(0);

        UpdateForward();

        MakeAttackMatrix();

        CheckSelfEffect(deltaTime);
        
        UpdateEffectPosition(mSelfEffectGo);

        if (CheckTargetHit(mOwner, mTarUnit))
        {
            mOutofDate = true;
            return;
        }

        UpdateHitCD(deltaTime);
        
        if(ShowAttackFrame) UpdateDebugFrame();

        mLifeTime += deltaTime;
    }

    /// <summary>
    /// 更新位置
    /// </summary>
    /// <param name="ratio"></param>
    protected override void UpdatePosition(float ratio)
    {
        if (mData.FllowReleaser != 0 ||
            mData.FramType == (int)ActionCommon.HitDefnitionFramType.SomatoType)
        {
            mInitPos = mOwner.Position;
        }

        ReFreshDistance();
        float curLengh = GetCurLengh();
        ratio = curLengh / mDistance;
        Vector3 targetPos = GetTargetHitPos();
        mPos = GetBeZierPos(targetPos, ratio);
        if (Vector3.SqrMagnitude(mPos - targetPos) < 0.01f)
            OutDate = true;
    }

    /// <summary>
    /// 获取当前飞行距离长度
    /// </summary>
    /// <returns></returns>
    protected float GetCurLengh()
    {
        float curLengh = mSpeed * mLifeTime + 0.5f * mAcceleration * mLifeTime * mLifeTime;
        if (mMaxSpeed == 0)
            return curLengh;
        float maxLengh = mMaxSpeed * mLifeTime;
        if (curLengh <= maxLengh)
            return curLengh;
        return maxLengh;
    }

    /// <summary>
    /// 获取贝塞尔位置
    /// </summary>
    /// <param name="ratio"></param>
    /// <returns></returns>
    protected Vector3 GetBeZierPos(Vector3 targetPos, float ratio)
    {
        Vector3 pos = mPos;
        int count = mPosList.Count;
        if (count == 0)
            pos = BezierTool.GetLinearPoint(mInitPos, targetPos, ratio);
        else if (count == 1)
            pos = BezierTool.GetQuadraticCurvePoint(mInitPos, mPosList[0], targetPos, ratio);
        else
            pos = BezierTool.GetCubicCurvePoint(mInitPos, mPosList[0], mPosList[1], targetPos, ratio);
        return pos;
    }

    /// <summary>
    /// 获取贝塞尔中间点
    /// </summary>
    protected void GetBezierMidPath()
    {
        mPosList.Clear();
        if (mData.BezierMidPath.Count == 0)
            return;
        for (int i = 0; i < mData.BezierMidPath.Count; i++)
        {
            ProtoBuf.Vector3Data editPos = mData.BezierMidPath[i];
            if (editPos.Vector3Data_Z == 0)
                continue;
            Vector3 pos = Vector3.zero;
            Utility.Vector3_Copy(editPos, ref pos);
            pos = GetEditorPos(pos);
            mPosList.Add(pos);
        }
    }

    /// <summary>
    /// 获取目标攻击位置
    /// </summary>
    /// <returns></returns>
    protected Vector3 GetTargetHitPos()
    {
        Vector3 targetPos = mTarUnitPosition;
        float heighPercent = mData.HitHeightPersent * 0.01f;
        float hitHeight = mTarUnitBounding.y * heighPercent;
        targetPos.y += hitHeight;
        return targetPos;
    }

    /// <summary>
    /// 获取编辑器位置
    /// </summary>
    /// <param name="pos"></param>
    /// <returns></returns>
    protected Vector3 GetEditorPos(Vector3 pos)
    {
        Vector3 targetPos = GetTargetHitPos();
        Vector3 forward = targetPos - mInitPos;
        //小于1不作曲线
        if(Vector3.SqrMagnitude(forward) < 1)
            return mInitPos;
        float dis = Vector3.Distance(mInitPos, targetPos);
        Vector3 position = forward.normalized * pos.z*0.01f * dis;
        position += mInitPos;
        pos.z = 0;
        pos *= 0.01f;
        Quaternion quaternion = Quaternion.LookRotation(forward);
        Matrix4x4 matrix = Matrix4x4.TRS(position, quaternion, Vector3.one);
        position = matrix.MultiplyPoint(pos);
        return position;
    }

    /// <summary>
    /// 计算距离
    /// </summary>
    /// <returns></returns>
    protected float CalculateDistance()
    {
        float dis = 0;
        int lengh = mPosList.Count;
        Vector3 targetPos = GetTargetHitPos();
        if (lengh == 0)
            dis = Vector3.Distance(mInitPos, targetPos);
        else if(lengh == 1)
        {
            int count = 10;
            for(int i = 0; i < 10; i++)
            {
                float weight = i / (float)count;
                float weight1 = (i + 1) / (float)count;
                Vector3 startPos = BezierTool.GetQuadraticCurvePoint(mInitPos, mPosList[0], targetPos, weight);
                Vector3 endPos = BezierTool.GetQuadraticCurvePoint(mInitPos, mPosList[0], targetPos, weight1);
                dis += Vector3.Distance(startPos,endPos);
            }
        }
        else
        {
            int count = 20;
            for (int i = 0; i < 10; i++)
            {
                float weight = i / (float)count;
                float weight1 = (i + 1) / (float)count;
                Vector3 startPos = BezierTool.GetCubicCurvePoint(mInitPos, mPosList[0], mPosList[1], targetPos, weight);
                Vector3 endPos = BezierTool.GetCubicCurvePoint(mInitPos, mPosList[0], mPosList[1], targetPos, weight1);
                dis += Vector3.Distance(startPos, endPos);
            }
        }
        if (dis == 0)
            dis = 0.1f;
        return dis;
    }

    /// <summary>
    /// 刷新总距离
    /// </summary>
    protected void ReFreshDistance()
    {
        if (!mData.IsTrackTarget)
            return;
        if (Vector3.SqrMagnitude(mTarUnitOriginalPosition - mTarUnitPosition) < 0.04f)
        {
            mChangingPos = false;
            return;
        }
        mChangingPos = true;
        mDistance = CalculateDistance();
    }

    /// <summary>
    /// 更新方向
    /// </summary>
    protected void UpdateForward()
    {
        if (mLifeTime == 0)
            return;
        Vector3 forward = mPos - mLastBulletPos;
        //防止目标位置不断改变时方向不断抖动
        if(mChangingPos)
            mForward = Vector3.Lerp(mForward, forward, 0.1f);
        else
            mForward = forward;
        mLastBulletPos = mPos;
    }
}
