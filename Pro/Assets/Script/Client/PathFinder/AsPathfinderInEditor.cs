#if UNITY_EDITOR

using UnityEngine;
using UnityEngine.SceneManagement;
using System;
using System.IO;
//using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
//using System.Diagnostics;
//using System.Threading;
using UnityEditor;
using UnityEditor.SceneManagement;

//using ProtoBuf;
using Loong.Game;
using Phantom.Protocal;


/// <summary>
/// A*地图生成编辑器
/// </summary>
[ExecuteInEditMode]
public class AsPathfinderInEditor : MonoBehaviour
{
    /// 地图ID ///
    [HideInInspector] [SerializeField]
    public uint MapId = 0;
    /// 地图类型(1:野外  2：副本) ///
    [HideInInspector] [SerializeField]
    public uint MapType = 1;
    /// 格子大小 ///
    [HideInInspector] [SerializeField]
    public float Tilesize = 1;
    /// 最大掉落高度 ///
    [HideInInspector] [SerializeField]
    public float MaxFalldownHeight = 0.5f;
    /// 爬坡高度 ///
    [HideInInspector] [SerializeField]
    public float ClimbLimit = 0.5f;
    /// 斜线移动 ///
    [HideInInspector] [SerializeField]
    public bool MoveDiagonal = true;

    /// 地图起始点（最小点、左下角） ///
    [HideInInspector] [SerializeField]
    public Vector3 MapStartPosition;
    /// 地图结束点（最大点、右上角） ///
    [HideInInspector] [SerializeField]
    public Vector3 MapEndPosition;

    public void SetMapStartPosition(Vector3 pos)
    {
        MapStartPosition = pos;
        SceneView.RepaintAll();
    }
    public void SetMapEndPosition(Vector3 pos)
    {
        MapEndPosition = pos;
        SceneView.RepaintAll();
    }


    /// 地图行走区域标签 ///
    [HideInInspector][SerializeField]
    public string MapAreaTag = "MapArea";

    /// 地图传送点标签 ///
    [HideInInspector][SerializeField]
    public string MapPortalTag = "MapPortal";

    [HideInInspector][SerializeField]
    public string MapBlockTag = "MapBlock";

    [HideInInspector][SerializeField]
    public string MapBlockSpeTag = "MapBlockSpe";

    [HideInInspector][SerializeField]
    public string MapSaveZoneTag = "MapSaveZone";

    [HideInInspector][SerializeField]
    public string MapLoadZoneTag = "LoadZone";


    [HideInInspector]
    public bool DrawMapInEditor = false;
    [HideInInspector]
    public bool DrawPortalInEditor = false;
    [HideInInspector]
    public bool DrawAppearZoneInEditor = false;
    [HideInInspector]
    public bool CheckFullTileSize = false;

    public List<string> DisallowedTags;
    public List<string> IgnoreTags;

    [HideInInspector]
    public int HeuristicAggression;

    public bool DrawMap
    {
        set {
            SceneView.RepaintAll();
            if (DrawMapInEditor != value)
            {
                DrawMapLines(value);
            }
            DrawMapInEditor = value;
        }
        get { return DrawMapInEditor; }
    }


    /// <summary>
    /// 地图数据
    /// </summary>
    private AsMapData mAsMap = null;
    /// <summary>
    /// 传送口列表
    /// </summary>
    private List<PortalFig> mPortalList = new List<PortalFig>();
    /// <summary>
    /// 操控传送口列表
    /// </summary>
    private List<AwakenPortalFig> mAwakenPortalList = new List<AwakenPortalFig>();


    //Set singleton!
    void Awake()
    {
        MapStartPosition = new Vector3(-20, -20, -20);
        MapEndPosition = new Vector3(20, 20, 20);

        DisallowedTags = new List<string>();
        DisallowedTags.Add("MapBlock");
        DisallowedTags.Add("MapBlockSpe");

        IgnoreTags = new List<string>();
        IgnoreTags.Add("Untagged");
        IgnoreTags.Add("Player");
        IgnoreTags.Add("Enemy");
        IgnoreTags.Add("MapDoorBlock");
    }

    void Start()
    {
        if (Tilesize <= 0)
        {
            Tilesize = 1;
        }

        //AsPathfinder.Instance.CreateMap();
    }

    private void OnDestroy()
    {
        if(mArrowGo != null)
        {
            GameObject.DestroyImmediate(mArrowGo);
            mArrowGo = null;
        }
    }

    //Go through one 
    void Update()
    {
        DrawMapLines(DrawMapInEditor);
    }

    #region map
    //-------------------------------------------------INSTANIATE MAP-----------------------------------------------//

    //private void FillMapNode(uint xLen, uint yLen, List<SaveMapNode> nodeList, List<SavePortalInfo> savePortalList)
    //{
    //    mAsMap.InitMapDetail(xLen, yLen, nodeList, savePortalList);
    //}

    private void FillBinaryMapNode(uint xLen, uint yLen, List<BinaryMapNode> nodeList, List<SavePortalInfo> savePortalList)
    {
        mAsMap.InitBinaryMapDetail(xLen, yLen, nodeList, savePortalList);
    }

    /// <summary>
    /// 读取地图
    /// </summary>
    /// <param name="mapData"></param>
    //public void LoadMap(AsSaveMapData mapData, List<PortalFig> pFigList)
    //{
    //    if (mAsMap == null)
    //    {
    //        mAsMap = new AsMapData();
    //    }

    //    if (mapData == null)
    //    {
    //        iTrace.Error("LY", "Save map data is null !!! ");
    //        return;
    //    }

    //    mPortalList = pFigList;

    //    MapId = mapData.mapId;
    //    Tilesize = mapData.tilesize;
    //    MaxFalldownHeight = mapData.falldownHeight;
    //    ClimbLimit = mapData.climbLimit;
    //    MapStartPosition = mapData.startPosition;
    //    MapEndPosition = mapData.endPosition;
    //    HeuristicAggression = mapData.heuristicAggression;
    //    MoveDiagonal = mapData.moveDiagonal;

    //    MapPortalTag = mapData.portalTag;
    //    DisallowedTags = new List<string>(mapData.disallowedTags);
    //    IgnoreTags = new List<string>(mapData.ignoreTags);

    //    FillMapNode(mapData.xNum, mapData.yNum, mapData.saveMapNodes, mapData.portalList);
    //}

