using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using ProtoBuf;
using Loong.Game;

public class ChainLightning : HitAction
{
    float mSpeedLimit = 10000;
    float mSpeed = 0;
    ActionData mActionData = null;
    List<ChainLightningInfo> mCLIList = new List<ChainLightningInfo>();
    List<ChainLightningInfo> mClashCLIList = new List<ChainLightningInfo>();
    List<GameObject> mTargetList = new List<GameObject>();
    public override void ReInit()
    {
        base.ReInit();
        mSpeed = 0;
        mActionData = null;
        mCLIList.Clear();
        mClashCLIList.Clear();
        mTargetList.Clear();
    }

    public override void Init(ProtoBuf.AttackDefData data, Unit owner, string action, int harmSection)
    {
        base.Init(data, owner, action, harmSection);

        Vector3 startPos = owner.Position;
        Vector3 forward = owner.UnitTrans.forward;
        Vector3 endPos = mTarUnit.Position;
        endPos.y += mTarUnit.Collider.height * 0.5f;
        mSpeed = mData.BulletSpeed * 0.01f;
        mActionData = mOwner.ActionStatus.ActiveAction;
        mLifeTime = 0.0f;
        mTargetList.Clear();

        float ox = mData.EmitterPos.Vector3Data_X * 0.01f;
        float oy = mData.EmitterPos.Vector3Data_Y * 0.01f;
        float oz = mData.EmitterPos.Vector3Data_Z * 0.01f;
        GameObject go = new GameObject();
        go.transform.position = startPos;
        go.transform.forward = forward;
        Vector3 pos = go.transform.TransformPoint(ox, oy, oz);
        AddChainLightning(pos, endPos, forward, mTarUnit);
        GameObject.Destroy(go);
    }

    /// <summary>
    /// 添加一个闪电链
    /// </summary>
    void AddChainLightning(Vector3 startPos, Vector3 endPos, Vector3 forward, Unit target)
    {
        ChainLightningInfo cli = new ChainLightningInfo();
        cli.startPos = startPos;
        cli.lastPos = cli.startPos;
        cli.curPos = cli.startPos;
        cli.endPos = endPos;
        cli.forward = (endPos - startPos).normalized;
        cli.isPlayingEffect = false;
        cli.speed = mData.BulletSpeed * 0.01f;
        cli.acceleration = mData.AccelerationSpeed * 0.01f;
        cli.target = target;
        cli.isHitTarget = false;
        cli.hideEffectFrame = 0;
        mCLIList.Add(cli);
        mTargetList.Add(target.UnitTrans.gameObject);
    }

    public override void Update()
    {
        if (mOwner == null || mLifeTime >= 6f || mLifeTime > mDuration)
            mOutofDate = true;
        if (mOutofDate)
        {
            ClearChainLightnings();
            return;
        }
        UpdateCLIList();
        UpdateClashCLIList();
        if (mCLIList.Count == 0 && mClashCLIList.Count == 0)
            mOutofDate = true;
        mLifeTime += Time.deltaTime;
    }

    /// <summary>
    /// 更新有效闪电链列表
    /// </summary>
    private void UpdateCLIList()
    {
        for (int i = 0; i < mCLIList.Count; )
        {
            LoadEffect(mCLIList[i]);
            UpdateSpeed(mCLIList[i]);
            UpdateCurPos(mCLIList[i]);
            if (IsHitTarget(mCLIList[i]))
                ProcessHit(mCLIList[i].target);
            if (!UpdateMoveInfoEffected(mCLIList[i]))
            {
                Unit target = FindNearestTarget(mCLIList[i]);
                mCLIList[i].lastPos = mCLIList[i].startPos;
                mCLIList[i].speed = mSpeed;
                mCLIList[i].curPos = mCLIList[i].startPos;
                if (target != null)
                {
                    Vector3 startPos = mCLIList[i].endPos;
                    Vector3 endPos = target.Position;
                    endPos.y += target.Collider.height * 0.5f;
                    Vector3 forward = (endPos - startPos).normalized;
                    AddChainLightning(startPos, endPos, forward, target);
                }
                mClashCLIList.Add(mCLIList[i]);
                mCLIList.RemoveAt(i);
                break;
            }
            i++;
        }
    }

    /// <summary>
    /// 更新呆销毁的闪电链列表
    /// </summary>
    private void UpdateClashCLIList()
    {
        for (int i = 0; i < mClashCLIList.Count; )
        {
            UpdateSpeed(mClashCLIList[i]);
            UpdateCurPos(mClashCLIList[i]);
            if (HideChainLightningEffect(mClashCLIList[i]))
            {
                mClashCLIList[i].Clear(mData.SelfEffect);
                mClashCLIList.RemoveAt(i);
                break;
            }
            i++;
        }
    }

