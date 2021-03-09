using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Loong.Game;


public class NetUnitMove
{
    /// LY add begin ///
    
    /// <summary>
    /// 跳跃类型枚举
    /// </summary>
    //public enum JumpType
    //{
    //    JT_None = 0,
    //    //JT_CtrlCall,                /* 玩家操作控制调用 */
    //    JT_PathfindCall,            /* 自动寻路调用 */
    //    JT_ServerCall,              /* 服务器调用 */
    //    JT_Max
    //}

    /// LY add end ///

    #region 私有变量
    /// <summary>
    /// 摇杆移动目标点
    /// </summary>
    private Vector3 mMoveDesPos = Vector3.zero;
    /// <summary>
    /// 摇杆移动方向
    /// </summary>
    private Vector3 mMoveFoward = Vector3.zero;
    /// <summary>
    /// 是否已到达目标点
    /// </summary>
    private bool isMoveDesPosDone = true;
    /// <summary>
    /// 是否旋转完成
    /// </summary>
    private bool isRotateDone = true;
    /// <summary>
    /// 移动速度
    /// </summary>
    private float mMoveSpeed = 0;
    /// <summary>
    /// 旋转速度
    /// </summary>
    private float mRotateSpeed = 8;
    /// <summary>
    /// 移动类型
    /// </summary>
    private MoveType mMoveType = MoveType.None;
    /// <summary>
    /// 正常移动停止
    /// </summary>
    private bool bNormalMoveStop = false;

    /// LY add begin ///

    /// <summary>
    /// 移动单位
    /// </summary>
    private Unit mOwner;

    /// <summary>
    /// 当前跳跃类型
    /// </summary>
    //public JumpType mCurJumpType = JumpType.JT_None;
    /// <summary>
    /// 跳跃路线反向
    /// </summary>
    private PortalFig mPortalFig = null;
    /// <summary>
    /// 跳跃曲线组
    /// </summary>
    private List<JumpPathInfo> mJumpPathsInfo = null;
    /// <summary>
    /// 完成跳跃回调
    /// </summary>
    private Action mFinishJumpCB = null;

    private int mJumpPathIndex = 0;
    private bool mNoCurveMove = false;

    /// <summary>
    /// 跳跃等待计时器
    /// </summary>
    private Timer mWaitTimer = null;
    /// LY add end ///

    #endregion

    #region 属性
    //public bool InJumping
    //{
    //    get { return mCurJumpType != JumpType.JT_None; }
    //}

    public bool NoCurveMove
    {
        get { return mNoCurveMove; }
        set { mNoCurveMove = value; }
    }

