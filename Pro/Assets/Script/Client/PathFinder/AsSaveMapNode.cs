using UnityEngine;
using System.Text;
using System.IO;
using System;
//using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 传送口信息
/// </summary>
[Serializable]
public class SavePortalInfo
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


    public SavePortalInfo()
    {

    }

    public SavePortalInfo(PortalInfo pInfo, PortalFig pFig)
    {
        portalId = pInfo.portalId;
        belongBlockId = pInfo.belongBlockId;
        linkMapId = pInfo.linkMapId;
        linkPortalId = pInfo.linkPortalId;
    }

    public void Clear()
    {
        portalId = 0;
        belongBlockId = 0;
        linkMapId = 0;
        linkPortalId = 0;
    }

    public void Read(BinaryReader reader)
    {
        portalId = reader.ReadUInt32();
        belongBlockId = reader.ReadUInt16();
        linkMapId = reader.ReadUInt32();
        linkPortalId = reader.ReadUInt32();

    }

    public void Save(BinaryWriter write)
    {
        write.Write(portalId);
        write.Write(belongBlockId);
        write.Write(linkMapId);
        write.Write(linkPortalId);
    }
}

/// <summary>
/// 操控传送口信息
/// </summary>
[Serializable]
public class SaveAwakenPortalInfo
{
    /// <summary>
    /// 传送口Id
    /// </summary>
    public uint portalId = 0;
    /// <summary>
    /// 链接地图Id
    /// </summary>
    public uint linkMapId = 0;


    public SaveAwakenPortalInfo()
    {

    }

    public SaveAwakenPortalInfo(uint aporId, uint linkId)
    {
        portalId = aporId;
        linkMapId = linkId;
    }

    public void Clear()
    {
        portalId = 0;
        linkMapId = 0;
    }

    public void Read(BinaryReader reader)
    {
        portalId = reader.ReadUInt32();
        linkMapId = reader.ReadUInt32();
    }

    public void Save(BinaryWriter write)
    {
        write.Write(portalId);
        write.Write(linkMapId);
    }
}

[Serializable]
public class SVector3
{
    public float x = 0f;
    public float y = 0f;
    public float z = 0f;

    public SVector3()
    {

    }

    //public SVector3(Vector3 vec3)
    //{
    //    x = vec3.x;
    //    y = vec3.y;
    //    z = vec3.z;
    //}

    public void Clear()
    {
        x = 0f;
        y = 0f;
        z = 0f;
    }

    public void SetVal(Vector3 vec3)
    {
        x = vec3.x;
        y = vec3.y;
        z = vec3.z;
    }

    public Vector3 GetVector3()
    {
        return new Vector3(x, y, z);
    }

    public void Read(BinaryReader reader)
    {
        x = reader.ReadSingle();
        y = reader.ReadSingle();
        z = reader.ReadSingle();
    }

    public void Save(BinaryWriter write)
    {
        write.Write(x);
        write.Write(y);
        write.Write(z);
    }
}

/// <summary>
/// 地图格子数据
/// </summary>
[Serializable]
public class BinaryMapNode
{
    public uint Id = 0;                                 /* 索引Id */
    public UInt16 x = 0;                                /* 索引X */
    public UInt16 y = 0;                                /* 索引Y */
    public SVector3 pos = null;                         /* 真实坐标（中心点） */

    public byte walkType = 1;                           /* 行走类型：0、不可走；1、可行走；2、边缘地区；3、墙 */
    public bool saveZone = false;                       /* 是否安全区 */

    public UInt16 blBlockId = 0;                        /* 所属区块Id */
    public uint portalIndex = 0;                        /* 传送接口Id */
    public uint loadZoneId = 0;                         /* 预加载区域Id */

    [SerializeField]
    public List<uint> connectNodes = new List<uint>();  /* 连通节点 */


    public BinaryMapNode()
    {
        
    }

    public void Clear()
    {
        Id = 0;
        x = 0;
        y = 0;
        if(pos != null)
        {
            pos.Clear();
            if(Application.isPlaying == true)
            {
                ObjPool.Instance.Add(pos);
            }
            pos = null;
        }
        walkType = 1;
        saveZone = false;
        blBlockId = 0;
        portalIndex = 0;
        loadZoneId = 0;
        if(connectNodes != null)
        {
            connectNodes.Clear();
        }
    }

