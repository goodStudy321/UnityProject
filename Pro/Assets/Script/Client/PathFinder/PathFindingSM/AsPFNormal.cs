using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 正常寻路
/// </summary>
public class AsPFNormal : AsPFBase
{
    /// <summary>
    /// 需要经过地图Id(不包含当前)
    /// </summary>
    private List<uint> mPassMapList = new List<uint>();

    protected float mLastDis = 0f;
    protected float mWalkSpd = 1f;
    protected Vector3 mEndPos = Vector3.zero;


    public AsPFNormal() : base()
    {

    }

    public AsPFNormal(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {

    }

    public override void Clear()
    {
        base.Clear();

        mPassMapList.Clear();
        mLastDis = 0f;
        mWalkSpd = 1f;
        mEndPos = Vector3.zero;
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
            mPassMapList = MapPathMgr.instance.FindPassMapList(pfInfo.mapId);
        }
        //mPathEndPos = pfInfo.endPos;

        InsertFindPath(pfInfo.startPos, mEndPos);
    }

    /// <summary>
    /// 当前地图路径完成
    /// </summary>
    protected void WalkPathFinish()
    {
        /// 完成寻路 ///
        if (mPassMapList == null || mPassMapList.Count <= 0)
        {
            Finish();
        }
        /// 读取下一个地图 ///
        else
        {
            mUnit.ActionStatus.ChangeIdleAction();

            /// 通知更换地图 ///
            AsNode standNode = MapPathMgr.instance.FindClosestNode(mUnit.Position);
            if (standNode == null)
            {
                iTrace.eError("LY", "Finish path stand node is null !!! ");
                Break(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
                return;
            }

            uint curProId = 0;
            uint desPorId = 0;
            if (standNode.IsProtal)
            {
                PortalFig tPF = MapPathMgr.instance.MapAssis.GetPortalFigById(standNode.portalIndex);
                if (tPF == null)
                {
                    iTrace.eError("LY", "AsNode portal miss !!! ");
                    Break(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
                    return;
                }
                curProId = tPF.mPortalId;
                desPorId = tPF.mLinkPortalId;
            }
            
            AutoMountMgr.instance.StopTimer(mUnit);
            NavMoveBuff.instance.StopTimer(mUnit);

            PFChangeScene pfChangeScene = ObjPool.Instance.Get<PFChangeScene>();
            pfChangeScene.SetInitVal(mUnit, (int)mPassMapList[0], curProId, desPorId, 0, false, 0.5f, 1f, InsertPreAction, OverCurAction);
            mCurAction = pfChangeScene;
            mPassMapList.RemoveAt(0);
            mCurAction.Start();
        }
    }

    /// <summary>
    /// 添加到查找路径队列
    /// </summary>
    protected void InsertFindPath(Vector3 startPosition, Vector3 endPosition)
    {
        /// 获取去这张地图的跳转口，获得坐标 ///
        if (mPassMapList != null && mPassMapList.Count > 0)
        {
            PassMapFindPath(mPassMapList[0], startPosition);
        }
        else
        {
            AutoMountMgr.instance.StartTimer(mUnit);
            NavMoveBuff.instance.StartTimer(mUnit);

            PFWalk pfWalk = ObjPool.Instance.Get<PFWalk>();
            pfWalk.SetInitVal(mUnit, endPosition, mWalkSpd, mLastDis, InsertPreAction, OverCurAction);
            mCurAction = pfWalk;
            mCurAction.Start();
        }
    }

    /// <summary>
    /// 跨地图寻路
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="startPos"></param>
    protected void PassMapFindPath(uint mapId, Vector3 startPos)
    {
        Vector3 endPos = Vector3.zero;
        PortalFig tFig = MapPathMgr.instance.MapAssis.FindPortalByLinkMapId(mapId);
        if (tFig == null)
        {
            iTrace.Error("LY", "Can not find portalfig !!! To map id : " + mapId);
            Break(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
            return;
        }

        endPos = tFig.transform.position;
        
        AutoMountMgr.instance.StartTimer(mUnit);
        NavMoveBuff.instance.StartTimer(mUnit);

        PFWalk pfWalk = ObjPool.Instance.Get<PFWalk>();
        pfWalk.SetInitVal(mUnit, endPos, mWalkSpd, mLastDis, InsertPreAction, OverCurAction);
        mCurAction = pfWalk;
        mCurAction.Start();
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        if (mWaitActionList != null && mWaitActionList.Count > 0)
        {
            base.OverCurAction(actState, type);
            return;
        }


        if (type == PFActionBase.ResultType.RT_Success)
        {
            switch (actState)
            {
                case PFActionBase.ActionState.FS_WALK:
                    {
                        WalkPathFinish();
                    }
                    break;
                case PFActionBase.ActionState.FS_CHANGEMAP:
                    {
                        InsertFindPath(mUnit.Position, mEndPos);
                    }
                    break;
                default:
                    {
                        iTrace.Log("LY", "AsPFSample::OverCurAction type error !!! " + actState);
                    }
                    break;
            }
        }
        else
        {
            base.OverCurAction(actState, type);
        }
    }
}