    /// <summary>
    /// 是否正常移动停止
    /// </summary>
    public bool IsNormalMoveStop
    {
        get { return bNormalMoveStop; }
        set { bNormalMoveStop = value; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void Init(Unit unit)
    {
        mOwner = unit;
        if (mOwner == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "NetUnitMove::Init  Unit is null !!! ");
#endif
        }
    }

    /// <summary>
    /// 设置移动方向
    /// </summary>
    /// <param name="foward"></param>
    public void SetMoveFoward(Vector3 foward)
    {
        mMoveFoward = foward;
        if (foward == Vector3.zero)
            isRotateDone = true;
        else
            isRotateDone = false;
    }

    /// <summary>
    /// 设置移动目标点
    /// </summary>
    /// <param name="desPos"></param>
    public void SetMoveDesPos(Vector3 desPos)
    {
        isMoveDesPosDone = false;
        mMoveDesPos = desPos;
    }

    /// <summary>
    /// 设置移动速度
    /// </summary>
    /// <param name="moveType"></param>
    public void SetMoveSpeed(Unit unit, MoveType moveType)
    {
        mMoveType = moveType;
        if (moveType == MoveType.None)
            return;
        if (moveType == MoveType.Normal)
            mMoveSpeed = unit.MoveSpeed;
        else
            mMoveSpeed = MoveSpeed.instance.MoveDic[moveType];
    }

    /// <summary>
    /// 设置旋转速度
    /// </summary>
    /// <param name="rotateSpeed"></param>
    public void SetRotateSpeed(Unit unit)
    {
        float rotateSpeed = unit.ActionStatus.ActiveAction.RotateSpeed;
        mRotateSpeed = rotateSpeed;
    }

    /// <summary>
    /// 重置旋转速度
    /// </summary>
    public void ReSetRotateSp()
    {
        mRotateSpeed = 8;
    }
    
    /// <summary>
    /// 更新移动
    /// </summary>
    public void UpdateMove(Unit unit)
    {
        if (unit.Dead)
            return;
        UpdateFoward(unit);
        if (isMoveDesPosDone)
            return;
        float speed = mMoveSpeed * Time.deltaTime;
        Vector3 pos = unit.Position + mMoveFoward.normalized * speed;
        if (Vector3.Dot(mMoveFoward, (mMoveDesPos - pos)) > 0)
        {
            unit.Position = pos;
            return;
        }
        isMoveDesPosDone = true;
        unit.Position = mMoveDesPos;
        //如果是正常移动且没有收到移动停止指令
        if (mMoveType == MoveType.Normal && !bNormalMoveStop)
            return;
        if (!unit.ActionStatus.CheckInterrupt("N0000"))
            return;
        unit.ActionStatus.ChangeIdleAction();
    }

    /// <summary>
    /// 更新方向
    /// </summary>
    /// <param name="unit"></param>
    public void UpdateFoward(Unit unit)
    {
        if (unit.Dead)
            return;
        if (isRotateDone)
            return;
        if (mRotateSpeed == 0)
            return;
        Vector3 forward = unit.UnitTrans.forward;
        float desRad = Mathf.Atan2(mMoveFoward.x, mMoveFoward.z);
        float scrRad = Mathf.Atan2(forward.x, forward.z);
        float rad = Mathf.Abs(desRad - scrRad);
        if(rad > 0.01f)
        {
            unit.SetOrientation(desRad, mRotateSpeed);
            return;
        }
        isRotateDone = true;
    }

    /// <summary>
    /// 清除移动信息
    /// </summary>
    public void ClearMoveInfo()
    {
        if (isMoveDesPosDone && isRotateDone)
            return;
        Clear();
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        mMoveDesPos = Vector3.zero;
        mMoveFoward = Vector3.zero;
        isMoveDesPosDone = true;
        isRotateDone = true;
        mMoveSpeed = 0;
        mRotateSpeed = 8;
        mMoveType = MoveType.None;
        bNormalMoveStop = false;

        if(mWaitTimer != null)
        {
            mWaitTimer.Dispose();
            mWaitTimer = null;
        }
    }

    public void Dispose()
    {
        Clear();
        ClearJumpState();
        mFinishJumpCB = null;
        mNoCurveMove = false;
    }

    /// LY add begin ///

    /// <summary>
    /// 请求跳跃
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="jumpType"></param>
    /// <param name="desPos"></param>
    /// <param name="portalId"></param>
    /// <param name="mapId"></param>
    public void RequestJump(Unit unit, Vector3 desPos, uint portalId, uint mapId = 0, Action finCB = null)
    {
        if (unit.ParentUnit != null && unit.ParentUnit.UnitUID == User.instance.MapData.UID)
            unit.ParentUnit.mNetUnitMove.mFinishJumpCB = finCB;
        else
            mFinishJumpCB = finCB;
        NetMove.RequestChangePosDir(unit, desPos, (int)mapId, (int)portalId);

        /// 玩家自己直接处理跳转口跳转，不等待服务器的返回 ///
        Unit tPlayer = InputMgr.instance.mOwner;
        tPlayer.mNetUnitMove.ServerCallJumpPath(tPlayer, portalId, true);
    }

    /// <summary>
    /// 跳转点跳跃
    /// </summary>
    /// <param name="mUnit"></param>
    /// <param name="portalId"></param>
    /// <param name="finCB"></param>
    public void ServerCallJumpPath(Unit owner, uint portalId, bool localFst = false)
    {
        /// 玩家自己跳转不用等待服务器返回处理 ///w
        //if (localFst == false && owner == InputVectorMove.instance.MoveUnit)
        //    return;

        //if(mCurJumpType == JumpType.JT_None)
        //{
        //    mCurJumpType = JumpType.JT_ServerCall;
        //}
        //if (mOwner.Mount != null)
        //    mCurJumpType = mOwner.Mount.mNetUnitMove.mCurJumpType;
        
        mPortalFig = MapPathMgr.instance.MapAssis.GetPortalFigById(portalId);
        /// 找不到跳转口 ///
        if (mPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "NetUnitMove::ServerCallJumpPath   Portal miss !!! " + portalId);
#endif
            return;
        }

        //PendantMgr.instance.SetLocalPendantsShowState(mOwner, false, OpStateType.Jump);

        /// 没有跳转曲线信息 ///
        mJumpPathsInfo = mPortalFig.GetAllJumpPathsInfo();
        if(mJumpPathsInfo == null || mJumpPathsInfo.Count <= 0)
        {
            PortalFig toPF = MapPathMgr.instance.MapAssis.GetPortalFigById(mPortalFig.mLinkPortalId);
            if (toPF == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Jump to portal miss !!! " + portalId);
#endif
            }
            else
            {
                Vector3 tVer = toPF.transform.position - mPortalFig.transform.position;
                owner.SetOrientation(Mathf.Atan2(tVer.x,tVer.z));
                if (owner.Mount != null)
                    owner = owner.Mount;
                owner.Position = toPF.transform.position;
            }

            JumpPathsFinish();
            mNoCurveMove = true;
            return;
        }
        
        PendantMgr.instance.SetLocalPendantsShowState(owner, false, OpStateType.Jump);

        mJumpPathIndex = 0;
        PlayCurIndexPath();
    }

