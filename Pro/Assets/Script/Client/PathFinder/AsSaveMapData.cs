//using UnityEngine;
//using System;
//using System.Collections;
//using System.Collections.Generic;

//using Loong.Game;


/// <summary>
/// 地图数据
/// </summary>
//[Serializable]
//public class AsSaveMapData : ScriptableObject
//{
//    public uint mapId = 0;                              /* 地图Id */
//    public float tilesize = 1;                          /* 格子大小 */
//    public float falldownHeight = 0f;                   /* 掉落高度 */
//    public float climbLimit = 0f;                       /* 爬坡高度 */
//    public Vector3 startPosition = Vector3.zero;        /* 地图起始点（最小点、左下角） */
//    public Vector3 endPosition = Vector3.zero;          /* 地图结束点（最大点、右上角） */
//    public int heuristicAggression;
//    public bool moveDiagonal = true;                    /* 斜线移动 */

//    public string portalTag;                            /* 地图传送点标签 */
//    [SerializeField]
//    public List<string> disallowedTags;                 /* 禁止检测标签 */
//    [SerializeField]
//    public List<string> ignoreTags;                     /* 忽略检测标签 */

//    public uint xNum = 0;
//    public uint yNum = 0;
//    /// <summary>
//    /// 地图节点列表
//    /// </summary>
//    [SerializeField]
//    public List<SaveMapNode> saveMapNodes = new List<SaveMapNode>();

//    /// <summary>
//    /// 地图传送口列表
//    /// </summary>
//    [SerializeField]
//    public List<SavePortalInfo> portalList = new List<SavePortalInfo>();


//    public AsSaveMapData()
//    {

//    }

//    public void FillMapNode(AsNode[,] mapNode)
//    {
//        xNum = (uint)mapNode.GetLength(0);
//        yNum = (uint)mapNode.GetLength(1);

//        for (int i = 0; i < mapNode.GetLength(1); i++)
//        {
//            for (int j = 0; j < mapNode.GetLength(0); j++)
//            {
//                if(mapNode[j, i] != null)
//                {
//                    mapNode[j, i].baseData.FillConnectNode(mapNode[j, i].connectNodes);
//                    saveMapNodes.Add(mapNode[j, i].baseData.Clone());
//                }
//            }
//        }
//    }

//    public void AddPortalInfo(PortalInfo pInfo, PortalFig pFig)
//    {
//        portalList.Add(new SavePortalInfo(pInfo, pFig));
//    }
//}