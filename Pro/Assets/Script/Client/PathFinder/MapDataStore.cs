using System;
using System.IO;
using UnityEngine;
//using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;

#if UNITY_EDITOR
//#define LOCAL_ASSET
#endif

using Loong.Game;


/// <summary>
/// ��ͼ���ݲֿ�
/// </summary>
public class MapDataStore
{
#if LOCAL_ASSET
    private string prefabPath = "Assets/Scene/Share/Prefab/MapBlockObject/";
    private string assetPath = "Assets/Scene/Share/Custom/MapData/";
#endif

    private static MapDataStore mInstance = new MapDataStore();

    /// <summary>
    /// ��ж�ص�ͼ�����ֵ�
    /// </summary>
    private Dictionary<uint, BinaryMapData> m_mapMapData = new Dictionary<uint, BinaryMapData>();
    /// <summary>
    /// ��ж�ص�ͼ��ײ���ֵ�
    /// </summary>
    private Dictionary<uint, GameObject> m_mapMapBlock = new Dictionary<uint, GameObject>();

    /// <summary>
    /// ��ʱ���治ж�ص�ͼ�����ֵ�
    /// </summary>
    private Dictionary<uint, BinaryMapData> m_mapTempMapData = new Dictionary<uint, BinaryMapData>();
    /// <summary>
    /// ��ʱ���治ж�ص�ͼ��ײ���ֵ�
    /// </summary>
    private Dictionary<uint, GameObject> m_mapTempMapBlock = new Dictionary<uint, GameObject>();

    /// <summary>
    /// ��ǰ��ͼ����
    /// </summary>
    //private AsSaveMapData mMapDataCopy = null;
    private BinaryMapData mMapDataCopy = null;


    /// <summary>
    /// ����ָ��
    /// </summary>
    public static MapDataStore Instance
    {
        get
        {
            if(mInstance == null)
            {
                mInstance = new MapDataStore();
            }
            return mInstance;
        }
    }

    public BinaryMapData MapDataCopy
    {
        get
        {
            return mMapDataCopy;
        }
        set
        {
            DisposeMapData(false);
            mMapDataCopy = value;
        }
    }


    private MapDataStore()
    {
        iTrace.Log("LY", "Map data store create !!! ");
    }


    /// <summary>
    /// ��ͼ�����Ƿ��Ѿ���ȡ
    /// </summary>
    /// <param name="mapId"></param>
    /// <returns></returns>
    public bool IsMapDataLoaded(uint mapId)
    {
        if (mMapDataCopy == null || mMapDataCopy.mapId != mapId)
        {
            return false;
        }

        return true;
    }

    /// <summary>
    /// ��ӳ־û���ͼ����
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="mapData"></param>
    public void AddPersistMapData(uint mapId, BinaryMapData mapData)
    {
        if(mapData == null || m_mapMapData.ContainsKey(mapId))
        {
            return;
        }
        
        m_mapMapData.Add(mapId, mapData);
    }

    /// <summary>
    /// ��ȡ�־û���ͼ����
    /// </summary>
    /// <param name="mapId"></param>
    /// <returns></returns>
    public BinaryMapData GetPersistMapData(uint mapId)
    {
        if (m_mapMapData.ContainsKey(mapId) == false)
        {
            return null;
        }

        if(m_mapMapData[mapId] == null)
        {
            m_mapMapData.Remove(mapId);
            return null;
        }

        return m_mapMapData[mapId];
    }

    public void AddPersistMapBlock(uint mapId, GameObject block)
    {
        if (block == null || m_mapMapBlock.ContainsKey(mapId))
            return;

        GameObject.DontDestroyOnLoad(block);
        m_mapMapBlock.Add(mapId, block);
    }

    public GameObject GetPersistMapBlock(uint mapId)
    {
        if(m_mapMapBlock.ContainsKey(mapId) == false)
        {
            return null;
        }

        if(m_mapMapBlock[mapId] == null)
        {
            m_mapMapBlock.Remove(mapId);
            return null;
        }

        m_mapMapBlock[mapId].SetActive(true);
        return m_mapMapBlock[mapId];
    }

    public void AddTempPersistMapData(uint mapId, BinaryMapData mapData)
    {
        if (mapData == null || m_mapTempMapData.ContainsKey(mapId))
        {
            return;
        }

        m_mapTempMapData.Add(mapId, mapData);
    }

    public BinaryMapData GetTempPersistMapData(uint mapId)
    {
        if (m_mapTempMapData.ContainsKey(mapId) == false)
        {
            return null;
        }

        if(m_mapTempMapData[mapId] == null)
        {
            m_mapTempMapData.Remove(mapId);
            return null;
        }

        BinaryMapData retData = m_mapTempMapData[mapId];
        m_mapTempMapData.Remove(mapId);
        return retData;
    }

    public void ClearTempPersistMapData()
    {
        foreach (BinaryMapData value in m_mapTempMapData.Values)
        {
            value.Clear();
            ObjPool.Instance.Add(value);
        }
        m_mapTempMapData.Clear();
    }

    public void AddTempPersistMapBlock(uint mapId, GameObject block)
    {
        if (block == null || m_mapTempMapBlock.ContainsKey(mapId))
            return;

        GameObject.DontDestroyOnLoad(block);
        m_mapTempMapBlock.Add(mapId, block);
    }

