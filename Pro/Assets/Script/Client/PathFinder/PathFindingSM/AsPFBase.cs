using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 寻路类型基础
/// </summary>
public class AsPFBase
{
    /// <summary>
    /// 默认停止距离
    /// </summary>
    protected static readonly float STOP_DIS = 0.2f;

    public delegate PFActionBase InsertFun(Action<PFActionBase.ActionState, PFActionBase.ResultType> finCB);

    /// <summary>
    /// 寻路动作单位
    /// </summary>
    protected Unit mUnit = null;
    /// <summary>
    /// 寻路信息
    /// </summary>
    protected ReqPathFinding pfInfo = null;
    /// <summary>
    /// 完成回调（主要用于通知AsPathfinding完成寻路）
    /// </summary>
    protected Action finCB = null;
    /// <summary>
    /// 当前行为状态
    /// </summary>
    protected PFActionBase mCurAction = null;
    /// <summary>
    /// 等待执行行为状态
    /// </summary>
    protected List<PFActionBase> mWaitActionList = new List<PFActionBase>();

    //private readonly bool mNeedStopAnim = true;

    
    /// <summary>
    /// 目标点坐标
    /// </summary>
    //protected Vector3 mPathEndPos = Vector3.zero;


    public Unit Vehicle
    {
        get { return mUnit; }
        set
        {
            mUnit = value;
            if (mCurAction != null)
            {
                mCurAction.Vehicle = mUnit;
            }
            if(mWaitActionList != null)
            {
                for(int a = 0; a < mWaitActionList.Count; a++)
                {
                    mWaitActionList[a].Vehicle = mUnit;
                }
            }
        }
    }

    /// <summary>
    /// 改变移动速度
    /// </summary>
    public float MoveSpeed
    {
        set
        {
            //mMoveSpeed = value;
            if (mCurAction != null && mCurAction is PFWalk)
            {
                ((PFWalk)mCurAction).SetMoveSpd(value);
                //mCurAction.SetMoveSpd(mMoveSpeed);
            }

            if (mWaitActionList != null)
            {
                for (int a = 0; a < mWaitActionList.Count; a++)
                {
                    if (mWaitActionList[a] is PFWalk)
                    {
                        ((PFWalk)mWaitActionList[a]).SetMoveSpd(value);
                    }
                }
            }
        }
    }


    public AsPFBase()
    {

    }

    public AsPFBase(Unit pfUnit, ReqPathFinding info, Action callback)
    {
        SetInitVal(pfUnit, info, callback);
    }

    public virtual void SetInitVal(Unit pfUnit, ReqPathFinding info, Action callback)
    {
        mUnit = pfUnit;
        pfInfo = info.Copy();
        finCB = callback;
    }

    /// <summary>
    /// 清理工作
    /// </summary>
    public virtual void Clear()
    {
        mUnit = null;
        pfInfo = null;
        finCB = null;
        ClearCurAction();
        ClearWaitAction();
    }

    /// <summary>
    /// 判断是否可以打断状态
    /// </summary>
    /// <returns></returns>
    public virtual bool CanBreakState()
    {
        if(mCurAction == null)
            return true;

        return mCurAction.CanBreak;
    }

    /// <summary>
    /// 获取当前行动状态
    /// </summary>
    /// <returns></returns>
    public PFActionBase.ActionState GetCurActionState()
    {
        if (mCurAction == null)
            return PFActionBase.ActionState.FS_UNKNOWN;

        return mCurAction.ActionType;
    }

    /// <summary>
    /// 获取寻路类型
    /// </summary>
    /// <returns></returns>
    public virtual AsPathfinding.PathFindingType GetPFType()
    {
        return AsPathfinding.PathFindingType.PFT_UnKnown;
    }

    public virtual void Start()
    {

    }

    public virtual void Update(float dTime)
    {
        if(mCurAction != null)
        {
            mCurAction.Update(dTime);
        }
    }

    public virtual void Break(AsPathfinding.PathResultType resultType)
    {
        ClearWaitAction();

        if (mCurAction != null)
        {
            mCurAction.Break(PFActionBase.ResultType.RT_CallBreak);
            ClearCurAction();
        }
        else
        {
            AutoMountMgr.instance.StopTimer(mUnit);
            NavMoveBuff.instance.StopTimer(mUnit);

            if (pfInfo != null && pfInfo.finCB != null)
            {
                pfInfo.finCB(mUnit, resultType);
            }

            if (finCB != null)
            {
                finCB();
                finCB = null;
            }
        }
    }
    
    //protected void UnitStopSendPos()
    //{
    //    if(mUnit == null || mUnit.UnitTrans == null)
    //    {
    //        return;
    //    }

    //    long sendPot = NetMove.GetPointInfo(mUnit.Position, mUnit.UnitTrans.localEulerAngles.y);
    //    NetMove.RequestStopMove(sendPot);
    //}

