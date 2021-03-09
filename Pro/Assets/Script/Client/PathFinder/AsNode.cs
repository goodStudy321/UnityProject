using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;

/// <summary>
/// A*寻路单位格子结构
/// </summary>
public class AsNode
{
    //public SaveMapNode baseData = null;
    public BinaryMapNode baseData = null;

    public AsNode parent    = null;
    public bool walkable    = true;
    public int F            = 0;
    public int H            = 0;
    public int G            = 0;
    
    //Use for faster look ups
    public int sortedIndex = -1;

    /// <summary>
    /// 连通节点
    /// </summary>
    [SerializeField]
    public List<Vector2> connectNodes = null;

    /// <summary>
    /// 需要回收
    /// </summary>
    private bool needRyc = true;


    public uint ID
    {
        get { return baseData.Id; }
        set { baseData.Id = value; }
    }
    public UInt16 xKey
    {
        get { return baseData.x; }
        set { baseData.x = value; }
    }
    public UInt16 yKey
    {
        get { return baseData.y; }
        set { baseData.y = value; }
    }
    //public Vector3 pos
    //{
    //    get { return baseData.pos; }
    //    set { baseData.pos = value; }
    //}
    public Vector3 pos
    {
        get { return baseData.pos.GetVector3(); }
        set {
            if(baseData.pos == null)
            {
                if(Application.isPlaying == true)
                {
                    baseData.pos = ObjPool.Instance.Get<SVector3>();
                }
                else
                {
                    baseData.pos = new SVector3();
                }
            }
            baseData.pos.SetVal(value);
        }
    }
    public uint portalIndex
    {
        get { return baseData.portalIndex; }
    }

    /// <summary>
    /// 是否跳转口
    /// </summary>
    public bool IsProtal
    {
        get
        {
            return baseData.portalIndex > 0;
        }
    }
    /// <summary>
    /// 是否墙壁
    /// </summary>
    public bool IsWall
    {
        get
        {
            return baseData.walkType == 3;
        }
    }
    public bool IsBound
    {
        get
        {
            return baseData.walkType == 2;
        }
    }
    public bool IsSaveZone
    {
        get
        {
            return baseData.saveZone;
        }
    }
    /// <summary>
    /// 是否可以行走
    /// </summary>
    public bool CanWalk
    {
        get
        {
            if (walkable == false)
                return false;

            return (baseData.walkType == 1 || baseData.walkType == 2);
        }
    }
    public bool CanWalkNoBound
    {
        get
        {
            if (walkable == false)
                return false;

            return (baseData.walkType == 1);
        }
    }


    private void FillConnectNode(List<uint> indexList)
    {
        if(indexList == null || indexList.Count <= 0)
        {
            return;
        }

        connectNodes = new List<Vector2>();
        for(int a = 0; a < indexList.Count; a++)
        {
            uint iX = indexList[a] / 10000;
            uint iY = indexList[a] % 10000;
            connectNodes.Add(new Vector2(iX, iY));
        }
    }
    

    public AsNode()
    {
        
    }

    public AsNode(UInt16 indexX, UInt16 indexY, uint idValue, Vector3 pos, byte wType, uint portalId = 0, AsNode p = null)
    {
        //baseData = new BinaryMapNode();
        baseData = ObjPool.Instance.Get<BinaryMapNode>();
        baseData.x = indexX;
        baseData.y = indexY;
        baseData.Id = idValue;
        if (baseData.pos == null)
        {
            if (Application.isPlaying == true)
            {
                baseData.pos = ObjPool.Instance.Get<SVector3>();
            }
            else
            {
                baseData.pos = new SVector3();
            }
        }
        baseData.pos.SetVal(pos);
        baseData.walkType = wType;
        baseData.portalIndex = portalId;

        parent = p;

        walkable = (baseData.walkType == 1 || baseData.walkType == 2);
        F = 0;
        G = 0;
        H = 0;
    }

    //public AsNode(BinaryMapNode node)
    //{
    //    baseData = node;

    //    walkable = CanWalk;
    //    parent = null;
    //    F = 0;
    //    G = 0;
    //    H = 0;

    //    FillConnectNode(baseData.connectNodes);
    //}

    public void SetData(UInt16 indexX, UInt16 indexY, uint idValue, Vector3 pos, byte wType, uint portalId = 0, AsNode p = null)
    {
        //baseData = new BinaryMapNode();
        baseData = ObjPool.Instance.Get<BinaryMapNode>();
        baseData.x = indexX;
        baseData.y = indexY;
        baseData.Id = idValue;
        if (baseData.pos == null)
        {
            if (Application.isPlaying == true)
            {
                baseData.pos = ObjPool.Instance.Get<SVector3>();
            }
            else
            {
                baseData.pos = new SVector3();
            }
        }
        baseData.pos.SetVal(pos);
        baseData.walkType = wType;
        baseData.portalIndex = portalId;

        parent = p;

        walkable = (baseData.walkType == 1 || baseData.walkType == 2);
        F = 0;
        G = 0;
        H = 0;
    }

