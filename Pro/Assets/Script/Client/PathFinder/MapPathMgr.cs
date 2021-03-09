#if UNITY_EDITOR
    using UnityEditor;
#endif

using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;

using Loong.Game;


/// <summary>
/// 地图路径管理器
/// </summary>
public class MapPathMgr
{
    public static readonly MapPathMgr instance = new MapPathMgr();

    //private MonoBehaviour mMainMono = null;
    private MapAssistant mMapAssi = null;
    /// <summary>
    /// 简易地图数据
    /// </summary>
    private Dictionary<uint, SimplifyMapInfo> map_simplifyMaps = new Dictionary<uint, SimplifyMapInfo>();

    /// <summary>
    /// 预加载地图数据
    /// </summary>
    private BinaryMapData mPreloadMapData = null;
    /// <summary>
    /// 当前地图数据
    /// </summary>
    private BinaryMapData mCurMapData = null;

    private long mOriWantPos = 0;
    /// <summary>
    /// 将要同步的位置
    /// </summary>
    private Vector3 mWantPos = Vector3.zero;
    /// <summary>
    /// 设置了同步位置
    /// </summary>
    private bool mSetWantPos = false;

    /// <summary>
    /// 是否加载地图
    /// </summary>
    private bool mLoadMap = false;
    /// <summary>
    /// 地图建筑节点
    /// </summary>
    private GameObject mMapBlockRoot = null;

    /// 地图ID ///
    private uint mCurMapId = 0;
    /// 格子大小 ///
    private float Tilesize = 1;
    /// 格子半径 ///
    private float halfTil;
    /// 斜线移动 ///
    private bool MoveDiagonal = true;

    /// 地图起始点（最小点、左下角） ///
    private Vector3 MapStartPosition;
    /// 地图结束点（最大点、右上角） ///
    private Vector3 MapEndPosition;
    /// 地图中间点（就是中间点啊） ///
    private Vector3 MapCenterPosition;

    private int HeuristicAggression;

    /// <summary>
    /// 地图数据
    /// </summary>
    private AsMapData mAsMap = null;


    //FPS
    private float updateinterval = 1F;
    private int frames = 0;
    private float timeleft = 1F;
    private int FPS = 60;
    private int times = 0;
    private int averageFPS = 0;

    int maxSearchRounds = 0;

    //Queue path finding to not bottleneck it
    private List<AsQueuePath> queue = new List<AsQueuePath>();
    private List<AsQueueFallowPath> fpQueue = new List<AsQueueFallowPath>();

    public MapAssistant MapAssis
    {
        get { return mMapAssi; }
    }
    public uint CurMapId
    {
        get { return mCurMapId; }
    }
    public Vector3 MapStartPos
    {
        get { return MapStartPosition; }
    }
    public Vector3 MapEndPos
    {
        get { return MapEndPosition; }
    }
    public Vector3 MapCenterPos
    {
        get { return MapCenterPosition; }
    }
    public bool MapInit
    {
        get
        {
            return mLoadMap;
        }
    }


    private void Init()
    {
        //MainMono = Global.Main;
        mMapAssi = new MapAssistant();
        mMapAssi.ResetAssistant();
    }

    #region map
    ///////// AsNode内存池 /////////

    /// <summary>
    /// 仓库列表
    /// </summary>
    private List<AsNode> mAsNodeDepot = new List<AsNode>();

    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    public AsNode GetAsNode()
    {
        if (mAsNodeDepot == null)
        {
            mAsNodeDepot = new List<AsNode>();
        }

        if (mAsNodeDepot.Count <= 0)
        {
            return new AsNode();
        }
        else
        {
            AsNode retNode = mAsNodeDepot[mAsNodeDepot.Count - 1];
            mAsNodeDepot.RemoveAt(mAsNodeDepot.Count - 1);
            retNode.Reset();
            return retNode;
        }
    }

    public void RecycleAsNode(AsNode node)
    {
        if (node == null)
            return;

        if (mAsNodeDepot == null)
        {
            mAsNodeDepot = new List<AsNode>();
        }

        //if(mAsNodeDepot.Contains(node) == false)
        //{
        node.Reset();
        mAsNodeDepot.Add(node);
        //}
    }

    ////////////////////////////////

    //-------------------------------------------------INSTANIATE MAP-----------------------------------------------//
    /// <summary>
    /// 读取简易地图
    /// </summary>
    public void LoadSimplifyMap()
    {
        string prefabName = "SimplifyMapData.bytes";
        AssetMgr.Instance.Add(prefabName, LoadDataCb);
    }

    private void LoadDataCb(System.Object gbj)
    {
        if (gbj == null)
        {
            iTrace.Log("LY", "Can not load SimplifyMapData.bytes !!! ");
            return;
        }

        TextAsset loadAsset = gbj as TextAsset;
        MapSimplifyDatas loadData = new MapSimplifyDatas();
        loadData.Read(loadAsset.bytes);

        for(int a = 0; a < loadData.mapList.Count; a++)
        {
            SimplifyMap tMap = loadData.mapList[a];
            if(tMap != null && map_simplifyMaps.ContainsKey(tMap.mapId) == false)
            {
                map_simplifyMaps.Add(tMap.mapId, new SimplifyMapInfo(tMap));
            }
        }
    }

    private void FillMapNode(uint xLen, uint yLen, List<BinaryMapNode> nodeList, List<SavePortalInfo> savePortalList)
    {
        mAsMap.InitBinaryMapDetail(xLen, yLen, nodeList, savePortalList);
        SetListsSize((int)(xLen * yLen));
    }

    /// <summary>
    /// 读取地图
    /// </summary>
    /// <param name="mapData"></param>
    public void LoadMap(BinaryMapData mapData, List<PortalFig> pFigList, List<DoorBlock> doors, List<AwakenPortalFig> apFigList)
    {
        if (mAsMap == null)
        {
            mAsMap = new AsMapData();
        }

        if (mapData == null)
        {
            iTrace.Error("LY", "Save map data is null !!! ");
            mCurMapId = 0;
            return;
        }

        mAsMap.mapId = mapData.mapId;

        mMapAssi.PortalList = pFigList;
        mMapAssi.AwakenPortalList = apFigList;
        mMapAssi.DoorBlockList = doors;

        Tilesize = mapData.tilesize;
        halfTil = Tilesize / 2;
        MapStartPosition = mapData.startPosition.GetVector3();
        MapEndPosition = mapData.endPosition.GetVector3();
        MapCenterPosition = (MapStartPosition + MapEndPosition) / 2.0f;
        HeuristicAggression = mapData.heuristicAggression;
        MoveDiagonal = mapData.moveDiagonal;

        FillMapNode(mapData.xNum, mapData.yNum, mapData.saveMapNodes, mapData.portalList);
    }

    /// <summary>
    /// 组建地图资源
    /// </summary>
    private void BuildMapData()
    {
        if (mCurMapData == null)
        {
            iTrace.Error("LY", "Can not load map data !!! " + mCurMapId);
            mCurMapId = 0;
            return;
        }

        GameObject tBlock = MapDataStore.Instance.GetPersistMapBlock(mCurMapId);
        if(tBlock == null)
        {
            tBlock = MapDataStore.Instance.GetTempPersistMapBlock(mCurMapId);
        }
        if(tBlock != null)
        {
            tBlock.SetActive(true);
            FinLoadMapBlock(tBlock);
        }
        else
        {
            MapDataStore.Instance.LoadMapColliderObj(mCurMapId, FinLoadMapBlock);
        }
    }