    /// <summary>
    /// 读取地图
    /// </summary>
    /// <param name="mapData"></param>
    public void LoadBinaryMap(BinaryMapData mapData, List<PortalFig> pFigList, GameObject rotZoneRoot = null, 
        GameObject ctrlPortalRoot = null, GameObject loadZoneRoot = null, GameObject appearZoneRoot = null)
    {
        if (mAsMap == null)
        {
            mAsMap = new AsMapData();
        }

        if (mapData == null)
        {
            iTrace.Error("LY", "Save map data is null !!! ");
            return;
        }

        mPortalList = pFigList;

        MapId = mapData.mapId;
        Tilesize = mapData.tilesize;
        MaxFalldownHeight = mapData.falldownHeight;
        ClimbLimit = mapData.climbLimit;
        MapStartPosition = mapData.StartPos;
        MapEndPosition = mapData.EndPos;
        HeuristicAggression = mapData.heuristicAggression;
        MoveDiagonal = mapData.moveDiagonal;

        MapPortalTag = mapData.portalTag;
        DisallowedTags = new List<string>(mapData.disallowedTags);
        IgnoreTags = new List<string>(mapData.ignoreTags);

        if (ctrlPortalRoot != null && mapData.awakenPortalList != null && mapData.awakenPortalList.Count > 0)
        {
            for (int a = 0; a < mapData.awakenPortalList.Count; a++)
            {
                SaveAwakenPortalInfo tSAPI = mapData.awakenPortalList[a];
                GameObject tObj = ctrlPortalRoot.transform.GetChild(a).gameObject;
                AwakenPortalFig tAPF = tObj.GetComponent<AwakenPortalFig>();
                if (tAPF == null)
                {
                    tAPF = tObj.AddComponent<AwakenPortalFig>();
                }
                tAPF.mPortalId = tSAPI.portalId;
                tAPF.mLinkMapId = tSAPI.linkMapId;
            }
        }

        if (rotZoneRoot != null && mapData.camRotDatas != null && mapData.camRotDatas.Count > 0)
        {
            for(int a = 0; a < mapData.camRotDatas.Count; a++)
            {
                CamRotTriggerData tData = mapData.camRotDatas[a];
                GameObject camRotZone = Utility.FindNode(rotZoneRoot, tData.rootObjName);
                if(camRotZone != null)
                {
                    CameraRotateBind tCRB = camRotZone.AddComponent<CameraRotateBind>();
                    tCRB.TargetAngles = tData.targetAngles;
                    tCRB.Opposite = tData.opposite;
                    tCRB.IsTrigger = tData.isTrigger;
                    tCRB.Speed = tData.speed;

                    GameObject tC1 = Utility.FindNode(camRotZone, tData.child1Name);
                    if (tC1 != null)
                    {
                        tCRB.dTrgger1 = tC1.AddComponent<DirTriggerChild>();
                    }
                    GameObject tC2 = Utility.FindNode(camRotZone, tData.child2Name);
                    if (tC2 != null)
                    {
                        tCRB.dTrgger2 = tC2.AddComponent<DirTriggerChild>();
                    }
                }

            }
        }

        if (loadZoneRoot != null && mapData.loadZoneDatas != null && mapData.loadZoneDatas.Count > 0)
        {
            for (int a = 0; a < mapData.loadZoneDatas.Count; a++)
            {
                if(a >= loadZoneRoot.transform.childCount)
                {
                    continue;
                }

                PreLoadZoneData tPZD = mapData.loadZoneDatas[a];
                GameObject tObj = loadZoneRoot.transform.GetChild(a).gameObject;
                PreloadZone tPZ = tObj.GetComponent<PreloadZone>();
                if (tPZ == null)
                {
                    tPZ = tObj.AddComponent<PreloadZone>();
                }
                tPZ.mZoneId = tPZD.zoneId;
                tPZ.mSourceId = tPZD.resIndex;
            }
        }

        if (appearZoneRoot != null && mapData.appearZoneFigs != null && mapData.appearZoneFigs.Count > 0)
        {
            for(int a = 0; a < appearZoneRoot.transform.childCount; a++)
            {
                GameObject tObj = appearZoneRoot.transform.GetChild(a).gameObject;
                BinaryAppearZoneFig tBAZF = null;
                for (int b = 0; b < mapData.appearZoneFigs.Count; b++)
                {
                    if(tObj.name == mapData.appearZoneFigs[b].mZoneName)
                    {
                        tBAZF = mapData.appearZoneFigs[b];
                        break;
                    }
                }

                if(tBAZF != null)
                {
                    AppearCtrlZone tACZ = tObj.GetComponent<AppearCtrlZone>();
                    if (tACZ == null)
                    {
                        tACZ = tObj.AddComponent<AppearCtrlZone>();
                    }
                    tACZ.mZoneName = tBAZF.mZoneName;
                    tACZ.mShowZoneNames = new List<string>(tBAZF.mShowZoneNames);
                    tACZ.mHideZoneNames = new List<string>(tBAZF.mHideZoneNames);
                }
            }
        }

        FillBinaryMapNode(mapData.xNum, mapData.yNum, mapData.saveMapNodes, mapData.portalList);
    }

    #endregion //End map

    //---------------------------------------DRAW MAP IN EDITOR-------------------------------------//
    #region 绘制地图区域
    void OnDrawGizmosSelected()
    {
        if (Application.isPlaying == true)
        {
            return;
        }

        if (DrawMapInEditor == true)
        {
            Gizmos.color = new Color(1, 1, 1, 0.3f);
            Vector3 tCenter = (MapStartPosition + MapEndPosition) / 2.0f;
            Vector3 tSize = MapEndPosition - MapStartPosition;

            /// 绘制生成寻路范围 ///
            Gizmos.DrawCube(tCenter, tSize);
        }
    }

    private List<Vector3> portalCenters = null;
    private List<Vector3> portalSizes = null;

    [DrawGizmo(GizmoType.Active | GizmoType.NonSelected | GizmoType.Selected)]
    public void DrawPortalArea(bool isDraw, List<Vector3> centers, List<Vector3> sizes)
    {
        DrawPortalInEditor = isDraw;
        if(DrawPortalInEditor == true)
        {
            portalCenters = centers;
            portalSizes = sizes;
        }
        else
        {
            portalCenters = null;
            portalSizes = null;
        }
    }

    private List<Vector3> appearZoneCenters = null;
    private List<Vector3> appearZoneSizes = null;
    private List<Color> appearZoneColors = null;

    [DrawGizmo(GizmoType.Active | GizmoType.NonSelected | GizmoType.Selected)]
    public void DrawAppearZone(bool isDraw, List<Vector3> centers, List<Vector3> sizes, List<Color> colors)
    {
        DrawAppearZoneInEditor = isDraw;
        if (DrawAppearZoneInEditor == true)
        {
            appearZoneCenters = centers;
            appearZoneSizes = sizes;
            appearZoneColors = colors;
        }
        else
        {
            appearZoneCenters = null;
            appearZoneSizes = null;
            appearZoneColors = null;
        }
    }

    private void OnDrawGizmos()
    {
        if (DrawPortalInEditor)
        {
            Gizmos.color = new Color(0, 0.2f, 1.0f, 0.3f);
            for (int a = 0; a < portalCenters.Count; a++)
            {
                Gizmos.DrawCube(portalCenters[a], portalSizes[a]);
            }
        }

        if (DrawAppearZoneInEditor)
        {
            for (int a = 0; a < appearZoneCenters.Count; a++)
            {
                Gizmos.color = appearZoneColors[a];
                Gizmos.DrawCube(appearZoneCenters[a], appearZoneSizes[a]);
            }
        }
    }

