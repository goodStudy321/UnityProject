using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 地图数据
/// </summary>
public class AsMapData
{
    /// <summary>
    /// 地图Id
    /// </summary>
    public uint mapId = 0;

    public uint mXLen = 0;
    public uint mYLen = 0;
    /// <summary>
    /// 地图数据
    /// </summary>
    public AsNode[,] Map = null;

    /// <summary>
    /// 地图区块列表
    /// </summary>
    public List<MapBlock> mapBlockList = new List<MapBlock>();

    /// <summary>
    /// 地图传送口列表
    /// </summary>
    public List<PortalInfo> portalList = new List<PortalInfo>();


    public AsMapData()
    {

    }

    /// <summary>
    /// 填充地图数据
    /// </summary>
    /// <param name="xLen"></param>
    /// <param name="yLen"></param>
    /// <param name="nodeList"></param>
    /// <param name="savePortalList"></param>
    //public void InitMapDetail(uint xLen, uint yLen, List<SaveMapNode> nodeList, List<SavePortalInfo> savePortalList, List<SaveAwakenPortalInfo> saveAPortalList)
    //{
    //    if(nodeList == null || nodeList.Count <= 0)
    //    {
    //        iTrace.Error("LY", "Map node data error !!! ");
    //        return;
    //    }

    //    mXLen = xLen;
    //    mYLen = yLen;
    //    Map = new AsNode[xLen, yLen];
    //    for(int a = 0; a < nodeList.Count; a++)
    //    {
    //        int xIndex = nodeList[a].x;
    //        int yIndex = nodeList[a].y;

    //        AsNode tNode = MapPathMgr.instance.GetAsNode();
    //        tNode.SetData(nodeList[a]);
    //        Map[xIndex, yIndex] = tNode;
    //        if (tNode.CanWalk)
    //        {
    //            /// 划分区块 ///
    //            MapBlock tBlock = GetMapBlock(tNode.baseData.blBlockId);
    //            if (tBlock != null)
    //            {
    //                tBlock.AddNode(tNode);
    //            }
    //            else
    //            {
    //                tBlock = new MapBlock(tNode.baseData.blBlockId);
    //                tBlock.AddNode(tNode);
    //                mapBlockList.Add(tBlock);
    //            }
    //        }
    //    }

    //    for(int a = 0; a < savePortalList.Count; a++)
    //    {
    //        portalList.Add(new PortalInfo(savePortalList[a]));
    //    }

    //    if (saveAPortalList != null)
    //    {
    //        for (int a = 0; a < saveAPortalList.Count; a++)
    //        {
    //            awakenPortalList.Add(new AwakenPortalInfo(saveAPortalList[a]));
    //        }
    //    }
    //}

    public void InitBinaryMapDetail(uint xLen, uint yLen, List<BinaryMapNode> nodeList, List<SavePortalInfo> savePortalList)
    {
        if (nodeList == null || nodeList.Count <= 0)
        {
            iTrace.Error("LY", "Map node data error !!! ");
            return;
        }

        if (xLen <= 0 || xLen > 10000 || yLen <= 0 || yLen > 10000)
        {
            iTrace.Error("LY", "Map node X Y error !!! ");
            return;
        }

        mXLen = xLen;
        mYLen = yLen;
        Map = new AsNode[xLen, yLen];
        for (int a = 0; a < nodeList.Count; a++)
        {
            int xIndex = nodeList[a].x;
            int yIndex = nodeList[a].y;

            AsNode tNode = MapPathMgr.instance.GetAsNode();
            tNode.SetData(nodeList[a]);
            Map[xIndex, yIndex] = tNode;
            if (tNode.CanWalk)
            {
                /// 划分区块 ///
                MapBlock tBlock = GetMapBlock(tNode.baseData.blBlockId);
                if (tBlock != null)
                {
                    tBlock.AddNode(tNode);
                }
                else
                {
                    tBlock = new MapBlock(tNode.baseData.blBlockId);
                    tBlock.AddNode(tNode);
                    mapBlockList.Add(tBlock);
                }
            }
        }

        for (int a = 0; a < savePortalList.Count; a++)
        {
            portalList.Add(new PortalInfo(savePortalList[a]));
        }
    }

    public void Dispose()
    {
        for(int a = 0; a < mXLen; a++)
        {
            for(int b = 0; b < mYLen; b++)
            {
                AsNode tNode = Map[a, b];
                if(tNode != null)
                {
                    MapPathMgr.instance.RecycleAsNode(tNode);
                }
            }
        }
        Map = null;
    }

    /// <summary>
    /// 添加新区块
    /// </summary>
    /// <param name="node"></param>
    public void AddMapBlock(AsNode node)
    {
        MapBlock newBlock = new MapBlock((UInt16)(mapBlockList.Count + 1));
        newBlock.AddNode(node);
        mapBlockList.Add(newBlock);
    }

    public void ResetBlockId()
    {
        if (mapBlockList == null)
            return;

        for(int a = 0; a < mapBlockList.Count; a++)
        {
            mapBlockList[a].mBlockId = (ushort)(a + 1);
        }
    }

    public void FillNodesBlockId()
    {
        if (mapBlockList == null)
            return;

        for (int a = 0; a < mapBlockList.Count; a++)
        {
            List<AsNode> tNodeList = mapBlockList[a].mMapNode;
            for (int b = 0; b < tNodeList.Count; b++)
            {
                tNodeList[b].baseData.blBlockId = mapBlockList[a].mBlockId;
            }
        }
    }

    /// <summary>
    /// 获取地图区块
    /// </summary>
    /// <param name="blockId"></param>
    /// <returns></returns>
    public MapBlock GetMapBlock(uint blockId)
    {
        for(int a = 0; a < mapBlockList.Count; a++)
        {
            if(mapBlockList[a].mBlockId == blockId)
            {
                return mapBlockList[a];
            }
        }
        return null;
    }

    /// <summary>
    /// 传送口是否存在
    /// </summary>
    /// <param name="pId"></param>
    /// <returns></returns>
    public bool ContainsPortal(uint pId)
    {
        for(int a = 0; a < portalList.Count; a++)
        {
            if(portalList[a].portalId == pId)
            {
                return true;
            }
        }
        return false;
    }

    /// <summary>
    /// 添加传送口
    /// </summary>
    /// <param name="pInfo"></param>
    public void AddPortalInfo(PortalInfo pInfo)
    {
        if(ContainsPortal(pInfo.portalId))
        {
            iTrace.Error("LY", "Portal has existed !!! " + pInfo.portalId);
            return;
        }
        portalList.Add(pInfo);
    }

    /// <summary>
    /// 获取传送口
    /// </summary>
    /// <param name="portalId"></param>
    /// <returns></returns>
    public PortalInfo GetPortalInfo(uint portalId)
    {
        for(int a = 0; a < portalList.Count; a++)
        {
            if(portalList[a].portalId == portalId)
            {
                return portalList[a];
            }
        }
        return null;
    }

    public AsNode GetMapNodeByIndex(uint x, uint y)
    {
        if (x >= Map.GetLength(0) || y >= Map.GetLength(1))
        {
            return null;
        }

        return Map[x, y];
    }
}