    public void Read(BinaryReader reader)
    {
        Id = reader.ReadUInt32();
        x = reader.ReadUInt16();
        y = reader.ReadUInt16();
        if(pos == null)
        {
            if (Application.isPlaying == true)
            {
                pos = ObjPool.Instance.Get<SVector3>();
            }
            else
            {
                pos = new SVector3();
            }
        }
        pos.Read(reader);
        walkType = reader.ReadByte();
        saveZone = reader.ReadBoolean();
        blBlockId = reader.ReadUInt16();
        portalIndex = reader.ReadUInt32();
        loadZoneId = reader.ReadUInt32();

        int len = reader.ReadInt32();
        for (int i = 0; i < len; i++)
        {
            var cn = reader.ReadUInt32();
            connectNodes.Add(cn);
        }
    }

    public void Save(BinaryWriter write)
    {
        write.Write(Id);
        write.Write(x);
        write.Write(y);
        pos.Save(write);
        write.Write(walkType);
        write.Write(saveZone);
        write.Write(blBlockId);
        write.Write(portalIndex);
        write.Write(loadZoneId);
        if(connectNodes == null)
        {
            connectNodes = new List<uint>();
        }
        int len = connectNodes.Count;
        write.Write(len);

        for (int i = 0; i < len; i++)
        {
            var cn = connectNodes[i];
            write.Write(cn);
        }
    }

    public void FillConnectNode(List<Vector2> indexList)
    {
        if (indexList == null || indexList.Count <= 0)
        {
            return;
        }

        connectNodes = new List<uint>();
        for (int a = 0; a < indexList.Count; a++)
        {
            connectNodes.Add((uint)indexList[a].x * 10000 + (uint)indexList[a].y);
        }
    }

    public BinaryMapNode Clone()
    {
        BinaryMapNode retNode = null;
        if(Application.isPlaying == true)
        {
            retNode = ObjPool.Instance.Get<BinaryMapNode>();
        }
        else
        {
            retNode = new BinaryMapNode();
        }

        retNode.Id = Id;
        retNode.x = x;
        retNode.y = y;
        retNode.pos = pos;
        retNode.walkType = walkType;
        retNode.saveZone = saveZone;
        retNode.blBlockId = blBlockId;
        retNode.portalIndex = portalIndex;
        retNode.loadZoneId = loadZoneId;
        if (connectNodes != null)
        {
            retNode.connectNodes = new List<uint>(connectNodes);
        }

        return retNode;
    }
}

/// <summary>
/// 地图保存数据(二进制)
/// </summary>
[Serializable]
public class BinaryMapData
{
    public uint mapId = 0;                                                  /* 地图Id */
    public float tilesize = 1;                                              /* 格子大小 */
    public float falldownHeight = 0f;                                       /* 掉落高度 */
    public float climbLimit = 0f;                                           /* 爬坡高度 */
    public SVector3 startPosition = null;                                   /* 地图起始点（最小点、左下角） */
    public SVector3 endPosition = null;                                     /* 地图结束点（最大点、右上角） */
    public int heuristicAggression = 0;
    public bool moveDiagonal = true;                                        /* 斜线移动 */

    public string portalTag = "";                                           /* 地图传送点标签 */
    [SerializeField]
    public List<string> disallowedTags = new List<string>();                /* 禁止检测标签 */
    [SerializeField]
    public List<string> ignoreTags = new List<string>();                    /* 忽略检测标签 */

    public uint xNum = 0;
    public uint yNum = 0;
    /// <summary>
    /// 地图节点列表
    /// </summary>
    [SerializeField]
    public List<BinaryMapNode> saveMapNodes = new List<BinaryMapNode>();

    /// <summary>
    /// 地图传送口列表
    /// </summary>
    [SerializeField]
    public List<SavePortalInfo> portalList = new List<SavePortalInfo>();
    /// <summary>
    /// 地图操控传送口列表
    /// </summary>
    public List<SaveAwakenPortalInfo> awakenPortalList = new List<SaveAwakenPortalInfo>();

    /// <summary>
    /// 地图传送口数据
    /// </summary>
    public List<BinaryPortalFig> savePortalFig = new List<BinaryPortalFig>();

    /// <summary>
    /// 转换摄像机触发器
    /// </summary>
    [SerializeField]
    public List<CamRotTriggerData> camRotDatas = new List<CamRotTriggerData>();

    /// <summary>
    /// 预加载区域数据
    /// </summary>
    public List<PreLoadZoneData> loadZoneDatas = new List<PreLoadZoneData>();
    /// <summary>
    /// 显示控制区域数据
    /// </summary>
    public List<BinaryAppearZoneFig> appearZoneFigs = new List<BinaryAppearZoneFig>();


