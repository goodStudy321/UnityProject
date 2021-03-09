using UnityEngine;
using System.Collections;

public class LaserLightHit : HitAction
{
    /// <summary>
    /// 线渲染器
    /// </summary>
    LineRenderer mLineRenderer = null;
    private float mSpeed;
    private float mMaxSpeed;
    private float mAcceleration;
    /// <summary>
    /// 路径移动点数量
    /// </summary>
    private int mPathListCount = 0;
    /// <summary>
    /// 距离
    /// </summary>
    private float mDistance = 0;
    /// <summary>
    /// 单位半径
    /// </summary>
    private float mUnitRadius = 0;
    /// <summary>
    /// 击中目标相对高度
    /// </summary>
    private float mHitHeight = 0;
    /// <summary>
    /// 攻击位置
    /// </summary>
    private Vector3 mHitPos = Vector3.zero;

    /// <summary>
    /// 重置
    /// </summary>
    public override void ReInit()
    {
        base.ReInit();
        mLineRenderer = null;
        mSpeed = 0;
        mMaxSpeed = 0;
        mAcceleration = 0;
        mPathListCount = 0;
        mDistance = 0;
        mUnitRadius = 0;
        mHitHeight = 0;
        mHitPos = Vector3.zero;
    }

    /// <summary>
    /// 初始化
    /// </summary>
    public override void Init(ProtoBuf.AttackDefData data, Unit owner, string action, int harmSection)
    {
        base.Init(data, owner, action, harmSection);
        mLineRenderer = null;

        mPos = mOwner.Position;
        float ox = mData.EmitterPos.Vector3Data_X * 0.01f;
        float oy = mData.EmitterPos.Vector3Data_Y * 0.01f;
        float oz = mData.EmitterPos.Vector3Data_Z * 0.01f;
        
        Vector3 offset = new Vector3(ox,oy,oz);
        mInitPos = mAttackDefMatrix.MultiplyPoint(offset);
        mPos = mInitPos;
        CalculateForward();
        //矫正mAttackDefMatrix
        MakeAttackMatrix();

        mLifeTime = 0.0f;
        mSpeed = mData.BulletSpeed * 0.01f;
        mMaxSpeed = mData.BulletSpeed * 0.01f;
        mAcceleration = mData.AccelerationSpeed * 0.01f;
        mPathListCount = mData.PathList.Count;
        if (mPathListCount > 1)
            return;

        if(mTarUnit == null)
            mOutofDate = true;
        mUnitRadius = SkillHelper.instance.GetUnitModelRadius(mTarUnit);
        mHitPos = CalculateRealHitPos();
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
        if (UpdatePathPos())
            return;
        UpdatePointPos(deltaTime);
    }

    /// <summary>
    /// 更新路径激光位置
    /// </summary>
    protected bool UpdatePathPos()
    {
        if (mPathListCount <= 1)
            return false;
        base.Update();
        UpdateEffectPosition();
        return true;
    }

    /// <summary>
    /// 更新点对点激光位置
    /// </summary>
    protected void UpdatePointPos(float deltaTime)
    {
        if (UpdateDelayTime(deltaTime))
            return;
        if (mOwner == null || mLifeTime >= mDuration || MaxCountOutDate())
            mOutofDate = true;
        UpdatePos(0);
        MakeAttackMatrix();
        CheckSelfEffect(deltaTime);
        CheckTargetHit(mOwner, mTarUnit);
        UpdateEffectPosition();
        UpdateHitCD(deltaTime);
        mLifeTime += deltaTime;
        if (ShowAttackFrame)
            UpdateDebugFrame();
    }

    /// <summary>
    /// 更新特效位置
    /// </summary>
    protected void UpdateEffectPosition()
    {
        if (mSelfEffectGo == null)
            return;
        if (mLineRenderer == null)
        {
            mLineRenderer = mSelfEffectGo.GetComponentInChildren<LineRenderer>();
            if (mLineRenderer == null)
                return;
        }
        mLineRenderer.SetPosition(0, mInitPos);
        mLineRenderer.SetPosition(1, mPos);
        Transform childTrans = null;
        if (mSelfEffectGo.transform.childCount > 0)
            childTrans = mSelfEffectGo.transform.GetChild(0);
        if (childTrans == null)
            return;
        for (int i = 0; i < childTrans.childCount; i++)
        {
            if (i == 0)
            {
                Transform trans = childTrans.GetChild(0);
                if (trans == null)
                    continue;
                trans.position = mPos;
            }
            else if (i == 1)
            {
                Transform trans = childTrans.GetChild(1);
                if (trans == null)
                    break;
                trans.position = childTrans.InverseTransformPoint(mInitPos);
                break;
            }
        }
    }

    /// <summary>
    /// 更新位置
    /// </summary>
    /// <param name="ratio"></param>
    protected void UpdatePos(float ratio)
    {
        if (mSpeed == 0)
            return;
        if (mDistance == 0)
            return;
        if (mData.FllowReleaser != 0 ||
            mData.FramType == (int)ActionCommon.HitDefnitionFramType.SomatoType)
        {
            mInitPos = mOwner.Position;
        }

        ReFreshHitPosAndDis();
        float curLengh = GetCurLengh();
        ratio = curLengh / mDistance;
        mPos = GetBeZierPos(mHitPos, ratio);
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
    /// 刷新总距离
    /// </summary>
    protected void ReFreshHitPosAndDis()
    {
        if (!mData.IsTrackTarget)
            return;
        if (Vector3.SqrMagnitude(mTarUnitOriginalPosition - mTarUnitPosition) < 0.04f)
            return;
        SetTargetHitPos();
        mDistance = CalculateDistance();
    }

    /// <summary>
    /// 计算距离
    /// </summary>
    /// <returns></returns>
    protected float CalculateDistance()
    {
        float dis = 0;
        dis = Vector3.Distance(mInitPos, mHitPos);
        if (dis == 0)
            dis = 0.1f;
        return dis;
    }

    /// <summary>
    /// 获取贝塞尔位置
    /// </summary>
    /// <param name="ratio"></param>
    /// <returns></returns>
    protected Vector3 GetBeZierPos(Vector3 targetPos, float ratio)
    {
        Vector3 pos = mPos;
        pos = BezierTool.GetLinearPoint(mInitPos, targetPos, ratio);
        return pos;
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
    /// 更新方向
    /// </summary>
    protected void CalculateForward()
    {
        Vector3 forward = GetTargetHitPos() - mInitPos;
        mForward = forward.normalized;
    }

    /// <summary>
    /// 获取目标真正攻击位置
    /// </summary>
    /// <returns></returns>
    protected Vector3 CalculateRealHitPos()
    {
        CalculateForward();
        float heighPercent = mData.HitHeightPersent * 0.01f;
        mHitHeight = mTarUnitBounding.y * heighPercent;
        Vector3 deltaPos = -mForward * mUnitRadius;
        Vector3 pos = mTarUnitPosition + deltaPos;
        pos.y += mHitHeight;
        return pos;
    }

    /// <summary>
    /// 设置目标攻击位置
    /// </summary>
    protected void  SetTargetHitPos()
    {
        if (!mData.IsTrackTarget)
            return;
        mHitPos = CalculateRealHitPos();
    }
}