    public void SetData(BinaryMapNode node)
    {
        baseData = node;
        needRyc = false;

        walkable = CanWalk;
        parent = null;
        F = 0;
        G = 0;
        H = 0;

        FillConnectNode(baseData.connectNodes);
    }

    public void Reset()
    {
        //if (baseData != null && needRyc == true)
        //{
        //    baseData.Clear();
        //    ObjPool.Instance.Add(baseData);
        //}
        
        baseData = null;
        needRyc = true;

        parent = null;
        walkable = true;
        F = 0;
        H = 0;
        G = 0;

        sortedIndex = -1;
        connectNodes = null;
    }

    public AsNode Clone()
    {
        AsNode retNode = MapPathMgr.instance.GetAsNode();
        retNode.baseData = baseData.Clone();

        retNode.walkable = walkable;
        if (connectNodes != null)
        {
            retNode.connectNodes = new List<Vector2>(connectNodes);
        }
        
        return retNode;
    }

    public AsNode CloneSetParent(AsNode p)
    {
        AsNode retNode = Clone();
        retNode.parent = p;

        return retNode;
    }

    public void SetNodeWalkState(bool isOpen)
    {
        if(isOpen == true)
        {
            if((baseData.walkType == 1 || baseData.walkType == 2) == true)
            {
                walkable = true;
            }
        }
        else
        {
            walkable = false;
        }
    }

    /// <summary>
    /// 添加连通节点索引
    /// </summary>
    /// <param name="tNodeIndex"></param>
    public void AddConnetNode(Vector2 tNodeIndex)
    {
        if(connectNodes == null)
        {
            connectNodes = new List<Vector2>();
        }

        connectNodes.Add(tNodeIndex);
    }
}

/// <summary>
/// 传送口信息
/// </summary>
public class PortalInfo
{
    /// <summary>
    /// 传送口Id
    /// </summary>
    public uint portalId = 0;
    /// <summary>
    /// 所属区块Id
    /// </summary>
    public UInt16 belongBlockId = 0;
    /// <summary>
    /// 链接地图Id
    /// </summary>
    public uint linkMapId = 0;
    /// <summary>
    /// 链接传送口Id
    /// </summary>
    public uint linkPortalId = 0;

    public PortalInfo()
    {

    }

    public PortalInfo(PortalFig pFig, UInt16 bBIds)
    {
        portalId = pFig.mPortalId;
        linkMapId = pFig.mLinkMapId;
        linkPortalId = pFig.mLinkPortalId;

        belongBlockId = bBIds;
    }

    public PortalInfo(SavePortalInfo saveData)
    {
        portalId = saveData.portalId;
        belongBlockId = saveData.belongBlockId;
        linkMapId = saveData.linkMapId;
        linkPortalId = saveData.linkPortalId;
    }
}


/// <summary>
/// 地图区块数据
/// </summary>
public class MapBlock
{
    /// <summary>
    /// 区块Id
    /// </summary>
    public UInt16 mBlockId = 0;
    /// <summary>
    /// 区块内传送口列表
    /// </summary>
    public List<uint> mPortalIds = new List<uint>();
    /// <summary>
    /// 区块内可行走区域
    /// </summary>
    public List<AsNode> mMapNode = new List<AsNode>();


    public MapBlock(UInt16 id)
    {
        mBlockId = id;
    }

    /// <summary>
    /// 检测是否包含地图格子
    /// </summary>
    /// <param name="node"></param>
    /// <returns></returns>
    public bool CheckContain(AsNode node)
    {
        if (node == null)
            return false;

        return mMapNode.Contains(node);
    }

    /// <summary>
    /// 检测是否与区块相邻
    /// </summary>
    /// <param name="node"></param>
    /// <returns></returns>
    public bool CheckBeside(AsNode mayBeBlockNode, AsNode checkNode, float dis)
    {
        if(CheckContain(mayBeBlockNode) == true)
        {
            if(Mathf.Abs(mayBeBlockNode.pos.y - checkNode.pos.y) <= dis)
            {
                return true;
            }
        }

        return false;
    }

    /// <summary>
    /// 添加节点到区块
    /// </summary>
    public void AddNode(AsNode node)
    {
        if(CheckContain(node) == true)
        {
            return;
        }
        
        mMapNode.Add(node);
        node.baseData.blBlockId = mBlockId;
        if(node.IsProtal && mPortalIds.Contains(node.baseData.portalIndex) == false)
        {
            mPortalIds.Add(node.baseData.portalIndex);
        }
    }