    public Vector3 StartPos
    {
        get
        {
            if (startPosition == null)
            {
                return Vector3.zero;
            }

            return new Vector3(startPosition.x, startPosition.y, startPosition.z);
        }
    }

    public Vector3 EndPos
    {
        get
        {
            if (endPosition == null)
            {
                return Vector3.zero;
            }

            return new Vector3(endPosition.x, endPosition.y, endPosition.z);
        }
    }


    public BinaryMapData()
    {
        
    }

    /// <summary>
    /// 清理工作
    /// </summary>
    public void Clear()
    {
        mapId = 0;
        tilesize = 1;
        falldownHeight = 0f;
        climbLimit = 0f;
        if(startPosition != null)
        {
            startPosition.Clear();
            if (Application.isPlaying == true)
            {
                ObjPool.Instance.Add(startPosition);
            }
            startPosition = null;
        }
        if(endPosition != null)
        {
            endPosition.Clear();
            if (Application.isPlaying == true)
            {
                ObjPool.Instance.Add(endPosition);
            }
            endPosition = null;
        }
        heuristicAggression = 0;
        moveDiagonal = true;
        portalTag = "";
        if(disallowedTags != null)
        {
            disallowedTags.Clear();
        }
        if(ignoreTags != null)
        {
            ignoreTags.Clear();
        }
        xNum = 0;
        yNum = 0;

        if(saveMapNodes != null)
        {
            for (int a = 0; a < saveMapNodes.Count; a++)
            {
                if (saveMapNodes[a] != null)
                {
                    saveMapNodes[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(saveMapNodes[a]);
                    }
                }
            }
            saveMapNodes.Clear();
        }

        if(portalList != null)
        {
            for(int a = 0; a < portalList.Count; a++)
            {
                if(portalList[a] != null)
                {
                    portalList[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(portalList[a]);
                    }
                }
            }
            portalList.Clear();
        }

        if(awakenPortalList != null)
        {
            for(int a = 0; a < awakenPortalList.Count; a++)
            {
                if(awakenPortalList[a] != null)
                {
                    awakenPortalList[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(awakenPortalList[a]);
                    }
                }
            }
            awakenPortalList.Clear();
        }

        if(savePortalFig != null)
        {
            for(int a = 0; a < savePortalFig.Count; a++)
            {
                if(savePortalFig[a] != null)
                {
                    savePortalFig[a].Clear();
                    if(Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(savePortalFig[a]);
                    }
                }
            }
            savePortalFig.Clear();
        }

        if(camRotDatas != null)
        {
            for(int a = 0; a < camRotDatas.Count; a++)
            {
                if(camRotDatas[a] != null)
                {
                    camRotDatas[a].Clear();
                    if(Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(camRotDatas[a]);
                    }
                }
            }
            camRotDatas.Clear();
        }

        if(loadZoneDatas != null)
        {
            for(int a = 0; a < loadZoneDatas.Count; a++)
            {
                if(loadZoneDatas[a] != null)
                {
                    loadZoneDatas[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(loadZoneDatas[a]);
                    }
                }
                
            }
            loadZoneDatas.Clear();
        }

        if(appearZoneFigs != null)
        {
            for(int a = 0; a < appearZoneFigs.Count; a++)
            {
                if(appearZoneFigs[a] != null)
                {
                    appearZoneFigs[a].Clear();
                    if(Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(appearZoneFigs[a]);
                    }
                }
            }
            appearZoneFigs.Clear();
        }
    }

#if UNITY_EDITOR
    public void FillMapNode(AsNode[,] mapNode)
    {
        xNum = (uint)mapNode.GetLength(0);
        yNum = (uint)mapNode.GetLength(1);

        for (int i = 0; i < mapNode.GetLength(1); i++)
        {
            for (int j = 0; j < mapNode.GetLength(0); j++)
            {
                if (mapNode[j, i] != null)
                {
                    mapNode[j, i].baseData.FillConnectNode(mapNode[j, i].connectNodes);
                    BinaryMapNode tNode = mapNode[j, i].baseData;
                    saveMapNodes.Add(tNode);
                }
            }
        }
    }
#endif

    public void AddPortalInfo(PortalInfo pInfo, PortalFig pFig)
    {
        portalList.Add(new SavePortalInfo(pInfo, pFig));
    }

    public void AddAwakenPortalInfo(uint aporId, uint linkId)
    {
        awakenPortalList.Add(new SaveAwakenPortalInfo(aporId, linkId));
    }

