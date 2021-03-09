using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

using Loong.Game;

public class UnitMove
{
    #region 私有变量
    //移动单位
    private Unit mOwner;
    //是否在地面
    private bool mOnGround = true;
    //寻路类
    private AsPathfinding mAsPathfinding;
    #endregion

    #region 属性
    /// <summary>
    /// 是否在地面
    /// </summary>
    public bool OnGround
    {
        get { return mOnGround; }
    }

    /// <summary>
    /// 正在寻路
    /// </summary>
    public bool InPathFinding
    {
        get
        {
            if (mAsPathfinding == null)
            {
                return false;
            }
            return mAsPathfinding.InPathFinding();
        }
    }

    /// <summary>
    /// 路径跟随
    /// </summary>
    //public bool FollowPath
    //{
    //    set { mAsPathfinding.FollowPath = value; }
    //    get { return mAsPathfinding.FollowPath; }
    //}

    /// <summary>
    /// 是否正在跳跃
    /// </summary>
    public bool IsJumping
    {
        get
        {
            if (mAsPathfinding == null)
            {
                return false;
            }
            return mAsPathfinding.InJumping;
        }
    }

    /// <summary>
    /// 寻路对象
    /// </summary>
    public AsPathfinding Pathfinding
    {
        get { return mAsPathfinding; }
        set { mAsPathfinding = value; }
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
        if (unit == null)
            return;
        if (unit.mUnitAttInfo.UnitType == UnitType.Mount)
            return;
        mAsPathfinding = new AsPathfinding(unit);
    }

    /// <summary>
    /// 改变交通工具
    /// </summary>
    /// <param name="unit"></param>
    public void ChangeVehicle(Unit unit)
    {
        if (mAsPathfinding == null)
            return;
        mAsPathfinding.Vehicle = unit;
        if (unit.UnitUID == mOwner.UnitUID)
            return;
        unit.mUnitMove.Pathfinding = mAsPathfinding;
    }

    /// <summary>
    /// 单位移动
    /// </summary>
    public void Move(Vector3 delPos)
    {
        if (!UnitHelper.instance.CanMoveExceptDead(mOwner))
            return;
        if (delPos == Vector3.zero)
            return;

        RaycastHit hit;
        Vector3 origin = mOwner.Position + new Vector3(0, 0.5f, 0);
        Vector3 direction = delPos;
        Ray rayObsta = new Ray(origin, direction);
        if (Physics.Raycast(rayObsta, out hit, direction.magnitude + mOwner.ActionStatus.Bounding.z, (1 << LayerTool.Wall) | (1 << LayerTool.Unit) | (1 << LayerTool.NPC)))
        {
            if (hit.collider.gameObject.layer == LayerTool.Wall || hit.collider.gameObject.tag == TagTool.ObstacleUnit)
                return;
        }

        Vector3 tmpV3 = new Vector3(delPos.x, 0, delPos.z);
        if (tmpV3 != Vector3.zero)
        {
            mOwner.Position += tmpV3;
            if(tmpV3.sqrMagnitude > 0.01f && !mOwner.Dead)
                NetMove.SendMove(mOwner, mOwner.Position, SendMoveType.SendMoveRoleWalk);
        }
        if (delPos.y == 0)
            return;
        float height = UnitHelper.instance.GetTerrainHeight(mOwner.Position);
        if (mOwner.UnitTrans.gameObject.layer == LayerMask.NameToLayer("Skyunit"))
            height += 7;
        if (height < mOwner.Position.y + delPos.y)
        {
            mOnGround = false;
            mOwner.Position += new Vector3(0, delPos.y, 0);
        }
        else
        {
            mOnGround = true;
            mOwner.Position = new Vector3(mOwner.Position.x, height, mOwner.Position.z);
        }
    }

    /// <summary>
    /// 设置自动寻路提示
    /// </summary>
    public void SetAutoPathFindTip(bool isAutoPathFind)
    {
        if (mOwner == null)
            return;
        if (mOwner.UnitUID != User.instance.MapData.UID &&
            mOwner.ParentUnit != null && 
            mOwner.ParentUnit.UnitUID != User.instance.MapData.UID)
            return;
        EventMgr.Trigger("OnAutoPathFind", isAutoPathFind);
    }