    /// <summary>
    /// 合并区块
    /// </summary>
    /// <param name="nodeList"></param>
    /// <param name="pIdList"></param>
    public void MergeBlock(List<AsNode> nodeList, List<uint> pIds)
    {
        mMapNode.AddRange(nodeList);
        for(int a = 0; a < nodeList.Count; a++)
        {
            nodeList[a].baseData.blBlockId = mBlockId;
        }

        mPortalIds.AddRange(pIds);
    }
}

/// <summary>
/// 区块内路径子路径（路径最小单位）
/// </summary>
public class SmallPath
{
    /// <summary>
    /// 路径长度
    /// </summary>
    public float mPathLength = 0f;
    /// <summary>
    /// 路径行走时间
    /// </summary>
    public float mPathTime = 0f;
    /// <summary>
    /// 路径末尾等待时间
    /// </summary>
    public float mWaitTimeAtEnd = 0f;
    /// <summary>
    /// 路径点
    /// </summary>
    public List<Vector3> mPathPoints = new List<Vector3>();

    /// <summary>
    /// 计算路径长度
    /// </summary>
    public void CalLength()
    {
        mPathLength = 0f;
        for (int a = 0; a < mPathPoints.Count - 1; a++)
        {
            float tLen = Vector3.Distance(mPathPoints[a], mPathPoints[a + 1]);
            mPathLength += tLen;
        }
    }
}

/// <summary>
/// 区块内路径结构
/// </summary>
public class BlockPath
{
    /// <summary>
    /// 起始跳转口Id
    /// </summary>
    public uint beginPortalId = 0;
    /// <summary>
    /// 结尾跳转口Id
    /// </summary>
    public uint endPortalId = 0;
    /// <summary>
    /// 跳转到跳转口Id
    /// </summary>
    public uint toPortalId = 0;
    /// <summary>
    /// 完整路径
    /// </summary>
    public List<SmallPath> mPathList = new List<SmallPath>();


    /// <summary>
    /// 弹出第一条路径
    /// </summary>
    /// <returns></returns>
    public SmallPath PopFirstPath()
    {
        if(mPathList == null || mPathList.Count <= 0)
        {
            return null;
        }

        SmallPath retPath = mPathList[0];
        mPathList.RemoveAt(0);
        return retPath;
    }

    /// <summary>
    /// 添加路径
    /// </summary>
    /// <param name="sPath"></param>
    public void PushPath(SmallPath sPath)
    {
        if(sPath == null)
        {
            return;
        }

        mPathList.Add(sPath);
    }
}

/// <summary>
/// 寻路行走路径（包含多条，可跳转区域和跳转地图）
/// </summary>
public class WalkPath
{
    /// <summary>
    /// 寻路起始点
    /// </summary>
    public AsNode mStartNode = null;
    /// <summary>
    /// 寻路终止点
    /// </summary>
    public AsNode mEndNode = null;
    /// <summary>
    /// 是否有路径
    /// </summary>
    public bool mHasPath = true;

    /// <summary>
    /// 完整路径
    /// </summary>
    public List<BlockPath> mPathList = new List<BlockPath>();

    /// <summary>
    /// 路径数量
    /// </summary>
    public int PathNum
    {
        get { return mPathList.Count; }
    }

    /// <summary>
    /// 获得当前路径
    /// </summary>
    /// <returns></returns>
    public BlockPath GetCurPath()
    {
        if(mPathList == null || mPathList.Count <= 0)
        {
            return null;
        }

        return mPathList[0];
    }

    /// <summary>
    /// 删除当前路径
    /// </summary>
    public void RemoveCurPath()
    {
        if (mPathList == null || mPathList.Count <= 0)
        {
            return;
        }

        mPathList.RemoveAt(0);
    }

    /// <summary>
    /// 弹出第一条路径
    /// </summary>
    /// <returns></returns>
    public BlockPath PopFirstPath()
    {
        if (mPathList == null || mPathList.Count <= 0)
        {
            return null;
        }

        BlockPath retPath = mPathList[0];
        mPathList.RemoveAt(0);
        return retPath;
    }

    public void PushPath(BlockPath path)
    {
        mPathList.Add(path);
    }
}

/// <summary>
/// 配置路径点信息
/// </summary>
public class FigPathPotInfo
{
    /// <summary>
    /// 路径点坐标
    /// </summary>
    public Vector3 mPoint;
    /// <summary>
    /// 间隔时间
    /// </summary>
    public float mDuration = 0f;
    /// <summary>
    /// 等待时间
    /// </summary>
    public float mDelay = 0f;


    public FigPathPotInfo Copy()
    {
        FigPathPotInfo retData = new FigPathPotInfo();

        retData.mPoint = mPoint;
        retData.mDuration = mDuration;
        retData.mDelay = mDelay;

        return retData;
    }
}