using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 行走
/// </summary>
public class PFWalk : PFActionBase
{
    /// <summary>
    /// 默认停止距离
    /// </summary>
    protected static readonly float DEF_STOP_DIS = 0.2f;

    /// <summary>
    /// 目标点坐标
    /// </summary>
    protected Vector3 mPathEndPos = Vector3.zero;
    /// <summary>
    /// 默认速度
    /// </summary>
    protected float mInitSpeed = 1.0f;
    /// <summary>
    /// 移动速度
    /// </summary>
    protected float mMoveSpeed = 1.0f;
    /// <summary>
    /// 终点判断距离
    /// </summary>
    protected float mLastDis = 0.2f;
    /// <summary>
    /// 当前判断停止距离
    /// </summary>
    protected float mStopDis = 0f;
    /// <summary>
    /// 移动旋转速度
    /// </summary>
    //protected readonly float mRotateSpeed = 9f;
    /// <summary>
    /// 跟随路径使用默认速度
    /// </summary>
    protected bool mFLUseDefSpd = false;

    /// <summary>
    /// 当前地图行走路径
    /// </summary>
    protected WalkPath mPath = null;
    /// <summary>
    /// 以区块划分，区块内可以有多条子路径
    /// </summary>
    protected BlockPath mBlockPath = null;
    /// <summary>
    /// 当前执行最小路径(路径最小单位，存在于区块内)
    /// </summary>
    protected SmallPath mSmallPath = null;

    /// <summary>
    /// 当前跳转口Id
    /// </summary>
    protected uint mCurPortalId = 0;
    /// <summary>
    /// 跳转到跳转口的Id
    /// </summary>
    protected uint mToPortalId = 0;
    /// <summary>
    /// 等待路径返回
    /// </summary>
    protected bool mWaitCalPath = false;