    void DrawMapLines(bool isDraw)
    {
        /// 画线 ///
        if (isDraw == true && mAsMap != null && mAsMap.Map != null)
        {
            for (int i = 0; i < mAsMap.Map.GetLength(1); i++)
            {
                for (int j = 0; j < mAsMap.Map.GetLength(0); j++)
                {
                    if (mAsMap.Map[j, i] == null)
                        continue;
                    
                    if (!mAsMap.Map[j, i].CanWalk && mAsMap.Map[j, i].IsWall == false)
                    {
                        continue;
                    }

                    float halfT = Tilesize / 2;
                    Vector3 tPos = mAsMap.Map[j, i].pos;
                    Vector3 pot1 = new Vector3(tPos.x - halfT, tPos.y, tPos.z - halfT);
                    Vector3 pot2 = new Vector3(tPos.x - halfT, tPos.y, tPos.z + halfT);
                    Vector3 pot3 = new Vector3(tPos.x + halfT, tPos.y, tPos.z - halfT);
                    Vector3 pot4 = new Vector3(tPos.x + halfT, tPos.y, tPos.z + halfT);

                    if (mAsMap.Map[j, i].IsProtal == true)
                    {
                        UnityEngine.Debug.DrawLine(pot1, pot2, Color.blue);
                        UnityEngine.Debug.DrawLine(pot2, pot3, Color.blue);
                        UnityEngine.Debug.DrawLine(pot3, pot4, Color.blue);
                        UnityEngine.Debug.DrawLine(pot4, pot1, Color.blue);
                        UnityEngine.Debug.DrawLine(pot1, pot3, Color.blue);
                        UnityEngine.Debug.DrawLine(pot2, pot4, Color.blue);
                    }
                    else if (mAsMap.Map[j, i].IsWall == true)
                    {
                        UnityEngine.Debug.DrawLine(pot1, pot2, Color.red);
                        UnityEngine.Debug.DrawLine(pot2, pot3, Color.red);
                        UnityEngine.Debug.DrawLine(pot3, pot4, Color.red);
                        UnityEngine.Debug.DrawLine(pot4, pot1, Color.red);
                        UnityEngine.Debug.DrawLine(pot1, pot3, Color.red);
                        UnityEngine.Debug.DrawLine(pot2, pot4, Color.red);
                    }
                    else if (mAsMap.Map[j, i].IsBound == true)
                    {
                        UnityEngine.Debug.DrawLine(pot1, pot2, Color.yellow);
                        UnityEngine.Debug.DrawLine(pot2, pot3, Color.yellow);
                        UnityEngine.Debug.DrawLine(pot3, pot4, Color.yellow);
                        UnityEngine.Debug.DrawLine(pot4, pot1, Color.yellow);
                        UnityEngine.Debug.DrawLine(pot1, pot3, Color.yellow);
                        UnityEngine.Debug.DrawLine(pot2, pot4, Color.yellow);
                    }
                    else
                    {
                        if(mAsMap.Map[j, i].IsSaveZone == true)
                        {
                            UnityEngine.Debug.DrawLine(pot1, pot2, Color.cyan);
                            UnityEngine.Debug.DrawLine(pot2, pot3, Color.cyan);
                            UnityEngine.Debug.DrawLine(pot3, pot4, Color.cyan);
                            UnityEngine.Debug.DrawLine(pot4, pot1, Color.cyan);
                            UnityEngine.Debug.DrawLine(pot1, pot3, Color.cyan);
                            UnityEngine.Debug.DrawLine(pot2, pot4, Color.cyan);
                        }
                        else
                        {
                            UnityEngine.Debug.DrawLine(pot1, pot2, Color.green);
                            UnityEngine.Debug.DrawLine(pot2, pot3, Color.green);
                            UnityEngine.Debug.DrawLine(pot3, pot4, Color.green);
                            UnityEngine.Debug.DrawLine(pot4, pot1, Color.green);
                            UnityEngine.Debug.DrawLine(pot1, pot3, Color.green);
                            UnityEngine.Debug.DrawLine(pot2, pot4, Color.green);
                        }
                    }

                    //for (int y = i - 1; y < i + 2; y++)
                    //{
                    //    for (int x = j - 1; x < j + 2; x++)
                    //    {
                    //        if (y < 0 || x < 0 || y >= mAsMap.Map.GetLength(1) || x >= mAsMap.Map.GetLength(0) || mAsMap.Map[x, y] == null)
                    //            continue;

                    //        if (mAsMap.Map[j, i].pos.y > mAsMap.Map[x, y].pos.y && 
                    //            Mathf.Abs(mAsMap.Map[j, i].pos.y - mAsMap.Map[x, y].pos.y) > MaxFalldownHeight)
                    //            continue;

                    //        if (mAsMap.Map[j, i].pos.y < mAsMap.Map[x, y].pos.y && 
                    //            Mathf.Abs(mAsMap.Map[x, y].pos.y - mAsMap.Map[j, i].pos.y) > ClimbLimit)
                    //            continue;

                    //        Vector3 start = mAsMap.Map[j, i].pos;
                    //        Vector3 end = mAsMap.Map[x, y].pos;

                    //        if (mAsMap.Map[x, y].IsProtal == true)
                    //        {
                    //            UnityEngine.Debug.DrawLine(start, end, Color.blue);
                    //        }
                    //        else if(mAsMap.Map[j, i].IsWall == true)
                    //        {
                    //            UnityEngine.Debug.DrawLine(start, end, Color.red);
                    //        }
                    //        else if (mAsMap.Map[j, i].IsBound == true)
                    //        {
                    //            UnityEngine.Debug.DrawLine(start, end, Color.yellow);
                    //        }
                    //        else
                    //        {
                    //            UnityEngine.Debug.DrawLine(start, end, Color.green);
                    //        }
                    //    }
                    //}
                }
            }
        }
        /// 清除画线 ///
        else
        {
            SceneView.RepaintAll();
        }
    }
#endregion

#region 地图区块操作

    /// <summary>
    /// 生成地图区块
    /// </summary>
    private void BuildMapBlock()
    {
        if(mAsMap.Map == null)
        {
            iTrace.Error("LY", "No map data !!! ");
            return;
        }

        iTrace.Log("LY", "" + mAsMap.Map.GetLength(1) + "   " + mAsMap.Map.GetLength(0));

        if (mAsMap.Map != null)
        {
            for (int i = 0; i < mAsMap.Map.GetLength(1); i++)
            {
                for (int j = 0; j < mAsMap.Map.GetLength(0); j++)
                {
                    AsNode tNode = mAsMap.Map[j, i];
                    if(tNode != null && tNode.CanWalk == true)
                    {
                        MapBlockNodeCheck(tNode);
                    }
                }
            }
        }
        mAsMap.FillNodesBlockId();

        iTrace.Log("LY", "Map block number : " + mAsMap.mapBlockList.Count);
        for(int a = 0; a < mAsMap.mapBlockList.Count; a++)
        {
            iTrace.Log("LY", "Block id : " + mAsMap.mapBlockList[a].mBlockId);
        }
    }
    
    /// <summary>
    /// 检测添加区块节点
    /// </summary>
    /// <param name="node"></param>
    private void MapBlockNodeCheck(AsNode node)
    {
        if (node == null)
            return;

        int w = node.xKey;
        int h = node.yKey;

        if (w == 0 && h == 0)
        {
            mAsMap.AddMapBlock(node);
        }
        else if(h == 0)
        {
            MapBlock tMB = null;
            AsNode tNode = mAsMap.Map[w - 1, h];
            if (tNode == null)
            {
                mAsMap.AddMapBlock(node);
                return;
            }

            for (int a = 0; a < mAsMap.mapBlockList.Count; a++)
            {
                if (mAsMap.mapBlockList[a].CheckBeside(tNode, node, ClimbLimit))
                {
                    tMB = mAsMap.mapBlockList[a];
                    break;
                }
            }

            if(tMB == null)
            {
                mAsMap.AddMapBlock(node);
            }
            else
            {
                tMB.AddNode(node);
            }
        }
        else if(w == 0)
        {
            MapBlock tMB = null;
            AsNode tNode = mAsMap.Map[w, h - 1];
            if (tNode == null)
            {
                mAsMap.AddMapBlock(node);
                return;
            }

            for (int a = 0; a < mAsMap.mapBlockList.Count; a++)
            {
                if (mAsMap.mapBlockList[a].CheckBeside(tNode, node, ClimbLimit))
                {
                    tMB = mAsMap.mapBlockList[a];
                    break;
                }
            }

            if (tMB == null)
            {
                mAsMap.AddMapBlock(node);
            }
            else
            {
                tMB.AddNode(node);
            }
        }
        else
        {
            MapBlock tMB1 = null;
            MapBlock tMB2 = null;

            AsNode tNode = mAsMap.Map[w - 1, h];
            if (tNode != null)
            {
                for (int a = 0; a < mAsMap.mapBlockList.Count; a++)
                {
                    if (mAsMap.mapBlockList[a].CheckBeside(tNode, node, ClimbLimit))
                    {
                        tMB1 = mAsMap.mapBlockList[a];
                        break;
                    }
                }
            }

            tNode = mAsMap.Map[w, h - 1];
            if (tNode != null)
            {
                for (int a = 0; a < mAsMap.mapBlockList.Count; a++)
                {
                    if (mAsMap.mapBlockList[a].CheckBeside(tNode, node, ClimbLimit))
                    {
                        tMB2 = mAsMap.mapBlockList[a];
                        break;
                    }
                }
            }
            
            if (tMB1 == null && tMB2 == null)
            {
                mAsMap.AddMapBlock(node);
            }
            else if(tMB2 == null)
            {
                tMB1.AddNode(node);
            }
            else if(tMB1 == null)
            {
                tMB2.AddNode(node);
            }
            else
            {
                if(tMB1.mBlockId == tMB2.mBlockId)
                {
                    if(tMB1 != tMB2)
                    {
                        iTrace.Error("LY", "Two block has the same id : " + tMB1.mBlockId);
                    }

                    tMB1.AddNode(node);
                }
                else if(tMB1.mBlockId < tMB2.mBlockId)
                {
                    tMB1.MergeBlock(tMB2.mMapNode, tMB2.mPortalIds);
                    mAsMap.mapBlockList.Remove(tMB2);
                    mAsMap.ResetBlockId();
                    tMB1.AddNode(node);
                }
                else
                {
                    tMB2.MergeBlock(tMB1.mMapNode, tMB1.mPortalIds);
                    mAsMap.mapBlockList.Remove(tMB1);
                    mAsMap.ResetBlockId();
                    tMB2.AddNode(node);
                }
            }
        }
    }