    /// <summary>
    /// 行为完成
    /// </summary>
    protected virtual void Finish()
    {
        AutoMountMgr.instance.StartTimer(mUnit);
        NavMoveBuff.instance.StartTimer(mUnit);

        if (pfInfo != null && pfInfo.finCB != null)
        {
            pfInfo.finCB(mUnit, AsPathfinding.PathResultType.PRT_PATH_SUC);
        }

        if(finCB != null)
        {
            finCB();
            finCB = null;
        }
    }

    /// <summary>
    /// 插入前置处理状态
    /// </summary>
    /// <param name="stateType"></param>
    protected virtual void InsertPreAction(params object[] args)
    {
        if(args == null || args.Length <= 0)
        {
            iTrace.eError("LY", "AsPFBase::InsertPreAction args error !!!");
            Break(AsPathfinding.PathResultType.PRT_ERROR_BREAK);
            return;
        }

        if(args[0] is PFActionBase.ActionState)
        {
            if (mCurAction != null)
            {
                mWaitActionList.Add(mCurAction);
                mCurAction.Hangup();
            }

            PFActionBase.ActionState aState = (PFActionBase.ActionState)args[0];
            switch (aState)
            {
                case PFActionBase.ActionState.FS_WAIT:
                    {
                        //mCurAction = new PFWait(args[1] as Unit, (float)args[2], InsertPreAction, OverCurAction);
                        PFWait pfWait = ObjPool.Instance.Get<PFWait>();
                        pfWait.SetInitVal(args[1] as Unit, (float)args[2], InsertPreAction, OverCurAction);
                        mCurAction = pfWait;
                        mCurAction.Start();
                    }
                    break;
                case PFActionBase.ActionState.FS_JUMP:
                    {
                        PFJump pfJump = ObjPool.Instance.Get<PFJump>();
                        pfJump.SetInitVal(args[1] as Unit, args[2] as PortalFig, args[3] as PortalFig, InsertPreAction, OverCurAction);
                        mCurAction = pfJump;
                        mCurAction.Start();
                    }
                    break;
                default:
                    break;
            }
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="actState"></param>
    /// <param name="type"></param>
    protected virtual void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        //iTrace.eLog("LY", "Call base !!! ");
        if(type != PFActionBase.ResultType.RT_Success)
        {
            iTrace.eLog("LY", "Path finding action state no success !!! " + type);

            ClearWaitAction();
            ClearCurAction();

            AutoMountMgr.instance.StartTimer(mUnit);
            NavMoveBuff.instance.StartTimer(mUnit);

            if (pfInfo != null && pfInfo.finCB != null)
            {
                switch(type)
                {
                    case PFActionBase.ResultType.RT_CallBreak:
                        pfInfo.finCB(mUnit, AsPathfinding.PathResultType.PRT_CALL_BREAK);
                        break;
                    case PFActionBase.ResultType.RT_PassiveBreak:
                        pfInfo.finCB(mUnit, AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
                        break;
                    case PFActionBase.ResultType.RT_Unexpect:
                        pfInfo.finCB(mUnit, AsPathfinding.PathResultType.PRT_ERROR_BREAK);
                        break;
                    default:
                        break;
                }
            }

            if (finCB != null)
            {
                finCB();
                finCB = null;
            }

            return;
        }

        if(mWaitActionList != null && mWaitActionList.Count > 0)
        {
            mCurAction = mWaitActionList[mWaitActionList.Count - 1];
            mWaitActionList.RemoveAt(mWaitActionList.Count - 1);
            mCurAction.Recovery();
        }
        else
        {
            Finish();
        }
    }

    /// <summary>
    /// 路径完成后等待
    /// </summary>
    /// <param name="actState"></param>
    /// <param name="type"></param>
    protected virtual void AfterPathWaitFin(PFActionBase.ActionState actState, int type)
    {
        iTrace.Log("LY", "Call base !!! ");
    }

    /// <summary>
    /// 转换场景失败
    /// </summary>
    /// <param name="args"></param>
    protected virtual void FailChangeScene(params object[] args)
    {
        Break(AsPathfinding.PathResultType.PRT_CALL_BREAK);
    }

    /// <summary>
    /// 清理当前行为状态
    /// </summary>
    protected virtual void ClearCurAction()
    {
        if(mCurAction != null)
        {
            mCurAction.Clear();
            ObjPool.Instance.Add(mCurAction);
            mCurAction = null;
        }
    }

    /// <summary>
    /// 清理等待行为状态
    /// </summary>
    protected virtual void ClearWaitAction()
    {
        if (mWaitActionList == null)
            return;

        for (int a = 0; a < mWaitActionList.Count; a++)
        {
            if (mWaitActionList[a] != null)
            {
                mWaitActionList[a].Clear();
                ObjPool.Instance.Add(mWaitActionList[a]);
            }
        }
        mWaitActionList.Clear();
    }
}