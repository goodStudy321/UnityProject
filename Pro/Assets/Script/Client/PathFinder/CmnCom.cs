using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// Ѱ·����ṹ
/// </summary>
public class ReqPathFinding
{
    public AsPathfinding.PathFindingType mPFType = AsPathfinding.PathFindingType.PFT_UnKnown;
    /// <summary>
    /// Ŀ���ͼId
    /// </summary>
    public uint mapId = 0;
    /// <summary>
    /// ��ʼ��ת��Id
    /// </summary>
    public uint fromPortalId = 0;
    /// <summary>
    /// Ŀ����ת��Id
    /// </summary>
    public uint toPortalId = 0;
    /// <summary>
    /// ��ʼλ��
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// Ŀ��λ��
    /// </summary>
    public Vector3 endPos;
    /// <summary>
    /// ��Ծ�յ���Ϣ
    /// </summary>
    public long jumpDes = 0;
    /// <summary>
    /// �����ٶ�
    /// </summary>
    public float walkSpd = 1.0f;
    /// <summary>
    /// ֹͣ����
    /// </summary>
    public float stopDis = -1;
    /// <summary>
    /// ����ص�
    /// </summary>
    public Action<Unit, AsPathfinding.PathResultType> finCB = null;

    /// <summary>
    /// ��ʾת����������ʱ
    /// </summary>
    public bool showCSTip = false;
    /// <summary>
    /// ǰ�õȴ�ʱ�䣨ת������С��Ьʹ�ã�
    /// </summary>
    public float preTime = 0f;
    /// <summary>
    /// ���õȴ�ʱ�䣨ת������С��Ьʹ�ã�
    /// </summary>
    public float afterTime = 0f;

    /// <summary>
    /// ����·��ʹ��Ĭ���ٶ�
    /// </summary>
    public bool flUseDefSpd = false;
    /// <summary>
    /// ����·����Ϣ
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