    public void Read(string path)
    {
        using (var fs = new FileStream(path, FileMode.Open))
        {
            var bytes = new byte[fs.Length];
            fs.Read(bytes, 0, (int)fs.Length);
            Read(bytes);
        }
    }


    public void Read(byte[] bytes)
    {
        using (var ms = new MemoryStream(bytes))
        {
            using (var reader = new BinaryReader(ms, Encoding.UTF8))
            {
                mapId = reader.ReadUInt32();
                tilesize = reader.ReadSingle();
                falldownHeight = reader.ReadSingle();
                climbLimit = reader.ReadSingle();
                if(startPosition == null)
                {
                    startPosition = ObjPool.Instance.Get<SVector3>();
                    //startPosition = new SVector3();
                }
                startPosition.Read(reader);
                if(endPosition == null)
                {
                    endPosition = ObjPool.Instance.Get<SVector3>();
                    //endPosition = new SVector3();
                }
                endPosition.Read(reader);
                heuristicAggression = reader.ReadInt32();
                moveDiagonal = reader.ReadBoolean();

                //portalTag = reader.ReadString();
                ExString.Read(ref portalTag, reader);
                int length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    //var str = reader.ReadString();
                    var str = "";
                    ExString.Read(ref str, reader);
                    disallowedTags.Add(str);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    //var str = reader.ReadString();
                    var str = "";
                    ExString.Read(ref str, reader);
                    ignoreTags.Add(str);
                }

                xNum = reader.ReadUInt32();
                yNum = reader.ReadUInt32();

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    BinaryMapNode it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<BinaryMapNode>();
                    }
                    else
                    {
                        it = new BinaryMapNode();
                    }
                    it.Read(reader);
                    saveMapNodes.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    SavePortalInfo it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<SavePortalInfo>();
                    }
                    else
                    {
                        it = new SavePortalInfo();
                    }
                    it.Read(reader);
                    portalList.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    SaveAwakenPortalInfo it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<SaveAwakenPortalInfo>();
                    }
                    else
                    {
                        it = new SaveAwakenPortalInfo();
                    }
                    it.Read(reader);
                    awakenPortalList.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    BinaryPortalFig it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<BinaryPortalFig>();
                    }
                    else
                    {
                        it = new BinaryPortalFig();
                    }
                    it.Read(reader);
                    savePortalFig.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    CamRotTriggerData it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<CamRotTriggerData>();
                    }
                    else
                    {
                        it = new CamRotTriggerData();
                    }
                    it.Read(reader);
                    camRotDatas.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    PreLoadZoneData it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<PreLoadZoneData>();
                    }
                    else
                    {
                        it = new PreLoadZoneData();
                    }
                    it.Read(reader);
                    loadZoneDatas.Add(it);
                }

                length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    BinaryAppearZoneFig it = null;
                    if (Application.isPlaying == true)
                    {
                        it = ObjPool.Instance.Get<BinaryAppearZoneFig>();
                    }
                    else
                    {
                        it = new BinaryAppearZoneFig();
                    }
                    it.Read(reader);
                    appearZoneFigs.Add(it);
                }
            }
        }
    }


    public void Write(string path)
    {
        using (var fs = new FileStream(path, FileMode.OpenOrCreate))
        {
            using (var write = new BinaryWriter(fs, Encoding.UTF8))
            {
                write.Write(mapId);
                write.Write(tilesize);
                write.Write(falldownHeight);
                write.Write(climbLimit);
                startPosition.Save(write);
                endPosition.Save(write);
                write.Write(heuristicAggression);
                write.Write(moveDiagonal);

                //write.Write(portalTag);
                ExString.Write(portalTag, write);
                int length = disallowedTags.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var str = disallowedTags[i];
                    ExString.Write(str, write);
                }

                length = ignoreTags.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var str = ignoreTags[i];
                    ExString.Write(str, write);
                }

                write.Write(xNum);
                write.Write(yNum);

                length = saveMapNodes.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = saveMapNodes[i];
                    it.Save(write);
                }

                length = portalList.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = portalList[i];
                    it.Save(write);
                }

                length = awakenPortalList.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = awakenPortalList[i];
                    it.Save(write);
                }

                length = savePortalFig.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = savePortalFig[i];
                    it.Save(write);
                }

                length = camRotDatas.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = camRotDatas[i];
                    it.Save(write);
                }

                length = loadZoneDatas.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = loadZoneDatas[i];
                    it.Save(write);
                }

                length = appearZoneFigs.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var it = appearZoneFigs[i];
                    it.Save(write);
                }
            }
        }
    }
}