    private void FinLoadMapBlock(GameObject gObj)
    {
        mMapBlockRoot = gObj;
        MonoBehaviour.DontDestroyOnLoad(mMapBlockRoot);
        GameObject mPortalObj = Utility.FindNode(mMapBlockRoot, "MapPortal");

        List<PortalFig> tFigList = null;
        if (mPortalObj != null)
        {
            for (int a = 0; a < mPortalObj.transform.childCount; a++)
            {
                GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
                GameObject displayNode = Utility.FindNode(tObj, "DisplayZone");
                if (displayNode == null)
                {
                    displayNode = new GameObject("DisplayZone");
                    displayNode.transform.parent = tObj.transform;
                    displayNode.transform.localPosition = Vector3.zero;
                    displayNode.transform.localScale = Vector3.one;
                }
                if (displayNode.GetComponent<DisplayZone>() == null)
                {
                    displayNode.AddComponent<DisplayZone>();
                }
            }

            for (int a = 0; a < mCurMapData.savePortalFig.Count; a++)
            {
                GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
                PortalFig tPF = tObj.GetComponent<PortalFig>();
                if (tPF == null)
                {
                    tPF = tObj.AddComponent<PortalFig>();
                }
                tPF.InitData(mCurMapData.savePortalFig[a]);
            }
            tFigList = new List<PortalFig>(mPortalObj.GetComponentsInChildren<PortalFig>());
        }

        GameObject tAwakenPortalObj = Utility.FindNode(mMapBlockRoot, "MapCtrlPortal");
        List<AwakenPortalFig> tAPFigList = null;
        if (tAwakenPortalObj != null)
        {
            for (int a = 0; a < mCurMapData.awakenPortalList.Count; a++)
            {
                if (tAPFigList == null)
                {
                    tAPFigList = new List<AwakenPortalFig>();
                }

                GameObject tObj = tAwakenPortalObj.transform.GetChild(a).gameObject;
                AwakenPortalFig tAPF = tObj.GetComponent<AwakenPortalFig>();
                if (tAPF == null)
                {
                    tAPF = tObj.AddComponent<AwakenPortalFig>();
                }
                tAPF.mPortalId = mCurMapData.awakenPortalList[a].portalId;
                tAPF.mLinkMapId = mCurMapData.awakenPortalList[a].linkMapId;

                tAPFigList.Add(tAPF);
            }
        }

        GameObject mZoneObj = Utility.FindNode(mMapBlockRoot, "MapSaveZone");
        if (mZoneObj != null)
        {
            for (int a = 0; a < mZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mZoneObj.transform.GetChild(a).gameObject;
                if (tObj.GetComponent<SaveZoneFig>() == null)
                {
                    tObj.AddComponent<SaveZoneFig>();
                }
            }
        }

        GameObject mDoorObj = Utility.FindNode(mMapBlockRoot, "MapDoorBlock");
        List<DoorBlock> tBlockList = null;
        if (mDoorObj != null)
        {
            tBlockList = new List<DoorBlock>(mDoorObj.GetComponentsInChildren<DoorBlock>());
        }

        GameObject rotZoneRoot = Utility.FindNode(mMapBlockRoot, "CamRotZoneRoot");
        if (rotZoneRoot != null && mCurMapData.camRotDatas != null && mCurMapData.camRotDatas.Count > 0)
        {
            for (int a = 0; a < mCurMapData.camRotDatas.Count; a++)
            {
                CamRotTriggerData tData = mCurMapData.camRotDatas[a];
                GameObject camRotZone = Utility.FindNode(rotZoneRoot, tData.rootObjName);
                if (camRotZone != null)
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

        GameObject tLoadZoneObj = Utility.FindNode(mMapBlockRoot, "LoadZone");
        if (tLoadZoneObj != null)
        {
            tLoadZoneObj.SetActive(false);
        }

        GameObject tAppearZoneObj = Utility.FindNode(mMapBlockRoot, "AppearCtrlZone");
        if (tAppearZoneObj != null && mCurMapData.appearZoneFigs != null && mCurMapData.appearZoneFigs.Count > 0)
        {
            for (int a = 0; a < tAppearZoneObj.transform.childCount; a++)
            {
                GameObject tObj = tAppearZoneObj.transform.GetChild(a).gameObject;
                BinaryAppearZoneFig tBAZF = null;
                for (int b = 0; b < mCurMapData.appearZoneFigs.Count; b++)
                {
                    if (tObj.name == mCurMapData.appearZoneFigs[b].mZoneName)
                    {
                        tBAZF = mCurMapData.appearZoneFigs[b];
                        break;
                    }
                }

                if (tBAZF != null)
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

        LoadMap(mCurMapData, tFigList, tBlockList, tAPFigList);
        //mLoadMap = true;
        InitDoorBlock();
        mLoadMap = true;
        if(mSetWantPos == true)
        {
            ChangeWantPos();
        }

        Unit mainPlayer = InputVectorMove.instance.MoveUnit;
        if (mainPlayer != null)
        {
            UnitHelper.instance.SetRayHitPosition(mainPlayer.Position, mainPlayer);
        }
    }
    #endregion //End map

    //---------------------------------------SETUP PATH QUEUE---------------------------------------//

    public void InsertInQueue(Vector3 startPos, Vector3 endPos, Action<WalkPath> pathMethod)
    {
        if (mLoadMap == false)
        {
            iTrace.Error("LY", "Map data unload !!! ");
            return;
        }

        AsQueuePath q = new AsQueuePath(startPos, endPos, pathMethod);
        queue.Add(q);
    }

    public void InsertInFallowQueue(Vector3 startPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> pathMethod)
    {
        if (mLoadMap == false)
        {
            iTrace.Error("LY", "Map data unload !!! ");
            return;
        }

        AsQueueFallowPath q = new AsQueueFallowPath(startPos, pathPoints, pathMethod);
        fpQueue.Add(q);
    }

    #region astar
    //---------------------------------------FIND PATH: A*------------------------------------------//
    private AsNode[] openList;
    private AsNode[] closedList;
    private Vector3 startPos;
    private Vector3 endPos;
    private AsNode pathStartNode;
    private AsNode pathEndNode;
    private AsNode currentNode;
    //Use it with KEY: F-value, VALUE: ID. ID's might be looked up in open and closed list then
    private List<AsNodeSearch> sortedOpenList = new List<AsNodeSearch>();

    private void SetListsSize(int size)
    {
        int realSize = size;

        //iTrace.Log("LY", "---------------     Map grid size : " + realSize);

        if (realSize <= 0 || realSize > 250000)
        {
            iTrace.Error("LY", "Map grid size too large : " + realSize);
            realSize = 250000;
        }

        openList = new AsNode[realSize];
        closedList = new AsNode[realSize];
    }

    IEnumerator PathHandler(Vector3 startPos, Vector3 endPos, Action<WalkPath> listMethod)
    {
        //yield return mMainMono.StartCoroutine(SinglePath(startPos, endPos, listMethod));
        yield return MonoEvent.Start(SinglePath(startPos, endPos, listMethod));
    }

    IEnumerator SinglePath(Vector3 startPos, Vector3 endPos, Action<WalkPath> listMethod)
    {
        FindPath(startPos, endPos, listMethod);
        yield return null;
    }

    IEnumerator FallowPathHandler(Vector3 startPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> listMethod)
    {
        //yield return mMainMono.StartCoroutine(FallowPath(startPos, pathPoints, listMethod));
        yield return MonoEvent.Start(FallowPath(startPos, pathPoints, listMethod));
    }

    IEnumerator FallowPath(Vector3 startPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> listMethod)
    {
        FindFallowPath(startPos, pathPoints, listMethod);
        yield return null;
    }

    #region 检测寻路是否可走直线
    /// <summary>
    /// 移除路径中的共线点
    /// </summary>
    /// <param name="pathNodes"></param>
    //private void RemoveCollinePoint(ref List<AsNode> pathNodes, ref List<AsNode> replNodes)
    //{
    //    for(int a = pathNodes.Count - 1; a >= 2; a--)
    //    {
    //        if(pathNodes.Count <= 2)
    //        {
    //            break;
    //        }

    //        AsNode checkANode = pathNodes[a];
    //        AsNode checkBNode = pathNodes[a - 1];
    //        AsNode checkCNode = pathNodes[a - 2];
    //        if ((checkBNode.xKey - checkANode.xKey) == (checkCNode.xKey - checkBNode.xKey)
    //                && (checkBNode.yKey - checkANode.yKey) == (checkCNode.yKey - checkBNode.yKey))
    //        {
    //            if(replNodes.Contains(checkBNode))
    //            {
    //                replNodes.Remove(checkBNode);
    //            }
    //            pathNodes.RemoveAt(a - 1);
    //        }
    //    }
    //}

    /// <summary>
    /// 是否可以走直线
    /// </summary>
    /// <param name="startNode"></param>
    /// <param name="endNode"></param>
    /// <returns></returns>
    private bool CanWalkLine(AsNode startNode, AsNode endNode, bool hard = false)
    {
        if (startNode.xKey == endNode.xKey && startNode.yKey == endNode.yKey)
        {
            return true;
        }

        Vector2 dummyPot1 = new Vector2(startNode.xKey + halfTil, startNode.yKey + halfTil);
        Vector2 dummyPot2 = new Vector2(endNode.xKey + halfTil, endNode.yKey + halfTil);

        int gridDistX = Mathf.Abs(startNode.xKey - endNode.xKey);
        int gridDistY = Mathf.Abs(startNode.yKey - endNode.yKey);

        bool loopX = gridDistX >= gridDistY ? true : false;

        int loopStart = 0;
        int loopEnd = 0;

        List<AsNode> passNodes = null;

        if (loopX)
        {
            loopStart = Mathf.Min(startNode.xKey, endNode.xKey);
            loopEnd = Mathf.Max(startNode.xKey, endNode.xKey);

            for (int a = loopStart; a <= loopEnd; a++)
            {
                if (a == loopStart)
                    continue;

                float yCoord = Utility.GetPointOnLine(dummyPot1, dummyPot2, a, 0);
                passNodes = GetNodesUnderPoint(new Vector2(a, yCoord));
                for (int b = 0; b < passNodes.Count; b++)
                {
                    if (passNodes[b] == null)
                        return false;

                    bool tCanWalk = hard ? CanWalkHard(passNodes[b]) : CanWalkEasy(passNodes[b]);
                    if (tCanWalk == false)
                    {
                        return false;
                    }

                    if (b > 0)
                    {
                        Vector2 checkCon1 = new Vector2(passNodes[b].xKey, passNodes[b].yKey);
                        Vector2 checkCon2 = new Vector2(passNodes[b - 1].xKey, passNodes[b - 1].yKey);
                        if (passNodes[b - 1].connectNodes.Contains(checkCon1) == false
                            || passNodes[b].connectNodes.Contains(checkCon2) == false)
                        {
                            return false;
                        }
                    }
                }
            }
        }
        else
        {
            loopStart = Mathf.Min(startNode.yKey, endNode.yKey);
            loopEnd = Mathf.Max(startNode.yKey, endNode.yKey);

            for (int a = loopStart; a <= loopEnd; a++)
            {
                if (a == loopStart)
                    continue;

                float xCoord = Utility.GetPointOnLine(dummyPot1, dummyPot2, a, 1);
                passNodes = GetNodesUnderPoint(new Vector2(xCoord, a));
                for (int b = 0; b < passNodes.Count; b++)
                {
                    if (passNodes[b] == null)
                        return false;

                    bool tCanWalk = hard ? CanWalkHard(passNodes[b]) : CanWalkEasy(passNodes[b]);
                    if (tCanWalk == false)
                    {
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /// <summary>
    /// 获取网格交点相邻的格子
    /// </summary>
    /// <param name="crossPoint"></param>
    /// <returns></returns>
    private List<AsNode> GetNodesUnderPoint(Vector2 crossPoint)
    {
        List<AsNode> retNodes = new List<AsNode>();

        float xInt = Mathf.Floor(crossPoint.x + 0.5f);
        float yInt = Mathf.Floor(crossPoint.y + 0.5f);

        bool xIsInt = Mathf.Abs(crossPoint.x - xInt) < 0.000001;
        bool yIsInt = Mathf.Abs(crossPoint.y - yInt) < 0.000001;

        /// 在4个格子中间 ///
        if (xIsInt && yIsInt)
        {
            if (xInt - 1.0f > 0 && yInt - 1.0f > 0)
            {
                retNodes.Add(mAsMap.Map[(int)xInt - 1, (int)yInt - 1]);
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt - 1]);
                retNodes.Add(mAsMap.Map[(int)xInt - 1, (int)yInt]);
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
            }
            else if (xInt - 1.0f > 0)
            {
                retNodes.Add(mAsMap.Map[(int)xInt - 1, (int)yInt]);
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
            }
            else if (yInt - 1.0f > 0)
            {
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt - 1]);
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
            }
            else
            {
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
            }
        }
        /// 在格子纵向边上 ///
        else if (xIsInt)
        {
            if (xInt - 1.0f > 0)
            {
                retNodes.Add(mAsMap.Map[(int)xInt - 1, (int)yInt]);
            }

            retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
        }
        /// 在格子横向边上 ///
        else if (yIsInt)
        {
            if (yInt - 1.0f > 0)
            {
                retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt - 1]);
            }
            retNodes.Add(mAsMap.Map[(int)xInt, (int)yInt]);
        }
        /// 在格子内 ///
        else
        {
            retNodes.Add(mAsMap.Map[(int)crossPoint.x, (int)crossPoint.y]);
        }

        return retNodes;
    }

    /// <summary>
    /// 按方向查找可行走格子数量
    /// </summary>
    /// <param name="standX"></param>
    /// <param name="standY"></param>
    /// <param name="dirType">1：左上
    ///                       2：上
    ///                       3：右上
    ///                       4：右
    ///                       5：右下
    ///                       6：下
    ///                       7：左下
    ///                       8：左       </param>
    /// <returns></returns>
    private void CheckWalkableNodeNum(int standX, int standY, int dirType, ref int xOffset, ref int yOffset)
    {
        int retNum = 0;
        int xRat = 0;
        int yRat = 0;

        switch (dirType)
        {
            case 1:
                {
                    xRat = -1;
                    yRat = 1;
                }
                break;
            case 2:
                {
                    xRat = 0;
                    yRat = 1;
                }
                break;
            case 3:
                {
                    xRat = 1;
                    yRat = 1;
                }
                break;
            case 4:
                {
                    xRat = 1;
                    yRat = 0;
                }
                break;
            case 5:
                {
                    xRat = 1;
                    yRat = -1;
                }
                break;
            case 6:
                {
                    xRat = 0;
                    yRat = -1;
                }
                break;
            case 7:
                {
                    xRat = -1;
                    yRat = -1;
                }
                break;
            case 8:
                {
                    xRat = -1;
                    yRat = 0;
                }
                break;
            default:
                {
                    iTrace.Error("LY", "Try change node direct type error !!! ");
                }
                break;
        }

        for (int a = 1; a <= 6; a++)
        {
            if (CanWalkHard(standX + (xRat * a), standY + (yRat * a)) == false)
                break;
            retNum = a;
        }

        xOffset = retNum * xRat;
        yOffset = retNum * yRat;
    }

    /// <summary>
    /// 检测是否贴边格子
    /// </summary>
    /// <param name="oriNode"></param>
    /// <returns></returns>
    private bool IsBoundNode(AsNode oriNode)
    {
        if (oriNode.connectNodes.Count < 8)
        {
            return true;
        }

        for (int a = 0; a < oriNode.connectNodes.Count; a++)
        {
            int nX = (int)oriNode.connectNodes[a].x;
            int nY = (int)oriNode.connectNodes[a].y;

            if (CanWalkHard(nX, nY) == false)
            {
                return true;
            }
        }

        return false;
    }

    private int CheckAsNodeBP(AsNode oriNode, ref bool isCorner)
    {
        int oriX = oriNode.xKey;
        int oriY = oriNode.yKey;

        bool tTL = false;
        bool tT = false;
        bool tTR = false;
        bool tR = false;
        bool tBR = false;
        bool tB = false;
        bool tBL = false;
        bool tL = false;

        // 判断周边8方向是否可行走
        for (int a = 0; a < oriNode.connectNodes.Count; a++)
        {
            int nX = (int)oriNode.connectNodes[a].x;
            int nY = (int)oriNode.connectNodes[a].y;

            /// 左上 ///
            if (nX == oriX - 1 && nY == oriY + 1 && CanWalkHard(oriX - 1, oriY + 1))
            {
                tTL = true;
            }
            /// 上 ///
            else if (nX == oriX && nY == oriY + 1 && CanWalkHard(oriX, oriY + 1))
            {
                tT = true;
            }
            /// 右上 ///
            else if (nX == oriX + 1 && nY == oriY + 1 && CanWalkHard(oriX + 1, oriY + 1))
            {
                tTR = true;
            }
            /// 右 ///
            else if (nX == oriX + 1 && nY == oriY && CanWalkHard(oriX + 1, oriY))
            {
                tR = true;
            }
            /// 右下 ///
            else if (nX == oriX + 1 && nY == oriY - 1 && CanWalkHard(oriX + 1, oriY - 1))
            {
                tBR = true;
            }
            /// 下 ///
            else if (nX == oriX && nY == oriY - 1 && CanWalkHard(oriX, oriY - 1))
            {
                tB = true;
            }
            /// 左下 ///
            else if (nX == oriX - 1 && nY == oriY - 1 && CanWalkHard(oriX - 1, oriY - 1))
            {
                tBL = true;
            }
            /// 左 ///
            else if (nX == oriX - 1 && nY == oriY && CanWalkHard(oriX - 1, oriY))
            {
                tL = true;
            }
        }

        int retIndex = 0;
        // 不需要移动
        if (tTL && tT && tTR && tR && tBR && tB && tBL && tL)
        {
            retIndex = 0;
        }
        else
        {
            if (tL == false)
            {
                if (tR == false)
                {
                    retIndex = 0;
                }
                else if (tTL == false || tT == false || tTR == false)
                {
                    retIndex = 5;
                }
                else if (tBL == false || tB == false || tBR == false)
                {
                    retIndex = 3;
                }
                else
                {
                    retIndex = 4;
                }
            }
            else if (tT == false)
            {
                if (tB == false)
                {
                    retIndex = 0;
                }
                else if (tTR == false || tR == false || tBR == false)
                {
                    retIndex = 7;
                }
                else if (tTL == false || tL == false || tBL == false)
                {
                    retIndex = 5;
                }
                else
                {
                    retIndex = 6;
                }
            }
            else if (tR == false)
            {
                if (tL == false)
                {
                    retIndex = 0;
                }
                else if (tTL == false || tT == false || tTR == false)
                {
                    retIndex = 7;
                }
                else if (tBL == false || tB == false || tBR == false)
                {
                    retIndex = 1;
                }
                else
                {
                    retIndex = 8;
                }
            }
            else if (tB == false)
            {
                if (tT == false)
                {
                    retIndex = 0;
                }
                else if (tTL == false || tL == false || tBL == false)
                {
                    retIndex = 3;
                }
                else if (tTR == false || tR == false || tBR == false)
                {
                    retIndex = 1;
                }
                else
                {
                    retIndex = 2;
                }
            }
            isCorner = true;
        }

        return retIndex;
    }

    /// <summary>
    /// 查找更适合行走节点()
    /// </summary>
    /// <param name="oriNode">原始节点</param>
    /// <returns></returns>
    private AsNode FindMoreFitWalkNode(AsNode oriNode, ref bool isCorner)
    {
        int oriX = oriNode.xKey;
        int oriY = oriNode.yKey;

        int offsetX = 0;
        int offsetY = 0;

        AsNode retNode = null;
        isCorner = false;

        /// 检测是否需要调整路径格子 ///
        int movDir = CheckAsNodeBP(oriNode, ref isCorner);
        if (movDir > 0)
        {
            CheckWalkableNodeNum(oriX, oriY, movDir, ref offsetX, ref offsetY);
            if (offsetX != 0 || offsetY != 0)
            {
                offsetX = offsetX / 2;
                offsetY = offsetY / 2;
                retNode = mAsMap.Map[oriX + offsetX, oriY + offsetY];
                //iTrace.Log("LY", "Fit node offset : " + offsetX + "  " + offsetY);
            }

            //if(movDir == 1 || movDir == 3 || movDir == 5 || movDir == 7)
            //{
            //    isCorner = true;
            //}
        }

        return retNode;
    }

    #endregion

    /// <summary>
    /// 查找路径节点
    /// </summary>
    /// <param name="startPos"></param>
    /// <param name="endPos"></param>
    /// <returns></returns>
    private List<AsNode> FindChildPathNodes(Vector3 startPos, Vector3 endPos)
    {
        //The list we returns when path is found
        List<AsNode> returnPathNodes = null;

        //Find start and end nodes, if we cant return null and stop!
        SetStartAndEndNode(startPos, endPos);

        if (pathStartNode != null)
        {
            if (pathEndNode == null)
            {
                FindEndNode(endPos);
                if (pathEndNode == null)
                {
                    //still no end node - we leave and sends an empty list
                    maxSearchRounds = 0;
                    return null;
                }
            }

            returnPathNodes = new List<AsNode>();

            /// 检测直线行走 ///
            if (CanWalkLine(pathStartNode, pathEndNode, true) == true)
            {
                returnPathNodes.Add(pathStartNode);
                returnPathNodes.Add(pathEndNode);
            }
            else
            {
                //Clear lists if they are filled
                Array.Clear(openList, 0, openList.Length);
                Array.Clear(closedList, 0, closedList.Length);
                if (sortedOpenList.Count > 0) { sortedOpenList.Clear(); }

                //Insert start node
                openList[pathStartNode.ID] = pathStartNode;
                BHInsertNode(new AsNodeSearch((int)pathStartNode.ID, pathStartNode.F));

                bool endLoop = false;
                while (!endLoop)
                {
                    //If we have no nodes on the open list AND we are not at the end, then we got stucked! return empty list then.
                    if (sortedOpenList.Count == 0)
                    {
                        iTrace.Log("LY", "Empty Openlist, closedList");
                        return null;
                    }

                    //Get lowest node and insert it into the closed list
                    int id = BHGetLowest();
                    currentNode = openList[id];
                    closedList[currentNode.ID] = currentNode;
                    openList[id] = null;

                    if (currentNode.ID == pathEndNode.ID)
                    {
                        endLoop = true;
                        continue;
                    }
                    //Now look at neighbours, check for unwalkable tiles, bounderies, open and closed listed nodes.
                    if (MoveDiagonal)
                    {
                        NeighbourCheck();
                    }
                    else
                    {
                        NonDiagonalNeighborCheck();
                    }
                }

                while (currentNode.parent != null)
                {
                    /// 检测并去除共线点 ///
                    if (returnPathNodes.Count >= 2)
                    {
                        AsNode checkANode = currentNode;
                        AsNode checkBNode = returnPathNodes[returnPathNodes.Count - 1];
                        AsNode checkCNode = returnPathNodes[returnPathNodes.Count - 2];

                        if (IsBoundNode(checkANode) == false && IsBoundNode(checkBNode) == true)
                        {

                        }
                        else
                        {
                            int tAmBx = checkANode.xKey - checkBNode.xKey;
                            int tAmBy = checkANode.yKey - checkBNode.yKey;
                            int tBmCx = checkBNode.xKey - checkCNode.xKey;
                            int tBmCy = checkBNode.yKey - checkCNode.yKey;

                            if ((tAmBx == 0 && tBmCx == 0)
                                || (tAmBy == 0 && tBmCy == 0)
                                || (Math.Abs(tBmCx - tAmBx) == Math.Abs(tBmCy - tAmBy)))
                            {
                                returnPathNodes.RemoveAt(returnPathNodes.Count - 1);
                            }
                        }
                    }

                    /// 添加新节点到列表 ///
                    returnPathNodes.Add(currentNode);
                    /// 更替前置节点 ///
                    currentNode = currentNode.parent;
                }
                returnPathNodes.Add(pathStartNode);
                returnPathNodes.Reverse();
                maxSearchRounds = 0;
            }

            return returnPathNodes;
        }
        else
        {
            maxSearchRounds = 0;
            return null;
        }
    }

    /// <summary>
    /// 优化路径
    /// </summary>
    /// <param name="pathNodes"></param>
    /// <returns></returns>
    private List<Vector3> OptimizeSmallPath(List<AsNode> pathNodes)
    {
        List<AsNode> dealPathNodes = pathNodes;
        if (dealPathNodes == null || dealPathNodes.Count <= 0)
        {
            return null;
        }

        /// 查找更合适替代点(防止贴边走) ///
        List<AsNode> tNewPath = new List<AsNode>();
        List<AsNode> tReplPath = new List<AsNode>();
        Vector2 lastNodeOri = Vector2.zero;
        Vector2 lastNodeCng = Vector2.zero;
        Vector2 curNodeOri = Vector2.zero;
        Vector2 curNodeCng = Vector2.zero;
        tNewPath.Add(dealPathNodes[0]);
        tReplPath.Add(dealPathNodes[0]);
        for (int a = 1; a < dealPathNodes.Count - 1; a++)
        {
            bool tIsCorner = false;
            AsNode tReplaceNode = FindMoreFitWalkNode(dealPathNodes[a], ref tIsCorner);
            if (tReplaceNode != null
                 && CanWalkLine(dealPathNodes[a - 1], tReplaceNode) == true
                && CanWalkLine(tReplaceNode, dealPathNodes[a + 1]) == true)
            {
                lastNodeOri = new Vector2(dealPathNodes[a - 1].xKey, dealPathNodes[a - 1].yKey);
                curNodeOri = new Vector2(dealPathNodes[a].xKey, dealPathNodes[a].yKey);

                lastNodeCng = new Vector2(tNewPath[tNewPath.Count - 1].xKey, tNewPath[tNewPath.Count - 1].yKey);
                curNodeCng = new Vector2(tReplaceNode.xKey, tReplaceNode.yKey);

                if (Vector2.Dot(curNodeOri - lastNodeOri, curNodeCng - lastNodeCng) > 0)
                {
                    tNewPath.Add(tReplaceNode);
                    if (tIsCorner == true)
                    {
                        tReplPath.Add(tReplaceNode);
                    }

                    //if (tReplPath.Count <= 1)
                    //{
                    //    tReplPath.Add(tReplaceNode);
                    //}
                    //else
                    //{
                    //    AsNode checkLastNode = tReplPath[tReplPath.Count - 2];
                    //    if(CanWalkLine(tReplaceNode, checkLastNode, true) == true)
                    //    {
                    //        for(int i = tNewPath.Count - 1; i >= 0; i--)
                    //        {
                    //            if(tNewPath[i] == checkLastNode)
                    //            {
                    //                break;
                    //            }
                    //            tNewPath.RemoveAt(i);
                    //        }
                    //        tReplPath.RemoveAt(tReplPath.Count - 1);
                    //    }
                    //    tReplPath.Add(tReplaceNode);
                    //}

                    //tNewPath.Add(tReplaceNode);
                }
            }
            else
            {
                tNewPath.Add(dealPathNodes[a]);
            }
        }
        tNewPath.Add(dealPathNodes[dealPathNodes.Count - 1]);
        tReplPath.Add(dealPathNodes[dealPathNodes.Count - 1]);

        /// 去除共线点 ///
        //RemoveCollinePoint(ref dealPathNodes, ref tReplNodes);

        /// 去除多余拐点 ///
        //if (dealPathNodes.Count > 2)
        //{
        //    for (int a = dealPathNodes.Count - 1; a >= 0; a--)
        //    {
        //        for (int b = 0; b <= a - 2; b++)
        //        {
        //            if (CanWalkLine(dealPathNodes[a], dealPathNodes[b], true) == true)
        //            {
        //                for (int c = a - 1; c > b; c--)
        //                {
        //                    dealPathNodes.Remove(dealPathNodes[c]);
        //                }
        //                a = dealPathNodes.Count;
        //                break;
        //            }
        //        }
        //    }
        //}

        int tRmNum = 0;
        for (int a = 0; a < tReplPath.Count - 1; a++)
        {
            if (CanWalkLine(tReplPath[a - tRmNum], tReplPath[a + 1], true) == true)
            {
                AsNode tBNode = tReplPath[a - tRmNum];
                AsNode tENode = tReplPath[a + 1];
                int tBInd = tNewPath.IndexOf(tBNode) + 1;
                int tEInd = tNewPath.IndexOf(tENode) - 1;
                int tRng = tEInd - tBInd;

                tRmNum++;
                if (tRng < 0)
                {
                    continue;
                }
                tNewPath.RemoveRange(tNewPath.IndexOf(tBNode) + 1, tNewPath.IndexOf(tENode) - tNewPath.IndexOf(tBNode) - 1);
            }
            else
            {
                tRmNum = 0;
            }
        }

        List<Vector3> retPathPots = new List<Vector3>();
        for (int a = 0; a < tNewPath.Count; a++)
        {
            if (a == 0)
            {
                startPos.y = tNewPath[a].pos.y;
                retPathPots.Add(startPos);
            }
            else if (a == tNewPath.Count - 1)
            {
                endPos.y = tNewPath[a].pos.y;
                retPathPots.Add(endPos);
            }
            else
            {
                retPathPots.Add(tNewPath[a].pos);
            }
        }

        return retPathPots;
    }

    /// <summary>
    /// 同区块寻路
    /// </summary>
    /// <param name="startPos"></param>
    /// <param name="endPos"></param>
    /// <returns></returns>
    private List<Vector3> FindSmallPath(Vector3 startPos, Vector3 endPos)
    {
        List<AsNode> pathNodes = FindChildPathNodes(startPos, endPos);
        return OptimizeSmallPath(pathNodes);
    }

    /// <summary>
    /// 寻路方法
    /// </summary>
    /// <param name="startPos"></param>
    /// <param name="endPos"></param>
    /// <param name="listMethod"></param>
    public void FindPath(Vector3 startPos, Vector3 endPos, Action<WalkPath> pathMethod)
    {
        if (mLoadMap == false)
        {
            return;
        }

        //The path struct we returns when path is found
        WalkPath returnPath = new WalkPath();
        //Find start and end nodes, if we cant return null and stop!
        //SetFindingStartAndEndNode(startPos, endPos);
        returnPath.mStartNode = FindClosestNode(startPos, true);
        returnPath.mEndNode = FindClosestNode(endPos);

        /// 起始点或目标点不存在 ///
        if (returnPath.mStartNode == null || returnPath.mEndNode == null)
        {
            maxSearchRounds = 0;
            if (pathMethod != null)
            {
                pathMethod.Invoke(null);
            }
            return;
        }

        if (returnPath.mStartNode.baseData.blBlockId == returnPath.mEndNode.baseData.blBlockId)
        {
            List<Vector3> tCPath = FindSmallPath(startPos, endPos);
            if (tCPath != null && tCPath.Count > 0)
            {
                BlockPath retPath = new BlockPath();

                SmallPath tSPath = new SmallPath();
                tSPath.mPathPoints = tCPath;

                retPath.PushPath(tSPath);
                returnPath.PushPath(retPath);
            }
            else
            {
                returnPath.mHasPath = false;
            }
        }
        else
        {
            List<uint> tPassPortalIds = FindPassPortalId(returnPath.mStartNode.baseData.blBlockId, returnPath.mEndNode.baseData.blBlockId);
            if (tPassPortalIds.Count % 2 == 0)
            {
                List<PortalFig> tPFigList = new List<PortalFig>();
                List<Vector3> tPosList = new List<Vector3>();
                for (int a = 0; a < tPassPortalIds.Count; a++)
                {
                    PortalFig tPF = mMapAssi.GetPortalFigById(tPassPortalIds[a]);
                    tPFigList.Add(tPF);
                    tPosList.Add(tPF.transform.position);
                }
                tPFigList.Insert(0, null);
                tPFigList.Add(null);
                tPosList.Insert(0, startPos);
                tPosList.Add(endPos);

                for (int a = 0; a < tPosList.Count; a = a + 2)
                {
                    List<Vector3> tCPath = FindSmallPath(tPosList[a], tPosList[a + 1]);
                    if (tCPath == null)
                    {
                        returnPath.mHasPath = false;
                        continue;
                    }
                    BlockPath retPath = new BlockPath();

                    SmallPath tSPath = new SmallPath();
                    tSPath.mPathPoints = tCPath;

                    retPath.PushPath(tSPath);
                    retPath.beginPortalId = 0;
                    retPath.endPortalId = 0;
                    retPath.toPortalId = 0;
                    if (tPFigList[a] != null)
                    {
                        retPath.beginPortalId = tPFigList[a].mPortalId;
                    }
                    if (tPFigList[a + 1] != null)
                    {
                        retPath.endPortalId = tPFigList[a + 1].mPortalId;
                        retPath.toPortalId = tPFigList[a + 1].mLinkPortalId;
                    }

                    returnPath.PushPath(retPath);
                }
            }
            else
            {
                iTrace.Log("LY", "Pass portal number error !!! " + tPassPortalIds.Count);
            }

            //iTrace.Log("LY", "                   " + tPassPortalIds.Count);
        }

        if (pathMethod != null)
        {
            pathMethod.Invoke(returnPath);
        }
    }

    /// <summary>
    /// Find start and end Node
    /// </summary>
    /// <param name="start"></param>
    /// <param name="end"></param>
    private void SetStartAndEndNode(Vector3 start, Vector3 end)
    {
        startPos = start;
        pathStartNode = FindClosestNode(start);
        if (pathStartNode == null)
        {
            iTrace.Error("LY", "Start node miss !!! ");
        }
        endPos = end;
        pathEndNode = FindClosestNode(end);
        if (pathEndNode == null)
        {
            iTrace.Error("LY", "End node miss !!! ");
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="startPos"></param>
    /// <param name="pathPoints"></param>
    /// <param name="pathMethod"></param>
    public void FindFallowPath(Vector3 startPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> pathMethod)
    {
        if (mLoadMap == false)
        {
            return;
        }

        //The path struct we returns when path is found
        WalkPath returnPath = new WalkPath();
        BlockPath tBPath = new BlockPath();
        returnPath.PushPath(tBPath);
        for (int a = 0; a < pathPoints.Count; a++)
        {
            List<Vector3> tSP;
            if (a == 0)
            {
                tSP = FindSmallPath(startPos, pathPoints[a].mPoint);
            }
            else
            {
                tSP = FindSmallPath(pathPoints[a - 1].mPoint, pathPoints[a].mPoint);
            }

            if (tSP == null)
            {
                pathMethod.Invoke(null);
                return;
            }

            SmallPath tSPath = new SmallPath();
            tSPath.mPathPoints = tSP;
            tSPath.mPathTime = pathPoints[a].mDuration;
            tSPath.mWaitTimeAtEnd = pathPoints[a].mDelay;
            tSPath.CalLength();
            tBPath.PushPath(tSPath);
        }

        pathMethod.Invoke(returnPath);
    }

    public bool IsTheClosestNodeWalkable(Vector3 pos)
    {
        int x = (MapStartPosition.x < 0F) ? Mathf.FloorToInt(((pos.x + Mathf.Abs(MapStartPosition.x)) / Tilesize)) : Mathf.FloorToInt((pos.x - MapStartPosition.x) / Tilesize);
        int z = (MapStartPosition.z < 0F) ? Mathf.FloorToInt(((pos.z + Mathf.Abs(MapStartPosition.z)) / Tilesize)) : Mathf.FloorToInt((pos.z - MapStartPosition.z) / Tilesize);

        if (x < 0 || z < 0 || x > mAsMap.Map.GetLength(0) || z > mAsMap.Map.GetLength(1))
            return false;

        AsNode n = mAsMap.Map[x, z];
        return n.walkable;
    }

    /// <summary>
    /// 根据位置查找最近的可执行格子
    /// </summary>
    /// <param name="pos"></param>
    /// <returns></returns>
    public AsNode FindClosestNode(Vector3 pos, bool findNeightbours = false, bool showErr = true)
    {
        //int x = (MapStartPosition.x < 0F) ? Mathf.FloorToInt(((pos.x + Mathf.Abs(MapStartPosition.x)) / Tilesize)) : Mathf.FloorToInt((pos.x - MapStartPosition.x) / Tilesize);
        //int z = (MapStartPosition.z < 0F) ? Mathf.FloorToInt(((pos.z + Mathf.Abs(MapStartPosition.z)) / Tilesize)) : Mathf.FloorToInt((pos.z - MapStartPosition.z) / Tilesize);
        int x = (int)(Mathf.Abs((pos.x - MapStartPosition.x)) / Tilesize);
        int z = (int)(Mathf.Abs((pos.z - MapStartPosition.z)) / Tilesize);

        if (mAsMap == null || mAsMap.Map == null || x < 0 || z < 0 || x >= mAsMap.Map.GetLength(0) || z >= mAsMap.Map.GetLength(1))
            return null;

        AsNode n = mAsMap.Map[x, z];
        if (n == null)
        {
            if (showErr == true)
            {
                iTrace.eError("LY", "Map node null !!!  Pos : " + pos + "   x : " + x + "   z : " + z);
            }
            return null;
        }

        if (CanWalkEasy(n))
        {
            //return new AsNode(x, z, n.yCoord, n.ID, n.xCoord, n.zCoord, 
            //    n.walkable, n.isPortal, n.portalIndex);
            return n.Clone();
        }
        else
        {
            if (findNeightbours == false)
            {
                iTrace.Log("LY", "==================      " + n.pos);
                return null;
            }

            //If we get a non walkable tile, then look around its neightbours
            for (int i = z - 1; i < z + 2; i++)
            {
                for (int j = x - 1; j < x + 2; j++)
                {
                    //Check they are within bounderies
                    if (i > -1 && i < mAsMap.Map.GetLength(1) && j > -1 && j < mAsMap.Map.GetLength(0))
                    {
                        if (CanWalkEasy(mAsMap.Map[j, i]))
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
    }

    public AsNode FindClosestNodeNoSelf(Vector3 pos)
    {
        int x = (int)(Mathf.Abs((pos.x - MapStartPosition.x)) / Tilesize);
        int z = (int)(Mathf.Abs((pos.z - MapStartPosition.z)) / Tilesize);

        if (mAsMap == null || mAsMap.Map == null || x < 0 || z < 0 || x >= mAsMap.Map.GetLength(0) || z >= mAsMap.Map.GetLength(1))
            return null;

        AsNode n = mAsMap.Map[x, z];
        if (n == null || n.connectNodes == null)
        {
            return null;
        }

        for (int i = 0; i < n.connectNodes.Count; i++)
        {
            Vector2 tIndex = n.connectNodes[i];
            AsNode tNode = mAsMap.Map[(int)tIndex.x, (int)tIndex.y];
            if (tNode != null && CanWalkEasy(tNode))
            {
                return tNode.Clone();
            }
        }
        return null;
    }

    private void FindEndNode(Vector3 pos)
    {
        int x = (MapStartPosition.x < 0F) ? Mathf.FloorToInt(((pos.x + Mathf.Abs(MapStartPosition.x)) / Tilesize)) : Mathf.FloorToInt((pos.x - MapStartPosition.x) / Tilesize);
        int z = (MapStartPosition.z < 0F) ? Mathf.FloorToInt(((pos.z + Mathf.Abs(MapStartPosition.z)) / Tilesize)) : Mathf.FloorToInt((pos.z - MapStartPosition.z) / Tilesize);

        AsNode closestNode = mAsMap.Map[x, z];
        List<AsNode> walkableNodes = new List<AsNode>();

        int turns = 1;

        while (walkableNodes.Count < 1 && maxSearchRounds < (int)10 / Tilesize)
        {
            walkableNodes = EndNodeNeighbourCheck(x, z, turns);
            turns++;
            maxSearchRounds++;
        }

        if (walkableNodes.Count > 0) //If we found some walkable tiles we will then return the nearest
        {
            int lowestDist = 99999999;
            AsNode n = null;

            foreach (AsNode node in walkableNodes)
            {
                int i = GetHeuristics(closestNode, node);
                if (i < lowestDist)
                {
                    lowestDist = i;
                    n = node;
                }
            }
            //endNode = new AsNode(n.x, n.y, n.yCoord, n.ID, n.xCoord, n.zCoord, 
            //    n.walkable, n.isPortal, n.portalIndex);
            pathEndNode = n.Clone();
        }
    }

    private List<AsNode> EndNodeNeighbourCheck(int x, int z, int r)
    {
        List<AsNode> nodes = new List<AsNode>();

        for (int i = z - r; i < z + r + 1; i++)
        {
            for (int j = x - r; j < x + r + 1; j++)
            {
                //Check that we are within bounderis, and goes in ring around our end pos
                if (i > -1 && j > -1 && i < mAsMap.Map.GetLength(0) && j < mAsMap.Map.GetLength(1) &&
                    ((i < z - r + 1 || i > z + r - 1) || (j < x - r + 1 || j > x + r - 1)))
                {
                    //if it is walkable put it on the right list
                    if (mAsMap.Map[j, i].walkable)
                    {
                        nodes.Add(mAsMap.Map[j, i]);
                    }
                }
            }
        }

        return nodes;
    }

    /// <summary>
    /// 查找连通的节点（8个）
    /// </summary>
    private void NeighbourCheck()
    {
        if (currentNode.connectNodes == null)
            return;

        for (int a = 0; a < currentNode.connectNodes.Count; a++)
        {
            AsNode tNBNode = mAsMap.Map[(int)currentNode.connectNodes[a].x, (int)currentNode.connectNodes[a].y];
            //Check the node is walkable
            //if (MapNodeCanWalk(tNBNode))
            if (CanWalkEasy(tNBNode))
            //if (CanWalkHard(tNBNode))
            {
                //We do not recheck anything on the closed list
                if (!OnClosedList((int)tNBNode.ID))
                {
                    //If it is not on the open list then add it to
                    if (!OnOpenList((int)tNBNode.ID))
                    {
                        //AsNode addNode = tNBNode.Clone(currentNode);
                        AsNode addNode = tNBNode.CloneSetParent(currentNode);
                        addNode.H = GetHeuristics(tNBNode.xKey, tNBNode.yKey);
                        addNode.G = GetMovementCost(currentNode.xKey, currentNode.yKey, tNBNode.xKey, tNBNode.yKey, tNBNode.IsBound) + currentNode.G;
                        addNode.F = addNode.H + addNode.G;
                        //Insert on open list
                        openList[addNode.ID] = addNode;
                        //Insert on sorted list
                        BHInsertNode(new AsNodeSearch((int)addNode.ID, addNode.F));
                        //sortedOpenList.Add(new NodeSearch(addNode.ID, addNode.F));
                    }
                    else
                    {
                        ///If it is on openlist then check if the new paths movement cost is lower
                        AsNode n = GetNodeFromOpenList((int)tNBNode.ID);
                        if (currentNode.G + GetMovementCost(currentNode.xKey, currentNode.yKey, n.xKey, n.yKey, n.IsBound)
                            < openList[tNBNode.ID].G)
                        {
                            n.parent = currentNode;
                            n.G = currentNode.G + GetMovementCost(currentNode.xKey, currentNode.yKey, n.xKey, n.yKey, n.IsBound);
                            n.F = n.G + n.H;
                            BHSortNode((int)n.ID, n.F);
                            //ChangeFValue(n.ID, n.F);
                        }
                    }
                }
            }
        }
    }

    /// <summary>
    /// 查找连通的节点（4个）
    /// </summary>
    private void NonDiagonalNeighborCheck()
    {
        if (currentNode.connectNodes == null)
            return;

        for (int a = 0; a < currentNode.connectNodes.Count; a++)
        {
            AsNode tNBNode = mAsMap.Map[(int)currentNode.connectNodes[a].x, (int)currentNode.connectNodes[a].y];
            //Check that we are not moving diagonal
            if (GetMovementCost(currentNode.xKey, currentNode.yKey, tNBNode.xKey, tNBNode.yKey) < 14)
            {
                //Check the node is walkable
                if (CanWalkEasy(tNBNode))
                {
                    //We do not recheck anything on the closed list
                    if (!OnClosedList((int)tNBNode.ID))
                    {
                        //If it is not on the open list then add it to
                        if (!OnOpenList((int)tNBNode.ID))
                        {
                            //AsNode addNode = tNBNode.Clone(currentNode);
                            AsNode addNode = tNBNode.CloneSetParent(currentNode);
                            addNode.H = GetHeuristics(tNBNode.xKey, tNBNode.yKey);
                            addNode.G = GetMovementCost(currentNode.xKey, currentNode.yKey, tNBNode.xKey, tNBNode.yKey, tNBNode.IsBound)
                                + currentNode.G;
                            addNode.F = addNode.H + addNode.G;
                            //Insert on open list
                            openList[addNode.ID] = addNode;
                            //Insert on sorted list
                            BHInsertNode(new AsNodeSearch((int)addNode.ID, addNode.F));
                            //sortedOpenList.Add(new NodeSearch(addNode.ID, addNode.F));
                        }
                        else
                        {
                            ///If it is on openlist then check if the new paths movement cost is lower
                            AsNode n = GetNodeFromOpenList((int)tNBNode.ID);
                            if (currentNode.G + GetMovementCost(currentNode.xKey, currentNode.yKey, n.xKey, n.yKey, n.IsBound)
                                < openList[tNBNode.ID].G)
                            {
                                n.parent = currentNode;
                                n.G = currentNode.G + GetMovementCost(currentNode.xKey, currentNode.yKey, n.xKey, n.yKey, n.IsBound);
                                n.F = n.G + n.H;
                                BHSortNode((int)n.ID, n.F);
                                //ChangeFValue(n.ID, n.F);
                            }
                        }
                    }
                }
            }
        }
    }

    private void ChangeFValue(int id, int F)
    {
        foreach (AsNodeSearch ns in sortedOpenList)
        {
            if (ns.ID == id)
            {
                ns.F = F;
            }
        }
    }

    //Check if a Node is already on the openList
    private bool OnOpenList(int id)
    {
        return (openList[id] != null) ? true : false;
    }

    //Check if a Node is already on the closedList
    private bool OnClosedList(int id)
    {
        return (closedList[id] != null) ? true : false;
    }

    private int GetHeuristics(int x, int y)
    {
        //Make sure heuristic aggression is not less then 0!
        int HA = (HeuristicAggression < 0) ? 0 : HeuristicAggression;
        return (int)(Mathf.Abs(x - pathEndNode.xKey) * (10F + (10F * HA))) + (int)(Mathf.Abs(y - pathEndNode.yKey) * (10F + (10F * HA)));
    }

    private int GetHeuristics(AsNode a, AsNode b)
    {
        //Make sure heuristic aggression is not less then 0!
        int HA = (HeuristicAggression < 0) ? 0 : HeuristicAggression;
        return (int)(Mathf.Abs(a.xKey - b.xKey) * (10F + (10F * HA))) + (int)(Mathf.Abs(a.yKey - b.yKey) * (10F + (10F * HA)));
    }

    private int GetMovementCost(int x, int y, int j, int i, bool isBound = false)
    {
        //Moving straight or diagonal?
        if (isBound == true)
            return (x != j && y != i) ? 1014 : 1010;

        return (x != j && y != i) ? 14 : 10;
    }

    private AsNode GetNodeFromOpenList(int id)
    {
        return (openList[id] != null) ? openList[id] : null;
    }

    #region Binary_Heap (min)

    private void BHInsertNode(AsNodeSearch ns)
    {
        //We use index 0 as the root!
        if (sortedOpenList.Count == 0)
        {
            sortedOpenList.Add(ns);
            openList[ns.ID].sortedIndex = 0;
            return;
        }

        sortedOpenList.Add(ns);
        bool canMoveFurther = true;
        int index = sortedOpenList.Count - 1;
        openList[ns.ID].sortedIndex = index;

        while (canMoveFurther)
        {
            int parent = Mathf.FloorToInt((index - 1) / 2);

            if (index == 0) //We are the root
            {
                canMoveFurther = false;
                openList[sortedOpenList[index].ID].sortedIndex = 0;
            }
            else
            {
                if (sortedOpenList[index].F < sortedOpenList[parent].F)
                {
                    AsNodeSearch s = sortedOpenList[parent];
                    sortedOpenList[parent] = sortedOpenList[index];
                    sortedOpenList[index] = s;

                    //Save sortedlist index's for faster look up
                    openList[sortedOpenList[index].ID].sortedIndex = index;
                    openList[sortedOpenList[parent].ID].sortedIndex = parent;

                    //Reset index to parent ID
                    index = parent;
                }
                else
                {
                    canMoveFurther = false;
                }
            }
        }
    }

    private void BHSortNode(int id, int F)
    {
        bool canMoveFurther = true;
        int index = openList[id].sortedIndex;
        sortedOpenList[index].F = F;

        while (canMoveFurther)
        {
            int parent = Mathf.FloorToInt((index - 1) / 2);

            if (index == 0) //We are the root
            {
                canMoveFurther = false;
                openList[sortedOpenList[index].ID].sortedIndex = 0;
            }
            else
            {
                if (sortedOpenList[index].F < sortedOpenList[parent].F)
                {
                    AsNodeSearch s = sortedOpenList[parent];
                    sortedOpenList[parent] = sortedOpenList[index];
                    sortedOpenList[index] = s;

                    //Save sortedlist index's for faster look up
                    openList[sortedOpenList[index].ID].sortedIndex = index;
                    openList[sortedOpenList[parent].ID].sortedIndex = parent;

                    //Reset index to parent ID
                    index = parent;
                }
                else
                {
                    canMoveFurther = false;
                }
            }
        }
    }

    private int BHGetLowest()
    {

        if (sortedOpenList.Count == 1) //Remember 0 is our root
        {
            int ID = sortedOpenList[0].ID;
            sortedOpenList.RemoveAt(0);
            return ID;
        }
        else if (sortedOpenList.Count > 1)
        {
            //save lowest not, take our leaf as root, and remove it! Then switch through children to find right place.
            int ID = sortedOpenList[0].ID;
            sortedOpenList[0] = sortedOpenList[sortedOpenList.Count - 1];
            sortedOpenList.RemoveAt(sortedOpenList.Count - 1);
            openList[sortedOpenList[0].ID].sortedIndex = 0;

            int index = 0;
            bool canMoveFurther = true;
            //Sort the list before returning the ID
            while (canMoveFurther)
            {
                int child1 = (index * 2) + 1;
                int child2 = (index * 2) + 2;
                int switchIndex = -1;

                if (child1 < sortedOpenList.Count)
                {
                    switchIndex = child1;
                }
                else
                {
                    break;
                }
                if (child2 < sortedOpenList.Count)
                {
                    if (sortedOpenList[child2].F < sortedOpenList[child1].F)
                    {
                        switchIndex = child2;
                    }
                }
                if (sortedOpenList[index].F > sortedOpenList[switchIndex].F)
                {
                    AsNodeSearch ns = sortedOpenList[index];
                    sortedOpenList[index] = sortedOpenList[switchIndex];
                    sortedOpenList[switchIndex] = ns;

                    //Save sortedlist index's for faster look up
                    openList[sortedOpenList[index].ID].sortedIndex = index;
                    openList[sortedOpenList[switchIndex].ID].sortedIndex = switchIndex;

                    //Switch around idnex
                    index = switchIndex;
                }
                else
                {
                    break;
                }
            }
            return ID;

        }
        else
        {
            return -1;
        }
    }

    #endregion

    #endregion //End astar region!

    #region DynamicSupport

    /// <summary>
    /// 初始化动态门状态
    /// </summary>
    private void InitDoorBlock()
    {
        List<DoorBlock> tDBs = mMapAssi.DoorBlockList;

        if (tDBs == null)
            return;

        for (int a = 0; a < tDBs.Count; a++)
        {
            ChangeDoorBlockState(tDBs[a], tDBs[a].mDefaultState);
        }
    }

    private void ChangeAreaNodeState(Vector3 startPos, int xLength, int zLength, bool isOpen)
    {
        AsNode startNode = FindClosestNode(startPos);
        if (startNode == null)
        {
            iTrace.Error("LY", "Bounds start node can not be found !!! MapPathMgr::ChangeAreaNodeState");
            return;
        }

        for (int i = startNode.xKey - 1; i < startNode.xKey + xLength; i++)
        {
            for (int j = startNode.yKey - 1; j < startNode.yKey + zLength; j++)
            {
                if (i >= 0 && j >= 0 && i < mAsMap.Map.GetLength(0) && j < mAsMap.Map.GetLength(1))
                {
                    mAsMap.Map[i, j].SetNodeWalkState(isOpen);
                }
            }
        }
    }

    /// <summary>
    /// 改变阻挡物状态
    /// </summary>
    /// <param name="isOpen"></param>
    public void ChangeDoorBlockState(uint doorBlockId, bool isOpen)
    {
        DoorBlock tBlock = mMapAssi.FindDoorBlockById(doorBlockId);
        if (tBlock == null)
        {
            iTrace.Error("LY", "Can not find door block !!! " + doorBlockId);
            return;
        }
        ChangeDoorBlockState(tBlock, isOpen);
    }

    /// <summary>
    /// 改变阻挡物状态
    /// </summary>
    /// <param name="isOpen"></param>
    private void ChangeDoorBlockState(DoorBlock doorBlock, bool isOpen)
    {
        if (doorBlock == null)
            return;

        BoxCollider tC = doorBlock.GetComponent<BoxCollider>();
        Vector3 startPos = new Vector3(doorBlock.transform.position.x - tC.size.x / 2.0f, 0,
            doorBlock.transform.position.z - tC.size.z / 2.0f);
        UnityEngine.Debug.Log("Door block : " + startPos + "   " + isOpen);
        int xIterations = Mathf.CeilToInt(Mathf.Abs(tC.size.x / Tilesize)) + 1;
        int zIterations = Mathf.CeilToInt(Mathf.Abs(tC.size.z / Tilesize)) + 1;
        ChangeAreaNodeState(startPos, xIterations, zIterations, isOpen);
        tC.enabled = !isOpen;
    }

    #endregion

    #region 地图区块操作

    /// <summary>
    /// 根据Id获取地图区块
    /// </summary>
    /// <param name="blockId"></param>
    /// <returns></returns>
    public MapBlock GetMapBlock(uint blockId)
    {
        return mAsMap.GetMapBlock(blockId);
    }

    public Vector3 GetPortalFigToAsNodePos(uint portalId)
    {
        PortalFig tFig = mMapAssi.GetPortalFigById(portalId);
        if (tFig == null)
        {
            iTrace.Error("LY", "To portal id error !!!  ");
            return Vector3.zero;
        }

        AsNode tNode = FindClosestNode(tFig.transform.position);
        if (tNode == null)
        {
            iTrace.Error("LY", "AsNode error !!!  ");
            return Vector3.zero;
        }

        return tNode.pos;
    }

    /// <summary>
    /// 查找到底指定区块经过的传送口Id
    /// </summary>
    /// <param name="curBlockId"></param>
    /// <param name="desBlockId"></param>
    /// <returns></returns>
    public List<uint> FindPassPortalId(uint curBlockId, uint desBlockId)
    {
        List<uint> passPortalList = new List<uint>();

        if (curBlockId == desBlockId)
        {
            return passPortalList;
        }

        uint starBlockId = curBlockId;
        uint endBlockId = desBlockId;

        CheckDesMapBlock(starBlockId, endBlockId, passPortalList, new List<uint>());

        return passPortalList;
    }


    private bool CheckDesMapBlock(uint blockId, uint desBlockId, List<uint> passPortalIds, List<uint> containBlock)
    {
        if (blockId == desBlockId)
        {
            return true;
        }

        if (containBlock.Contains(blockId))
        {
            return false;
        }
        containBlock.Add(blockId);


        MapBlock tBlock = GetMapBlock(blockId);
        for (int a = 0; a < tBlock.mPortalIds.Count; a++)
        {
            PortalInfo tPInfo = mAsMap.GetPortalInfo(tBlock.mPortalIds[a]);
            if (tPInfo == null)
            {
                iTrace.Error("LY", "Can not find portal !!! " + tBlock.mPortalIds[a]);
                continue;
            }
            if (mCurMapId != tPInfo.linkMapId)
            {
                continue;
            }
            passPortalIds.Add(tPInfo.portalId);

            PortalInfo tLinkPInfo = mAsMap.GetPortalInfo(tPInfo.linkPortalId);
            if (tLinkPInfo == null)
            {
                iTrace.Error("LY", "Can not find link portal !!! " + tPInfo.linkPortalId);
                continue;
            }
            passPortalIds.Add(tLinkPInfo.portalId);

            if (CheckDesMapBlock(tLinkPInfo.belongBlockId, desBlockId, passPortalIds, containBlock) == true)
            {
                return true;
            }
            else
            {
                passPortalIds.RemoveAt(passPortalIds.Count - 1);
                passPortalIds.RemoveAt(passPortalIds.Count - 1);
            }
        }

        return false;
    }

    /// <summary>
    /// 获取到指定地图的跳转口坐标点
    /// </summary>
    /// <param name="mapId"></param>
    /// <returns></returns>
    public Vector3 GetMapEntrancePos(uint mapId)
    {
        if (mLoadMap == false)
        {
            iTrace.Error("LY", "Map data does not load !!! ");
            return Vector3.zero;
        }

        PortalFig tFig = MapAssis.FindPortalByLinkMapId(mapId);
        if (tFig == null)
        {
            iTrace.Error("LY", "No portal to this map : " + mapId);
            return Vector3.zero;
        }

        return tFig.transform.position;
    }

    /// <summary>
    /// 根据区域Id获取预加载资源索引
    /// </summary>
    /// <param name="zoneId"></param>
    /// <returns></returns>
    public uint GetPreLoadResIdByZoneId(uint zoneId)
    {
        if (mCurMapData == null || mCurMapData.loadZoneDatas == null || mCurMapData.loadZoneDatas.Count <= 0)
            return 0;

        for (int a = 0; a < mCurMapData.loadZoneDatas.Count; a++)
        {
            PreLoadZoneData tPZD = mCurMapData.loadZoneDatas[a];
            if (tPZD != null && tPZD.zoneId == zoneId)
            {
                return tPZD.resIndex;
            }
        }

        return 0;
    }

    #endregion

    public MapPathMgr()
    {
        //iTrace.Log("LY", "MapPathMgr create !!! ");
        Init();
    }

    /// <summary>
    /// 读取地图数据并组建地图
    /// </summary>
    /// <param name="mapId"></param>
    public void LoadMapData(uint mapId)
    {
        /// 避免重复创建地图 ///
        if (mCurMapId == mapId)
        {
            return;
        }

        if (mCurMapData != null)
        {
            DisposeMapData(mCurMapId, mapId);
        }

        mCurMapId = mapId;
        if (mCurMapId <= 0)
        {
            iTrace.Log("LY", "Special map id !!! " + mCurMapId);
            return;
        }

        if (mPreloadMapData != null)
        {
            MapDataStore.Instance.MapDataCopy = mPreloadMapData;
            FinLoadSaveData(mPreloadMapData);
            mPreloadMapData = null;
        }
        else
        {
            MapDataStore.Instance.LoadMapData(mapId, FinLoadSaveData);
        }
    }

    //private void FinLoadSaveData(AsSaveMapData mapData)
    //{
    //    mCurMapData = mapData;
    //    BuildMapData();
    //}

    private void FinLoadSaveData(BinaryMapData mapData)
    {
        mCurMapData = mapData;
        BuildMapData();
    }

    /// <summary>
    /// 释放地图数据
    /// </summary>
    public void DisposeMapData(uint disposeMapId, uint nextMapId, bool delAll = false)
    {
        if(delAll == true)
        {
            if (mMapBlockRoot != null)
            {
                MonoBehaviour.DestroyImmediate(mMapBlockRoot);
                mMapBlockRoot = null;
            }
            if (mMapAssi != null)
            {
                mMapAssi.ResetAssistant();
            }
            mLoadMap = false;
            if (mCurMapData != null)
            {
                mCurMapData = null;
            }

            if (mAsMap != null)
            {
                mAsMap.Dispose();
            }
            mAsMap = null;

            MapDataStore.Instance.DisposeMapData(false);

            mCurMapId = 0;

            MapDataStore.Instance.ClearTempPersistMapData();
            MapDataStore.Instance.ClearTempPersistMapBlock();

            return;
        }

        if (mMapBlockRoot != null)
        {
            if(disposeMapId != 0 || nextMapId != 0)
            {
                if (MapDataStore.Instance.CheckSceneMapPersist(mCurMapId) == true)
                {
                    mMapBlockRoot.SetActive(false);
                }
                else
                {
                    if(MapDataStore.Instance.CheckSceneMapPersist(nextMapId) == true)
                    {
                        mMapBlockRoot.SetActive(false);
                        MapDataStore.Instance.AddTempPersistMapBlock(mCurMapId, mMapBlockRoot);
                    }
                    else
                    {
                        MonoBehaviour.DestroyImmediate(mMapBlockRoot);
                    }
                }
            }
            else
            {
                MonoBehaviour.DestroyImmediate(mMapBlockRoot);
            }
            mMapBlockRoot = null;
        }
        if (mMapAssi != null)
        {
            mMapAssi.ResetAssistant();
        }
        mLoadMap = false;
        if(mCurMapData != null)
        {
            //mCurMapData.Clear();
            //ObjPool.Instance.Add(mCurMapData);
            mCurMapData = null;
        }

        if (mAsMap != null)
        {
            mAsMap.Dispose();
        }
        mAsMap = null;
        
        MapDataStore.Instance.DisposeMapData(MapDataStore.Instance.CheckSceneMapPersist(nextMapId));

        mCurMapId = 0;
    }

    float overalltimer = 0;
    int iterations = 0;

    //Go through one 
    public void Update(float dTime)
    {
        if (mLoadMap == false)
        {
            return;
        }

        timeleft -= dTime;
        frames++;

        if (timeleft <= 0F)
        {
            FPS = frames;
            averageFPS += frames;
            times++;
            timeleft = updateinterval;
            frames = 0;
        }

        float timer = 0F;
        float maxtime = 1000 / FPS;
        //Bottleneck prevention
        while (queue.Count > 0 && timer < maxtime)
        {
            Stopwatch sw = new Stopwatch();
            sw.Start();
            //mMainMono.StartCoroutine(PathHandler(queue[0].startPos, queue[0].endPos, queue[0].storeRef));
            MonoEvent.Start(PathHandler(queue[0].startPos, queue[0].endPos, queue[0].storeRef));
            //queue[0].storeRef.Invoke(FindPath(queue[0].startPos, queue[0].endPos));
            queue.RemoveAt(0);
            sw.Stop();
            //print("Timer: " + sw.ElapsedMilliseconds);
            timer += sw.ElapsedMilliseconds;
            overalltimer += sw.ElapsedMilliseconds;
            iterations++;
        }

        timer = 0F;
        while (fpQueue.Count > 0 && timer < maxtime)
        {
            Stopwatch sw = new Stopwatch();
            sw.Start();
            //mMainMono.StartCoroutine(FallowPathHandler(fpQueue[0].startPos, fpQueue[0].mPathPoints, fpQueue[0].storeRef));
            MonoEvent.Start(FallowPathHandler(fpQueue[0].startPos, fpQueue[0].mPathPoints, fpQueue[0].storeRef));
            //queue[0].storeRef.Invoke(FindPath(queue[0].startPos, queue[0].endPos));
            fpQueue.RemoveAt(0);
            sw.Stop();
            //print("Timer: " + sw.ElapsedMilliseconds);
            timer += sw.ElapsedMilliseconds;
            overalltimer += sw.ElapsedMilliseconds;
            iterations++;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="desMapId"></param>
    /// <returns></returns>
    public List<uint> FindPassMapList(uint desMapId)
    {
        List<uint> retMapList = new List<uint>();

        if (desMapId != mCurMapId)
        {
            CheckDesMap(mCurMapId, desMapId, retMapList, new List<uint>());
        }

        return retMapList;
    }

    private bool CheckDesMap(uint curMapId, uint desMapId, List<uint> passMapIds, List<uint> containMap)
    {
        if (curMapId == desMapId)
        {
            return true;
        }

        if (containMap.Contains(curMapId))
        {
            return false;
        }
        containMap.Add(curMapId);

        SceneInfo tSInfo = SceneInfoManager.instance.Find(curMapId);
        if (tSInfo == null)
        {
            return false;
        }

        List<uint> tLinkList = tSInfo.linkScene.list;

        /// 检测直接链接的 ///
        if (tLinkList.Contains(desMapId))
        {
            passMapIds.Add(desMapId);
            return true;
        }

        for (int a = 0; a < tLinkList.Count; a++)
        {
            passMapIds.Add(tLinkList[a]);
            if (CheckDesMap(tLinkList[a], desMapId, passMapIds, containMap) == true)
            {
                return true;
            }
            else
            {
                passMapIds.RemoveAt(passMapIds.Count - 1);
            }
        }
        return false;
    }

    public void SetPreloadMapData(BinaryMapData mapData)
    {
        mPreloadMapData = mapData;
    }

    public void SetWantDesPos(long desPos)
    {
        mOriWantPos = desPos;
        mSetWantPos = true;
    }

    public void ChangeWantPos()
    {
        mWantPos = NetMove.GetPositon(mOriWantPos);
    }

    public long GetOriWantPos()
    {
        return mOriWantPos;
    }

    public uint GetWantResId()
    {
        mSetWantPos = false;
        AsNode tNode = FindClosestNode(mWantPos);
        if (mCurMapData == null || tNode == null || tNode.baseData.loadZoneId <=0)
        {
            return 0;
        }

        return GetPreLoadResIdByZoneId(tNode.baseData.loadZoneId);
    }

    public uint GetResIdByPos(Vector3 pos)
    {
        AsNode tNode = FindClosestNode(pos);
        if (mCurMapData == null || tNode == null || tNode.baseData.loadZoneId <= 0)
        {
            return 0;
        }

        return GetPreLoadResIdByZoneId(tNode.baseData.loadZoneId);
    }

    #region 辅助函数
    public bool CanWalkEasy(int x, int y)
    {
        if (mLoadMap == false)
            return false;
        
        return CanWalkEasy(mAsMap.Map[x, y]);
    }

    public bool CanWalkEasy(AsNode node)
    {
        if (node == null)
            return false;

        return node.CanWalk;
    }

    public bool CanWalkHard(int x, int y)
    {
        if (mLoadMap == false)
            return false;

        return CanWalkHard(mAsMap.Map[x, y]);
    }

    public bool CanWalkHard(AsNode node)
    {
        if (node == null)
            return false;

        return node.CanWalkNoBound;
    }

    /// <summary>
    /// 判断是否安全区域
    /// </summary>
    /// <param name="pos"></param>
    /// <returns></returns>
    public bool IsSaveZone(Vector3 pos)
    {
        AsNode checkNode = FindClosestNode(pos, false, true);
        if(checkNode == null)
        {
            return false;
        }
        return checkNode.IsSaveZone;
    }
    #endregion

    #region 服务器和客户端坐标互换
    /// <summary>
    /// 服务器坐标到本地坐标转换
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    /// <returns></returns>
    public Vector3 PosServerToClient(int x, int y, bool getY = false)
    {
        if(mLoadMap == false || mAsMap == null)
        {
            return new Vector3(x / 100.0f, 0f, y / 100.0f);
        }

        uint indexX = (uint)(x / 100);
        uint indexY = (uint)(y / 100);
        AsNode tNode = mAsMap.GetMapNodeByIndex(indexX, indexY);
        if(tNode == null)
        {
            iTrace.eError("LY", "Can not find AsNode !!!  MapPathMgr::PosServerToClient");
            return Vector3.zero;
        }

        float dX = x % 100 / 100.0f;
        float dY = y % 100 / 100.0f;

        Vector3 retPos = tNode.pos;
        retPos.x = retPos.x - 0.5f + dX;
        retPos.z = retPos.z - 0.5f + dY;
        if (getY == false)
        {
            retPos.y = 0;
        }
        return retPos;
    }

    /// <summary>
    /// 本地坐标到服务器坐标转换
    /// </summary>
    /// <param name="clientPos"></param>
    /// <returns></returns>
    public Vector2 PosClientToServer(Vector3 clientPos)
    {
        if(mLoadMap == false || mAsMap == null)
        {
            int x = (int)(Mathf.Abs(clientPos.x) * 100);
            int y = (int)(Mathf.Abs(clientPos.z) * 100);
            return new Vector2(x, y);
        }

        AsNode tNode = FindClosestNode(clientPos);
        if (tNode == null)
        {
            iTrace.eError("LY", "Can not find AsNode !!!  MapPathMgr::PosClientToServer " + clientPos);
            return new Vector2(999999, 999999);
        }

        float tempX = (clientPos.x - (tNode.pos.x - 0.5f)) * 100;
        float tempY = (clientPos.z - (tNode.pos.z - 0.5f)) * 100;

        int dX = (int)tempX % 100;
        int dY = (int)tempY % 100;

        int indexX = (int)(tNode.xKey * 100) + dX;
        int indexY = (int)(tNode.yKey * 100) + dY;

        return new Vector2(indexX, indexY);
    }

    /// <summary>
    /// 本地坐标到服务器坐标转换
    /// </summary>
    /// <param name="clientPos"></param>
    /// <returns></returns>
    public Vector2 PosClientToServer(uint sceneId, Vector3 clientPos)
    {
        int x = 0;
        int y = 0;
        if (map_simplifyMaps.ContainsKey(sceneId) == false)
        {
            iTrace.Error("LY", "Can not get map data !!!  " + sceneId);

            x = (int)(Mathf.Abs(clientPos.x) * 100);
            y = (int)(Mathf.Abs(clientPos.z) * 100);
            return new Vector2(x, y);
        }

        SimplifyMapInfo mapINfo = map_simplifyMaps[sceneId];

        x = (int)(Mathf.Abs(clientPos.x - mapINfo.startPosition.x) * 100);
        y = (int)(Mathf.Abs(clientPos.z - mapINfo.startPosition.z) * 100);
        return new Vector2(x, y);
    }

    /// <summary>
    /// 服务器坐标到本地坐标转换
    /// </summary>
    /// <param name="x"></param>
    /// <param name="y"></param>
    /// <returns></returns>
    public Vector3 VPosServerToClient(int x, int z)
    {
        if (mLoadMap == false)
        {
            iTrace.eError("LY", "Map data is not loaded !!!  MapPathMgr::VPosServerToClient ");
            return new Vector3(x / 100.0f, 0f, z / 100.0f);
        }

        float tValX = x / 100f + MapStartPosition.x;
        float tValZ = z / 100f + MapStartPosition.z;

        return new Vector3(tValX, 0f, tValZ);
    }

    /// <summary>
    /// 本地坐标到服务器坐标转换(虚拟)
    /// </summary>
    /// <param name="clientPos"></param>
    /// <returns></returns>
    public Vector2 VPosClientToServer(Vector3 clientPos)
    {
        if (mLoadMap == false)
        {
            iTrace.eError("LY", "Map data is not loaded !!!  MapPathMgr::VPosClientToServer");
            int x = (int)(Mathf.Abs(clientPos.x) * 100);
            int y = (int)(Mathf.Abs(clientPos.z) * 100);
            return new Vector2(x, y);
        }

        int tValX = (int)((clientPos.x - MapStartPosition.x) * 100);
        int tValZ = (int)((clientPos.z - MapStartPosition.z) * 100);

        return new Vector2(tValX, tValZ);
    }
    #endregion
}