    /// <summary>
    /// 检测是否墙边节点
    /// </summary>
    /// <param name="centerPot"></param>
    /// <returns></returns>
    private bool CheckBoundNode(Vector3 centerPot, float dist, ref Vector3 colPot)
    {
        float halfTil = Tilesize / 2;
        Vector3 pot1 = new Vector3(centerPot.x - halfTil, centerPot.y + 10, centerPot.z - halfTil);
        Vector3 pot2 = new Vector3(centerPot.x + halfTil, centerPot.y + 10, centerPot.z - halfTil);
        Vector3 pot3 = new Vector3(centerPot.x - halfTil, centerPot.y + 10, centerPot.z + halfTil);
        Vector3 pot4 = new Vector3(centerPot.x + halfTil, centerPot.y + 10, centerPot.z + halfTil);

        RaycastHit hit;
        int layermask = (1 << LayerMask.NameToLayer("Ground")) | (1 << LayerMask.NameToLayer("Wall"));
        if (Physics.Raycast(pot1, Vector3.down, out hit, dist, layermask))
        {
            if(hit.collider.gameObject.tag == MapAreaTag)
            {
                colPot = hit.point;
                return true;
            }
        }
        if (Physics.Raycast(pot2, Vector3.down, out hit, dist, layermask))
        {
            if (hit.collider.gameObject.tag == MapAreaTag)
            {
                colPot = hit.point;
                return true;
            }
        }
        if (Physics.Raycast(pot3, Vector3.down, out hit, dist, layermask))
        {
            if (hit.collider.gameObject.tag == MapAreaTag)
            {
                colPot = hit.point;
                return true;
            }
        }
        if (Physics.Raycast(pot4, Vector3.down, out hit, dist, layermask))
        {
            if (hit.collider.gameObject.tag == MapAreaTag)
            {
                colPot = hit.point;
                return true;
            }
        }
        
        return false;
    }


    /// <summary>
    /// 根据Id获取地图区块
    /// </summary>
    /// <param name="blockId"></param>
    /// <returns></returns>
    public MapBlock GetMapBlock(uint blockId)
    {
        return mAsMap.GetMapBlock(blockId);
    }

    /// <summary>
    /// 获取传送口配置
    /// </summary>
    /// <param name="portalId"></param>
    /// <returns></returns>
    public PortalFig GetPortalFigById(uint portalId)
    {
        for(int a = 0; a < mPortalList.Count; a++)
        {
            if(mPortalList[a].mPortalId == portalId)
            {
                return mPortalList[a];
            }
        }

        Debug.LogError("Can not find portal :  map, " + MapId + "    portal, " + portalId);
        return null;
    }

    public AwakenPortalFig GetAwakenPortalFigById(uint portalId)
    {
        for (int a = 0; a < mAwakenPortalList.Count; a++)
        {
            if (mAwakenPortalList[a].mPortalId == portalId)
            {
                return mAwakenPortalList[a];
            }
        }

        Debug.LogError("Can not find awaken portal :  map, " + MapId + "    portal, " + portalId);
        return null;
    }

    #endregion

    #region 编辑器使用

    /// <summary>
    /// 清除地图数据
    /// </summary>
    public void ClearMap()
    {
        if (Application.isPlaying == true || mAsMap == null)
        {
            return;
        }
        
        mAsMap.Map = null;
        mAsMap = null;
    }
    