    /// <summary>
    /// 落地动作完成
    /// </summary>
    public void LandAnimFinish()
    {
        if(mPortalFig == null)
        {
            InputMgr.instance.CanInput = true;
            return;
        }

        /// 跳跃完成 ///
        if (mJumpPathsInfo == null || mJumpPathIndex >= mJumpPathsInfo.Count)
        {
            JumpPathsFinish();
        }
        else
        {
            PlayCurIndexPath();
        }
    }

    /// <summary>
    /// 清除跳跃标记
    /// </summary>
    public void ClearJumpState()
    {
        if (mWaitTimer != null)
        {
            mWaitTimer.Dispose();
            mWaitTimer = null;
        }
        mJumpPathIndex = -1;
        mJumpPathsInfo = null;
        mPortalFig = null;
        if (mOwner != null && mOwner.Mount != null)
            mOwner.Mount.mNetUnitMove.ClearJumpState();
    }


    /// LY add end ///

    #endregion


    #region 私有方法

    private bool PlayCurIndexPath()
    {
        if(mJumpPathIndex < 0 || mJumpPathIndex >= mJumpPathsInfo.Count)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Jump index error !!! " + mJumpPathIndex);
#endif
            JumpPathsFinish();
            mNoCurveMove = true;
            return false;
        }

        int realIndex = mJumpPathIndex;
        if(mPortalFig.mReverse == true)
        {
            realIndex = mJumpPathsInfo.Count - 1 - mJumpPathIndex;
        }
        JumpPathInfo tInfo = mJumpPathsInfo[realIndex];
        if (tInfo == null)
        {
            return false;
        }

        if (CheckRunCurvePreWait(tInfo) == true)
        {
            return true;
        }

