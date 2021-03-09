using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 曲线跳跃
/// </summary>
public class AsPFJump : AsPFBase
{
    /// <summary>
    /// 起始跳转口
    /// </summary>
    protected PortalFig mFromPortalFig = null;
    /// <summary>
    /// 到达跳转口
    /// </summary>
    protected PortalFig mToPortalFig = null;


    public AsPFJump() : base()
    {

    }

    public AsPFJump(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {
        mFromPortalFig = MapPathMgr.instance.MapAssis.GetPortalFigById(info.fromPortalId);
        if(mFromPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump can not find mFromPortalFig !!! ");
#endif
        }
        mToPortalFig = MapPathMgr.instance.MapAssis.GetPortalFigById(info.toPortalId);
        if (mToPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump can not find mToPortalFig !!! ");
#endif
        }
    }

    public AsPFJump(Unit pfUnit, ReqPathFinding info, PortalFig fromPF, PortalFig toPF, Action callback) : base(pfUnit, info, callback)
    {
        mFromPortalFig = fromPF;
        if (mFromPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump mFromPortalFig is null !!! ");
#endif
        }
        mToPortalFig = toPF;
        if (mToPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump mToPortalFig is null !!! ");
#endif
        }
    }

    public override void Clear()
    {
        base.Clear();

        mFromPortalFig = null;
        mToPortalFig = null;
    }

    public override void SetInitVal(Unit pfUnit, ReqPathFinding info, Action callback)
    {
        base.SetInitVal(pfUnit, info, callback);

        mFromPortalFig = MapPathMgr.instance.MapAssis.GetPortalFigById(info.fromPortalId);
        if (mFromPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump can not find mFromPortalFig !!! ");
#endif
        }
        mToPortalFig = MapPathMgr.instance.MapAssis.GetPortalFigById(info.toPortalId);
        if (mToPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump can not find mToPortalFig !!! ");
#endif
        }
    }

    public void SetInitVal(Unit pfUnit, ReqPathFinding info, PortalFig fromPF, PortalFig toPF, Action callback)
    {
        base.SetInitVal(pfUnit, info, callback);

        mFromPortalFig = fromPF;
        if (mFromPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump mFromPortalFig is null !!! ");
#endif
        }
        mToPortalFig = toPF;
        if (mToPortalFig == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "AsPFJump::AsPFJump mToPortalFig is null !!! ");
#endif
        }
    }

    public override void Start()
    {
        InputMgr.instance.CanInput = false;
        NetMove.RequestStopMove(pfInfo.jumpDes);

        base.Start();

        PFJump pfJump = ObjPool.Instance.Get<PFJump>();
        pfJump.SetInitVal(mUnit, mFromPortalFig, mToPortalFig, InsertPreAction, OverCurAction);
        mCurAction = pfJump;
        mCurAction.Start();
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        base.OverCurAction(actState, type);
        InputMgr.instance.CanInput = true;
    }
}