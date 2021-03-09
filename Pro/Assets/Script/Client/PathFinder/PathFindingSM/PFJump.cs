//using UnityEngine;
using System;
//using System.Collections;
//using System.Collections.Generic;


using Phantom;
using Loong.Game;


/// <summary>
/// 跳跃
/// </summary>
public class PFJump : PFActionBase
{
    /// <summary>
    /// 当前跳转口
    /// </summary>
    protected PortalFig fromPF = null;
    /// <summary>
    /// 目标跳转口
    /// </summary>
    protected PortalFig toPF = null;


    public PFJump() : base()
    {

    }

    public PFJump(Unit unit, PortalFig from, PortalFig to, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
        : base(unit, preActCB, finCB)
    {
        mActionState = ActionState.FS_JUMP;
        fromPF = from;
        toPF = to;
        mCanBreak = false;
    }

    public void SetInitVal(Unit unit, PortalFig from, PortalFig to, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
    {
        base.SetInitVal(unit, preActCB, finCB);

        mActionState = ActionState.FS_JUMP;
        fromPF = from;
        toPF = to;
        mCanBreak = false;
    }

    public override void Clear()
    {
        base.Clear();

        fromPF = null;
        toPF = null;
    }

    public override void Start()
    {
        base.Start();

        InputMgr.instance.CanInput = false;
        AutoMountMgr.instance.StopTimer(mUnit);

        if (GameSceneManager.instance.EnablePrealodArea())
        {
            uint resId = MapPathMgr.instance.GetResIdByPos(toPF.transform.position);
            if (resId > 0)
            {
                PreloadAreaMgr.Instance.Start(resId, FinishPreload);
            }
            else
            {
                FinishPreload();
            }
        }
        else
        {
            FinishPreload();
        }
    }

    public override void Break(ResultType bType)
    {
        if (mUnit != null)
        {
            PathTool.PathMoveMgr.instance.CheckRemoveInPathUnit(mUnit);
            if(mUnit.Mount != null)
            {
                PathTool.PathMoveMgr.instance.CheckRemoveInPathUnit(mUnit.Mount);
            }
            if(mUnit.ParentUnit != null)
            {
                PathTool.PathMoveMgr.instance.CheckRemoveInPathUnit(mUnit.ParentUnit);
            }
        }
        base.Break(bType);
        InputMgr.instance.CanInput = true;
    }

    public override void Update(float dTime)
    {
        base.Update(dTime);
        
    }

    protected virtual void FinishPreload()
    {
        /// 向服务器请求跳跃，等待返回执行跳跃 ///
        mUnit.mNetUnitMove.RequestJump(mUnit, toPF.transform.position, fromPF.mPortalId, 0, ServerRespondJump);
    }

    /// <summary>
    /// 服务器响应跳跃
    /// </summary>
    protected virtual void ServerRespondJump()
    {
        InputMgr.instance.CanInput = true;
        Finish();
    }
}