[Serializable]
public class SVector4
{
    public float x = 0f;
    public float y = 0f;
    public float z = 0f;
    public float w = 0f;

    public SVector4()
    {

    }

    public SVector4(Vector4 vec4)
    {
        SetVal(vec4);
    }

    public SVector4(Color col)
    {
        SetVal(col);
    }

    public void Clear()
    {
        x = 0f;
        y = 0f;
        z = 0f;
        w = 0f;
    }

    public void SetVal(Vector4 vec4)
    {
        x = vec4.x;
        y = vec4.y;
        z = vec4.z;
        w = vec4.w;
    }

    public void SetVal(Color col)
    {
        x = col.r;
        y = col.g;
        z = col.b;
        w = col.a;
    }

    public Vector4 GetVector4()
    {
        return new Vector4(x, y, z, w);
    }

    public Color GetColor()
    {
        return new Color(x, y, z, w);
    }


    public void Read(BinaryReader reader)
    {
        x = reader.ReadSingle();
        y = reader.ReadSingle();
        z = reader.ReadSingle();
        w = reader.ReadSingle();
    }

    public void Save(BinaryWriter write)
    {
        write.Write(x);
        write.Write(y);
        write.Write(z);
        write.Write(w);
    }
}

[Serializable]
public class SAnimationCurve
{
    public List<SVector4> curveKey = new List<SVector4>();

    public void Clear()
    {
        if(curveKey != null)
        {
            for(int a = 0; a < curveKey.Count; a++)
            {
                if(curveKey[a] != null)
                {
                    curveKey[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(curveKey[a]);
                    }
                }
            }
            curveKey.Clear();
        }
    }

    public void Read(BinaryReader reader)
    {
        int length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            SVector4 it = null;
            if (Application.isPlaying == true)
            {
                it = ObjPool.Instance.Get<SVector4>();
            }
            else
            {
                it = new SVector4();
            }
            it.Read(reader);
            curveKey.Add(it);
        }
    }

    public void Save(BinaryWriter write)
    {
        int length = curveKey.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = curveKey[i];
            it.Save(write);
        }

    }
}

[Serializable]
public class BinaryPortalFig
{
    /// <summary>
    /// 传送口Id
    /// </summary>
    public uint mPortalId = 0;
    /// <summary>
    /// 链接地图Id
    /// </summary>
    public uint mLinkMapId = 0;
    /// <summary>
    /// 链接传送口Id
    /// </summary>
    public uint mLinkPortalId = 0;
    /// <summary>
    /// 是否反转
    /// </summary>
    public bool mReverse = false;
    /// <summary>
    /// 面朝方向
    /// </summary>
    public int mFaceType = 1;
    /// <summary>
    /// 解锁跳转点角色等级
    /// </summary>
    public uint mUnlockCharLv = 0;
    /// <summary>
    /// 解锁任务Id
    /// </summary>
    public int mUnlockMissionId = 0;


    /// <summary>
    /// 跳转曲线集合
    /// </summary>
    public List<uint> mJumpPaths = new List<uint>();
    /// <summary>
    /// 曲线跳跃时间集合
    /// </summary>
    public List<float> mJumpTimeList = new List<float>();
    /// <summary>
    /// 速度曲线集合
    /// </summary>
    public List<SAnimationCurve> mAnimCurves = new List<SAnimationCurve>();
    /// <summary>
    /// 曲线对应跳跃动画名称
    /// </summary>
    public List<string> mUseAnimNames = new List<string>();

    /// <summary>
    /// 前置等待时间集合
    /// </summary>
    public List<float> mPreWaitTimeList = new List<float>();
    /// <summary>
    /// 前置等待动画集合
    /// </summary>
    public List<string> mPreAnimList = new List<string>();
    /// <summary>
    /// 前置特效集合
    /// </summary>
    public List<string> mPreFxList = new List<string>();
    /// <summary>
    /// 前置等待前隐藏角色
    /// </summary>
    public List<bool> mPPHideList = new List<bool>();
    /// <summary>
    /// 前置等待后隐藏角色
    /// </summary>
    public List<bool> mPAHideList = new List<bool>();

    /// <summary>
    /// 后置等待时间集合
    /// </summary>
    public List<float> mAftWaitTimeList = new List<float>();
    /// <summary>
    /// 后置等待动画集合
    /// </summary>
    public List<string> mAftAnimList = new List<string>();
    /// <summary>
    /// 后置特效集合
    /// </summary>
    public List<string> mAftFxList = new List<string>();
    /// <summary>
    /// 后置等待前隐藏角色
    /// </summary>
    public List<bool> mAPHideList = new List<bool>();
    /// <summary>
    /// 后置等待后隐藏角色
    /// </summary>
    public List<bool> mAAHideList = new List<bool>();