    /// <summary>
    /// 创建地图数据
    /// </summary>
    public void CreateMap(Bounds bound)
    {
        if (Application.isPlaying == true)
        {
            return;
        }

        MapStartPosition = bound.min + new Vector3(-2, -2, -2);
        MapEndPosition = bound.max + new Vector3(2, 2, 2);

        if (mAsMap == null)
        {
            mAsMap = new AsMapData();
        }

        if (mAsMap.Map != null)
        {
            mAsMap.Map = null;
        }

        //Find positions for start and end of map
        float startX = MapStartPosition.x;
        float startZ = MapStartPosition.z;
        float endX = MapEndPosition.x;
        float endZ = MapEndPosition.z;

        //Find tile width and height
        int width = (int)((endX - startX) / Tilesize) + 1;
        int height = (int)((endZ - startZ) / Tilesize) + 1;

        //Set map up
        mAsMap.Map = new AsNode[width, height];

        float halfTil = Tilesize / 2;
        //Fill up Map
        for (ushort i = 0; i < height; i++)
        {
            for (ushort j = 0; j < width; j++)
            {
                float x = startX + (j * Tilesize) + halfTil; //Position from where we raycast - X
                float z = startZ + (i * Tilesize) + halfTil; //Position from where we raycast - Z
                uint ID = (uint)(i * width) + j; //ID we give to our Node!

                //float dist = Mathf.Abs(MapStartPosition.y) + Mathf.Abs(MapEndPosition.y);
                float dist = Mathf.Abs(MapEndPosition.y - MapStartPosition.y) + 100;
                RaycastHit[] hit;
                if (CheckFullTileSize)
                {
                    //hit = Physics.SphereCastAll(new Vector3(x, MapEndPosition.y, z), Tilesize / 2, Vector3.down, dist);
                    hit = Physics.BoxCastAll(new Vector3(x, MapEndPosition.y, z), new Vector3(halfTil, halfTil, halfTil), 
                        Vector3.down, Quaternion.identity, dist);
                }
                else
                {
                    hit = Physics.SphereCastAll(new Vector3(x, MapEndPosition.y, z), Tilesize / 16, Vector3.down, dist);
                }
                bool free = true;
                float maxY = -Mathf.Infinity;

                bool tHitPortal = false;
                bool tHitZone = false;
                float tColH = 0f;
                float tColY = 0f;
                PortalFig tFig = null;
                PreloadZone tPZ = null;
                foreach (RaycastHit h in hit)
                {
                    if (DisallowedTags.Contains(h.transform.tag))
                    {
                        if (h.point.y > maxY)
                        {
                            if (h.transform.tag == MapBlockTag)
                            {
                                /// 检测是否围墙边界 ///
                                Vector3 hitPot = Vector3.zero;
                                if(CheckBoundNode(new Vector3(x, MapEndPosition.y, z), dist, ref hitPot))
                                {
                                    mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, hitPot.y, z), 2);
                                }
                                else
                                {
                                    mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, h.point.y, z), 3);
                                }
                            }
                            else if(h.transform.tag == MapBlockSpeTag)
                            {
                                mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, h.point.y, z), 2);
                            }
                            else
                            {
                                //It is a disallowed walking tile, make it false
                                mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, h.point.y, z), 0); //Non walkable tile!
                            }
                            free = false;
                            if (h.transform.tag != MapLoadZoneTag)
                            {
                                maxY = h.point.y;
                            }
                        }
                    }
                    else if (IgnoreTags.Contains(h.transform.tag))
                    {
                        
                    }
                    //else
                    else if (h.transform.tag == MapAreaTag || h.transform.tag == MapPortalTag || h.transform.tag == MapSaveZoneTag || h.transform.tag == MapLoadZoneTag)
                    {
                        bool tPor = false;

                        if(h.transform.tag == MapLoadZoneTag)
                        {
                            tPZ = h.transform.GetComponent<PreloadZone>();
                            continue;
                        }

                        if (h.transform.tag == MapPortalTag)
                        {
                            tFig = h.transform.GetComponent<PortalFig>();
                            if (tFig != null)
                            {
                                tHitPortal = true;
                                tColH = ((BoxCollider)h.collider).size.y;
                                tColY = h.point.y;

                                if (mPortalList.Contains(tFig) == false)
                                {
                                    mPortalList.Add(tFig);
                                }
                            }
                            //continue;
                            tPor = true;
                        }

                        if(h.transform.tag == MapSaveZoneTag)
                        {
                            tHitZone = true;
                        }

                        if (h.point.y > maxY)
                        {
                            //It is allowed to walk on this tile, make it walkable!
                            if (tHitPortal == true && tFig != null && Mathf.Abs(tColY - h.point.y) <= tColH)
                            {
                                if(tPor == true)
                                {
                                    if (mAsMap.Map[j, i] != null && mAsMap.Map[j, i].walkable == true)
                                    {
                                        mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, mAsMap.Map[j, i].pos.y, z), 1, tFig.mPortalId);   //walkable tile!
                                        free = false;
                                        maxY = h.point.y;
                                        if(tHitZone == true)
                                        {
                                            mAsMap.Map[j, i].baseData.saveZone = true;
                                        }
                                    }
                                }
                                else
                                {
                                    mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, h.point.y, z), 1, tFig.mPortalId);   //walkable tile!
                                    free = false;
                                    maxY = h.point.y;
                                    if (tHitZone == true)
                                    {
                                        mAsMap.Map[j, i].baseData.saveZone = true;
                                    }
                                }
                            }
                            else
                            {
                                if (tHitZone == true)
                                {
                                    mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, maxY, z), 1);   //walkable tile!
                                }
                                else
                                {
                                    mAsMap.Map[j, i] = new AsNode(j, i, ID, new Vector3(x, h.point.y, z), 1);   //walkable tile!
                                    maxY = h.point.y;
                                }
                                free = false;

                                if (tHitZone == true)
                                {
                                    mAsMap.Map[j, i].baseData.saveZone = true;
                                }
                            }
                        }
                    }
                }
                //We hit nothing set tile to false
                if (free == true)
                {
                    mAsMap.Map[j, i] = null;    //Non walkable tile! 
                }
                if(mAsMap.Map[j, i] != null && tPZ != null)
                {
                    mAsMap.Map[j, i].baseData.loadZoneId = tPZ.mZoneId;
                }
            }
        }

        //计算连通节点
        for (int i = 0; i < height; i++)
        {
            for (int j = 0; j < width; j++)
            {
                AsNode tNode = mAsMap.Map[j, i];
                if(tNode == null)
                {
                    continue;
                }

                if (j - 1 >= 0)
                {
                    /// 左 ///
                    if(mAsMap.Map[j - 1, i] != null && mAsMap.Map[j - 1, i].CanWalk
                        && HeightNeighbourCheck(mAsMap.Map[j - 1, i].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j - 1, i));
                    }
                    /// 左下 ///
                    if(i - 1 >= 0 && mAsMap.Map[j - 1, i - 1] != null && mAsMap.Map[j - 1, i - 1].CanWalk
                         && HeightNeighbourCheck(mAsMap.Map[j - 1, i - 1].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j - 1, i - 1));
                    }
                    /// 左上 ///
                    if (i + 1 < height && mAsMap.Map[j - 1, i + 1] != null && mAsMap.Map[j - 1, i + 1].CanWalk
                         && HeightNeighbourCheck(mAsMap.Map[j - 1, i + 1].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j - 1, i + 1));
                    }
                }

                /// 下 ///
                if (i - 1 >= 0 && mAsMap.Map[j, i - 1] != null && mAsMap.Map[j, i - 1].CanWalk
                     && HeightNeighbourCheck(mAsMap.Map[j, i - 1].pos.y, tNode.pos.y))
                {
                    tNode.AddConnetNode(new Vector2(j, i - 1));
                }
                /// 上 ///
                if (i + 1 < height && mAsMap.Map[j, i + 1] != null && mAsMap.Map[j, i + 1].CanWalk
                     && HeightNeighbourCheck(mAsMap.Map[j, i + 1].pos.y, tNode.pos.y))
                {
                    tNode.AddConnetNode(new Vector2(j, i + 1));
                }

                if(j + 1 < width)
                {
                    /// 右 ///
                    if (mAsMap.Map[j + 1, i] != null && mAsMap.Map[j + 1, i].CanWalk
                         && HeightNeighbourCheck(mAsMap.Map[j + 1, i].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j + 1, i));
                    }
                    /// 右下 ///
                    if(i - 1 >= 0 && mAsMap.Map[j + 1, i - 1] != null && mAsMap.Map[j + 1, i - 1].CanWalk
                         && HeightNeighbourCheck(mAsMap.Map[j + 1, i - 1].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j + 1, i - 1));
                    }
                    /// 右上 ///
                    if (i + 1 < height && mAsMap.Map[j + 1, i + 1] != null && mAsMap.Map[j + 1, i + 1].CanWalk
                         && HeightNeighbourCheck(mAsMap.Map[j + 1, i + 1].pos.y, tNode.pos.y))
                    {
                        tNode.AddConnetNode(new Vector2(j + 1, i + 1));
                    }
                }
            }
        }

        BuildMapBlock();

        /// 填充传送口信息 ///
        mAsMap.portalList.Clear();
        for (int a = 0; a < mPortalList.Count; a++)
        {
            AsNode tNode = FindClosestNode(mPortalList[a].transform.position, false);
            if (tNode == null)
            {
                iTrace.Error("LY", "Portal position error !!! " + mPortalList[a].mPortalId);
                continue;
            }
            mAsMap.AddPortalInfo(new PortalInfo(mPortalList[a], tNode.baseData.blBlockId));
        }
    }

    private bool HeightNeighbourCheck(float height1, float height2)
    {
        if ((height1 - height2 < ClimbLimit && height1 - height2 >= 0) 
            || (height2 - height1 < MaxFalldownHeight && height2 >= height1))
        {
            return true;
        }

        return false;
    }

    /// <summary>
    /// 根据位置查找最近的可执行格子
    /// </summary>
    /// <param name="pos"></param>
    /// <returns></returns>
    private AsNode FindClosestNode(Vector3 pos, bool findNeightbours = true)
    {
        int x = (MapStartPosition.x < 0F) ? Mathf.FloorToInt(((pos.x + Mathf.Abs(MapStartPosition.x)) / Tilesize)) : Mathf.FloorToInt((pos.x - MapStartPosition.x) / Tilesize);
        int z = (MapStartPosition.z < 0F) ? Mathf.FloorToInt(((pos.z + Mathf.Abs(MapStartPosition.z)) / Tilesize)) : Mathf.FloorToInt((pos.z - MapStartPosition.z) / Tilesize);

        if (x < 0 || z < 0 || x > mAsMap.Map.GetLength(0) || z > mAsMap.Map.GetLength(1))
            return null;

        AsNode n = mAsMap.Map[x, z];
        if (n != null && n.CanWalk)
        {
            //return new AsNode(x, z, n.yCoord, n.ID, n.xCoord, n.zCoord, 
            //    n.walkable, n.isPortal, n.portalIndex);
            return n.Clone();
        }
        else if(findNeightbours)
        {
            //If we get a non walkable tile, then look around its neightbours
            for (int i = z - 1; i < z + 2; i++)
            {
                for (int j = x - 1; j < x + 2; j++)
                {
                    //Check they are within bounderies
                    if (i > -1 && i < mAsMap.Map.GetLength(1) && j > -1 && j < mAsMap.Map.GetLength(0))
                    {
                        if (mAsMap.Map[j, i].walkable)
                        {
                            //return new AsNode(j, i, Map[j, i].yCoord, Map[j, i].ID, Map[j, i].xCoord, Map[j, i].zCoord, 
                            //    Map[j, i].walkable, Map[j, i].isPortal, Map[j, i].portalIndex);

                            return mAsMap.Map[j, i].Clone();
                        }
                    }
                }
            }
            return null;
        }

        return null;
    }

    /// <summary>
    /// 保存地图数据（我也不知道为什么要放这里）
    /// </summary>
    BinaryMapData mSaveMapData;

    /// <summary>
    /// 保存地图寻路数据
    /// </summary>
    //public bool SaveEditMapData()
    //{
    //    if(mAsMap.Map == null)
    //    {
    //        EditorUtility.DisplayDialog("Error", "请先生成地图数据", "确定");
    //        return false;
    //    }

    //    string tPath = "Assets/Scene/Share/Custom/MapData/" + MapId.ToString() + ".asset";
    //    if (AssetDatabase.FindAssets(tPath) != null)
    //    {
    //        AssetDatabase.DeleteAsset(tPath);
    //    }

    //    mSaveMapData = ScriptableObject.CreateInstance<AsSaveMapData>();
    //    mSaveMapData.mapId = MapId;
    //    mSaveMapData.tilesize = Tilesize;
    //    mSaveMapData.falldownHeight = MaxFalldownHeight;
    //    mSaveMapData.climbLimit = ClimbLimit;
    //    mSaveMapData.startPosition = MapStartPosition;
    //    mSaveMapData.endPosition = MapEndPosition;
    //    mSaveMapData.heuristicAggression = HeuristicAggression;
    //    mSaveMapData.moveDiagonal = MoveDiagonal;

    //    mSaveMapData.portalTag = MapPortalTag;
    //    mSaveMapData.disallowedTags = new List<string>(DisallowedTags);
    //    mSaveMapData.ignoreTags = new List<string>(IgnoreTags);

    //    mSaveMapData.FillMapNode(mAsMap.Map);

    //    for(int a = 0; a < mAsMap.portalList.Count; a++)
    //    {
    //        mSaveMapData.AddPortalInfo(mAsMap.portalList[a], GetPortalFigById(mAsMap.portalList[a].portalId));
    //    }
        
    //    AssetDatabase.CreateAsset(mSaveMapData, tPath);
    //    //tSaveMapData = null;

    //    SaveEditMapDataForServer();

    //    return true;
    //}

    /// <summary>
    /// 保存地图寻路数据
    /// </summary>
    public bool SaveEditMapBinaryData(GameObject rotZoneRoot = null, 
        GameObject ctrlPortalRoot = null, GameObject loadZoneRoot = null, GameObject appearZoneRoot = null)
    {
        if (mAsMap.Map == null)
        {
            EditorUtility.DisplayDialog("Error", "请先生成地图数据", "确定");
            return false;
        }

        string tPath = "Assets/Scene/Share/Custom/MapData/" + MapId.ToString() + ".bytes";
        if (File.Exists(tPath))
        {
            File.Delete(tPath);
        }

        BinaryMapData tSaveBD = new BinaryMapData();
        tSaveBD.mapId = MapId;
        tSaveBD.tilesize = Tilesize;
        tSaveBD.falldownHeight = MaxFalldownHeight;
        tSaveBD.climbLimit = ClimbLimit;
        //tSaveBD.startPosition = new SVector3(MapStartPosition);
        //tSaveBD.endPosition = new SVector3(MapEndPosition);
        if (tSaveBD.startPosition == null)
        {
            if (Application.isPlaying == true)
            {
                tSaveBD.startPosition = ObjPool.Instance.Get<SVector3>();
            }
            else
            {
                tSaveBD.startPosition = new SVector3();
            }
        }
        tSaveBD.startPosition.SetVal(MapStartPosition);
        if (tSaveBD.endPosition == null)
        {
            if (Application.isPlaying == true)
            {
                tSaveBD.endPosition = ObjPool.Instance.Get<SVector3>();
            }
            else
            {
                tSaveBD.endPosition = new SVector3();
            }
        }
        tSaveBD.endPosition.SetVal(MapEndPosition);

        tSaveBD.heuristicAggression = HeuristicAggression;
        tSaveBD.moveDiagonal = MoveDiagonal;

        tSaveBD.portalTag = MapPortalTag;
        tSaveBD.disallowedTags = new List<string>(DisallowedTags);
        tSaveBD.ignoreTags = new List<string>(IgnoreTags);

        tSaveBD.FillMapNode(mAsMap.Map);

        for (int a = 0; a < mAsMap.portalList.Count; a++)
        {
            tSaveBD.AddPortalInfo(mAsMap.portalList[a], GetPortalFigById(mAsMap.portalList[a].portalId));
            tSaveBD.savePortalFig.Add(new BinaryPortalFig(GetPortalFigById(mAsMap.portalList[a].portalId)));
        }

        if(ctrlPortalRoot != null && ctrlPortalRoot.transform.childCount > 0)
        {
            if (tSaveBD.awakenPortalList == null)
            {
                tSaveBD.awakenPortalList = new List<SaveAwakenPortalInfo>();
            }
            tSaveBD.awakenPortalList.Clear();

            for(int a = 0; a < ctrlPortalRoot.transform.childCount; a++)
            {
                GameObject tObj = ctrlPortalRoot.transform.GetChild(a).gameObject;
                AwakenPortalFig tAPF = tObj.GetComponent<AwakenPortalFig>();
                if(tAPF != null)
                {
                    SaveAwakenPortalInfo tSAPI = new SaveAwakenPortalInfo(tAPF.mPortalId, tAPF.mLinkMapId);
                    tSaveBD.awakenPortalList.Add(tSAPI);
                }
            }
        }

        if(rotZoneRoot != null && rotZoneRoot.transform.childCount > 0)
        {
            if(tSaveBD.camRotDatas == null)
            {
                tSaveBD.camRotDatas = new List<CamRotTriggerData>();
            }
            tSaveBD.camRotDatas.Clear();

            for (int a = 0; a < rotZoneRoot.transform.childCount; a++)
            {
                CamRotTriggerData tCRTD = new CamRotTriggerData();
                GameObject tObj = rotZoneRoot.transform.GetChild(a).gameObject;
                CameraRotateBind tCRB = tObj.GetComponent<CameraRotateBind>();

                tCRTD.rootObjName = tObj.name;
                tCRTD.targetAngles = tCRB.TargetAngles;
                tCRTD.opposite = tCRB.Opposite;
                tCRTD.isTrigger = tCRB.IsTrigger;
                tCRTD.speed = tCRB.Speed;
                tCRTD.child1Name = tCRB.dTrgger1.name;
                tCRTD.child2Name = tCRB.dTrgger2.name;

                tSaveBD.camRotDatas.Add(tCRTD);
            }
        }

        if (loadZoneRoot != null && loadZoneRoot.transform.childCount > 0)
        {
            if (tSaveBD.loadZoneDatas == null)
            {
                tSaveBD.loadZoneDatas = new List<PreLoadZoneData>();
            }
            tSaveBD.loadZoneDatas.Clear();

            for (int a = 0; a < loadZoneRoot.transform.childCount; a++)
            {
                GameObject tObj = loadZoneRoot.transform.GetChild(a).gameObject;
                PreloadZone tPZ = tObj.GetComponent<PreloadZone>();
                if (tPZ != null)
                {
                    PreLoadZoneData tPZD = new PreLoadZoneData();
                    tPZD.zoneId = tPZ.mZoneId;
                    tPZD.resIndex = tPZ.mSourceId;
                    tSaveBD.loadZoneDatas.Add(tPZD);
                }
            }
        }

        if (appearZoneRoot != null && appearZoneRoot.transform.childCount > 0)
        {
            if (tSaveBD.appearZoneFigs == null)
            {
                tSaveBD.appearZoneFigs = new List<BinaryAppearZoneFig>();
            }
            tSaveBD.appearZoneFigs.Clear();

            for (int a = 0; a < appearZoneRoot.transform.childCount; a++)
            {
                GameObject tObj = appearZoneRoot.transform.GetChild(a).gameObject;
                AppearCtrlZone tACZ = tObj.GetComponent<AppearCtrlZone>();
                if (tACZ != null)
                {
                    BinaryAppearZoneFig tBAZF = new BinaryAppearZoneFig();
                    tBAZF.mZoneName = tACZ.name;
                    tBAZF.mShowZoneNames = new List<string>(tACZ.mShowZoneNames);
                    tBAZF.mHideZoneNames = new List<string>(tACZ.mHideZoneNames);

                    tSaveBD.appearZoneFigs.Add(tBAZF);
                }
            }
        }

        SaveBinaryMapData(tSaveBD, tPath);
        SaveEditMapDataForServer();

        return true;
    }

    /// <summary>
    /// 序列化二进制地图数据
    /// </summary>
    /// <param name="saveMapData"></param>
    private void SaveBinaryMapData(BinaryMapData saveMapData, string savePath)
    {
        ////文件流
        //FileStream fileStream = new FileStream(savePath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        ////新建二进制格式化程序
        //BinaryFormatter bf = new BinaryFormatter();
        ////序列化
        //bf.Serialize(fileStream, saveMapData);
        //fileStream.Dispose();

        saveMapData.Write(savePath);
    }

    private void SaveEditMapDataForServer()
    {
        if (mAsMap.Map == null)
        {
            iTrace.Log("LY", "Please create map data first !!!  AsPathfinderInEditor :: SaveEditMapDataForServer");
            return;
        }

        c_map_config saveMapConfig = new c_map_config();
        saveMapConfig.map_id = (int)MapId;
        saveMapConfig.map_type = (int)MapType;
        saveMapConfig.map_width = mAsMap.Map.GetLength(0);
        saveMapConfig.map_height = mAsMap.Map.GetLength(1);

        if (saveMapConfig.map_width > 0)
        {
            //saveMapConfig.map_offset_mx = (int)((mAsMap.Map[0, 0].baseData.pos.x - 0.5f) * 100);
            //saveMapConfig.map_offset_my = (int)((mAsMap.Map[0, 0].baseData.pos.z - 0.5f) * 100);
            saveMapConfig.map_offset_mx = (int)(MapStartPosition.x * 100);
            saveMapConfig.map_offset_my = (int)(MapStartPosition.z * 100);
            
            iTrace.Log("LY", "Map offset : " + new Vector2(saveMapConfig.map_offset_mx, saveMapConfig.map_offset_my));
        }

        /// 填充可行走格子 ///
        saveMapConfig.tiles.Clear();
        for (int i = 0; i < mAsMap.Map.GetLength(1); i++)
        {
            for (int j = 0; j < mAsMap.Map.GetLength(0); j++)
            {
                if (mAsMap.Map[j, i] == null)
                    continue;

                if(mAsMap.Map[j, i].CanWalk == true /*|| mAsMap.Map[j, i].isWall == true*/)
                {
                    c_map_tile tTile = new c_map_tile();
                    tTile.x = mAsMap.Map[j, i].baseData.x;
                    tTile.y = mAsMap.Map[j, i].baseData.y;
                    tTile.is_safe = mAsMap.Map[j, i].baseData.saveZone;

                    saveMapConfig.tiles.Add(tTile);
                }
            }
        }

        /// 填充出生点 ///
        saveMapConfig.born_points.Clear();
        GameObject bornPotRoot = GameObject.Find("MapBornPot");
        for(int a = 0; a < bornPotRoot.transform.childCount; a++)
        {
            Transform tForm = bornPotRoot.transform.GetChild(a);

            c_born_point tBP = new c_born_point();
            // 阵型Id
            BornPotFig tBPFig = tForm.GetComponent<BornPotFig>();
            tBP.camp_id = 0;
            if(tBPFig != null)
            {
                tBP.camp_id = (int)tBPFig.mCampId;
            }
            // 出生点位置
            tBP.mx = (int)(tForm.position.x * 100) - saveMapConfig.map_offset_mx;
            tBP.my = (int)(tForm.position.z * 100) - saveMapConfig.map_offset_my;

            tBP.mdir = ((int)tForm.eulerAngles.y + 360) % 360;

            saveMapConfig.born_points.Add(tBP);
        }

        /// 填充跳转点 ///
        saveMapConfig.jump_points.Clear();
        for (int a = 0; a < mPortalList.Count; a++)
        {
            PortalFig tFig = mPortalList[a];
            c_jump_point tJP = new c_jump_point();
            tJP.jump_id = (int)tFig.mPortalId;

            AsNode tNode = FindClosestNode(tFig.transform.position);
            if(tNode == null)
            {
                iTrace.Error("LY", "Portal error !!  AsPathfinderInEditor :: SaveEditMapDataForServer");
                continue;
            }
            tJP.mx = tNode.baseData.x * 100 + 50;
            tJP.my = tNode.baseData.y * 100 + 50;

            saveMapConfig.jump_points.Add(tJP);
        }
        
        byte[] buff = ProtobufTool.SerializeEditor<c_map_config>(saveMapConfig);
        try
        {
            string filePath = "../server/config/map/";
            filePath = filePath + MapId.ToString() + ".bin";
            FileStream nFile = new FileStream(filePath, FileMode.Create);
            nFile.Seek(0, SeekOrigin.Begin);
            nFile.Write(buff, 0, buff.Length);
            nFile.Close();
        }
        catch (Exception ex)
        {
            throw ex;
        }
    }

    public Dictionary<int, Vector4> GetOccupPoints()
    {
        Dictionary<int, Vector4> retPots = new Dictionary<int, Vector4>();

        GameObject tObj = GameObject.Find("OccupPoint");
        if(tObj == null)
        {
            iTrace.eError("LY", "没有占领根节点 ： OccupPoint");
            return null;
        }
        
        Transform tTrans = tObj.transform;
        for(int a = 0; a < tTrans.childCount; a++)
        {
            OccupTrigger tOT = tTrans.GetChild(a).GetComponent<OccupTrigger>();
            float radius = tOT.GetComponent<SphereCollider>().radius;
            if (tOT == null)
            {
                continue;
            }

            Vector3 tPos = tTrans.GetChild(a).position;
            float wPosX = (int)(tPos.x * 100 - MapStartPosition.x * 100);
            float wPosY = (int)(tPos.y * 100);
            float wPosZ = (int)(tPos.z * 100 - MapStartPosition.z * 100);
 
            if(retPots.ContainsKey(tOT.Index) == false)
            {
                retPots[tOT.Index] = new Vector4(wPosX, wPosY, wPosZ, radius);
            }
        }

        return retPots;
    }

    public Dictionary<int, string> GetXHPoints()
    {
        Dictionary<int, string> retPots = new Dictionary<int, string>();

        GameObject tObj = GameObject.Find("Area");
        if (tObj == null)
        {
            iTrace.eError("XGY", "没有占领根节点 ： Area");
            return null;
        }

        Transform tTrans = tObj.transform;
        for (int a = 0; a < tTrans.childCount; a++)
        {
            Transform trans = tTrans.GetChild(a);
            if (trans == null)
            {
                continue;
            }

            Vector3 tPos = trans.position;
            string wPosX = ((int)(100*(tPos.x - MapStartPosition.x))).ToString();
            string wPosZ = ((int)(100*(tPos.z - MapStartPosition.z))).ToString();
            string wPos = wPosX + "," + wPosZ;
            string name = trans.name;
            retPots[int.Parse(trans.name)] = wPos;
        }

        return retPots;
    }

    public void DeletePortalFig(PortalFig pFig)
    {
        if(mPortalList.Contains(pFig))
        {
            mPortalList.Remove(pFig);
        }
    }

    /// <summary>
    /// 渲染小地图
    /// </summary>
    //public void RenderMiniMapJpg(bool outLine)
    //{
    //    if (mAsMap.Map == null)
    //    {
    //        EditorUtility.DisplayDialog("Error", "请先生成地图数据", "确定");
    //        return;
    //    }

    //    if (EditorSceneManager.loadedSceneCount <= 0 || EditorSceneManager.loadedSceneCount > 1)
    //    {
    //        EditorUtility.DisplayDialog("Error", "打开场景超过一个", "确定");
    //        return;
    //    }

    //    Vector3 vMin = MapStartPosition;
    //    Vector3 vMax = MapEndPosition;
    //    vMax.y = vMin.y = vMax.y + 50;

    //    GameObject cameraObj = new GameObject("MiniMapCamera");
    //    Camera cam = cameraObj.AddComponent<Camera>();

    //    cameraObj.transform.eulerAngles = new Vector3(90, 0, 0);
    //    cameraObj.transform.position = (vMax + vMin) * 0.5f;
    //    cam.orthographic = true;
    //    Vector3 vExtend = vMax - vMin;
    //    cam.orthographicSize = (Mathf.Abs(vExtend.x) > Mathf.Abs(vExtend.z) ? Mathf.Abs(vExtend.x) : Mathf.Abs(vExtend.z)) * 0.5f;
    //    cam.clearFlags = CameraClearFlags.Depth;

    //    string[] paths = AssetDatabase.FindAssets("mapclip");
    //    RenderTexture renderTex = null;
    //    if (paths.Length > 0)
    //    {
    //        string filePath = AssetDatabase.GUIDToAssetPath(paths[0]);

    //        renderTex = AssetDatabase.LoadAssetAtPath(filePath, typeof(RenderTexture)) as RenderTexture;
    //        cam.targetTexture = renderTex;
    //        cam.Render();
    //        cam.targetTexture = null;
    //    }

    //    // Set the supplied RenderTexture as the active one
    //    RenderTexture.active = renderTex;

    //    // Create a new Texture2D and read the RenderTexture image into it
    //    Texture2D tex = new Texture2D(renderTex.width, renderTex.height);
    //    tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);

    //    byte[] bytes = tex.EncodeToJPG();

    //    Scene scene = SceneManager.GetActiveScene();
    //    string[] namebuff = scene.name.Split(char.Parse("/"));
    //    string sceneName = namebuff[namebuff.Length - 1];
    //    sceneName = sceneName.Replace(".unity", "");
    //    //UnityEngine.Debug.Log("Scene name : " + sceneName);

    //    string savePath = Application.dataPath + "/EditorResource/MiniMapTemp/";
    //    //UnityEngine.Debug.Log("MiniMap save place : " + savePath);
    //    if (!Directory.Exists(savePath))
    //    {
    //        Directory.CreateDirectory(savePath);
    //    }
    //    if (outLine == true)
    //    {
    //        savePath = savePath + "/" + "map_" + sceneName + "_o.jpg";
    //    }
    //    else
    //    {
    //        savePath = savePath + "/" + "map_" + sceneName + ".jpg";
    //    }
    //    File.WriteAllBytes(savePath, bytes);

    //    RenderTexture.active = null;

    //    GameObject.DestroyImmediate(cameraObj);
    //}

    private GameObject mArrowGo = null;

    public void CreateArrowGo()
    {
        if(mArrowGo == null)
        {
            string prefabPath = "Assets/EditorResource/MapDirArrow.prefab";
            GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(prefabPath, typeof(GameObject)) as GameObject;
            mArrowGo = Instantiate(tLoadPrefab);
            mArrowGo.name = tLoadPrefab.name;
        }
    }

    /// <summary>
    /// 渲染新小地图
    /// </summary>
    public void RenderNewMiniMapJpg(bool outLine, ref bool hasRot, ref int mapId, ref int rotY)
    {
        if (mAsMap.Map == null)
        {
            EditorUtility.DisplayDialog("Error", "请先生成地图数据", "确定");
            return;
        }

        if (EditorSceneManager.loadedSceneCount <= 0 || EditorSceneManager.loadedSceneCount > 1)
        {
            EditorUtility.DisplayDialog("Error", "打开场景超过一个", "确定");
            return;
        }

        Vector3 vMin = MapStartPosition;
        Vector3 vMax = MapEndPosition;
        vMax.y = vMin.y = vMax.y + 50;

        GameObject cameraObj = new GameObject("MiniMapCamera");
        Camera cam = cameraObj.AddComponent<Camera>();

        cameraObj.transform.eulerAngles = new Vector3(90, 0, 0);
        cameraObj.transform.position = (vMax + vMin) * 0.5f;
        cam.orthographic = true;
        float vExtend = Vector3.Distance(vMax, vMin);
        cam.orthographicSize = vExtend * 0.5f;
        cam.clearFlags = CameraClearFlags.Depth;

        if(mArrowGo != null)
        {
            Vector3 tLe = cameraObj.transform.localEulerAngles;
            tLe.y = (int)mArrowGo.transform.localEulerAngles.y;
            cameraObj.transform.localEulerAngles = tLe;

            hasRot = true;
            mapId = (int)MapId;
            rotY = (int)tLe.y;
        }

        string[] paths = AssetDatabase.FindAssets("mapclip");
        RenderTexture renderTex = null;
        if (paths.Length > 0)
        {
            string filePath = AssetDatabase.GUIDToAssetPath(paths[0]);

            renderTex = AssetDatabase.LoadAssetAtPath(filePath, typeof(RenderTexture)) as RenderTexture;
            cam.targetTexture = renderTex;
            cam.Render();
            cam.targetTexture = null;
        }

        // Set the supplied RenderTexture as the active one
        RenderTexture.active = renderTex;

        // Create a new Texture2D and read the RenderTexture image into it
        Texture2D tex = new Texture2D(renderTex.width, renderTex.height);
        tex.ReadPixels(new Rect(0, 0, tex.width, tex.height), 0, 0);

        byte[] bytes = tex.EncodeToJPG();

        Scene scene = SceneManager.GetActiveScene();
        string[] namebuff = scene.name.Split(char.Parse("/"));
        string sceneName = namebuff[namebuff.Length - 1];
        sceneName = sceneName.Replace(".unity", "");
        //UnityEngine.Debug.Log("Scene name : " + sceneName);

        string savePath = Application.dataPath + "/EditorResource/MiniMapTemp/";
        //UnityEngine.Debug.Log("MiniMap save place : " + savePath);
        if (!Directory.Exists(savePath))
        {
            Directory.CreateDirectory(savePath);
        }
        if (outLine == true)
        {
            savePath = savePath + "/" + "map_" + sceneName + "_o.jpg";
        }
        else
        {
            savePath = savePath + "/" + "map_" + sceneName + ".jpg";
        }
        File.WriteAllBytes(savePath, bytes);

        RenderTexture.active = null;

        GameObject.DestroyImmediate(cameraObj);
    }

    private void EnableAllRenderer(List<Renderer> renders, bool enable)
    {
        for (int i = 0; i < renders.Count; i++)
        {
            renders[i].gameObject.SetActive(enable);
        }
    }

    public void TestReadData()
    {
        byte[] buff;
        try
        {
            string filePath = "../ToServerData/love.txt";
            FileStream file = new FileStream(filePath, FileMode.Open);
            buff = new byte[file.Length];
            //文件指针指向0位置
            file.Seek(0, SeekOrigin.Begin);
            //读入两百个字节
            file.Read(buff, 0, (int)file.Length);
            file.Close();

            c_map_config tConfig = ProtobufTool.Deserialize<c_map_config>(buff);

            iTrace.Log("LY", tConfig.map_id.ToString());
            iTrace.Log("LY", tConfig.tiles[0].x.ToString());
        }
        catch (Exception ex)
        {
            throw ex;
        }

    }

#endregion
}

#endif