    public PFWalk() : base()
    {

    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="path"></param>
    /// <param name="stopDis"></param>
    /// <param name="finCB">返回值
    /// 0：中断
    /// 1：成功
    /// 2：需要重新获取路径
    /// </param>
    public PFWalk(Unit unit, Vector3 desPos, float moveSpd, float stopDis, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
        : base(unit, preActCB, finCB)
    {
        mActionState = ActionState.FS_WALK;
        mPathEndPos = desPos;
        mInitSpeed = moveSpd;
        mMoveSpeed = moveSpd;
        if(stopDis < 0)
        {
            mLastDis = DEF_STOP_DIS;
        }
        else if(stopDis == 0)
        {
            mLastDis = 0.01f;
        }
        else
        {
            mLastDis = stopDis;
        }

        mCanBreak = true;
        mWaitCalPath = false;
    }

    public void SetInitVal(Unit unit, Vector3 desPos, float moveSpd, float stopDis, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
    {
        base.SetInitVal(unit, preActCB, finCB);

        mActionState = ActionState.FS_WALK;
        mPathEndPos = desPos;
        mInitSpeed = moveSpd;
        mMoveSpeed = moveSpd;
        if (stopDis < 0)
        {
            mLastDis = DEF_STOP_DIS;
        }
        else if (stopDis == 0)
        {
            mLastDis = 0.01f;
        }
        else
        {
            mLastDis = stopDis;
        }

        mCanBreak = true;
        mWaitCalPath = false;
    }

    public override void Clear()
    {
        base.Clear();

        mPathEndPos = Vector3.zero;

        mInitSpeed = 1.0f;
        mMoveSpeed = 1.0f;
        mLastDis = 0.2f;
        mStopDis = 0f;
        mFLUseDefSpd = false;
        mSmallPath = null;
        mCurPortalId = 0;
        mToPortalId = 0;
        mWaitCalPath = false;
}

    public override void Start()
    {
        if(mUnit == null)
        {
            if(mFinCB != null)
            {
                mFinCB(mActionState, ResultType.RT_Unexpect);
            }
            return;
        }

        base.Start();

        AutoMountMgr.instance.StartTimer(mUnit);
        NavMoveBuff.instance.StartTimer(mUnit);
        mWaitCalPath = true;
        MapPathMgr.instance.InsertInQueue(mUnit.Position, mPathEndPos, SetPath);
    }

    public void Start2(WalkPath path)
    {
        base.Start();

        AutoMountMgr.instance.StartTimer(mUnit);
        NavMoveBuff.instance.StartTimer(mUnit);
        mWaitCalPath = true;
        SetPath(path);
    }

    public override void Break(ResultType bType)
    {
        StopWalkAnim();
        mWaitCalPath = false;
        UnitStopSendPos();
        base.Break(bType);
    }

    public override void Update(float dTime)
    {
        base.Update(dTime);

        if(mWaitCalPath == true)
        {
            return;
        }

        if (IsSmallPathFinish() == true)
        {
            UnitStopSendPos();
            SmallPathFinish();
            return;
        }

        Vector3 nowCalPoint = mUnit.Position;
        Vector3 nextPathPoint = mSmallPath.mPathPoints[0];
        Vector3 nextCalPoint = nextPathPoint;
        nowCalPoint.y = 0;
        nextCalPoint.y = 0;

        /// 角色与目标路点距离 ///
        float desDis = Vector3.Distance(nowCalPoint, nextCalPoint);

        /// 已经到达目标路点 ///
        if (desDis <= mStopDis)
        {
            /// 调整朝向 ///
            SetUnitRot(nextPathPoint);
            mSmallPath.mPathPoints.RemoveAt(0);

            if (IsSmallPathFinish() == true)
            {
                UnitStopSendPos();
                SmallPathFinish();
                return;
            }
            //同步下一路点
            else
            {
                CheckStopDis();
                NetMove.SendMove(mUnit, mSmallPath.mPathPoints[0], SendMoveType.SendMovePoint);
            }
        }

        /// 限制最大移动时间 ///
        float deltaTime = Time.deltaTime > 0.05f ? 0.05f : Time.deltaTime;
        /// 将要移动到的位置 ///
        Vector3 trendPos = Vector3.MoveTowards(mUnit.Position, nextPathPoint, deltaTime * mMoveSpeed);
        trendPos.y = 0;
        float trendDesDis = Vector3.Distance(nowCalPoint, trendPos);
        /// 如果将要移动距离超出目标与路点距离 ///
        if(trendDesDis > desDis)
        {
            /// 调整朝向 ///
            SetUnitRot(nextPathPoint);
            /// 改变位置 ///
            mUnit.Position = nextPathPoint;
            NetMove.SendMove(mUnit, mUnit.Position, SendMoveType.SendMoveRoleWalk);

            mSmallPath.mPathPoints.RemoveAt(0);
            if (IsSmallPathFinish() == true)
            {
                UnitStopSendPos();
                SmallPathFinish();
            }

            return;
        }

        //////////////// 检测是否进入不可行走区域 ////////////////
        
        AsNode tNode = MapPathMgr.instance.FindClosestNode(trendPos);
        /// 重新寻路 ///
        if (tNode == null)
        {
            tNode = MapPathMgr.instance.FindClosestNodeNoSelf(mUnit.Position);
            if(tNode != null)
            {
                //MapPathMgr.instance.InsertInQueue(mUnit.Position, mPathEndPos, SetPath);
                MapPathMgr.instance.InsertInQueue(tNode.pos, mPathEndPos, SetPath);
            }
            else
            {
#if UNITY_EDITOR
                iTrace.eError("LY", "Can not find start node !!! ");
#endif
                Break(ResultType.RT_Unexpect);
            }
            return;
        }

        ////////////////////////////////////////////////////////

        /// 如果角色在待机状态，调用行走动作 ///
        if (mUnit.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Idle)
        {
            mUnit.ActionStatus.ChangeMoveAction();
        }

        /// 改变位置 ///
        mUnit.Position = Vector3.MoveTowards(mUnit.Position, nextPathPoint, deltaTime * mMoveSpeed);
        /// 调整朝向 ///
        SetUnitRot(nextPathPoint);

        NetMove.SendMove(mUnit, mUnit.Position, SendMoveType.SendMoveRoleWalk);
    }

    /// <summary>
    /// 路径设置返回
    /// </summary>
    /// <param name="path"></param>
    protected virtual void SetPath(WalkPath path)
    {
        mWaitCalPath = false;
        if (path == null || path.mHasPath == false || path.mPathList == null || path.mPathList.Count <= 0)
        {
            iTrace.eError("LY", "Can not find path !!! ");
            Break(ResultType.RT_Unexpect);
            //Break(AsPathfinding.PathResultType.PRT_NOPATH);
            return;
        }

        mPath = path;
        mBlockPath = mPath.PopFirstPath();
        if(mBlockPath == null)
        {
            iTrace.eError("LY", "PFWalk::SetPath BlockPath is null !!! ");
            Break(ResultType.RT_Unexpect);
            return;
        }

        mSmallPath = mBlockPath.PopFirstPath();
        if(mSmallPath == null)
        {
            iTrace.eError("LY", "PFWalk::SetPath SmallPath is null !!! ");
            Break(ResultType.RT_Unexpect);
            return;
        }

        //mSmallPath.mPathPoints.RemoveAt(0);
        CheckStopDis();
        if(mSmallPath.mPathPoints.Count > 0)
        {
            NetMove.SendMove(mUnit, mSmallPath.mPathPoints[0], SendMoveType.SendMovePoint);
        }
        mUnit.ActionStatus.ChangeMoveAction();
    }

    /// <summary>
    /// 检测行走停止距离
    /// </summary>
    protected void CheckStopDis()
    {
        mStopDis = 0.01f;

        if (mBlockPath != null && mBlockPath.mPathList != null && mBlockPath.mPathList.Count > 0)
        {
            return;
        }

        if (mSmallPath != null && mSmallPath.mPathPoints != null && mSmallPath.mPathPoints.Count > 1)
        {
            return;
        }

        mStopDis = mLastDis;
    }

    protected void UnitStopSendPos()
    {
        if (mUnit == null || mUnit.UnitTrans == null)
        {
            return;
        }

        long sendPot = NetMove.GetPointInfo(mUnit.Position, mUnit.UnitTrans.localEulerAngles.y);
        NetMove.RequestStopMove(sendPot);
    }

    public override void SetMoveSpd(float spd)
    {
        mMoveSpeed = spd;
    }

    /// <summary>
    /// 检查最小路径是否完成
    /// </summary>
    /// <returns></returns>
    protected bool IsSmallPathFinish()
    {
        if(mSmallPath == null || mSmallPath.mPathPoints == null || mSmallPath.mPathPoints.Count <= 0)
        {
            return true;
        }
        return false;
    }

    /// <summary>
    /// 最小路径完成
    /// </summary>
    protected void SmallPathFinish()
    {
        if (mSmallPath == null || mSmallPath.mWaitTimeAtEnd <= 0)
        {
            WaitFinish();
            return;
        }

        StopWalkAnim();
        mRecoveryCB = WaitFinish;
        mPreActionNeed(ActionState.FS_WAIT, mUnit, mSmallPath.mWaitTimeAtEnd);
    }

    /// <summary>
    /// 区块路径完成
    /// </summary>
    protected void BlockPathFinish()
    {
        if (mBlockPath != null)
        {
            mCurPortalId = mBlockPath.endPortalId;
            mToPortalId = mBlockPath.toPortalId;
        }
        else
        {
            mCurPortalId = 0;
            mToPortalId = 0;
        }

        /// 本地图寻路已经完成 ///
        if (mPath == null || mPath.mPathList.Count <= 0)
        {
            WalkPathFinish();
        }
        /// 到达跳转点 ///
        else
        {
            mBlockPath = mPath.PopFirstPath();

            PortalFig tPortal = MapPathMgr.instance.MapAssis.GetPortalFigById(mCurPortalId);
            if (tPortal == null)
            {
                JumpFinishCallBack();
                return;
            }
            else
            {
                /// 错误情况 ///
                if (tPortal.mLinkMapId != MapPathMgr.instance.CurMapId)
                {
                    iTrace.eError("LY", "In path finding, portal link map is not current !!! ");
                    Break(ResultType.RT_Unexpect);
                }
                /// 跳转传送口 ///
                else
                {
                    PortalFig toPF = MapPathMgr.instance.MapAssis.GetPortalFigById(tPortal.mLinkPortalId);
                    if (toPF == null)
                    {
                        iTrace.Error("LY", "Jump to portal miss !!! " + tPortal.mLinkPortalId);
                        //WalkPathFinish();
                        Break(ResultType.RT_Unexpect);
                        return;
                    }

                    mRecoveryCB = JumpFinishCallBack;
                    mPreActionNeed(ActionState.FS_JUMP, mUnit, tPortal, toPF);
                }
            }
        }
    }

    /// <summary>
    /// 等待结束
    /// </summary>
    protected void WaitFinish()
    {
        if (mBlockPath == null)
        {
            BlockPathFinish();
            return;
        }

        mSmallPath = mBlockPath.PopFirstPath();
        if (mSmallPath == null || mSmallPath.mPathPoints == null || mSmallPath.mPathPoints.Count <= 0)
        {
            BlockPathFinish();
            return;
        }
        mSmallPath.mPathPoints.RemoveAt(0);

        if (mFLUseDefSpd == false && mSmallPath.mPathTime > 0f)
        {
            mMoveSpeed = mSmallPath.mPathLength / mSmallPath.mPathTime;
        }
        else
        {
            mMoveSpeed = mInitSpeed;
        }
        CheckStopDis();
        NetMove.SendMove(mUnit, mSmallPath.mPathPoints[0], SendMoveType.SendMovePoint);
    }

    /// <summary>
    /// 跳跃完成回调
    /// </summary>
    protected virtual void JumpFinishCallBack()
    {
        //InputMgr.instance.CanInput = true;

        mUnit.ActionStatus.ChangeAction("N0020", 0);
        ActionHelper.PlayRidingAnim(mUnit, true);
        AutoMountMgr.instance.StartTimer(mUnit);

        mSmallPath = mBlockPath.PopFirstPath();
        if (mSmallPath != null && mSmallPath.mPathPoints != null && mSmallPath.mPathPoints.Count > 0)
        {
            mSmallPath.mPathPoints.RemoveAt(0);
            CheckStopDis();
            mUnit.ActionStatus.ChangeMoveAction();
        }
        else
        {
            SmallPathFinish();
        }
    }

    /// <summary>
    /// 当前地图路径完成
    /// </summary>
    protected virtual void WalkPathFinish()
    {
        /// 完成寻路 ///
        StopWalkAnim();
        Finish();
    }

    /// <summary>
    /// 停止移动动画
    /// </summary>
    protected void StopWalkAnim()
    {
        if (mUnit != null)
        {
            mUnit.ActionStatus.ChangeIdleAction();
        }
    }
}