    /// <summary>
    /// 锁定手动跳转
    /// </summary>
    public bool mLockManualJump = false;


    public BinaryPortalFig()
    {

    }

    public BinaryPortalFig(PortalFig portalFig)
    {
        SetVal(portalFig);
    }

    public void SetVal(PortalFig portalFig)
    {
        mPortalId = portalFig.mPortalId;
        mLinkMapId = portalFig.mLinkMapId;
        mLinkPortalId = portalFig.mLinkPortalId;
        mReverse = portalFig.mReverse;
        mFaceType = (int)portalFig.mFaceType;
        mUnlockCharLv = portalFig.mUnlockCharLv;
        mUnlockMissionId = portalFig.mUnlockMissionId;
        mJumpPaths = new List<uint>(portalFig.mJumpPaths);
        mJumpTimeList = new List<float>(portalFig.mJumpTimeList);

        mAnimCurves = new List<SAnimationCurve>();
        for (int a = 0; a < portalFig.mAnimCurves.Count; a++)
        {
            SAnimationCurve tSCurve = null;
            if(Application.isPlaying == true)
            {
                tSCurve = ObjPool.Instance.Get<SAnimationCurve>();
            }
            else
            {
                tSCurve = new SAnimationCurve();
            }

            AnimationCurve tCurve = portalFig.mAnimCurves[a];
            for (int b = 0; b < tCurve.keys.Length; b++)
            {
                Keyframe tKF = tCurve.keys[b];
                Vector4 saveKey = new Vector4(tKF.time, tKF.value, tKF.inTangent, tKF.outTangent);
                SVector4 sVec4 = null;
                if(Application.isPlaying == true)
                {
                    sVec4 = ObjPool.Instance.Get<SVector4>();
                    sVec4.SetVal(saveKey);
                }
                else
                {
                    sVec4 = new SVector4(saveKey);
                }

                tSCurve.curveKey.Add(sVec4);
            }
            mAnimCurves.Add(tSCurve);
        }
        mUseAnimNames = new List<string>(portalFig.mUseAnimNames);

        mPreWaitTimeList = new List<float>(portalFig.mPreWaitTimeList);
        mPreAnimList = new List<string>(portalFig.mPreAnimList);
        mPreFxList = new List<string>(portalFig.mPreFxList);
        mPPHideList = new List<bool>(portalFig.mPPHideList);
        mPAHideList = new List<bool>(portalFig.mPAHideList);

        mAftWaitTimeList = new List<float>(portalFig.mAftWaitTimeList);
        mAftAnimList = new List<string>(portalFig.mAftAnimList);
        mAftFxList = new List<string>(portalFig.mAftFxList);
        mAPHideList = new List<bool>(portalFig.mAPHideList);
        mAAHideList = new List<bool>(portalFig.mAAHideList);

        mLockManualJump = portalFig.mLockManualJump;
    }

    public void Clear()
    {
        mPortalId = 0;
        mLinkMapId = 0;
        mLinkPortalId = 0;
        mReverse = false;
        mFaceType = 1;
        mUnlockCharLv = 0;
        mUnlockMissionId = 0;
        if(mJumpPaths != null)
        {
            mJumpPaths.Clear();
        }
        if(mJumpTimeList != null)
        {
            mJumpTimeList.Clear();
        }
        if(mAnimCurves != null)
        {
            for (int a = 0; a < mAnimCurves.Count; a++)
            {
                if (mAnimCurves[a] != null)
                {
                    mAnimCurves[a].Clear();
                    if (Application.isPlaying == true)
                    {
                        ObjPool.Instance.Add(mAnimCurves[a]);
                    }
                }
            }
            mAnimCurves.Clear();
        }
        if(mUseAnimNames != null)
        {
            mUseAnimNames.Clear();
        }
        if(mPreWaitTimeList != null)
        {
            mPreWaitTimeList.Clear();
        }
        if(mPreAnimList != null)
        {
            mPreAnimList.Clear();
        }
        if(mPreFxList != null)
        {
            mPreFxList.Clear();
        }
        if(mPPHideList != null)
        {
            mPPHideList.Clear();
        }
        if(mPAHideList != null)
        {
            mPAHideList.Clear();
        }
        if(mAftWaitTimeList != null)
        {
            mAftWaitTimeList.Clear();
        }
        if(mAftAnimList != null)
        {
            mAftAnimList.Clear();
        }
        if(mAftFxList != null)
        {
            mAftFxList.Clear();
        }
        if(mAPHideList != null)
        {
            mAPHideList.Clear();
        }
        if(mAAHideList != null)
        {
            mAAHideList.Clear();
        }
        mLockManualJump = false;
}