    /// <summary>
    /// 更新速度
    /// </summary>
    private void UpdateSpeed(ChainLightningInfo info)
    {
        info.speed += info.acceleration * Time.deltaTime;
        info.speed = Mathf.Min(info.speed, mSpeedLimit);
    }

    /// <summary>
    /// 更新当前位置
    /// </summary>
    private void UpdateCurPos(ChainLightningInfo info)
    {
        info.lastPos = info.curPos;
        float distance = info.speed * Time.deltaTime;
        info.curPos += info.forward * distance;
    }

    /// <summary>
    /// 更新移动路径有效性
    /// </summary>
    private bool UpdateMoveInfoEffected(ChainLightningInfo info)
    {
        bool result = true;
        if (Vector3.Angle(info.curPos - info.endPos, info.lastPos - info.endPos) > 90)
            result = false;
        return result;
    }

    /// <summary>
    /// 闪电链特效加载
    /// </summary>
    private void LoadEffect(ChainLightningInfo info)
    {
        if (info.isPlayingEffect)
            return;
        info.isPlayingEffect = true;
        AssetMgr.LoadPrefab(mData.SelfEffect,(effect) =>
            {
                effect.transform.parent = null;
                effect.SetActive(true);
                info.effect = effect;
                UpdateEffect(info);
            });
    }

    /// <summary>
    /// 更新闪电链特效位置
    /// </summary>
    private void UpdateEffect(ChainLightningInfo info)
    {
        if (info.effect == null)
            return;
        LineRenderer lineRenderer = info.effect.GetComponentInChildren<LineRenderer>();
        if (lineRenderer == null)
            return;
        lineRenderer.SetPosition(0, info.startPos);
        lineRenderer.SetPosition(1, info.endPos);
    }

    /// <summary>
    /// 判断是否击中目标
    /// </summary>
    private bool IsHitTarget(ChainLightningInfo info)
    {
        if (info.isHitTarget)
            return false;
        Unit target = info.target;
        Vector3 curPos = info.curPos;
        float curOrientation = Mathf.Atan2(info.forward.x, info.forward.z);
        Vector3 endPos = info.endPos;
        float endOrientation = Mathf.Atan2(info.target.UnitTrans.forward.x, info.target.UnitTrans.forward.z);

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

        Utility.Rotate(ref BoundOffsetX, ref BoundOffsetZ, endOrientation);

        bool hitSuccess = false;
        switch ((ActionCommon.HitDefnitionFramType)mData.FramType)
        {
            case ActionCommon.HitDefnitionFramType.CuboidType:
            case ActionCommon.HitDefnitionFramType.SomatoType:
                {
                    Vector3 vBounding = targetActionStatus.Bounding;
                    Vector3 cubeDef = Vector3.Scale(mCubeHitDefSize, InterplateValue);
                    if (Utility.RectangleHitDefineCollision(
                         curPos, curOrientation,
                         cubeDef,
                         endPos, endOrientation,
                         vBounding))
                    {
                        hitSuccess = true;
                        info.isHitTarget = true;
                    }
                    break;
                }
        }
        return hitSuccess;
    }

    /// <summary>
    /// 查找最近目标
    /// </summary>
    private Unit FindNearestTarget(ChainLightningInfo info)
    {
        if (mTargetList.Count >= mData.AllMaxHitCount)
            return null;
        List<Unit> list = UnitMgr.instance.UnitList;
        float tempDis = float.MaxValue;
        Unit finalTarget = null;
        int unitcount = list.Count;
        for (int i = 0; i < unitcount; i++)
        {
            Unit target = list[i];
            if (mTargetList.Contains(target.UnitTrans.gameObject))
                continue;
            if (!HitHelper.instance.CanHitTarget(mOwner, target, mActionData))
                continue;
            Vector3 endPos = target.Position;
            endPos.y = target.Collider.height * 0.5f;
            float distance = Vector3.SqrMagnitude(info.endPos - endPos);
            if (distance <= 400 && distance <= tempDis)
            {
                finalTarget = target;
                tempDis = distance;
            }
        }
        return finalTarget;
    }

    /// <summary>
    /// 隐藏闪电链
    /// </summary>
    private bool HideChainLightningEffect(ChainLightningInfo info)
    {
        if (info.hideEffectFrame > 4)
            return true;
        info.hideEffectFrame++;
        return false;
    }

    /// <summary>
    /// 清除所有闪电链特效
    /// </summary>
    private void ClearChainLightnings()
    {
        for (int i = 0; i < mCLIList.Count; i++)
            mCLIList[i].Clear(mData.SelfEffect);
        mCLIList.Clear();
        for (int i = 0; i < mClashCLIList.Count; i++)
            mClashCLIList[i].Clear(mData.SelfEffect);
        mClashCLIList.Clear();
    }
}
