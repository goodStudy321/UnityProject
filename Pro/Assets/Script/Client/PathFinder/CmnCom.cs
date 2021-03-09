using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 寻路请求结构
/// </summary>
public class ReqPathFinding
{
    public AsPathfinding.PathFindingType mPFType = AsPathfinding.PathFindingType.PFT_UnKnown;
    /// <summary>
    /// 目标地图Id
    /// </summary>
    public uint mapId = 0;
    /// <summary>
    /// 起始跳转口Id
    /// </summary>
    public uint fromPortalId = 0;
    /// <summary>
    /// 目标跳转口Id
    /// </summary>
    public uint toPortalId = 0;
    /// <summary>
    /// 开始位置
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// 目标位置
    /// </summary>
    public Vector3 endPos;
    /// <summary>
    /// 跳跃终点信息
    /// </summary>
    public long jumpDes = 0;
    /// <summary>
    /// 行走速度
    /// </summary>
    public float walkSpd = 1.0f;
    /// <summary>
    /// 停止距离
    /// </summary>
    public float stopDis = -1;
    /// <summary>
    /// 结果回调
    /// </summary>
    public Action<Unit, AsPathfinding.PathResultType> finCB = null;

    /// <summary>
    /// 显示转换场景倒计时
    /// </summary>
    public bool showCSTip = false;
    /// <summary>
    /// 前置等待时间（转场景、小飞鞋使用）
    /// </summary>
    public float preTime = 0f;
    /// <summary>
    /// 后置等待时间（转场景、小飞鞋使用）
    /// </summary>
    public float afterTime = 0f;

    /// <summary>
    /// 跟随路径使用默认速度
    /// </summary>
    public bool flUseDefSpd = false;
    /// <summary>
    /// 跟随路径信息
    /// </summary>
    public List<FigPathPotInfo> pathInfo = null;


    public ReqPathFinding Copy()
    {
        ReqPathFinding retData = new ReqPathFinding();

        retData.mPFType = mPFType;
        retData.mapId = mapId;
        retData.fromPortalId = fromPortalId;
        retData.toPortalId = toPortalId;
        retData.startPos = startPos;
        retData.endPos = endPos;
        retData.jumpDes = jumpDes;
        retData.walkSpd = walkSpd;
        retData.stopDis = stopDis;
        retData.finCB = finCB;
        retData.showCSTip = showCSTip;
        retData.preTime = preTime;
        retData.afterTime = afterTime;
        retData.flUseDefSpd = flUseDefSpd;
        
        if(pathInfo != null)
        {
            retData.pathInfo = new List<FigPathPotInfo>();
            for (int a = 0; a < pathInfo.Count; a++)
            {
                retData.pathInfo.Add(pathInfo[a].Copy());
            }
        }

        return retData;
    }
}