    /// <summary>
    /// 开始寻路
    /// </summary>
    /// <param name="target">目标位置</param>
    /// <param name="mapId">地图ID--0代表本地图</param>
    /// <param name="callback">回调</param>
    public bool StartNav(Vector3 targetPos, float stopDis = -1f, uint mapId = 0, Action<Unit, AsPathfinding.PathResultType> callback = null, bool showAutoPathUI = true, float moveSpeed = 0)
    {
        if (mOwner.Dead)
            return false;
        if (!UnitHelper.instance.CanMove(mOwner))
            return false;
        //mOwner.ActionStatus.ChangeMoveAction();
        //AutoMountMgr.instance.StartTimer(mOwner);
        //NavMoveBuff.instance.StartTimer(mOwner);

        if (MapHelper.instance.CheckSceneResExist((int)mapId) == false)
        {
            UITip.LocalLog(690010);
            UIMgr.Open("UIDownload");
            if (callback != null)
            {
                callback(mOwner, AsPathfinding.PathResultType.PRT_CALL_BREAK);
            }
            iTrace.Error("LY", "场景资源尚未加载完成!");
            return false;
        }

        if (moveSpeed == 0)
            moveSpeed = mOwner.MoveSpeed;
        mAsPathfinding.FindPathAndMove(AsPathfinding.PathFindingType.PFT_Sample, mapId, mOwner.Position, targetPos, moveSpeed, stopDis, callback);
        if (!showAutoPathUI)
            return true;
        SetAutoPathFindTip(true);
        return true;
    }

    /// <summary>
    /// 跟从配置路径行走
    /// </summary>
    /// <param name="pathId"></param>
    public void FallowPath(ushort pathId, Action<Unit, AsPathfinding.PathResultType> finCB = null)
    {
        PathInfo tInfo = PathInfoManager.instance.Find(pathId);
        if (tInfo == null)
        {
            iTrace.Error("LY", "Can not find path : " + pathId);
            return;
        }

        List<FigPathPotInfo> tPathPoints = new List<FigPathPotInfo>();
        for(int a = 0; a < tInfo.points.list.Count; a++)
        {
            PathInfo.PointInfo tPInfo = tInfo.points.list[a];
            FigPathPotInfo tFPInfo = new FigPathPotInfo();
            tFPInfo.mPoint = new Vector3(tPInfo.point.x * 0.01f, 0f, tPInfo.point.z * 0.01f);
            tFPInfo.mDuration = (float)tPInfo.duration;
            tFPInfo.mDelay = (float)tPInfo.delay;

            tPathPoints.Add(tFPInfo);
        }

        mOwner.ActionStatus.ChangeMoveAction();

        bool tDefSpd = tInfo.defaultSpeed == 1;
        mAsPathfinding.FallowPath(mOwner.Position, tPathPoints, tDefSpd, mOwner.MoveSpeed, finCB);
    }

    //public void JumpOverAndPathFinding()
    //{
    //    mAsPathfinding.JumpFinishCallBack();
    //}

    /// <summary>
    /// 停止寻路
    /// </summary>
    public void StopNav(bool bStopAnim = true)
    {
        if (mAsPathfinding == null)
            return;
        UnitHelper.instance.ResetUnitData(mOwner);
        if (mAsPathfinding.PathFinish())
            return;
        mAsPathfinding.StopPathFinding(bStopAnim);
    }

    /// <summary>
    /// 设置自动寻路移动速度
    /// </summary>
    /// <param name="moveSpeed"></param>
    public void SetPathFindingSpeed(float moveSpeed)
    {
        if (mAsPathfinding == null)
            return;
        mAsPathfinding.MoveSpeed = moveSpeed;
    }

    /// <summary>
    /// 移动更新
    /// </summary>
    public void Update()
    {
        if (mAsPathfinding == null)
            return;
        if (mOwner != mAsPathfinding.Vehicle)
            return;
        mAsPathfinding.Move();
    }

    public void Dispose()
    {
        mOwner = null;
        mOnGround = true;
        mAsPathfinding = null;
}

    ///// <summary>
    ///// 请求跳跃
    ///// </summary>
    ///// <param name="unit"></param>
    ///// <param name="jumpType"></param>
    ///// <param name="desPos"></param>
    ///// <param name="portalId"></param>
    ///// <param name="mapId"></param>
    //public void RequestJump(Unit unit, JumpType jumpType, Vector3 desPos, uint portalId, uint mapId = 0)
    //{
    //    mUnitJumpType = jumpType;
    //    NetMove.RequestChangePosDir(unit, desPos, (int)mapId, (int)portalId);
    //}

    ///// <summary>
    ///// 跳转点跳跃
    ///// </summary>
    ///// <param name="mUnit"></param>
    ///// <param name="portalId"></param>
    ///// <param name="finCB"></param>
    //public void ServerCallJumpPath(uint portalId)
    //{
    //    mAsPathfinding.CallPathJump(portalId, mUnitJumpType);
    //}

    ///// <summary>
    ///// 清除跳跃标记
    ///// </summary>
    //public void ClearJumpState()
    //{
    //    mUnitJumpType = JumpType.JT_NONE;
    //}
    #endregion
}
