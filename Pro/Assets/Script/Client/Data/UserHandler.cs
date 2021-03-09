using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public partial class User
{

    #region 寻路
    public bool IsJumpling
    {
        get
        {
            Unit unit = InputVectorMove.instance.MoveUnit;
            if (unit != null && unit.mUnitMove != null && unit.mUnitMove.IsJumping)
            {
                return true;
            }
            return false;
        }
    }

    private int MissID = 0;

    public UInt32 MissTargetID = 0;

    //private bool IsStarNav = false;
    /// <summary>
    /// 通過場景id獲得該場景跳轉點
    /// </summary>
    public Vector3 GetMapEntrancePos(uint mapId)
    {
        Vector3 pos = MapPathMgr.instance.GetMapEntrancePos(mapId);
        return pos;
    }

    /// <summary>
    /// 主角是否在寻路中
    /// </summary>
    /// <returns></returns>
    public bool IsOwnerInPathFinding()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null)
            return false;

        return unit.mUnitMove.InPathFinding;
    }

    public void MissStarNavPath(Int32 missionID, Vector3 targetPos, UInt32 mapId, float stopDis = -1f, uint roleId = 0, bool isRtg = false)
    {
        //if (MissID == missionID) return;
        MissID = missionID;
        StartNavPath(targetPos, mapId, stopDis, roleId,isRtg);
    }

    public void EscortNavPath(Int32 missionID, Vector3 targetPos, UInt32 mapId, float stopDis = -1f, uint roleId = 0)
    {
        //if (MissID == missionID) return;
        MissID = missionID;
        MapHelper.instance.FindPathAndMoveDetail(mapId, targetPos, stopDis, NavPathsComplete);
    }


    public void StartNavPath(Vector3 targetPos, UInt32 mapId, float stopDis = -1f, uint roleId = 0, bool isRtg = false)
    {
        if (mShoesStatus) return;
        //iTrace.eError("hs", "---------------->>>  StartNavPath");
        MissTargetID = roleId;
        HangupMgr.instance.IsAutoSkill = false;
        HangupMgr.instance.IsMisKill = false;
        InputMgr.instance.ClearTarget();
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null) return;
        if (roleId != 0)
        {
            if (isRtg == true)
            {
                SetMisTarID(roleId);
                UnitWildRush.instance.SetRushInfo(InputMgr.instance.mOwner, targetPos, mapId);
                return;
            }
            Unit attacker = InputMgr.instance.mOwner;
            Unit target = SkillHelper.instance.GetNTarByTypeId(attacker, roleId);
            if (target == null)
            {
                stopDis = ActionHelper.GetUnitBoundingW(roleId);
                if (stopDis <= 0) stopDis = 1;
            }
            else
            {
                stopDis = SkillHelper.instance.GetUnitModelRadius(target);
                targetPos = target.Position;
            }
            stopDis += 0.3f;

            SetMisTarID(roleId);
        }
        //if (IsStarNav == true) return;
        //IsStarNav = true;
        unit.mUnitMove.StartNav(targetPos, stopDis, mapId, NavPathsComplete);
       // iTrace.Warning("hs", "################ 开始寻路 StartNav");
    }

    /// <summary>
    /// 设置目标Id
    /// </summary>
    /// <param name="roleId"></param>
    public void SetMisTarID(uint roleId)
    {
        if (roleId == 0)
            return;
        UnitType type = UnitHelper.instance.GetUnitType(roleId);
        if (type != UnitType.Monster)
        {
            ResetMisTarID();
            return;
        }
        HangupMgr.instance.IsMisKill = true;
    }

    /// <summary>
    /// 重置任务目标ID
    /// </summary>
    public void ResetMisTarID()
    {
        MissTargetID = 0;
        HangupMgr.instance.IsMisKill = false;
    }

    public void MissionFlyShoes(int missionID, Vector3 targetPos, Int32 mapId, float stopDis = -1f, uint roleId = 0)
    {
        //if (MissID == missionID) return;
        MissID = missionID;
        FlyShoes(targetPos, mapId, stopDis, roleId);
    }

    public void FlyShoes(Vector3 targetPos, Int32 mapId, float stopDis = -1f, uint roleId = 0)
    {
        //iTrace.eError("hs", "---------------->>>  FlyShoes");
        SetMisTarID(roleId);
        MissTargetID = roleId;
        mShoesStatus = true;
        MapHelper.instance.LittleFlyShoes(mapId, targetPos, stopDis, false, 0.5f, 0f, NavPathsComplete);
    }

    public void StopNavPath()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null) return;
        unit.mUnitMove.StopNav();
        HangupMgr.instance.IsAutoSkill = false;
        HangupMgr.instance.IsMisKill = false;
        UnitHelper.instance.ResetUnitData(InputMgr.instance.mOwner);
        MissID = 0;
    }

    /// <summary>
    /// 强制中断寻路
    /// </summary>
    public void ForceStopNavPath()
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null || unit.mUnitMove.Pathfinding == null)
            return;
        unit.mUnitMove.Pathfinding.ForceStopPathFinding(true);
    }

    public void ClearPlayerNavState(int stopType)
    {
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return;
        unit.mUnitMove.Pathfinding.ResetAllState((AsPathfinding.PathResultType)stopType);
    }

    public void NavPathsComplete(Unit unit, AsPathfinding.PathResultType type)
    {
        //iTrace.Warning("hs", "################ 寻路回调 NavPathsComplete");
        UnitHelper.instance.ResetUnitData(unit);
        HangupMgr.instance.IsAutoSkill = false;
        mShoesStatus = false;
        switch (type)
        {
            case AsPathfinding.PathResultType.PRT_PATH_SUC:
                //EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
                break;
            case AsPathfinding.PathResultType.PRT_CALL_BREAK:
                HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_PASSIVEBREAK:
                HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_ERROR_BREAK:
                HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_FORBIDEN:
                HangupMgr.instance.Clear();
                break;
            default:
                {
                    HangupMgr.instance.Clear();
                    iTrace.eError("LY", "Path finding result error !!! " + type);
                }
                break;
                

            //case AsPathfinding.PathResultType.PRT_SHOES_SUC:
            //    mShoesStatus = false;
            //    EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
            //    break;
            //case AsPathfinding.PathResultType.PRT_PATH_SUC:
            //    EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
            //    break;
            //case AsPathfinding.PathResultType.PRT_SHOES_BREAK:
            //    //iTrace.eError("hs", "---------------->>>  AsPathfinding.PathResultType.PRT_SHOES_BREAK");
            //    mShoesStatus = false;
            //    break;
            //case AsPathfinding.PathResultType.PRT_NOPATH:
            //case AsPathfinding.PathResultType.PRT_CALL_BREAK:
            //case AsPathfinding.PathResultType.PRT_CHANGE_SCENE_BREAK:
            //case AsPathfinding.PathResultType.PRT_FORBIDEN:
            //case AsPathfinding.PathResultType.PRT_RESTART_BREAK:
            //    HangupMgr.instance.Clear();
            //    break;
        }
        EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);

        /**
        if (type == AsPathfinding.PathResultType.PRT_PATH_SUC 
            || type == AsPathfinding.PathResultType.PRT_SHOES_SUC)
        {
            EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
        }
        else if (type == AsPathfinding.PathResultType.PRT_NOPATH
            || type == AsPathfinding.PathResultType.PRT_CALL_BREAK
            || type == AsPathfinding.PathResultType.PRT_CHANGE_SCENE_BREAK 
            ||type == AsPathfinding.PathResultType.PRT_FORBIDEN
            || type == AsPathfinding.PathResultType.PRT_RESTART_BREAK)
        {
            //bool autoMangup = HangupMgr.instance.IsAutoHangup;
            HangupMgr.instance.Clear();
            //if ((type == AsPathfinding.PathResultType.PRT_CALL_BREAK ||
            //    type == AsPathfinding.PathResultType.PRT_RESTART_BREAK)&& autoMangup)
            //    HangupMgr.instance.IsAutoHangup = true;
            //iTrace.eLog("hs", "-------------------------->>  寻路中断 " + ((AsPathfinding.PathResultType)type).ToString());
        }
        else if(type == AsPathfinding.PathResultType.PRT_RESTART_BREAK)
        {

        }
    **/
        MissionState = false;
        MissID = 0;
    }

    /// <summary>
    /// 纯粹地调用寻路
    /// </summary>
    /// <param name="targetPos"></param>
    /// <param name="mapId"></param>
    /// <param name="stopDis"></param>
    /// <param name="moveSpd"></param>
    public void StartNavPathPure(Vector3 targetPos, UInt32 mapId, float stopDis = -1f, bool showUI = true, float moveSpd = 0)
    {
        InputMgr.instance.ClearTarget();
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null)
        {
            iTrace.eError("LY", "Owner player miss !!!  UserHandler::StartNavPathPure");
            return;
        }

        unit.mUnitMove.StartNav(targetPos, stopDis, mapId, NavPathsPureComplete, showUI, moveSpd);
    }

    public void NavPathsPureComplete(Unit unit, AsPathfinding.PathResultType type)
    {
        EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
    }

    #endregion

    #region ui相关
    public UInt32 PetID { get { return (UInt32)((InputMgr.instance.mOwner != null && InputMgr.instance.mOwner.Pet != null) ? InputMgr.instance.mOwner.Pet.UnitUID : 3030101); } }

    public void OpenSystemAnime(UInt32 id, UInt16 time)
    {
        UIShowPendant.instance.Open(id, time);
    }
    #endregion

    #region buff
    /// <summary>
    /// 获取buff值
    /// </summary>
    /// <param name="seriesId"></param>
    /// <returns></returns>
    public float GetBufValBySrID(int seriesId)
    {
        float value = 0;
        if (MapData == null)
            return value;
        Unit u = UnitMgr.instance.FindUnitByUid(MapData.UID);
        if (u == null)
            return value;
        value = u.mBuffManager.GetBufValBySrID(seriesId);
        return value;
    }
    #endregion

    /// <summary>
    /// 通过序列ID获取buffId(非共存Buff)
    /// </summary>
    /// <param name="seriesId"></param>
    /// <returns></returns>
    public uint GetBuffIdBySrID(int seriesId)
    {
        uint value = 0;
        if (MapData == null)
            return value;
        Unit u = UnitMgr.instance.FindUnitByUid(MapData.UID);
        if (u == null)
            return value;
        value = u.mBuffManager.GetBuffIdBySrID(seriesId);
        return value;
    }

    #region 采集
    public void PathfindingToCollectionPos(UInt32 id, UInt32 sceneid, float tDis)
    {
        if (CollectionMgr.Collects != null)
        {
            List<Loong.Game.CollectionBase> list = CollectionMgr.Collects;
            foreach(Loong.Game.CollectionBase collection in list)
            {
                if (id != collection.Info.id) continue;
                if (CollectionMgr.State == CollectionState.Req ||
                    CollectionMgr.State == CollectionState.Run) return;
                StopNavPath();
                Vector3 cPos = collection.Go.transform.position;
                Vector3 rPos = User.instance.Pos;
                float dis = Vector3.Distance(new Vector3(cPos.x, 0, cPos.z), new Vector3(rPos.x, 0, rPos.z));
                if (tDis < dis)
                    StartNavPath(collection.Go.transform.position, sceneid);
                else
                    UIMgr.Open("UICollection");
                //HangupMgr.instance.IsAutoSkill = false;
                //if (InputVectorMove.instance.MoveUnit == null) return;
                //InputVectorMove.instance.MoveUnit.mUnitMove.StartNav(list[i].Go.transform.position, sceneid, NavPathsComplete);
                return;
            }
        }
    }
    #endregion

	#region 掉落
	public bool	IsDrop()
	{
		DropInfo info = DropMgr.GetCanPickupDrop();
		if (info != null) return true;
		return false;
	}
    #endregion

    #region 任务
    private bool mMissionState = false;
    public bool MissionState
    {
        set
        {
            mMissionState = value;
        }
        get { return mMissionState; }
    }

    private bool mIsEscort = false;
    //护送状态
    public bool IsEscort { set { mIsEscort = value; } get { return mIsEscort; } }
    #endregion

    #region 飞鞋状态
    private bool mShoesStatus = false;
    public bool ShoesStatus
    {
        set { mShoesStatus = value; }
        get { return mShoesStatus; }
    }
    #endregion

    #region 怪物血量
    /// <summary>
    /// 怪物typeid
    /// </summary>
    public int MonsterID = 0;
    public List<EventDelegate> onFinished = new List<EventDelegate>();
    public void UpdateMonsterHP(uint typeid ,long hp, long max)
    {
        UnitType type = UnitHelper.instance.GetUnitType(typeid);
        if (type != UnitType.Monster)
            return;
        EventMgr.Trigger(EventKey.OnUpdateMonsterHP, typeid, hp.ToString(), max.ToString());
    }
    #endregion

    #region 副本
    public void SetCopyDesPos(float startX,float startZ,float endX,float endZ)
    {
        CopyBatMgr.instance.SetDesPos(startX, startZ, endX, endZ);
    }
    #endregion

    #region 服务器时间
    public string GetServerTimeNow()
    {
        return TimeTool.GetServerTimeNow().ToString();
    }
    #endregion
}
