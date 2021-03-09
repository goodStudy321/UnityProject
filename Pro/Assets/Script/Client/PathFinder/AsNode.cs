using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;

/// <summary>
/// A*Ѱ·��λ���ӽṹ
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
    /// ��ͨ�ڵ�
    /// </summary>
    [SerializeField]
    public List<Vector2> connectNodes = null;

    /// <summary>
    /// ��Ҫ����
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
    /// �Ƿ���ת��
    /// </summary>
    public bool IsProtal
    {
        get
        {
            return baseData.portalIndex > 0;
        }
    }
    /// <summary>
    /// �Ƿ�ǽ��
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
    /// �Ƿ��������
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
    /// �����ͨ�ڵ�����
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
/// ���Ϳ���Ϣ
/// </summary>
public class PortalInfo
{
    /// <summary>
    /// ���Ϳ�Id
    /// </summary>
    public uint portalId = 0;
    /// <summary>
    /// ��������Id
    /// </summary>
    public UInt16 belongBlockId = 0;
    /// <summary>
    /// ���ӵ�ͼId
    /// </summary>
    public uint linkMapId = 0;
    /// <summary>
    /// ���Ӵ��Ϳ�Id
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
/// ��ͼ��������
/// </summary>
public class MapBlock
{
    /// <summary>
    /// ����Id
    /// </summary>
    public UInt16 mBlockId = 0;
    /// <summary>
    /// �����ڴ��Ϳ��б�
    /// </summary>
    public List<uint> mPortalIds = new List<uint>();
    /// <summary>
    /// �����ڿ���������
    /// </summary>
    public List<AsNode> mMapNode = new List<AsNode>();


    public MapBlock(UInt16 id)
    {
        mBlockId = id;
    }

    /// <summary>
    /// ����Ƿ������ͼ����
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
    /// ����Ƿ�����������
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
    /// ��ӽڵ㵽����
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
    /// �ϲ�����
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
/// ������·����·����·����С��λ��
/// </summary>
public class SmallPath
{
    /// <summary>
    /// ·������
    /// </summary>
    public float mPathLength = 0f;
    /// <summary>
    /// ·������ʱ��
    /// </summary>
    public float mPathTime = 0f;
    /// <summary>
    /// ·��ĩβ�ȴ�ʱ��
    /// </summary>
    public float mWaitTimeAtEnd = 0f;
    /// <summary>
    /// ·����
    /// </summary>
    public List<Vector3> mPathPoints = new List<Vector3>();

    /// <summary>
    /// ����·������
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
/// ������·���ṹ
/// </summary>
public class BlockPath
{
    /// <summary>
    /// ��ʼ��ת��Id
    /// </summary>
    public uint beginPortalId = 0;
    /// <summary>
    /// ��β��ת��Id
    /// </summary>
    public uint endPortalId = 0;
    /// <summary>
    /// ��ת����ת��Id
    /// </summary>
    public uint toPortalId = 0;
    /// <summary>
    /// ����·��
    /// </summary>
    public List<SmallPath> mPathList = new List<SmallPath>();


    /// <summary>
    /// ������һ��·��
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
    /// ���·��
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
/// Ѱ·����·������������������ת�������ת��ͼ��
/// </summary>
public class WalkPath
{
    /// <summary>
    /// Ѱ·��ʼ��
    /// </summary>
    public AsNode mStartNode = null;
    /// <summary>
    /// Ѱ·��ֹ��
    /// </summary>
    public AsNode mEndNode = null;
    /// <summary>
    /// �Ƿ���·��
    /// </summary>
    public bool mHasPath = true;

    /// <summary>
    /// ����·��
    /// </summary>
    public List<BlockPath> mPathList = new List<BlockPath>();

    /// <summary>
    /// ·������
    /// </summary>
    public int PathNum
    {
        get { return mPathList.Count; }
    }

    /// <summary>
    /// ��õ�ǰ·��
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
    /// ɾ����ǰ·��
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
    /// ������һ��·��
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
/// ����·������Ϣ
/// </summary>
public class FigPathPotInfo
{
    /// <summary>
    /// ·��������
    /// </summary>
    public Vector3 mPoint;
    /// <summary>
    /// ���ʱ��
    /// </summary>
    public float mDuration = 0f;
    /// <summary>
    /// �ȴ�ʱ��
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