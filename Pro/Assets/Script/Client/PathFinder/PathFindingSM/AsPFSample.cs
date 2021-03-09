using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 简易寻路
/// </summary>
public class AsPFSample : AsPFBase
{
    protected float mLastDis = 0f;
    protected float mWalkSpd = 1f;
    protected Vector3 mEndPos = Vector3.zero;

    
    public AsPFSample() : base()
    {

    }

    public AsPFSample(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {
        EventMgr.Add("ChangeSceneFail", FailChangeScene);
    }

    public override void Clear()
    {
        base.Clear();

        mLastDis = 0f;
        mWalkSpd = 1f;
        mEndPos = Vector3.zero;
    }

    public override void SetInitVal(Unit pfUnit, ReqPathFinding info, Action callback)
    {
        base.SetInitVal(pfUnit, info, callback);

        EventMgr.Add("ChangeSceneFail", FailChangeScene);
    }

    public override void Start()
    {
        base.Start();

        mLastDis = pfInfo.stopDis >= 0f ? pfInfo.stopDis : STOP_DIS;
        mWalkSpd = pfInfo.walkSpd > 0 ? pfInfo.walkSpd : mUnit.MoveSpeed;
        mEndPos = pfInfo.endPos;
        

        /// 跨地图寻路 ///
        if (pfInfo.mapId > 0 && pfInfo.mapId != MapPathMgr.instance.CurMapId)
        {
            AutoMountMgr.instance.StopTimer(mUnit);
            NavMoveBuff.instance.StopTimer(mUnit);

            PFChangeScene pfChangeScene = ObjPool.Instance.Get<PFChangeScene>();
            pfChangeScene.SetInitVal(mUnit, (int)pfInfo.mapId, 0, 0, 0, false, 0.5f, 1f, InsertPreAction, OverCurAction);
            mCurAction = pfChangeScene;
            mCurAction.Start();
        }
        else
        {
            AutoMountMgr.instance.StartTimer(mUnit);
            NavMoveBuff.instance.StartTimer(mUnit);

            PFWalk pfWalk = ObjPool.Instance.Get<PFWalk>();
            pfWalk.SetInitVal(mUnit, mEndPos, mWalkSpd, mLastDis, InsertPreAction, OverCurAction);
            mCurAction = pfWalk;
            mCurAction.Start();
        }
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        if(mWaitActionList != null && mWaitActionList.Count <= 0 && type == PFActionBase.ResultType.RT_Success)
        {
            switch (actState)
            {
                case PFActionBase.ActionState.FS_CHANGEMAP:
                    {
                        PFWalk pfWalk = ObjPool.Instance.Get<PFWalk>();
                        pfWalk.SetInitVal(mUnit, mEndPos, mWalkSpd, mLastDis, InsertPreAction, OverCurAction);
                        mCurAction = pfWalk;
                        mCurAction.Start();

                        return;
                    }
                    //break;
                default:
                    break;
            }
            
        }

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