    public void Read(BinaryReader reader)
    {
        mPortalId = reader.ReadUInt32();
        mLinkMapId = reader.ReadUInt32();
        mLinkPortalId = reader.ReadUInt32();
        mReverse = reader.ReadBoolean();
        mFaceType = reader.ReadInt32();
        mUnlockCharLv = reader.ReadUInt32();
        mUnlockMissionId = reader.ReadInt32();

        int length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadUInt32();
            mJumpPaths.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadSingle();
            mJumpTimeList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = new SAnimationCurve();
            it.Read(reader);
            mAnimCurves.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = "";
            ExString.Read(ref it, reader);
            mUseAnimNames.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadSingle();
            mPreWaitTimeList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = "";
            ExString.Read(ref it, reader);
            mPreAnimList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = "";
            ExString.Read(ref it, reader);
            mPreFxList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadBoolean();
            mPPHideList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadBoolean();
            mPAHideList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadSingle();
            mAftWaitTimeList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = "";
            ExString.Read(ref it, reader);
            mAftAnimList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = "";
            ExString.Read(ref it, reader);
            mAftFxList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadBoolean();
            mAPHideList.Add(it);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            var it = reader.ReadBoolean();
            mAAHideList.Add(it);
        }

        mLockManualJump = reader.ReadBoolean();
    }

    public void Save(BinaryWriter write)
    {
        write.Write(mPortalId);
        write.Write(mLinkMapId);
        write.Write(mLinkPortalId);
        write.Write(mReverse);
        write.Write(mFaceType);
        write.Write(mUnlockCharLv);
        write.Write(mUnlockMissionId);

        int length = mJumpPaths.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mJumpPaths[i];
            write.Write(it);
        }

        length = mJumpTimeList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mJumpTimeList[i];
            write.Write(it);
        }

        length = mAnimCurves.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAnimCurves[i];
            it.Save(write);
        }

        length = mUseAnimNames.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mUseAnimNames[i];
            ExString.Write(it, write);
        }

        length = mPreWaitTimeList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mPreWaitTimeList[i];
            write.Write(it);
        }

        length = mPreAnimList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mPreAnimList[i];
            ExString.Write(it, write);
        }

        length = mPreFxList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mPreFxList[i];
            ExString.Write(it, write);
        }

        length = mPPHideList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mPPHideList[i];
            write.Write(it);
        }

        length = mPAHideList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mPAHideList[i];
            write.Write(it);
        }

        length = mAftWaitTimeList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAftWaitTimeList[i];
            write.Write(it);
        }

        length = mAftAnimList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAftAnimList[i];
            ExString.Write(it, write);
        }

        length = mAftFxList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAftFxList[i];
            ExString.Write(it, write);
        }

        length = mAPHideList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAPHideList[i];
            write.Write(it);
        }

        length = mAAHideList.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            var it = mAAHideList[i];
            write.Write(it);
        }

        write.Write(mLockManualJump);
    }
}

[Serializable]
public class CamRotTriggerData
{
    public string rootObjName = "";
    public float targetAngles = 0;
    public bool opposite = false;
    public string child1Name = "";
    public string child2Name = "";
    public bool isTrigger = false;
    public float speed = 0f;

    public void Clear()
    {
        rootObjName = "";
        targetAngles = 0;
        opposite = false;
        child1Name = "";
        child2Name = "";
        isTrigger = false;
        speed = 0f;
}

    public void Read(BinaryReader reader)
    {
        ExString.Read(ref rootObjName, reader);
        targetAngles = reader.ReadSingle();
        opposite = reader.ReadBoolean();
        ExString.Read(ref child1Name, reader);
        ExString.Read(ref child2Name, reader);
        isTrigger = reader.ReadBoolean();
        speed = reader.ReadSingle();
    }

    public void Save(BinaryWriter write)
    {
        ExString.Write(rootObjName, write);
        write.Write(targetAngles);
        write.Write(opposite);
        
        ExString.Write(child1Name, write);
        ExString.Write(child2Name, write);
        write.Write(isTrigger);
        write.Write(speed);
    }
}

[Serializable]
public class PreLoadZoneData
{
    public uint zoneId = 0;
    public uint resIndex = 0;

    public void Clear()
    {
        zoneId = 0;
        resIndex = 0;
    }