    public GameObject GetTempPersistMapBlock(uint mapId)
    {
        if (m_mapTempMapBlock.ContainsKey(mapId) == false)
        {
            return null;
        }

        if(m_mapTempMapBlock[mapId] == null)
        {
            m_mapTempMapBlock.Remove(mapId);
            return null;
        }

        GameObject retBlock = m_mapTempMapBlock[mapId];
        m_mapTempMapBlock.Remove(mapId);
        retBlock.SetActive(true);
        return retBlock;
    }

    public void ClearTempPersistMapBlock()
    {
        foreach (GameObject value in m_mapTempMapBlock.Values)
        {
            GameObject.DestroyImmediate(value);
        }
        m_mapTempMapBlock.Clear();
    }

    public bool CheckCurSceneMapPersist()
    {
        if(GameSceneManager.instance.SceneInfo == null)
        {
            return false;
        }

        if (GameSceneManager.instance.SceneInfo.dontDestroy > 0)
            return true;

        return false;
    }

    /// <summary>
    /// ����ͼ�Ƿ�־û�
    /// </summary>
    /// <param name="mapId"></param>
    /// <returns></returns>
    public bool CheckSceneMapPersist(uint mapId)
    {
        //if(m_mapTempMapData.ContainsKey(mapId))
        //{
        //    return true;
        //}

        SceneInfo tInfo = SceneInfoManager.instance.Find(mapId);
        if(tInfo == null || tInfo.dontDestroy <= 0)
        {
            return false;
        }

        return true;
    }

    /// <summary>
    /// �ͷŵ�ͼ����
    /// </summary>
    /// <param name="mapId"></param>
    public void DisposeMapData(bool needAddPersist)
    {
        if (mMapDataCopy == null)
        {
            return;
        }

        if (MapDataStore.Instance.CheckSceneMapPersist(MapPathMgr.instance.CurMapId) == false)
        {
            if(needAddPersist == true)
            {
                AddTempPersistMapData(mMapDataCopy.mapId, mMapDataCopy);
            }
            else
            {
                //GameObject.Destroy(mMapDataCopy);
                mMapDataCopy.Clear();
                ObjPool.Instance.Add(mMapDataCopy);
            }
        }

        mMapDataCopy = null;
    }

    /// <summary>
    /// ��ȡ��ͼ����
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="loadFinishCB"></param>
    public void LoadMapData(uint mapId, Action<BinaryMapData> loadFinishCB)
    {
        if (IsMapDataLoaded(mapId) == true)
        {
            if (loadFinishCB != null)
            {
                loadFinishCB(mMapDataCopy);
            }
        }
        /// ���ļ��ж�ȡ ///
        else
        {
            DisposeMapData(CheckSceneMapPersist(mapId));

#if LOCAL_ASSET
            /// ���ض�ȡ��Դ ///
            string tMapPath = assetPath + mapId.ToString() + ".asset";
            mMapDataCopy = AssetDatabase.LoadAssetAtPath(tMapPath, typeof(AsSaveMapData)) as AsSaveMapData;
            if (mMapDataCopy == null)
            {
                iTrace.Error("LY", "No map data !!! ");
                return;
            }

            if (loadFinishCB != null)
            {
                loadFinishCB(mMapDataCopy);
            }
#else
            /// ��ȡbundle ///
            string prefabName = mapId.ToString() + ".bytes";
            AssetMgr.Instance.Load(prefabName, (gbj) =>
            {
                TextAsset textAsset = gbj as TextAsset;
                if (textAsset == null)
                {
                    iTrace.Error("LY", "No map data !!! ");
                    return;
                }

                //mMapDataCopy = new BinaryMapData();
                mMapDataCopy = ObjPool.Instance.Get<BinaryMapData>();
                mMapDataCopy.Read(textAsset.bytes);

                if (mMapDataCopy == null)
                {
                    iTrace.Error("LY", "No map data !!! ");
                    return;
                }

                SceneInfo tSInfo = SceneInfoManager.instance.Find(mapId);
                if(tSInfo != null && tSInfo.dontDestroy > 0)
                {
                    AddPersistMapData(mapId, mMapDataCopy);
                }

                if (loadFinishCB != null)
                {
                    loadFinishCB(mMapDataCopy);
                }
            });
#endif
        }
    }

    /// <summary>
    /// ��ȡ��ͼ������
    /// </summary>
    /// <param name="mapId"></param>
    /// <param name="loadFinishCB"></param>
    public void LoadMapColliderObj(uint mapId, Action<GameObject> loadFinishCB)
    {
#if LOCAL_ASSET
        /// ���ض�ȡ��Դ ///
        string localPath = prefabPath + mapId.ToString() + "_block.prefab";
        GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(localPath, typeof(GameObject)) as GameObject;
        if (tLoadPrefab != null)
        {
            mMapBlockRoot = GameObject.Instantiate(tLoadPrefab);
            //mMapBlockRoot.name = "ASMapEditNode";
        }
        else
        {
            iTrace.Error("LY", "Map block prefab miss !!! " + mapId);
        }

        if(loadFinishCB != null)
        {
            loadFinishCB(gObj);
        }
#else
        /// ��ȡbundle ///
        string prefabName = mapId.ToString() + "_block";
        AssetMgr.LoadPrefab(prefabName, (gObj) =>
        {
            if (gObj == null)
            {
                iTrace.Error("LY", "Map block prefab miss !!! " + mapId);
                return;
            }

            SceneInfo tSInfo = SceneInfoManager.instance.Find(mapId);
            if(tSInfo != null && tSInfo.dontDestroy > 0)
            {
                AddPersistMapBlock(mapId, gObj);
            }

            if(loadFinishCB != null)
            {
                loadFinishCB(gObj);
            }
        });
#endif
    }
}
