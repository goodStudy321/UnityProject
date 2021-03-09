using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 曲线跳跃
/// </summary>
public class AsPFChangeScene : AsPFBase
{
    /// <summary>
    /// 起始跳转口
    /// </summary>
    protected PortalFig mFromPortalFig = null;
    /// <summary>
    /// 到达跳转口
    /// </summary>
    protected PortalFig mToPortalFig = null;


    public AsPFChangeScene() : base()
    {

    }

    public AsPFChangeScene(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {
        EventMgr.Add("ChangeSceneFail", FailChangeScene);
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

        EventMgr.Add("ChangeSceneFail", FailChangeScene);
    }

    public override void Start()
    {
        InputMgr.instance.CanInput = false;

        base.Start();

        PFChangeScene pfChangeScene = ObjPool.Instance.Get<PFChangeScene>();
        pfChangeScene.SetInitVal(mUnit, (int)pfInfo.mapId, pfInfo.fromPortalId, pfInfo.toPortalId, pfInfo.jumpDes,
            pfInfo.showCSTip, pfInfo.preTime, pfInfo.afterTime, InsertPreAction, OverCurAction);
        mCurAction = pfChangeScene;
        mCurAction.Start();
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        InputMgr.instance.CanInput = true;
        //Finish();
        base.OverCurAction(actState, type);
    }

    protected override void Finish()
    {
        EventMgr.Remove("ChangeSceneFail", FailChangeScene);
        base.Finish();
    }

    public override void Break(AsPathfinding.PathResultType resultType)
    {
        EventMgr.Remove("ChangeSceneFail", FailChangeScene);
        base.Break(resultType);
    }
}