        return CheckRunCurve(tInfo);
    }

    /// <summary>
    /// 检测并执行曲线前等待
    /// </summary>
    /// <returns></returns>
    private bool CheckRunCurvePreWait(JumpPathInfo jInfo)
    {
        if (jInfo.mPreWaitTime > 0f)
        {
            if (mWaitTimer == null)
            {
                mWaitTimer = ObjPool.Instance.Get<Timer>();
            }
            //mWaitTimer.Reset();
            mWaitTimer.Seconds = jInfo.mPreWaitTime;
            mWaitTimer.complete += CurvePreWaitFin;
            mWaitTimer.Start();

            if (string.IsNullOrEmpty(jInfo.mPreAnim) == false)
            {
                mOwner.ActionStatus.ChangeAction(jInfo.mPreAnim, 0);
            }
             if(string.IsNullOrEmpty(jInfo.mPreFx) == false)
            {
                GameEventManager.instance.EnQueue(
                        new PlayEffectEvent(jInfo.mPreFx, mOwner, mOwner.Position, Vector3.one, Vector3.forward, 0, 0), true);
            }
            UnitMgr.instance.SetUnitActiveOnly(mOwner, !jInfo.mPPHide);

            return true;
        }

        return false;
    }

    /// <summary>
    /// 检测曲线运行状态
    /// </summary>
    /// <param name="jInfo"></param>
    /// <returns></returns>
    private bool CheckRunCurve(JumpPathInfo jInfo)
    {
        if (PathTool.PathMoveMgr.instance.RunPathMove(
            jInfo.mPathId, jInfo.mJumpTime, mPortalFig.mReverse, mPortalFig.mFaceType,
            mOwner, jInfo.mAnimCurve, CurveMoveFin))
        {
            /// 变换跳跃动作 ///
            if (string.IsNullOrEmpty(jInfo.mJumpAnim) == false)
            {
                /// 根据配置换动作 ///
                mOwner.ActionStatus.ChangeAction(jInfo.mJumpAnim, 0);
            }
            else
            {
                mOwner.ActionStatus.ChangeAction("N0030", 0);
            }

            return true;
        }

        return false;
    }

    /// <summary>
    /// 曲线前置等待完成
    /// </summary>
    private void CurvePreWaitFin()
    {
        mWaitTimer.complete -= CurvePreWaitFin;
        mWaitTimer.Stop();

        int realIndex = mJumpPathIndex;
        if (mPortalFig.mReverse == true)
        {
            realIndex = mJumpPathsInfo.Count - 1 - mJumpPathIndex;
        }
        JumpPathInfo tInfo = mJumpPathsInfo[realIndex];
        UnitMgr.instance.SetUnitActiveOnly(mOwner, !tInfo.mPAHide);
        CheckRunCurve(tInfo);
    }

    /// <summary>
    /// 曲线移动完成
    /// </summary>
    /// <param name="finType"></param>
    private void CurveMoveFin(PathTool.MoveOnPath.FinishType finType)
    {
        int realIndex = mJumpPathIndex;
        if (mPortalFig.mReverse == true)
        {
            realIndex = mJumpPathsInfo.Count - 1 - mJumpPathIndex;
        }
        JumpPathInfo tInfo = mJumpPathsInfo[realIndex];
        if(tInfo.mAftWaitTime > 0f)
        {
            if (mWaitTimer == null)
            {
                mWaitTimer = ObjPool.Instance.Get<Timer>();
            }
            //mWaitTimer.Reset();
            mWaitTimer.Seconds = tInfo.mAftWaitTime;
            mWaitTimer.complete += CurveAftWaitFin;
            mWaitTimer.Start();

            if (string.IsNullOrEmpty(tInfo.mAftAnim) == false)
            {
                mOwner.ActionStatus.ChangeAction(tInfo.mAftAnim, 0);
            }
            if (string.IsNullOrEmpty(tInfo.mAftFx) == false)
            {
                GameEventManager.instance.EnQueue(
                        new PlayEffectEvent(tInfo.mAftFx, mOwner, mOwner.Position, Vector3.one, Vector3.forward, 0, 0), true);
            }
            UnitMgr.instance.SetUnitActiveOnly(mOwner, !tInfo.mAPHide);
        }
        else
        {
            OneJumpPathFinish();
        }
    }

    /// <summary>
    /// 曲线后置等待完成
    /// </summary>
    private void CurveAftWaitFin()
    {
        mWaitTimer.complete -= CurveAftWaitFin;
        mWaitTimer.Stop();

        OneJumpPathFinish();
    }

    /// <summary>
    /// 一段跳跃路径完成
    /// </summary>
    private void OneJumpPathFinish()
    {
        /// 落地动作 ///
        //mOwner.ActionStatus.ChangeAction("N0032", 0);
        //mJumpPathIndex++;

        int rI = mJumpPathIndex;
        if (mPortalFig.mReverse == true)
        {
            rI = mJumpPathsInfo.Count - 1 - mJumpPathIndex;
        }
        JumpPathInfo tInfo = mJumpPathsInfo[rI];
        UnitMgr.instance.SetUnitActiveOnly(mOwner, !tInfo.mAAHide);

        mJumpPathIndex++;
        /// 跳跃完成 ///
        if (mJumpPathsInfo == null || mJumpPathIndex >= mJumpPathsInfo.Count)
        {
            if(mOwner.ActionStatus.ChangeAction("N0033", 0) == false)
            {
                mOwner.ActionStatus.ChangeAction("N0020", 0);
                LandAnimFinish();
            }
        }
        else
        {
            int realIndex = mJumpPathIndex;
            if (mPortalFig.mReverse == true)
            {
                realIndex = mJumpPathsInfo.Count - 1 - mJumpPathIndex;
            }

            if (mPortalFig != null && mPortalFig.mUseAnimNames != null 
                && realIndex < mPortalFig.mUseAnimNames.Count && string.IsNullOrEmpty(mPortalFig.mUseAnimNames[realIndex]) == false)
            {
                /// 根据配置换动作 ///
                string animName = mPortalFig.mUseAnimNames[realIndex];
                mOwner.ActionStatus.ChangeAction(animName, 0);
            }
            else
            {
                mOwner.ActionStatus.ChangeAction("N0032", 0);
            }

            //mOwner.ActionStatus.ChangeAction("N0032", 0);
            PlayCurIndexPath();
        }
    }

    /// <summary>
    /// 跳跃路径全部完成
    /// </summary>
    private void JumpPathsFinish()
    {
        PendantMgr.instance.SetLocalPendantsShowState(mOwner, true, OpStateType.Jump);
        
        /// 打开输入 ///
        if (UnitHelper.instance.IsOwner(mOwner))
        {
            InputMgr.instance.CanInput = true;
        }
        ClearJumpState();

        if (mFinishJumpCB != null)
        {
            mFinishJumpCB();
            mFinishJumpCB = null;
        }
    }

    #endregion
}
