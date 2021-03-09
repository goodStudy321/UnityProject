using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 跟随路径移动
/// </summary>
public class AsPFFollowPath : AsPFBase
{
    public AsPFFollowPath() : base()
    {

    }

    public AsPFFollowPath(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {
		
    }

    public override void Clear()
    {
        base.Clear();
    }

    public override void Start()
    {
        base.Start();
        MapPathMgr.instance.InsertInFallowQueue(pfInfo.startPos, pfInfo.pathInfo, SetPath);
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        //switch(actState)
        //{
        //    case PFActionBase.ActionState.FS_WALK:
        //        {
        //            if(type == 0)
        //            {

        //            }
        //            else if(type == 1)
        //            {
        //                mCurAction = null;
        //                SmallPathFinish();
        //            }
        //        }
        //        break;
        //    default:
        //        {
        //            iTrace.Log("LY", "AsPFSample::OverCurAction type error !!! " + actState);
        //        }
        //        break;
        //}

        base.OverCurAction(actState, type);
    }

    /// <summary>
    /// 路径完成后等待
    /// </summary>
    /// <param name="actState"></param>
    /// <param name="type"></param>
    //protected override void AfterPathWaitFin(PFActionBase.ActionState actState, int type)
    //{
    //    switch(actState)
    //    {
    //        case PFActionBase.ActionState.FS_WAIT:
    //            {
    //                mCurAction = null;
    //                WaitFinish();
    //            }
    //            break;
    //        default:
    //            {
    //                iTrace.Log("LY", "AsPFSample::AfterPathWaitFin type error !!! " + actState);
    //            }
    //            break;
    //    }
    //}

    /// <summary>
    /// 路径设置返回
    /// </summary>
    /// <param name="path"></param>
    protected virtual void SetPath(WalkPath path)
    {
        if (path == null || path.mHasPath == false || path.mPathList == null || path.mPathList.Count <= 0)
        {
            iTrace.eError("LY", "Can not find path !!! ");
            Break( AsPathfinding.PathResultType.PRT_PASSIVEBREAK );
            //Break(AsPathfinding.PathResultType.PRT_NOPATH);
            return;
        }

        //mPath = path;

        BlockPath tLBP = path.mPathList[path.mPathList.Count - 1];
        SmallPath tLSP = tLBP.mPathList[tLBP.mPathList.Count - 1];

        PFWalk pfWalk = ObjPool.Instance.Get<PFWalk>();
        pfWalk.SetInitVal(mUnit, tLSP.mPathPoints[tLSP.mPathPoints.Count - 1], 1, 0, InsertPreAction, OverCurAction);
        mCurAction = pfWalk;
        ((PFWalk)mCurAction).Start2(path);
    }
}