    public void Read(BinaryReader reader)
    {
        zoneId = reader.ReadUInt32();
        resIndex = reader.ReadUInt32();
    }

    public void Save(BinaryWriter write)
    {
        write.Write(zoneId);
        write.Write(resIndex);
    }
}

[Serializable]
public class BinaryAppearZoneFig
{
    /// <summary>
    /// 节点名称
    /// </summary>
    public string mZoneName = "";
    /// <summary>
    /// 显示区域名称列表
    /// </summary>
    public List<string> mShowZoneNames = new List<string>();
    /// <summary>
    /// 隐藏区域名称列表
    /// </summary>
    public List<string> mHideZoneNames = new List<string>();


    public BinaryAppearZoneFig()
    {

    }

    public void Clear()
    {
        mZoneName = "";
        if(mShowZoneNames != null)
        {
            mShowZoneNames.Clear();
        }
        if(mHideZoneNames != null)
        {
            mHideZoneNames.Clear();
        }
    }

    public void Read(BinaryReader reader)
    {
        ExString.Read(ref mZoneName, reader);

        int length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            string showName = "";
            ExString.Read(ref showName, reader);
            mShowZoneNames.Add(showName);
        }

        length = reader.ReadInt32();
        for (int i = 0; i < length; i++)
        {
            string hideName = "";
            ExString.Read(ref hideName, reader);
            mHideZoneNames.Add(hideName);
        }
    }

    public void Save(BinaryWriter write)
    {
        ExString.Write(mZoneName, write);

        int length = mShowZoneNames.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            string it = mShowZoneNames[i];
            ExString.Write(it, write);
        }

        length = mHideZoneNames.Count;
        write.Write(length);
        for (int i = 0; i < length; i++)
        {
            string it = mHideZoneNames[i];
            ExString.Write(it, write);
        }
    }
}

[Serializable]
public class MapSimplifyDatas
{
    [SerializeField]
    public List<SimplifyMap> mapList = new List<SimplifyMap>();

    public MapSimplifyDatas()
    {

    }

    public void Read(string path)
    {
        using (var fs = new FileStream(path, FileMode.Open))
        {
            var bytes = new byte[fs.Length];
            fs.Read(bytes, 0, (int)fs.Length);
            Read(bytes);
        }
    }


    public void Read(byte[] bytes)
    {
        using (var ms = new MemoryStream(bytes))
        {
            using (var reader = new BinaryReader(ms, Encoding.UTF8))
            {
                int length = reader.ReadInt32();
                for (int i = 0; i < length; i++)
                {
                    var data = new SimplifyMap();
                    data.Read(reader);
                    mapList.Add(data);
                }
            }
        }
    }

    public void Save(string path)
    {
        using (var fs = new FileStream(path, FileMode.OpenOrCreate))
        {
            using (var write = new BinaryWriter(fs, Encoding.UTF8))
            {
                int length = mapList.Count;
                write.Write(length);
                for (int i = 0; i < length; i++)
                {
                    var data = mapList[i];
                    data.Save(write);
                }
            }
        }
    }
}

public class SimplifyMapInfo
{
    public uint mapId = 0;
    public float tilesize = 1f;
    public Vector3 startPosition = Vector3.zero;
    public Vector3 endPosition = Vector3.zero;

    public SimplifyMapInfo()
    {

    }

    public SimplifyMapInfo(SimplifyMap mapData)
    {
        mapId = mapData.mapId;
        tilesize = mapData.tilesize;
        startPosition = mapData.startPosition.GetVector3();
        endPosition = mapData.endPosition.GetVector3();
    }
}

/// <summary>
/// 地图偏移值数据
/// </summary>
[Serializable]
public class SimplifyMap
{
    public uint mapId = 0;                              /* 地图Id */
    public float tilesize = 1f;                         /* 格子大小 */
    public SVector3 startPosition = new SVector3();     /* 地图起始点（最小点、左下角） */
    public SVector3 endPosition = new SVector3();       /* 地图结束点（最大点、右上角） */
    

    public SimplifyMap()
    {
        
    }

    public void Read(BinaryReader reader)
    {
        mapId = reader.ReadUInt32();
        tilesize = reader.ReadSingle();
        startPosition.Read(reader);
        endPosition.Read(reader);
    }


    public void Save(BinaryWriter write)
    {
        Debug.Log("Save SimplifyMap : " + mapId);

        write.Write(mapId);
        write.Write(tilesize);
        startPosition.Save(write);
        endPosition.Save(write);
    }
}