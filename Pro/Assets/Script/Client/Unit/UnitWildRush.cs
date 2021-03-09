using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitWildRush
{
    public static readonly UnitWildRush instance = new UnitWildRush();

    private UnitWildRush() { }

    #region 字段
    /// <summary>
    /// 冲刺者
    /// </summary>
    private Unit mAttacker;
    /// <summary>
    /// 目标位置
    /// </summary>
    private Vector3 mTarPos;
    /// <summary>
    /// 冲刺方向
    /// </summary>
    private Vector3 mRushForward;
    /// <summary>
    /// 是否开始冲刺
    /// </summary>
    private bool isBeginRushing = false;
    /// <summary>
    /// 冲刺距离
    /// </summary>
    private const float mMaxRushDis = 49f;
    /// <summary>
    /// 不冲刺距离
    /// </summary>
    private const float mUnRushDis = 9f;
    /// <summary>
    /// 冲刺速度
    /// </summary>
    private float mRushSpeed = 0;
    #endregion

    #region 属性
    /// <summary>
    /// 是否运行中
    /// </summary>
    public bool Excuting = false;
    #endregion

    #region 私有方法
    /// <summary>
    ///设置信息
    /// </summary>
    /// <returns></returns>
    private void SetInfo(Unit unit, Vector3 tarPos)
    {
        mAttacker = unit;
        mTarPos = tarPos;
        mTarPos.y = UnitHelper.instance.GetTerrainHeight(tarPos);
        mRushForward = mTarPos - mAttacker.Position;
        mRushForward.y = 0;
        mRushSpeed = MoveSpeed.instance.MoveDic[MoveType.Rush];
    }

    /// <summary>
    /// 是否在不冲刺距离范围内
    /// </summary>
    /// <returns></returns>
    private bool InUnRushDis()
    {
        float dis = Vector3.SqrMagnitude(mRushForward);
        if (dis > mUnRushDis)
            return false;
        return true;
    }

    /// <summary>
    /// 是否在冲刺距离内
    /// </summary>
    /// <returns></returns>
    private bool InRushDis()
    {
        Vector3 forward = mTarPos - mAttacker.Position;
        float dis = Vector3.SqrMagnitude(forward);
        if (dis > mMaxRushDis)
            return false;
        forward.y = 0;
        mRushForward = forward;
        return true;
    }

    /// <summary>
    /// 是否在行走距离内
    /// </summary>
    /// <returns></returns>
    private bool InWalkDis()
    {
        float sqrDis = Vector3.SqrMagnitude(mRushForward);
        if (sqrDis > mMaxRushDis)
            return true;
        return false;
    }
    
    /// <summary>
    /// 开始冲刺
    /// </summary>
    /// <returns></returns>
    private bool BegRush()
    {
        bool inRushDis = InRushDis();
        if (inRushDis == false)
            return false;
        isBeginRushing = true;
        RushEffect.instance.ShowEffect(mAttacker);
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
        Excuting = false;
        isBeginRushing = false;
        RushEffect.instance.HideEffect();
    }

    /// <summary>
    /// 检查冲刺点
    /// </summary>
    /// <param name="nxtPos">下一冲刺位置</param>
    /// <param name="rshFwd">冲刺方向</param>
    /// <returns></returns>
    private bool ChkNxtRshPos(Vector3 nxtPos, Vector3 rshFwd)
    {
        Vector3 forward = mTarPos - nxtPos;
        forward.y = 0;
        float dot = Vector3.Dot(rshFwd, forward);
        if (dot > 0)
            return false;
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
    /// 冲刺和旋转
    /// </summary>
    private bool RushAndRotate()
    {
        if (!isBeginRushing)
            return false;
        Rotate(mRushForward.normalized);

        float speed = mRushSpeed * Time.deltaTime;
        Vector3 rushDelta = mRushForward.normalized * speed;
        if (ChkHit(mRushForward, rushDelta))
        {
            EndRush();
            mAttacker.ActionStatus.ChangeIdleAction();
            return true;
        }
        Vector3 nxtPos = mAttacker.Position + rushDelta;
        if (ChkNxtRshPos(nxtPos, mRushForward))
        {
            EndRush();
            NetMove.RequestMoveRush(mAttacker, mTarPos, mRushForward);
            mAttacker.Position = mTarPos;
            mAttacker.ActionStatus.ChangeIdleAction();
            return true;
        }
        NetMove.RequestMoveRush(mAttacker, nxtPos, mRushForward);
        mAttacker.ActionStatus.ChangeMoveAction();
        mAttacker.Position = nxtPos;
        return true;
    }

    /// <summary>
    /// 检查碰撞
    /// </summary>
    /// <param name="rshFwd">冲刺方向</param>
    /// <param name="rshDelta">冲刺距离</param>
    /// <returns></returns>
    private bool ChkHit(Vector3 rshFwd, Vector3 rshDelta)
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
    /// 检查行为条件
    /// </summary>
    /// <returns></returns>
    private bool ChkActCon()
    {
        if (Excuting == false)
            return false;
        if (mAttacker == null)
            return false;
        if (mAttacker.mUnitMove == null)
            return false;
        if (mAttacker.mUnitMove.IsJumping)
            return false;
        return true;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置冲刺信息
    /// </summary>
    /// <param name="tarPos"></param>
    public void SetRushInfo(Unit unit,Vector3 tarPos,uint mapId)
    {
        if (unit == null)
            return;
        SetInfo(unit,tarPos);
        if (mapId == User.instance.SceneId)
        {
            bool unRushDis = InUnRushDis();
            if (unRushDis)
                return;
            Excuting = true;
            bool inWalkDis = InWalkDis();
            if (inWalkDis == false)
                return;
            unit.mUnitMove.StartNav(tarPos, 1f, mapId);
        }
        else
        {
            Excuting = true;
            unit.mUnitMove.StartNav(tarPos, 1f, mapId);
        }
    }

    public void Update()
    {
        if (!ChkActCon())
            return;
        if (!UnitHelper.instance.CanMove(mAttacker))
            return;
        if (RushAndRotate())
            return;
        BegRush();
    }

    public void Clear()
    {
        mAttacker = null;
        EndRush();
    }
    #endregion
}
