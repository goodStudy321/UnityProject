using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System.Xml;
using System.Xml.Serialization;

using NPOI.SS.UserModel;
using Loong.Edit;
using Loong.Game;


public class PathEditor : EditorWindow 
{
    public enum COMPILETYPE
    {
        CT_Unknown = -1,
        CT_Original,
        CT_Static,
        CT_Working,
        CT_Max
    }

    /// <summary>
    /// 地图障碍物体Prefer保存路径
    /// </summary>
    private static string mSavePath = "Assets/Scene/Share/Prefab/MapBlockObject/";
    
    private static string mGroundLayerName = "Ground";
    private static string mGroundOtherLayerName = "GroundOther";
    private static string mWallLayerName = "Wall";

    private static string mAsAreaTag = "MapArea";
    private static string mAsBlockTag = "MapBlock";
    private static string mAsPortalTag = "MapPortal";
    private static string mAsCtrlPortalTag = "MapCtrlPortal";
    private static string mAsBornPotTag = "MapBornPot";
    private static string mAsDoorTag = "MapDoorBlock";
    private static string mAsZoneTag = "MapSaveZone";
    private static string mAsLoadZoneTag = "LoadZone";

    private static string mAppearCtrlName = "AppearCtrlZone";

    private static string COMPILING_SIGN = "Compiling";


    private bool mInit = false;
    private Vector2 scrollPosition;
    private static COMPILETYPE mCompileType = COMPILETYPE.CT_Original;

    /// <summary>
    /// 编辑物体根节点
    /// </summary>
    private static GameObject mMapEditObjRoot = null;

    private static GameObject mAreaObj = null;
    private static GameObject mBlockObj = null;
    private static GameObject mPortalObj = null;
    private static GameObject mCtrlPortalObj = null;
    private static GameObject mBornPotObj = null;
    private static GameObject mDoorObj = null;
    private static GameObject mZoneObj = null;
    private static GameObject mLoadZoneObj = null;
    private static GameObject mAppearCtrlObj = null;

    private static GameObject mPathfinderObj = null;
    private static AsPathfinderInEditor mPathfinder = null;
    
    private Vector3 mAsAreaSize = new Vector3(10, 1, 10);
    private Vector3 mAsBlockSize = new Vector3(1, 10, 10);
    private Vector3 mAsPortalSize = new Vector3(3, 3, 3);
    private Vector3 mAsCtrlPortalSize = new Vector3(3, 3, 3);
    private Vector3 mAsDoorSize = new Vector3(2, 12, 12);
    private Vector3 mAsZoneSize = new Vector3(10, 1, 10);
    private Vector3 mAsLoadZonelSize = new Vector3(50, 50, 50);
    private Vector3 mAsAppearCtrlSize = new Vector3(50, 50, 50);

    private bool isOutLine = false;

    private bool mShowAreaObj = false;
    private bool mShowBlockObj = false;
    private bool mShowDoorObj = false;
    private bool mShowPortalArea = false;
    private bool mShowAppearZone = false;

    /// <summary>
    /// 地图blocks资源列表
    /// </summary>
    [SerializeField]
    private static string[] mMapBlockGuids = null; 
    /// <summary>
    /// 地图blocks路径
    /// </summary>
    private static string[] mMapBlockPaths = null;
    private static string[] mMapIds = null;


    private static void PreloadMapBlockInfo()
    {
        mMapBlockGuids = AssetDatabase.FindAssets("t:prefab", new string[] { "Assets/Scene/Share/Prefab/MapBlockObject" });
        if(mMapBlockGuids == null || mMapBlockGuids.Length <= 0)
        {
            return;
        }
        mMapBlockPaths = new string[mMapBlockGuids.Length];
        mMapIds = new string[mMapBlockGuids.Length];
        for (int a = 0; a < mMapBlockGuids.Length; a++)
        {
            mMapBlockPaths[a] = AssetDatabase.GUIDToAssetPath(mMapBlockGuids[a]);
            string tName = mMapBlockPaths[a];
            tName = tName.Replace("Assets/Scene/Share/Prefab/MapBlockObject/", "");
            tName = tName.Replace("_block.prefab", "");
            mMapIds[a] = tName;
        }
    }

    private void ClearUselessNode(GameObject rootNode)
    {
        if(rootNode == null)
        {
            return;
        }

        for(int a = rootNode.transform.childCount - 1; a >= 0; a--)
        {
            GameObject tCObj = rootNode.transform.GetChild(a).gameObject;
            if(tCObj.name.Contains("EffZone"))
            {
                DestroyImmediate(tCObj);
                continue;
            }

            if(tCObj.name == "MapPortal")
            {
                for(int b = tCObj.transform.childCount - 1; b >= 0; b--)
                {
                    GameObject tCCObj = tCObj.transform.GetChild(b).gameObject;
                    for(int c = tCCObj.transform.childCount -1; c >= 0; c--)
                    {
                        GameObject tCCCObj = tCCObj.transform.GetChild(c).gameObject;
                        if (tCCCObj.name == "DisplayZone" && tCCCObj.activeSelf == false)
                        {
                            DestroyImmediate(tCCCObj);
                        }
                    }
                }
            }
        }
    }

    /// <summary>
    /// 重链接地图节点
    /// </summary>
    private void ReconnectMapNode()
    {
        if(mMapEditObjRoot != null)
        {
            return;
        }

        mMapEditObjRoot = GameObject.Find("ASMapEditNode");
        if (mMapEditObjRoot == null)
        {
            Debug.LogWarning("LY :  ASMapEditNode miss !!! ");
        }
        else
        {
            mAreaObj = Utility.FindNode(mMapEditObjRoot, mAsAreaTag);
            mBlockObj = Utility.FindNode(mMapEditObjRoot, mAsBlockTag);
            mPortalObj = Utility.FindNode(mMapEditObjRoot, mAsPortalTag);
            mCtrlPortalObj = Utility.FindNode(mMapEditObjRoot, mAsCtrlPortalTag);
            mBornPotObj = Utility.FindNode(mMapEditObjRoot, mAsBornPotTag);
            mDoorObj = Utility.FindNode(mMapEditObjRoot, mAsDoorTag);
            mZoneObj = Utility.FindNode(mMapEditObjRoot, mAsZoneTag);
            mLoadZoneObj = Utility.FindNode(mMapEditObjRoot, mAsLoadZoneTag);
            mAppearCtrlObj = Utility.FindNode(mMapEditObjRoot, mAppearCtrlName);
        }


        mPathfinderObj = GameObject.Find("AsPathfinderInEditor");
        if (mPathfinderObj == null)
        {
            Debug.LogWarning("LY :  AsPathfinderInEditor miss !!! ");
        }
        else
        {
            mPathfinder = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
        }
    }

    /// <summary>
    /// 创建新地图
    /// </summary>
    private void CreateNewMap()
    {
        mMapEditObjRoot = GameObject.Find("ASMapEditNode");
        if (mMapEditObjRoot == null)
        {
            mMapEditObjRoot = new GameObject("ASMapEditNode");
        }
        else
        {
            mAreaObj = Utility.FindNode(mMapEditObjRoot, mAsAreaTag);
            mBlockObj = Utility.FindNode(mMapEditObjRoot, mAsBlockTag);
            mPortalObj = Utility.FindNode(mMapEditObjRoot, mAsPortalTag);
            mCtrlPortalObj = Utility.FindNode(mMapEditObjRoot, mAsCtrlPortalTag);
            mBornPotObj = Utility.FindNode(mMapEditObjRoot, mAsBornPotTag);
            mDoorObj = Utility.FindNode(mMapEditObjRoot, mAsDoorTag);
            mZoneObj = Utility.FindNode(mMapEditObjRoot, mAsZoneTag);
            mLoadZoneObj = Utility.FindNode(mMapEditObjRoot, mAsLoadZoneTag);
            mAppearCtrlObj = Utility.FindNode(mMapEditObjRoot, mAppearCtrlName);
        }
        mMapEditObjRoot.transform.position = Vector3.zero;

        if (mAreaObj == null)
        {
            mAreaObj = new GameObject(mAsAreaTag);
            mAreaObj.transform.parent = mMapEditObjRoot.transform;
            mAreaObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mAreaObj.transform, mGroundLayerName);
        }
        if (mBlockObj == null)
        {
            mBlockObj = new GameObject(mAsBlockTag);
            mBlockObj.transform.parent = mMapEditObjRoot.transform;
            mBlockObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mBlockObj.transform, mWallLayerName);
        }
        if (mPortalObj == null)
        {
            mPortalObj = new GameObject(mAsPortalTag);
            mPortalObj.transform.parent = mMapEditObjRoot.transform;
            mPortalObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mPortalObj.transform, mGroundOtherLayerName);
        }
        if (mCtrlPortalObj == null)
        {
            mCtrlPortalObj = new GameObject(mAsCtrlPortalTag);
            mCtrlPortalObj.transform.parent = mMapEditObjRoot.transform;
            mCtrlPortalObj.transform.localPosition = Vector3.zero;
            //Utility.SetGOLayerIncludeChilden(mPortalObj.transform, mGroundOtherLayerName);
        }
        if (mBornPotObj == null)
        {
            mBornPotObj = new GameObject(mAsBornPotTag);
            mBornPotObj.transform.parent = mMapEditObjRoot.transform;
            mBornPotObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mBornPotObj.transform, mGroundOtherLayerName);
        }
        if (mDoorObj == null)
        {
            mDoorObj = new GameObject(mAsDoorTag);
            mDoorObj.transform.parent = mMapEditObjRoot.transform;
            mDoorObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mDoorObj.transform, mWallLayerName);
        }
        if (mZoneObj == null)
        {
            mZoneObj = new GameObject(mAsZoneTag);
            mZoneObj.transform.parent = mMapEditObjRoot.transform;
            mZoneObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mZoneObj.transform, mGroundOtherLayerName);
        }
        if (mLoadZoneObj == null)
        {
            mLoadZoneObj = new GameObject(mAsLoadZoneTag);
            mLoadZoneObj.transform.parent = mMapEditObjRoot.transform;
            mLoadZoneObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mLoadZoneObj.transform, mGroundOtherLayerName);
        }
        if (mAppearCtrlObj == null)
        {
            mAppearCtrlObj = new GameObject(mAppearCtrlName);
            mAppearCtrlObj.transform.parent = mMapEditObjRoot.transform;
            mAppearCtrlObj.transform.localPosition = Vector3.zero;
        }

        //Utility.SetGOLayerIncludeChilden(mMapEditObjRoot.transform, mLayerName);

        mMapEditObjRoot.hideFlags = HideFlags.DontSaveInEditor;
        mAreaObj.hideFlags = HideFlags.DontSaveInEditor;
        mBlockObj.hideFlags = HideFlags.DontSaveInEditor;
        mPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mCtrlPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mBornPotObj.hideFlags = HideFlags.DontSaveInEditor;
        mDoorObj.hideFlags = HideFlags.DontSaveInEditor;
        mZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mAppearCtrlObj.hideFlags = HideFlags.DontSaveInEditor;

        mPathfinderObj = GameObject.Find("AsPathfinderInEditor");
        if (mPathfinderObj == null)
        {
            mPathfinderObj = new GameObject("AsPathfinderInEditor");
        }
        mPathfinderObj.transform.position = Vector3.zero;

        mPathfinder = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
        if (mPathfinder == null)
        {
            mPathfinder = mPathfinderObj.AddComponent<AsPathfinderInEditor>();
        }

        mPathfinderObj.hideFlags = HideFlags.DontSave;
    }

    private bool LoadMapBlock(string mapId, bool blockOnly = false)
    {
        string localPath = mSavePath + mapId + "_block.prefab";
        GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(localPath, typeof(GameObject)) as GameObject;
        if (tLoadPrefab != null)
        {
            mMapEditObjRoot = GameObject.Find("ASMapEditNode");
            if (mMapEditObjRoot != null)
            {
                if (EditorUtility.DisplayDialog("替换",
                "地图节点已经存在，是否替换  ?？？",
                "Yes",
                "No"))
                {
                    DestroyImmediate(mMapEditObjRoot);
                    mMapEditObjRoot = Instantiate(tLoadPrefab);
                    mMapEditObjRoot.name = "ASMapEditNode";
                }
            }
            else
            {
                mMapEditObjRoot = Instantiate(tLoadPrefab);
                mMapEditObjRoot.name = "ASMapEditNode";
            }

            ClearUselessNode(mMapEditObjRoot);
        }
        else
        {
            return false;
        }

        mAreaObj = Utility.FindNode(mMapEditObjRoot, mAsAreaTag);
        mBlockObj = Utility.FindNode(mMapEditObjRoot, mAsBlockTag);
        mPortalObj = Utility.FindNode(mMapEditObjRoot, mAsPortalTag);
        mCtrlPortalObj = Utility.FindNode(mMapEditObjRoot, mAsCtrlPortalTag);
        mBornPotObj = Utility.FindNode(mMapEditObjRoot, mAsBornPotTag);
        mDoorObj = Utility.FindNode(mMapEditObjRoot, mAsDoorTag);
        mZoneObj = Utility.FindNode(mMapEditObjRoot, mAsZoneTag);
        mLoadZoneObj = Utility.FindNode(mMapEditObjRoot, mAsLoadZoneTag);
        mAppearCtrlObj = Utility.FindNode(mMapEditObjRoot, mAppearCtrlName);
        if (mAreaObj == null)
        {
            mAreaObj = new GameObject(mAsAreaTag);
            mAreaObj.transform.parent = mMapEditObjRoot.transform;
            mAreaObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mAreaObj.transform, mGroundLayerName);
        }
        if (mBlockObj == null)
        {
            mBlockObj = new GameObject(mAsBlockTag);
            mBlockObj.transform.parent = mMapEditObjRoot.transform;
            mBlockObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mBlockObj.transform, mWallLayerName);
        }
        if (mPortalObj == null)
        {
            mPortalObj = new GameObject(mAsPortalTag);
            mPortalObj.transform.parent = mMapEditObjRoot.transform;
            mPortalObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mPortalObj.transform, mGroundOtherLayerName);
        }
        if (mCtrlPortalObj == null)
        {
            mCtrlPortalObj = new GameObject(mAsCtrlPortalTag);
            mCtrlPortalObj.transform.parent = mMapEditObjRoot.transform;
            mCtrlPortalObj.transform.localPosition = Vector3.zero;
            //Utility.SetGOLayerIncludeChilden(mPortalObj.transform, mGroundOtherLayerName);
        }
        if (mBornPotObj == null)
        {
            mBornPotObj = new GameObject(mAsBornPotTag);
            mBornPotObj.transform.parent = mMapEditObjRoot.transform;
            mBornPotObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mBornPotObj.transform, mGroundOtherLayerName);
        }
        else
        {
            for(int a = 0; a < mBornPotObj.transform.childCount; a++)
            {
                GameObject tCObj = mBornPotObj.transform.GetChild(a).gameObject;
                if(tCObj.GetComponent<BornPotFig>() == null)
                {
                    tCObj.AddComponent<BornPotFig>();
                }
            }
        }
        if (mDoorObj == null)
        {
            mDoorObj = new GameObject(mAsDoorTag);
            mDoorObj.transform.parent = mMapEditObjRoot.transform;
            mDoorObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mDoorObj.transform, mWallLayerName);
        }
        if (mZoneObj == null)
        {
            mZoneObj = new GameObject(mAsZoneTag);
            mZoneObj.transform.parent = mMapEditObjRoot.transform;
            mZoneObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mZoneObj.transform, mGroundOtherLayerName);
        }
        if (mLoadZoneObj == null)
        {
            mLoadZoneObj = new GameObject(mAsLoadZoneTag);
            mLoadZoneObj.transform.parent = mMapEditObjRoot.transform;
            mLoadZoneObj.transform.localPosition = Vector3.zero;
            Utility.SetGOLayerIncludeChilden(mLoadZoneObj.transform, mGroundOtherLayerName);
        }
        if (mAppearCtrlObj == null)
        {
            mAppearCtrlObj = new GameObject(mAppearCtrlName);
            mAppearCtrlObj.transform.parent = mMapEditObjRoot.transform;
            mAppearCtrlObj.transform.localPosition = Vector3.zero;
        }

        mMapEditObjRoot.hideFlags = HideFlags.DontSaveInEditor;
        mAreaObj.hideFlags = HideFlags.DontSaveInEditor;
        mBlockObj.hideFlags = HideFlags.DontSaveInEditor;
        mPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mCtrlPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mBornPotObj.hideFlags = HideFlags.DontSaveInEditor;
        mDoorObj.hideFlags = HideFlags.DontSaveInEditor;
        mZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.SetActive(true);
        mAppearCtrlObj.hideFlags = HideFlags.DontSaveInEditor;

        mPathfinderObj = GameObject.Find("AsPathfinderInEditor");
        if (mPathfinderObj == null)
        {
            mPathfinderObj = new GameObject("AsPathfinderInEditor");
        }
        mPathfinderObj.transform.position = Vector3.zero;

        if(mPortalObj != null)
        {
            for (int a = 0; a < mPortalObj.transform.childCount; a++)
            {
                GameObject tPF = mPortalObj.transform.GetChild(a).gameObject;
                GameObject tObj = Utility.FindNode(tPF, "DisplayZone");
                if(tObj == null)
                {
                    tObj = new GameObject("DisplayZone");
                    tObj.transform.parent = tPF.transform;
                    tObj.transform.localPosition = Vector3.zero;
                    tObj.transform.localScale = Vector3.one;
                }
                if(tObj.GetComponent<DisplayZone>() == null)
                {
                    tObj.AddComponent<DisplayZone>();
                }
            }
        }

        mPathfinder = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
        if (mPathfinder == null)
        {
            mPathfinder = mPathfinderObj.AddComponent<AsPathfinderInEditor>();
        }
        if (blockOnly)
        {
            mPathfinder.MapId = uint.Parse(mapId);
        }
        mPathfinderObj.hideFlags = HideFlags.DontSave;

        return true;
    }

    /// <summary>
    /// 读取已有地图
    /// </summary>
    /// <returns></returns>
    //private bool LoadMap(string mapid)
    //{
    //    LoadMapBlock(mapid);

    //    string tMapPath = "Assets/Scene/Share/Custom/MapData/" + mapid + ".asset";
    //    AsSaveMapData map = AssetDatabase.LoadAssetAtPath(tMapPath, typeof(AsSaveMapData)) as AsSaveMapData;
    //    Debug.Log("Id : " + mapid);
    //    if (map == null)
    //    {
    //        Debug.LogError("No map data !!! ");
    //    }
    //    else
    //    {
    //        mPathfinder.LoadMap(map, new List<PortalFig>(mPortalObj.GetComponentsInChildren<PortalFig>()));
    //    }

    //    return true;
    //}

    private BinaryMapData LoadBinaryMapData(string path)
    {
        ////文件流
        //FileStream fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.ReadWrite);
        ////新近二进制格式化程序
        //BinaryFormatter bf = new BinaryFormatter();
        ////反序列化
        //BinaryMapData loadData = (BinaryMapData)bf.Deserialize(fileStream);
        //fileStream.Dispose();
        //return loadData;

        BinaryMapData loadData = new BinaryMapData();
        loadData.Read(path);
        return loadData;
    }

    /// <summary>
    /// 读取已有地图(二进制)
    /// </summary>
    /// <param name="mapid"></param>
    /// <returns></returns>
    private bool LoadBinaryMap(string mapid)
    {
        LoadMapBlock(mapid);

        string tMapPath = "Assets/Scene/Share/Custom/MapData/" + mapid + ".bytes";
        BinaryMapData tMapData = LoadBinaryMapData(tMapPath);
        if (tMapData == null)
        {
            return false;
        }
        Debug.Log("二进制读取   Id : " + mapid);
        if (tMapData == null)
        {
            Debug.LogError("No map data !!! ");
        }
        else
        {
            for (int a = 0; a < mZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mZoneObj.transform.GetChild(a).gameObject;
                if (tObj.GetComponent<SaveZoneFig>() == null)
                {
                    tObj.AddComponent<SaveZoneFig>();
                }
            }
            int missNum = 0;
            for (int a = 0; a < tMapData.savePortalFig.Count; a++)
            {
                if(a >= mPortalObj.transform.childCount)
                {
                    missNum++;
                    continue;
                }
                GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
                PortalFig tPF = tObj.GetComponent<PortalFig>();
                if (tPF == null)
                {
                    tPF = tObj.AddComponent<PortalFig>();
                }
                tPF.InitData(tMapData.savePortalFig[a]);
            }
            if(missNum > 0)
            {
                for(int a = 0; a < missNum; a++)
                {
                    int listNum = tMapData.savePortalFig.Count;
                    tMapData.savePortalFig.RemoveAt(listNum - 1);
                }
            }

            GameObject camRotZone = Utility.FindNode(mMapEditObjRoot, "CamRotZoneRoot");
            GameObject ctrlPortalRoot = Utility.FindNode(mMapEditObjRoot, "MapCtrlPortal");
            GameObject loadZoneRoot = Utility.FindNode(mMapEditObjRoot, mAsLoadZoneTag);
            mPathfinder.LoadBinaryMap(tMapData, new List<PortalFig>(mPortalObj.GetComponentsInChildren<PortalFig>()), camRotZone, ctrlPortalRoot, loadZoneRoot, mAppearCtrlObj);
        }

        return true;
    }

    /// <summary>
    /// 删除地图数据
    /// </summary>
    /// <param name="mapid"></param>
    private void DeleteMap(string mapid)
    {
        string mapDataPath = "Assets/Scene/Share/Custom/MapData/" + mapid + ".asset";
        string blockPath = "Assets/Scene/Share/Prefab/MapBlockObject/" + mapid + "_block.prefab";
        string serverMapDataPath = "../server/config/map/" + mapid + ".bin";

        if(File.Exists(mapDataPath))
        {
            File.Delete(mapDataPath);
        }
        if (File.Exists(mapDataPath + ".meta"))
        {
            File.Delete(mapDataPath + ".meta");
        }
        if (File.Exists(serverMapDataPath))
        {
            File.Delete(serverMapDataPath);
        }
        if (File.Exists(serverMapDataPath + ".meta"))
        {
            File.Delete(serverMapDataPath + ".meta");
        }
        if (File.Exists(blockPath))
        {
            File.Delete(blockPath);
        }

        PreloadMapBlockInfo();
        Repaint();
    }


    [MenuItem("Developer Tools/打开地图编辑器")]
    private static void ShowWindow()
    {
        PathEditor pathWin = GetWindow<PathEditor>();
        pathWin.Show();
        pathWin.minSize = new Vector2(400, 700);
        mCompileType = COMPILETYPE.CT_Static;

        PreloadMapBlockInfo();
    }

    /// <summary>
    /// 销毁窗口调用
    /// </summary>
    void OnDestroy()
    {
        if(EditorPrefs.HasKey(COMPILING_SIGN))
        {
            EditorPrefs.DeleteKey(COMPILING_SIGN);
            Debug.Log("LY :  EditorPrefs delete compile sign !!! ");
        }

        //Debug.Log("Close ArchitectureEditor Window !!!");

        if (mInit == true)
        {
            if (mMapEditObjRoot != null && EditorUtility.DisplayDialog("保存",
                            "是否保存地图Prefab及数据  ?？？",
                            "Yes",
                            "No"))
            {
                if(SaveEditMapData(true) == true)
                {
                    DestroyImmediate(mAreaObj);
                    DestroyImmediate(mBlockObj);
                    DestroyImmediate(mPortalObj);
                    DestroyImmediate(mCtrlPortalObj);
                    DestroyImmediate(mBornPotObj);
                    DestroyImmediate(mDoorObj);
                    DestroyImmediate(mZoneObj);
                    DestroyImmediate(mLoadZoneObj);
                    DestroyImmediate(mAppearCtrlObj);

                    DestroyImmediate(mMapEditObjRoot);
                    DestroyImmediate(mPathfinderObj);
                }
            }
            else
            {

                /// 检测场景是否没有保存，保险处理 ///

                //AssetDatabase.FindAssets mPathfinder.MapId

                DestroyImmediate(mAreaObj);
                DestroyImmediate(mBlockObj);
                DestroyImmediate(mPortalObj);
                DestroyImmediate(mCtrlPortalObj);
                DestroyImmediate(mBornPotObj);
                DestroyImmediate(mDoorObj);
                DestroyImmediate(mZoneObj);
                DestroyImmediate(mLoadZoneObj);
                DestroyImmediate(mAppearCtrlObj);

                DestroyImmediate(mMapEditObjRoot);
                DestroyImmediate(mPathfinderObj);
            }
        }
    }

    

    private void OnGUI()
    {
        if (EditorApplication.isCompiling)
        {
            ShowNotification(new GUIContent("Compiling\n...Please wait..."));
            if (mCompileType == COMPILETYPE.CT_Working)
            {
                return;
            }

            if(mCompileType == COMPILETYPE.CT_Static)
            {
                Debug.Log("LY :  Set EditorPrefs Compile Sign !!! ");
                EditorPrefs.SetInt(COMPILING_SIGN, 1);
                mCompileType = COMPILETYPE.CT_Working;
            }

            return;
        }

        if(mCompileType == COMPILETYPE.CT_Working)
        {
            EditorPrefs.SetInt(COMPILING_SIGN, 0);
            mCompileType = COMPILETYPE.CT_Static;

            Debug.Log("LY :  ???? COMPILETYPE.CT_Working ???? ");
        }
        else if(mCompileType == COMPILETYPE.CT_Original)
        {
            if (!EditorPrefs.HasKey(COMPILING_SIGN))
            {
                EditorPrefs.SetInt(COMPILING_SIGN, 0);
            }
            else
            {
                int tCTS = EditorPrefs.GetInt(COMPILING_SIGN, -1);
                if (tCTS == 1)
                {
                    Debug.Log("LY :  Map editor lost connect !!! ");
                    EditorPrefs.SetInt(COMPILING_SIGN, 0);

                    /// 重新连接编辑节点 ///
                    if (mInit == false)
                    {
                        PreloadMapBlockInfo(); 
                    }
                    else
                    {
                        ReconnectMapNode(); 
                    }
                }

            }

            mCompileType = COMPILETYPE.CT_Static;
        }

        ///  ///
        if (mInit == false)
        {
            DrawDataBtns();

            GUILayout.Space(20);
            
            if (GUILayout.Button("创建新地图", GUILayout.Height(50)))
            {
                CreateNewMap();
                mInit = true;
                return;
            }

            GUILayout.BeginHorizontal();
            if (GUILayout.Button("创建场景碰撞平面", GUILayout.Height(50)))
            {
                GameObject tObj = GameObject.Find("DrawPointPlane");
                if(tObj == null)
                {
                    tObj = new GameObject("DrawPointPlane");
                    BoxCollider tBoxCol = tObj.AddComponent<BoxCollider>();
                    tBoxCol.size = new Vector3(1000, 1, 1000);
                    Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundLayerName);
                    tObj.hideFlags = HideFlags.DontSaveInEditor;
                }
                return;
            }
            GUILayout.EndHorizontal();

            if (GUILayout.Button("转换所有地图数据到新格式", GUILayout.Height(50)))
            {
                //ChangeAllDataToBinary();
                ChangeAllDataToNew();
                return;
            }

            //if (GUILayout.Button("转换所有预制体", GUILayout.Height(30f)))
            //{
            //    ResetAllMapBlock();
            //    return;
            //}

            if (GUILayout.Button("生成简易地图信息", GUILayout.Height(50)))
            {
                MakeSimplifyMap();
                return;
            }

            return;
        }

        scrollPosition = GUILayout.BeginScrollView(scrollPosition);

        /// 创建可行走区域 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建行走区域", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsArea();
        }
        mAsAreaSize = EditorGUILayout.Vector3Field("大小", mAsAreaSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mAreaObj, "行走区域", mAsAreaTag);

        GUILayout.Space(30);

        /// 创建不可行走区域 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建阻挡区域", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsBlock();
        }
        mAsBlockSize = EditorGUILayout.Vector3Field("大小", mAsBlockSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mBlockObj, "阻挡区域", mAsBlockTag);

        GUILayout.Space(30);

        /// 创建传送口 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建传送口", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsPortal();
        }
        mAsPortalSize = EditorGUILayout.Vector3Field("大小", mAsPortalSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mPortalObj, "传送口", mAsPortalTag);

        GUILayout.Space(30);
        
        /// 创建预加载区域 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建预加载区域", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsLoadZone();
        }
        mAsLoadZonelSize = EditorGUILayout.Vector3Field("大小", mAsLoadZonelSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mLoadZoneObj, "预加载区域", mAsLoadZoneTag);

        GUILayout.Space(30);

        /// 创建显示控制区域 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建显示控制区域", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsAppearCtrl();
        }
        mAsAppearCtrlSize = EditorGUILayout.Vector3Field("大小", mAsAppearCtrlSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mAppearCtrlObj, "显示控制区域", mAppearCtrlName);

        GUILayout.Space(30);

        /// 创建操控传送口 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建操控传送口", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsCtrlPortal();
        }
        mAsCtrlPortalSize = EditorGUILayout.Vector3Field("大小", mAsCtrlPortalSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mCtrlPortalObj, "操控传送口", mAsCtrlPortalTag);

        GUILayout.Space(30);

        /// 创建出生点 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建出生点", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsBornPot();
        }
        GUILayout.EndHorizontal();
        RepeatItemBtns(mBornPotObj, "出生点", mAsBornPotTag);

        GUILayout.Space(30);

        /// 创建动态阻挡墙 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建阻挡门", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsDoorBlock();
        }
        mAsDoorSize = EditorGUILayout.Vector3Field("大小", mAsDoorSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mDoorObj, "动态阻挡墙", mAsDoorTag);

        GUILayout.Space(30);

        /// 创建安全区域 ///
        GUILayout.BeginHorizontal();
        if (GUILayout.Button("创建安全区域", GUILayout.Width(150f), GUILayout.Height(30f)))
        {
            CreateAsZone();
        }
        mAsZoneSize = EditorGUILayout.Vector3Field("大小", mAsAreaSize, GUILayout.Height(25f));
        GUILayout.EndHorizontal();
        RepeatItemBtns(mZoneObj, "安全区域", mAsZoneTag);

        GUILayout.Space(30);


        /// 转换选择物体为成行走区域 ///
        GUILayout.BeginVertical();
        if (GUILayout.Button("转换选择物体为行走区域", GUILayout.Width(200f), GUILayout.Height(60f)))
        {
            ChangeMeshToWalkArea();
        }
        GUILayout.EndVertical();

        /// 转换选择物体为阻挡区域 ///
        GUILayout.BeginVertical();
        if (GUILayout.Button("转换选择物体为阻挡区域", GUILayout.Width(200f), GUILayout.Height(60f)))
        {
            ChangeMeshToBlock();
        }
        GUILayout.EndVertical();

        /// 转换选择物体为安全区域 ///
        GUILayout.BeginVertical();
        if (GUILayout.Button("转换选择物体为安全区域", GUILayout.Width(200f), GUILayout.Height(60f)))
        {
            ChangeMeshToSaveZone();
        }
        GUILayout.EndVertical();


        if (GUILayout.Button("生成地图寻路数据", GUILayout.Height(50f)))
        {
            CreateMapData();
        }
        if (GUILayout.Button("清除地图寻路数据", GUILayout.Height(50f)))
        {
            ClearMapData();
        }

        GUILayout.BeginHorizontal();
        //if (GUILayout.Button("保存地图数据", GUILayout.Height(50f)))
        //{
        //    SaveEditMapData(false);
        //}
        if (GUILayout.Button("保存地图数据(二进制)", GUILayout.Height(50f)))
        {
            SaveEditMapData(true);
        }
        GUILayout.EndHorizontal();
        if (GUILayout.Button("只保存地图预制体", GUILayout.Height(30f)))
        {
            SaveOnlyMapBlock();
        }

        if(GUILayout.Button("导出占领点坐标", GUILayout.Height(50f)))
        {
            SaveOccupPoint();
        }

        if (GUILayout.Button("导出仙魂副本守卫点坐标", GUILayout.Height(50f)))
        {
            SaveXHPoint();
        }

        GUILayout.BeginHorizontal();
        if (GUILayout.Button("渲染小地图", GUILayout.Height(50f)))
        {
            List<GameObject> tPorList = new List<GameObject>();
            List<Renderer> rends = new List<Renderer>();
            if(isOutLine == true)
            {
                Renderer[] renders = GameObject.FindObjectsOfType(typeof(Renderer)) as Renderer[];
                for (int a = 0; a < renders.Length; a++)
                {
                    if (renders[a].gameObject.activeSelf == true && renders[a].enabled == true)
                    {
                        renders[a].enabled = false;
                        rends.Add(renders[a]);
                    }
                }

                //ShowAreaObj(true);
                ShowBlockObj(true);
                //ShowPortalArea(true);
                string prefabPath = "Assets/EditorResource/JumpPot.prefab";
                GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(prefabPath, typeof(GameObject)) as GameObject;
                for (int a = 0; a < mPortalObj.transform.childCount; a++)
                {
                    GameObject tObj = Instantiate(tLoadPrefab);
                    tObj.transform.position = mPortalObj.transform.GetChild(a).position;
                    tObj.transform.localScale = new Vector3(2, 2, 2);
                    tPorList.Add(tObj);
                }
                //DestroyImmediate(tLoadPrefab);
            }

            MakeMiniMap(isOutLine);

            if(isOutLine == true)
            {
                for(int a = 0; a < rends.Count; a++)
                {
                    rends[a].enabled = true;
                }
                rends.Clear();

                //ShowAreaObj(false);
                ShowBlockObj(false);
                //ShowPortalArea(false);
                for (int a = 0; a < tPorList.Count; a++)
                {
                    GameObject.DestroyImmediate(tPorList[a]);
                }
                tPorList.Clear();
            }
        }

        isOutLine = EditorGUILayout.Toggle("渲染简易体", isOutLine);

        if (GUILayout.Button("创建地图朝向物体", GUILayout.Height(50f)))
        {
            mPathfinder.CreateArrowGo();
        }
        GUILayout.EndHorizontal();

        ShowAreaObj(GUILayout.Toggle(mShowAreaObj, "显示行走区域模型"));
        ShowBlockObj(GUILayout.Toggle(mShowBlockObj, "显示阻挡墙模型"));
        ShowDoorObj(GUILayout.Toggle(mShowDoorObj, "显示阻挡门模型"));
        ShowPortalArea(GUILayout.Toggle(mShowPortalArea, "显示跳转口区域"));
        ShowAppearZone(GUILayout.Toggle(mShowAppearZone, "显示 显示控制 区域"));

        GUILayout.EndScrollView();

        //if (GUILayout.Button("测试读取数据", GUILayout.Height(50f)))
        //{
        //    TestLoadAsset();
        //}
    }

    private void RepeatItemBtns(GameObject parentObj, string showName, string tapName)
    {
        int delWIndex = -1;
        GUILayout.BeginVertical();
        for (int a = 0; a < parentObj.transform.childCount; a++)
        {
            GameObject tSelObj = parentObj.transform.GetChild(a).gameObject;
            GUILayout.BeginHorizontal();
            string btnName = showName + (a + 1);
            if (GUILayout.Button(btnName, GUILayout.Width(200f), GUILayout.Height(30f)))
            {
                UnityEditor.Selection.activeGameObject = tSelObj;
                SceneViewUtil.Focus(tSelObj.transform);
            }
            if (GUILayout.Button("删除", GUILayout.Width(100f), GUILayout.Height(30f)))
            {
                if (EditorUtility.DisplayDialog("保存",
                            "是否删除" + showName + (a + 1) + "  ?？？",
                            "好鸭",
                            "不"))
                {
                    delWIndex = a;
                }
            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndVertical();
        if (delWIndex >= 0)
        {
            GameObject delObj = parentObj.transform.GetChild(delWIndex).gameObject;
            if (delObj.GetComponent<PortalFig>() != null)
            {
                mPathfinder.DeletePortalFig(delObj.GetComponent<PortalFig>());
            }
            DestroyImmediate(delObj);
            for (int a = 0; a < parentObj.transform.childCount; a++)
            {
                parentObj.transform.GetChild(a).name = tapName + (a + 1);
            }
        }
    }

    private void OnProjectChange()
    {
        PreloadMapBlockInfo();
        Repaint();
    }

    private void DrawDataBtns()
    {
        if (mMapBlockPaths == null || mMapBlockPaths.Length <= 0)
            return;

        scrollPosition = GUILayout.BeginScrollView(scrollPosition, GUILayout.Height(280));

        GUILayout.BeginVertical();
        for(int a = 0; a < mMapBlockPaths.Length; a++)
        {
            GUILayout.BeginHorizontal();
            //if (GUILayout.Button(mMapIds[a], GUILayout.Width(150)))
            //{
            //    mInit = LoadMap(mMapIds[a]);
            //}
            if (GUILayout.Button(mMapIds[a] + " : 二进制", GUILayout.Width(150)))
            {
                mInit = LoadBinaryMap(mMapIds[a]);
            }
            /// 只读取地图碰撞体 ///
            if (GUILayout.Button("只读取虚拟碰撞体", GUILayout.Width(150)))
            {
                mInit = LoadMapBlock(mMapIds[a], true);
            }
            if(GUILayout.Button("删除", GUILayout.Width(50)))
            {
                if (EditorUtility.DisplayDialog("删除地图数据",
                "Baby Σ(っ°Д°;)っ    确定删除 : " + mMapIds[a] + " 地图数据 ?？？",
                "确定",
                "取消"))
                {
                    DeleteMap(mMapIds[a]);
                }
            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndVertical();

        GUILayout.EndScrollView();
    }

    #region 编辑地图
    private void CreateAsArea()
    {
        for(int a = 0; a < mAreaObj.transform.childCount; a++)
        {
            mAreaObj.transform.GetChild(a).name = mAsAreaTag + (a + 1);
        }

        //GameObject tObj = new GameObject(mAsAreaTag + (mAreaObj.transform.childCount + 1));
        GameObject tObj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tObj.name = mAsAreaTag + (mAreaObj.transform.childCount + 1);

        //tObj.transform.position = mAsAreaPos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.transform.localScale = mAsAreaSize;
        tObj.tag = mAsAreaTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundLayerName);

        //BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        //tCol.size = mAsAreaSize;

        tObj.transform.parent = mAreaObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void ChangeMeshToWalkArea()
    {
        Transform[] tSelectGOs = Selection.transforms;
        if (tSelectGOs == null || tSelectGOs.Length <= 0)
        {
            EditorUtility.DisplayDialog("Error", "又搞事了 没有选择模型", "确定");
            return;
        }

        for (int a = 0; a < tSelectGOs.Length; a++)
        {
            GameObject tGO = tSelectGOs[a].gameObject;
            MeshCollider tMC = tGO.GetComponent<MeshCollider>();
            if(tMC == null)
            {
                Collider tCollider = tGO.GetComponent<Collider>();
                if(tCollider != null)
                {
                    Destroy(tCollider);
                }

                tMC = tGO.AddComponent<MeshCollider>();
                tMC.convex = false;
            }

            tGO.name = mAsAreaTag + (mAreaObj.transform.childCount + 1);

            tGO.tag = mAsAreaTag;
            Utility.SetGOLayerIncludeChilden(tGO.transform, mGroundLayerName);

            tGO.transform.parent = mAreaObj.transform;
        }
    }

    private void CreateAsBlock()
    {
        for (int a = 0; a < mBlockObj.transform.childCount; a++)
        {
            mBlockObj.transform.GetChild(a).name = mAsBlockTag + (a + 1);
        }

        //GameObject tObj = new GameObject(mAsBlockTag + (mBlockObj.transform.childCount + 1));
        GameObject tObj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tObj.name = mAsBlockTag + (mBlockObj.transform.childCount + 1);

        //tObj.transform.position = mAsBlockPos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.transform.localScale = mAsBlockSize;
        tObj.tag = mAsBlockTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mWallLayerName);

        //BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        //tCol.size = mAsBlockSize;

        tObj.transform.parent = mBlockObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void ChangeMeshToBlock()
    {
        Transform[] tSelectGOs = Selection.transforms;
        if (tSelectGOs == null || tSelectGOs.Length <= 0)
        {
            EditorUtility.DisplayDialog("Error", "又搞事了 没有选择模型", "确定");
            return;
        }

        for (int a = 0; a < tSelectGOs.Length; a++)
        {
            GameObject tGO = tSelectGOs[a].gameObject;
            MeshCollider tMC = tGO.GetComponent<MeshCollider>();
            if (tMC == null)
            {
                Collider tCollider = tGO.GetComponent<Collider>();
                if (tCollider != null)
                {
                    Destroy(tCollider);
                }

                tMC = tGO.AddComponent<MeshCollider>();
                tMC.convex = false;
            }
            
            tGO.name = mAsBlockTag + (mBlockObj.transform.childCount + 1);
            tGO.tag = mAsBlockTag;
            Utility.SetGOLayerIncludeChilden(tGO.transform, mWallLayerName);
            tGO.transform.parent = mBlockObj.transform;
        }
    }

    private void CreateAsPortal()
    {
        for (int a = 0; a < mPortalObj.transform.childCount; a++)
        {
            mPortalObj.transform.GetChild(a).name = mAsPortalTag + (a + 1);
        }

        GameObject tObj = new GameObject(mAsPortalTag + (mPortalObj.transform.childCount + 1));
        //tObj.transform.position = mAsPortalPos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.tag = mAsPortalTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);

        BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        tCol.size = mAsPortalSize;
        tCol.isTrigger = true;
        Rigidbody tRigi = tObj.AddComponent<Rigidbody>();
        tRigi.useGravity = false;
        tRigi.isKinematic = true;
        tRigi.constraints = RigidbodyConstraints.FreezePositionX | RigidbodyConstraints.FreezePositionY | RigidbodyConstraints.FreezePositionZ
            | RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;
        tObj.AddComponent<PortalFig>();

        tObj.transform.parent = mPortalObj.transform;

        GameObject newNode = new GameObject("DisplayZone");
        newNode.transform.parent = tObj.transform;
        newNode.transform.localPosition = Vector3.zero;
        newNode.transform.localScale = Vector3.one;
        newNode.AddComponent<DisplayZone>();

        Selection.activeGameObject = tObj;
    }

    private void CreateAsLoadZone()
    {
        for (int a = 0; a < mLoadZoneObj.transform.childCount; a++)
        {
            mLoadZoneObj.transform.GetChild(a).name = mAsLoadZoneTag + (a + 1);
        }

        GameObject tObj = new GameObject(mAsLoadZoneTag + (mLoadZoneObj.transform.childCount + 1));
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.tag = mAsLoadZoneTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);

        BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        tCol.size = mAsLoadZonelSize;
        tCol.isTrigger = true;

        tObj.transform.parent = mLoadZoneObj.transform;
        PreloadZone tPZ = tObj.AddComponent<PreloadZone>();
        tPZ.mZoneId = (uint)mLoadZoneObj.transform.childCount;

        Selection.activeGameObject = tObj;
    }

    private void CreateAsAppearCtrl()
    {
        for (int a = 0; a < mAppearCtrlObj.transform.childCount; a++)
        {
            mAppearCtrlObj.transform.GetChild(a).name = mAppearCtrlName + (a + 1);
        }

        GameObject tObj = new GameObject(mAppearCtrlName + (mAppearCtrlObj.transform.childCount + 1));
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        //tObj.tag = mAsLoadZoneTag;
        //Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);

        BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        tCol.size = mAsAppearCtrlSize;
        tCol.isTrigger = true;

        Rigidbody tRigi = tObj.AddComponent<Rigidbody>();
        tRigi.useGravity = false;
        tRigi.isKinematic = true;
        tRigi.constraints = RigidbodyConstraints.FreezePositionX | RigidbodyConstraints.FreezePositionY | RigidbodyConstraints.FreezePositionZ
            | RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;

        tObj.transform.parent = mAppearCtrlObj.transform;
        AppearCtrlZone tACZ = tObj.AddComponent<AppearCtrlZone>();
        tACZ.mZoneName = tObj.name;

        Selection.activeGameObject = tObj;
    }

    private void CreateAsCtrlPortal()
    {
        for (int a = 0; a < mCtrlPortalObj.transform.childCount; a++)
        {
            mCtrlPortalObj.transform.GetChild(a).name = mAsCtrlPortalTag + (a + 1);
        }

        string prefabPath = "Assets/EditorResource/AwakenPortal.prefab";
        GameObject tLoadPrefab = AssetDatabase.LoadAssetAtPath(prefabPath, typeof(GameObject)) as GameObject;
        GameObject tObj = Instantiate(tLoadPrefab);
        tObj.name = mAsCtrlPortalTag + (mCtrlPortalObj.transform.childCount + 1);

        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.tag = mAsCtrlPortalTag;
        //Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);
        
        tObj.transform.parent = mCtrlPortalObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void CreateAsBornPot()
    {
        GameObject tObj = new GameObject(mAsBornPotTag + (mBornPotObj.transform.childCount + 1));
        //tObj.transform.position = mAsBornPotPos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.AddComponent<BornPotFig>();
        tObj.tag = mAsBornPotTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);

        BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        tCol.size = mAsPortalSize;
        tCol.enabled = false;

        tObj.transform.parent = mBornPotObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void CreateAsDoorBlock()
    {
        //GameObject tObj = new GameObject(mAsDoorTag + (mDoorObj.transform.childCount + 1));
        GameObject tObj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tObj.name = mAsDoorTag + (mDoorObj.transform.childCount + 1);

        //tObj.transform.position = mAsDoorPos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.transform.localScale = mAsDoorSize;
        tObj.tag = mAsDoorTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mWallLayerName);

        //BoxCollider tCol = tObj.AddComponent<BoxCollider>();
        //tCol.size = mAsDoorSize;
        tObj.AddComponent<DoorBlock>();

        tObj.transform.parent = mDoorObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void CreateAsZone()
    {
        for (int a = 0; a < mZoneObj.transform.childCount; a++)
        {
            mZoneObj.transform.GetChild(a).name = mAsZoneTag + (a + 1);
        }
        
        GameObject tObj = GameObject.CreatePrimitive(PrimitiveType.Cube);
        tObj.name = mAsZoneTag + (mZoneObj.transform.childCount + 1);

        //tObj.transform.position = mAsZonePos;
        Vector3 camPos = SceneView.lastActiveSceneView.pivot;
        tObj.transform.position = camPos;
        tObj.transform.localScale = mAsZoneSize;
        tObj.tag = mAsZoneTag;
        Utility.SetGOLayerIncludeChilden(tObj.transform, mGroundOtherLayerName);

        Collider tCol = tObj.GetComponent<Collider>();
        tCol.isTrigger = true;
        Rigidbody tRigi = tObj.AddComponent<Rigidbody>();
        tRigi.useGravity = false;
        tRigi.isKinematic = true;
        tRigi.constraints = RigidbodyConstraints.FreezePositionX | RigidbodyConstraints.FreezePositionY | RigidbodyConstraints.FreezePositionZ
            | RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;
        tObj.AddComponent<SaveZoneFig>();

        tObj.transform.parent = mZoneObj.transform;

        Selection.activeGameObject = tObj;
    }

    private void ChangeMeshToSaveZone()
    {
        Transform[] tSelectGOs = Selection.transforms;
        if (tSelectGOs == null || tSelectGOs.Length <= 0)
        {
            EditorUtility.DisplayDialog("Error", "又搞事情 没有选择模型", "确定");
            return;
        }

        for (int a = 0; a < tSelectGOs.Length; a++)
        {
            GameObject tGO = tSelectGOs[a].gameObject;
            MeshCollider tMC = tGO.GetComponent<MeshCollider>();
            if (tMC == null)
            {
                Collider tCollider = tGO.GetComponent<Collider>();
                if (tCollider != null)
                {
                    Destroy(tCollider);
                }

                tMC = tGO.AddComponent<MeshCollider>();
                tMC.convex = false;
                tMC.isTrigger = true;
            }
            
            Rigidbody tRigi = tGO.AddComponent<Rigidbody>();
            tRigi.useGravity = false;
            tRigi.isKinematic = true;
            tRigi.constraints = RigidbodyConstraints.FreezePositionX | RigidbodyConstraints.FreezePositionY | RigidbodyConstraints.FreezePositionZ
                | RigidbodyConstraints.FreezeRotationX | RigidbodyConstraints.FreezeRotationY | RigidbodyConstraints.FreezeRotationZ;

            tGO.name = mAsZoneTag + (mZoneObj.transform.childCount + 1);
            tGO.tag = mAsZoneTag;
            Utility.SetGOLayerIncludeChilden(tGO.transform, mGroundOtherLayerName);

            tGO.AddComponent<SaveZoneFig>();

            tGO.transform.parent = mZoneObj.transform;
        }
    }

    /// <summary>
    /// 显示可行走模型
    /// </summary>
    /// <param name="show"></param>
    public void ShowAreaObj(bool show)
    {
        mShowAreaObj = show;
        for (int a = 0; a < mAreaObj.transform.childCount; a++)
        {
            GameObject tObj = mAreaObj.transform.GetChild(a).gameObject;
            Renderer tRen = tObj.GetComponent<Renderer>();
            if (tRen != null)
            {
                tRen.enabled = show;
            }
        }
        for (int a = 0; a < mZoneObj.transform.childCount; a++)
        {
            GameObject tObj = mZoneObj.transform.GetChild(a).gameObject;
            Renderer tRen = tObj.GetComponent<Renderer>();
            if (tRen != null)
            {
                tRen.enabled = show;
            }
        }
    }

    /// <summary>
    /// 显示阻挡墙模型
    /// </summary>
    /// <param name="show"></param>
    public void ShowBlockObj(bool show)
    {
        mShowBlockObj = show;
        for (int a = 0; a < mBlockObj.transform.childCount; a++)
        {
            GameObject tObj = mBlockObj.transform.GetChild(a).gameObject;
            Renderer tRen = tObj.GetComponent<Renderer>();
            if (tRen != null)
            {
                tRen.enabled = show;
            }
        }
    }

    /// <summary>
    /// 显示阻挡门模型
    /// </summary>
    /// <param name="show"></param>
    public void ShowDoorObj(bool show)
    {
        mShowDoorObj = show;
        for (int a = 0; a < mDoorObj.transform.childCount; a++)
        {
            GameObject tObj = mDoorObj.transform.GetChild(a).gameObject;
            Renderer tRen = tObj.GetComponent<Renderer>();
            if (tRen != null)
            {
                tRen.enabled = show;
            }
        }
    }

    /// <summary>
    /// 显示跳转点区域
    /// </summary>
    /// <param name="show"></param>
    public void ShowPortalArea(bool show)
    {
        AsPathfinderInEditor tEditor = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
        if (tEditor == null)
            return;

        mShowPortalArea = show;
        if (show == false)
        {
            tEditor.DrawPortalArea(false, null, null);
            return;
        }

        List<Vector3> centers = new List<Vector3>();
        List<Vector3> sizes = new List<Vector3>();
        for (int a = 0; a < mPortalObj.transform.childCount; a++)
        {
            BoxCollider tBC = mPortalObj.transform.GetChild(a).GetComponent<BoxCollider>();
            centers.Add(tBC.transform.position);
            sizes.Add(new Vector3(tBC.transform.localScale.x * tBC.size.x,
                tBC.transform.localScale.y * tBC.size.y,
                tBC.transform.localScale.z * tBC.size.z));
        }

        tEditor.DrawPortalArea(true, centers, sizes);
    }

    /// <summary>
    /// 显示预加载区域
    /// </summary>
    /// <param name="show"></param>
    //public void ShowLoadZoneArea(bool show)
    //{
    //    AsPathfinderInEditor tEditor = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
    //    if (tEditor == null)
    //        return;

    //    mShowPortalArea = show;
    //    if (show == false)
    //    {
    //        tEditor.DrawPortalArea(false, null, null);
    //        return;
    //    }

    //    List<Vector3> centers = new List<Vector3>();
    //    List<Vector3> sizes = new List<Vector3>();
    //    for (int a = 0; a < mLoadZoneObj.transform.childCount; a++)
    //    {
    //        BoxCollider tBC = mLoadZoneObj.transform.GetChild(a).GetComponent<BoxCollider>();
    //        centers.Add(tBC.transform.position);
    //        sizes.Add(new Vector3(tBC.transform.localScale.x * tBC.size.x,
    //            tBC.transform.localScale.y * tBC.size.y,
    //            tBC.transform.localScale.z * tBC.size.z));
    //    }

    //    tEditor.DrawPortalArea(true, centers, sizes);
    //}

    public void ShowAppearZone(bool show)
    {
        AsPathfinderInEditor tEditor = mPathfinderObj.GetComponent<AsPathfinderInEditor>();
        if (tEditor == null)
            return;

        mShowAppearZone = show;
        if (show == false)
        {
            tEditor.DrawAppearZone(false, null, null, null);
            return;
        }

        
        List<Vector3> centers = new List<Vector3>();
        List<Vector3> sizes = new List<Vector3>();
        List<Color> colors = new List<Color>();
        for (int a = 0; a < mAppearCtrlObj.transform.childCount; a++)
        {
            BoxCollider tBC = mAppearCtrlObj.transform.GetChild(a).GetComponent<BoxCollider>();
            centers.Add(tBC.transform.position);
            sizes.Add(new Vector3(tBC.transform.localScale.x * tBC.size.x,
                tBC.transform.localScale.y * tBC.size.y,
                tBC.transform.localScale.z * tBC.size.z));
            colors.Add(new Color(Random.value, Random.value, Random.value, 0.3f));
        }

        tEditor.DrawAppearZone(true, centers, sizes, colors);
    }
    #endregion


    private Bounds CalMapBound()
    {
        float minX = float.MaxValue;
        float minY = float.MaxValue;
        float minZ = float.MaxValue;

        float maxX = float.MinValue;
        float maxY = float.MinValue;
        float maxZ = float.MinValue;

        /// 行走区域 ///
        for (int a = 0; a < mAreaObj.transform.childCount; a++)
        {
            GameObject tObj = mAreaObj.transform.GetChild(a).gameObject;
            Collider tCol = tObj.GetComponent<Collider>();
            if (tCol != null)
            {
                if (tCol.bounds.min.x < minX)
                    minX = tCol.bounds.min.x;
                if (tCol.bounds.min.y < minY)
                    minY = tCol.bounds.min.y;
                if (tCol.bounds.min.z < minZ)
                    minZ = tCol.bounds.min.z;

                if (tCol.bounds.max.x > maxX)
                    maxX = tCol.bounds.max.x;
                if (tCol.bounds.max.y > maxY)
                    maxY = tCol.bounds.max.y;
                if (tCol.bounds.max.z > maxZ)
                    maxZ = tCol.bounds.max.z;
            }
        }
        /// 阻挡区域 ///
        for (int a = 0; a < mBlockObj.transform.childCount; a++)
        {
            GameObject tObj = mBlockObj.transform.GetChild(a).gameObject;
            Collider tCol = tObj.GetComponent<BoxCollider>();
            if (tCol != null)
            {
                if (tCol.bounds.min.x < minX)
                    minX = tCol.bounds.min.x;
                if (tCol.bounds.min.y < minY)
                    minY = tCol.bounds.min.y;
                if (tCol.bounds.min.z < minZ)
                    minZ = tCol.bounds.min.z;

                if (tCol.bounds.max.x > maxX)
                    maxX = tCol.bounds.max.x;
                if (tCol.bounds.max.y > maxY)
                    maxY = tCol.bounds.max.y;
                if (tCol.bounds.max.z > maxZ)
                    maxZ = tCol.bounds.max.z;
            }
        }
        /// 跳转点 ///
        for (int a = 0; a < mPortalObj.transform.childCount; a++)
        {
            GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
            Collider tCol = tObj.GetComponent<BoxCollider>();
            if (tCol != null)
            {
                if (tCol.bounds.min.x < minX)
                    minX = tCol.bounds.min.x;
                if (tCol.bounds.min.y < minY)
                    minY = tCol.bounds.min.y;
                if (tCol.bounds.min.z < minZ)
                    minZ = tCol.bounds.min.z;

                if (tCol.bounds.max.x > maxX)
                    maxX = tCol.bounds.max.x;
                if (tCol.bounds.max.y > maxY)
                    maxY = tCol.bounds.max.y;
                if (tCol.bounds.max.z > maxZ)
                    maxZ = tCol.bounds.max.z;
            }
        }
        /// 出生点 ///
        for (int a = 0; a < mBornPotObj.transform.childCount; a++)
        {
            GameObject tObj = mBornPotObj.transform.GetChild(a).gameObject;
            Collider tCol = tObj.GetComponent<BoxCollider>();
            if (tCol != null)
            {
                if (tCol.bounds.min.x < minX)
                    minX = tCol.bounds.min.x;
                if (tCol.bounds.min.y < minY)
                    minY = tCol.bounds.min.y;
                if (tCol.bounds.min.z < minZ)
                    minZ = tCol.bounds.min.z;

                if (tCol.bounds.max.x > maxX)
                    maxX = tCol.bounds.max.x;
                if (tCol.bounds.max.y > maxY)
                    maxY = tCol.bounds.max.y;
                if (tCol.bounds.max.z > maxZ)
                    maxZ = tCol.bounds.max.z;
            }
        }
        /// 动态门物体 ///
        for (int a = 0; a < mDoorObj.transform.childCount; a++)
        {
            GameObject tObj = mDoorObj.transform.GetChild(a).gameObject;
            Collider tCol = tObj.GetComponent<BoxCollider>();
            if (tCol != null)
            {
                if (tCol.bounds.min.x < minX)
                    minX = tCol.bounds.min.x;
                if (tCol.bounds.min.y < minY)
                    minY = tCol.bounds.min.y;
                if (tCol.bounds.min.z < minZ)
                    minZ = tCol.bounds.min.z;

                if (tCol.bounds.max.x > maxX)
                    maxX = tCol.bounds.max.x;
                if (tCol.bounds.max.y > maxY)
                    maxY = tCol.bounds.max.y;
                if (tCol.bounds.max.z > maxZ)
                    maxZ = tCol.bounds.max.z;
            }
        }

        Bounds retBound = new Bounds();
        Vector3 minPot = new Vector3(minX, minY, minZ);
        Vector3 maxPot = new Vector3(maxX, maxY, maxZ);

        retBound.center = (minPot + maxPot) / 2;
        retBound.min = minPot;
        retBound.max = maxPot;
        
        return retBound;
    }

    /// <summary>
    /// 生成地图寻路数据
    /// </summary>
    private void CreateMapData()
    {
        if(mPathfinder.MapId <= 0)
        {
            EditorUtility.DisplayDialog("Error", "没有指定地图Id ！！！", "确定");
            return;
        }

        mPathfinder.CreateMap(CalMapBound());
        EditorUtility.SetDirty(mPathfinder.gameObject);
        //AssetDatabase.Refresh();
    }

    /// <summary>
    /// 清楚地图寻路数据
    /// </summary>
    private void ClearMapData()
    {
        mPathfinder.ClearMap();
        EditorUtility.SetDirty(mPathfinder.gameObject);
        //AssetDatabase.Refresh();
        //if (SceneView.currentDrawingSceneView != null)
        //{
        //    SceneView.currentDrawingSceneView.Repaint();
        //}
    }

    /// <summary>
    /// 保存地图数据
    /// </summary>
    private bool SaveEditMapData(bool binData)
    {
        //mPathfinder.SaveEditMapData();

        if (mPathfinder.MapId == 0)
        {
            EditorUtility.DisplayDialog("Error", "没有指定地图Id", "确定");
            return false;
        }

        /// 保存Prefab ///
        if (mMapEditObjRoot == null)
        {
            mMapEditObjRoot = GameObject.Find("ASMapEditNode");
            if (mMapEditObjRoot == null)
            {
                EditorUtility.DisplayDialog("Error", "没有生成地图节点", "确定");
                Debug.LogError("Edit root do not exist !!!");
                return false;
            }

            EditorUtility.DisplayDialog("Error", "因某些原因，地图保存节点丢失，请重新生成地图数据再保存", "确定");
            return false;
        }

        if (mAreaObj.transform.childCount <= 0)
        {
            Debug.LogError("No walk area !!!");
            return false;
        }

        /// 保存数据 ///
        if (binData == false)
        {
            //if (mPathfinder.SaveEditMapData() == false)
            //{
            //    return false;
            //}
            iTrace.Error("LY", "No this funtion !!! ");
        }
        else
        {
            //if (mPathfinder.SaveEditMapBinaryData(Utility.FindNode(mMapEditObjRoot, "CamRotZoneRoot"), 
            //    Utility.FindNode(mMapEditObjRoot, "MapCtrlPortal"), Utility.FindNode(mMapEditObjRoot, mAsLoadZoneTag)) == false)
            //{
            //    return false;
            //}
            if (mPathfinder.SaveEditMapBinaryData(Utility.FindNode(mMapEditObjRoot, "CamRotZoneRoot"),
                mCtrlPortalObj, mLoadZoneObj, mAppearCtrlObj) == false)
            {
                return false;
            }
        }

        mMapEditObjRoot.hideFlags = HideFlags.None;
        mAreaObj.hideFlags = HideFlags.None;
        mBlockObj.hideFlags = HideFlags.None;
        mPortalObj.hideFlags = HideFlags.None;
        mCtrlPortalObj.hideFlags = HideFlags.None;
        mBornPotObj.hideFlags = HideFlags.None;
        mDoorObj.hideFlags = HideFlags.None;
        mZoneObj.hideFlags = HideFlags.None;
        mLoadZoneObj.hideFlags = HideFlags.None;
        mLoadZoneObj.SetActive(false);
        mAppearCtrlObj.hideFlags = HideFlags.None;

        ShowAreaObj(false);
        ShowBlockObj(false);
        ShowDoorObj(false);

        List<PortalFig> tPFList = new List<PortalFig>();
        List<AwakenPortalFig> tAPFList = new List<AwakenPortalFig>();
        List<SaveZoneFig> tSZFList = new List<SaveZoneFig>();
        List<PreloadZone> tPZList = new List<PreloadZone>();
        List<DisplayZone> tDZList = new List<DisplayZone>();
        List<AppearCtrlZone> tACZList = new List<AppearCtrlZone>();
        if (binData == true)
        {
            for (int a = 0; a < mPortalObj.transform.childCount; a++)
            {
                GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
                PortalFig tPF = tObj.GetComponent<PortalFig>();
                tPFList.Add(tPF);
                tPF.hideFlags = HideFlags.DontSave;
                
                for(int b = 0; b < tObj.transform.childCount; b++)
                {
                    GameObject tCObj = tObj.transform.GetChild(b).gameObject;
                    DisplayZone tDZ = tCObj.GetComponent<DisplayZone>();
                    if(tDZ != null)
                    {
                        tDZList.Add(tDZ);
                        tDZ.hideFlags = HideFlags.DontSave;
                    }
                }
            }
            for(int a = 0; a < mCtrlPortalObj.transform.childCount; a++)
            {
                GameObject tObj = mCtrlPortalObj.transform.GetChild(a).gameObject;
                AwakenPortalFig tAPF = tObj.GetComponent<AwakenPortalFig>();
                tAPFList.Add(tAPF);
                tAPF.hideFlags = HideFlags.DontSave;
            }
            for (int a = 0; a < mZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mZoneObj.transform.GetChild(a).gameObject;
                SaveZoneFig tSZF = tObj.GetComponent<SaveZoneFig>();
                tSZFList.Add(tSZF);
                tSZF.hideFlags = HideFlags.DontSave;
            }
            for (int a = 0; a < mLoadZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mLoadZoneObj.transform.GetChild(a).gameObject;
                PreloadZone tPZ = tObj.GetComponent<PreloadZone>();
                tPZList.Add(tPZ);
                tPZ.hideFlags = HideFlags.DontSave;
            }
            for (int a = 0; a < mAppearCtrlObj.transform.childCount; a++)
            {
                GameObject tObj = mAppearCtrlObj.transform.GetChild(a).gameObject;
                AppearCtrlZone tACZ = tObj.GetComponent<AppearCtrlZone>();
                tACZList.Add(tACZ);
                tACZ.hideFlags = HideFlags.DontSave;
            }
        }

        List<CameraRotateBind> mCamRotBinds = new List<CameraRotateBind>();
        List<DirTriggerChild> mDirTriggers = new List<DirTriggerChild>();
        if (binData == true)
        {
            GameObject tRZRoot = Utility.FindNode(mMapEditObjRoot, "CamRotZoneRoot");
            if (tRZRoot != null && tRZRoot.transform.childCount > 0)
            {
                for (int a = 0; a < tRZRoot.transform.childCount; a++)
                {
                    GameObject tC = tRZRoot.transform.GetChild(a).gameObject;
                    CameraRotateBind tCRB = tC.GetComponent<CameraRotateBind>();
                    mCamRotBinds.Add(tCRB);
                    tCRB.hideFlags = HideFlags.DontSave;
                    for (int b = 0; b < tC.transform.childCount; b++)
                    {
                        GameObject tCC = tC.transform.GetChild(b).gameObject;
                        DirTriggerChild tDTC = tCC.GetComponent<DirTriggerChild>();
                        mDirTriggers.Add(tDTC);
                        tDTC.hideFlags = HideFlags.DontSave;
                    }
                }
            }
        }

        string localPath = mSavePath + mPathfinder.MapId.ToString() + "_block.prefab";
        //Object savePrefab = PrefabUtility.CreateEmptyPrefab(localPath);
        //PrefabUtility.ReplacePrefab(mMapEditObjRoot, savePrefab, ReplacePrefabOptions.ConnectToPrefab);
        PrefabUtility.SaveAsPrefabAsset(mMapEditObjRoot, localPath);

        if (binData == true)
        {
            for (int a = 0; a < tPFList.Count; a++)
            {
                tPFList[a].hideFlags = HideFlags.None;
            }
            for(int a = 0; a < tAPFList.Count; a++)
            {
                tAPFList[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < tSZFList.Count; a++)
            {
                tSZFList[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < mCamRotBinds.Count; a++)
            {
                mCamRotBinds[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < mDirTriggers.Count; a++)
            {
                mDirTriggers[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < tPZList.Count; a++)
            {
                tPZList[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < tDZList.Count; a++)
            {
                tDZList[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < tACZList.Count; a++)
            {
                tACZList[a].hideFlags = HideFlags.None;
            }
        }

        mMapEditObjRoot.hideFlags = HideFlags.DontSaveInEditor;
        mAreaObj.hideFlags = HideFlags.DontSaveInEditor;
        mBlockObj.hideFlags = HideFlags.DontSaveInEditor;
        mPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mCtrlPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mBornPotObj.hideFlags = HideFlags.DontSaveInEditor;
        mDoorObj.hideFlags = HideFlags.DontSaveInEditor;
        mZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.SetActive(true);
        mAppearCtrlObj.hideFlags = HideFlags.DontSaveInEditor;

        return true;
    }

    /// <summary>
    /// 只保存地图预制体
    /// </summary>
    private bool SaveOnlyMapBlock(bool binData = true)
    {
        if (mPathfinder.MapId == 0)
        {
            EditorUtility.DisplayDialog("Error", "没有指定地图Id", "确定");
            return false;
        }

        /// 保存Prefab ///
        if (mMapEditObjRoot == null)
        {
            mMapEditObjRoot = GameObject.Find("ASMapEditNode");
            if (mMapEditObjRoot == null)
            {
                EditorUtility.DisplayDialog("Error", "没有生成地图节点", "确定");
                Debug.LogError("Edit root do not exist !！！");
                return false;
            }

            EditorUtility.DisplayDialog("Error", "因某些原因，地图保存节点丢失，请重新生成地图数据再保存", "确定");
            return false;
        }

        if (mAreaObj.transform.childCount <= 0)
        {
            Debug.LogError("No walk area !！！");
            return false;
        }

        mMapEditObjRoot.hideFlags = HideFlags.None;
        mAreaObj.hideFlags = HideFlags.None;
        mBlockObj.hideFlags = HideFlags.None;
        mPortalObj.hideFlags = HideFlags.None;
        mCtrlPortalObj.hideFlags = HideFlags.None;
        mBornPotObj.hideFlags = HideFlags.None;
        mDoorObj.hideFlags = HideFlags.None;
        mZoneObj.hideFlags = HideFlags.None;
        mLoadZoneObj.hideFlags = HideFlags.None;
        mAppearCtrlObj.hideFlags = HideFlags.None;

        ShowAreaObj(false);
        ShowBlockObj(false);
        ShowDoorObj(false);

        List<PortalFig> tPFList = new List<PortalFig>();
        List<AwakenPortalFig> tAPFList = new List<AwakenPortalFig>();
        if (binData == true)
        {
            for (int a = 0; a < mPortalObj.transform.childCount; a++)
            {
                GameObject tObj = mPortalObj.transform.GetChild(a).gameObject;
                PortalFig tPF = tObj.GetComponent<PortalFig>();
                if (tPF != null)
                {
                    tPFList.Add(tPF);
                    tPF.hideFlags = HideFlags.DontSave;
                }
            }
            for(int a = 0; a < mCtrlPortalObj.transform.childCount; a++)
            {
                GameObject tObj = mCtrlPortalObj.transform.GetChild(a).gameObject;
                AwakenPortalFig tAPF = tObj.GetComponent<AwakenPortalFig>();
                if(tAPF != null)
                {
                    tAPFList.Add(tAPF);
                    tAPF.hideFlags = HideFlags.DontSave;
                }
            }
        }

        List<SaveZoneFig> tSZFList = new List<SaveZoneFig>();
        List<PreloadZone> tPZList = new List<PreloadZone>();
        List<AppearCtrlZone> tACZList = new List<AppearCtrlZone>();
        if (binData == true)
        {
            for (int a = 0; a < mZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mZoneObj.transform.GetChild(a).gameObject;
                SaveZoneFig tSZF = tObj.GetComponent<SaveZoneFig>();
                if (tSZF != null)
                {
                    tSZFList.Add(tSZF);
                    tSZF.hideFlags = HideFlags.DontSave;
                }
            }
            for (int a = 0; a < mLoadZoneObj.transform.childCount; a++)
            {
                GameObject tObj = mLoadZoneObj.transform.GetChild(a).gameObject;
                PreloadZone tPZ = tObj.GetComponent<PreloadZone>();
                tPZList.Add(tPZ);
                tPZ.hideFlags = HideFlags.DontSave;
            }
            for (int a = 0; a < mAppearCtrlObj.transform.childCount; a++)
            {
                GameObject tObj = mAppearCtrlObj.transform.GetChild(a).gameObject;
                AppearCtrlZone tACZ = tObj.GetComponent<AppearCtrlZone>();
                tACZList.Add(tACZ);
                tACZ.hideFlags = HideFlags.DontSave;
            }
        }

        List<CameraRotateBind> mCamRotBinds = new List<CameraRotateBind>();
        List<DirTriggerChild> mDirTriggers = new List<DirTriggerChild>();
        if (binData == true)
        {
            GameObject tRZRoot = Utility.FindNode(mMapEditObjRoot, "CamRotZoneRoot");
            if (tRZRoot != null && tRZRoot.transform.childCount > 0)
            {
                for (int a = 0; a < tRZRoot.transform.childCount; a++)
                {
                    GameObject tC = tRZRoot.transform.GetChild(a).gameObject;
                    CameraRotateBind tCRB = tC.GetComponent<CameraRotateBind>();
                    mCamRotBinds.Add(tCRB);
                    tCRB.hideFlags = HideFlags.DontSave;
                    for (int b = 0; b < tC.transform.childCount; b++)
                    {
                        GameObject tCC = tC.transform.GetChild(b).gameObject;
                        DirTriggerChild tDTC = tCC.GetComponent<DirTriggerChild>();
                        mDirTriggers.Add(tDTC);
                        tDTC.hideFlags = HideFlags.DontSave;
                    }
                }
            }
        }

        string localPath = mSavePath + mPathfinder.MapId.ToString() + "_block.prefab";
        //Object savePrefab = PrefabUtility.CreateEmptyPrefab(localPath);
        //PrefabUtility.ReplacePrefab(mMapEditObjRoot, savePrefab, ReplacePrefabOptions.ConnectToPrefab);
        PrefabUtility.SaveAsPrefabAsset(mMapEditObjRoot, localPath);

        if (binData == true)
        {
            for (int a = 0; a < tPFList.Count; a++)
            {
                tPFList[a].hideFlags = HideFlags.None;
            }

            for(int a = 0; a < tAPFList.Count; a++)
            {
                tAPFList[a].hideFlags = HideFlags.None;
            }

            for (int a = 0; a < tSZFList.Count; a++)
            {
                tSZFList[a].hideFlags = HideFlags.None;
            }

            for (int a = 0; a < mCamRotBinds.Count; a++)
            {
                mCamRotBinds[a].hideFlags = HideFlags.None;
            }

            for (int a = 0; a < mDirTriggers.Count; a++)
            {
                mDirTriggers[a].hideFlags = HideFlags.None;
            }

            for (int a = 0; a < tPZList.Count; a++)
            {
                tPZList[a].hideFlags = HideFlags.None;
            }
            for (int a = 0; a < tACZList.Count; a++)
            {
                tACZList[a].hideFlags = HideFlags.None;
            }
        }

        mMapEditObjRoot.hideFlags = HideFlags.DontSaveInEditor;
        mAreaObj.hideFlags = HideFlags.DontSaveInEditor;
        mBlockObj.hideFlags = HideFlags.DontSaveInEditor;
        mPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mCtrlPortalObj.hideFlags = HideFlags.DontSaveInEditor;
        mBornPotObj.hideFlags = HideFlags.DontSaveInEditor;
        mDoorObj.hideFlags = HideFlags.DontSaveInEditor;
        mZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mLoadZoneObj.hideFlags = HideFlags.DontSaveInEditor;
        mAppearCtrlObj.hideFlags = HideFlags.DontSaveInEditor;

        return true;
    }

    /// <summary>
    /// 保存占领点
    /// </summary>
    private void SaveOccupPoint()
    {
        //mPathfinder

        string filePath = Path.GetFullPath("../table/B 帮战占领点.xls");
        IWorkbook resWorkbook = ExcelTool.GetWrokBook(filePath, "Sheet1");
        try
        {
            ISheet resSheet = resWorkbook.GetSheet("Sheet1");
            int bRow = resSheet.FirstRowNum;
            int eRow = resSheet.LastRowNum;

            int idCol = ExcelTool.GetColumn(resSheet, 0, "id");
            int posCol = ExcelTool.GetColumn(resSheet, 0, "坐标");
            int radius = ExcelTool.GetColumn(resSheet, 0, "半径");

            Dictionary<int, Vector4> tOPs = mPathfinder.GetOccupPoints();
            if(tOPs == null)
            {
                return;
            }
            for (int a = bRow; a <= eRow; a++)
            {
                int tPotId = 0;
                IRow tRow = resSheet.GetRow(a);
                if (tRow == null)
                    continue;

                bool tS = int.TryParse(ExcelTool.ReadString(resSheet.GetRow(a), idCol), out tPotId);
                if (tS == true && tOPs.ContainsKey(tPotId) == true)
                {
                    Vector4 vec = tOPs[tPotId];
                    ExcelTool.WriteString(resSheet.GetRow(a), posCol, vec.x + "," + vec.y + "," + vec.z );
                    ExcelTool.WriteString(resSheet.GetRow(a), radius, vec.w.ToString());
                }
            }

            ExcelTool.Save(resWorkbook, filePath);
        }
        catch (System.Exception e)
        {
            UIEditTip.Error("LY,写入Excel发生错误:{0}" , e.Message);
        }
        finally
        {
            if (resWorkbook != null) resWorkbook.Close();
        }
    }


    /// <summary>
    /// 保存仙魂副本占领点
    /// </summary>
    private void SaveXHPoint()
    {
        //mPathfinder

        string filePath = Path.GetFullPath("../table/X 仙魂副本守卫点.xls");
        IWorkbook resWorkbook = ExcelTool.GetWrokBook(filePath, "Sheet1");
        try
        {
            ISheet resSheet = resWorkbook.GetSheet("Sheet1");

            Dictionary<int, string> posDic = mPathfinder.GetXHPoints();
            if (posDic == null)
            {
                return;
            }

            foreach (var pos in posDic)
            {
                int snCol = ExcelTool.GetColumn(resSheet, 0, "id");
                int hCol = ExcelTool.GetColumn(resSheet, 0, "坐标");
                IRow row = resSheet.CreateRow(pos.Key);
                ExcelTool.WriteInt(row, snCol, pos.Key);
                ExcelTool.WriteString(row, hCol, pos.Value);
            }

            ExcelTool.Save(resWorkbook, filePath);
        }
        catch (System.Exception e)
        {
            UIEditTip.Error("LY, 写入Excel发生错误:{0}" , e.Message);
        }
        finally
        {
            if (resWorkbook != null) resWorkbook.Close();
        }
    }

    /// <summary>
    /// 渲染小地图
    /// </summary>
    private void MakeMiniMap(bool outLine)
    {
        //mPathfinder.RenderMiniMapJpg(outLine);
        bool hasRot = false;
        int mapId = 0;
        int rotY = 0;
        mPathfinder.RenderNewMiniMapJpg(outLine, ref hasRot, ref mapId, ref rotY);
        if(hasRot == true)
        {
            ExportCamRotateExcel(mapId, rotY);
        }
    }

    private static void ExportCamRotateExcel(int mapId, int rotY)
    {
        string filePath = Path.GetFullPath("../table/C 场景设置表.xls");

        IWorkbook resWorkbook = ExcelTool.GetWrokBook(filePath, "Sheet1");
        try
        {
            ISheet resSheet = resWorkbook.GetSheet("Sheet1");
            int mapCol = ExcelTool.GetColumn(resSheet, 0, "场景ID");
            int tarCol = ExcelTool.GetColumn(resSheet, 0, "小地图旋转角度");
            for (int a = 1; a < resSheet.LastRowNum; a++)
            {
                if(resSheet.GetRow(a) == null)
                {
                    continue;
                }
                int tMapId = int.Parse(ExcelTool.ReadString(resSheet.GetRow(a), mapCol));
                if (tMapId == mapId)
                {
                    ExcelTool.WriteInt(resSheet.GetRow(a), tarCol, rotY);
                    break;
                }
            }
            ExcelTool.Save(resWorkbook, filePath);
        }
        catch (System.Exception e)
        {
            UIEditTip.Error("LY,写入Excel发生错误:{0}" , e.Message);
        }
        finally
        {
            if (resWorkbook != null) resWorkbook.Close();
        }
    }

    private void ResetAllMapBlock()
    {
        if (mMapBlockPaths == null || mMapBlockPaths.Length <= 0)
            return;

        for (int a = 0; a < mMapBlockPaths.Length; a++)
        {
            if (LoadBinaryMap(mMapIds[a]) == false)
            {
                Debug.LogError("No map data !!! ");
                continue;
            }
            else
            {
                //mPathfinder.SaveEditMapBinaryData();
                SaveOnlyMapBlock();

                DestroyImmediate(mAreaObj);
                DestroyImmediate(mBlockObj);
                DestroyImmediate(mPortalObj);
                DestroyImmediate(mCtrlPortalObj);
                DestroyImmediate(mBornPotObj);
                DestroyImmediate(mDoorObj);
                DestroyImmediate(mZoneObj);
                DestroyImmediate(mLoadZoneObj);
                DestroyImmediate(mAppearCtrlObj);

                DestroyImmediate(mMapEditObjRoot);
                DestroyImmediate(mPathfinderObj);
            }
        }
    }

    private void ChangeAllDataToNew()
    {
        if (mMapBlockPaths == null || mMapBlockPaths.Length <= 0)
            return;

        for (int a = 0; a < mMapBlockPaths.Length; a++)
        {
            string tMapPath = "Assets/Scene/Share/Custom/MapData/" + mMapIds[a] + ".bytes";
            if (File.Exists(tMapPath) == false)
            {
                continue;
            }

            if (LoadBinaryMap(mMapIds[a]) == false)
            {
                Debug.LogError("No map data !!! ");
                continue;
            }
            else
            {
                SaveEditMapData(true);

                DestroyImmediate(mAreaObj);
                DestroyImmediate(mBlockObj);
                DestroyImmediate(mPortalObj);
                DestroyImmediate(mBornPotObj);
                DestroyImmediate(mDoorObj);
                DestroyImmediate(mZoneObj);
                DestroyImmediate(mLoadZoneObj);
                DestroyImmediate(mAppearCtrlObj);

                DestroyImmediate(mMapEditObjRoot);
                DestroyImmediate(mPathfinderObj);
            }
        }
    }

    /// <summary>
    /// 生成简易地图数据
    /// </summary>
    private void MakeSimplifyMap()
    {
        if (mMapBlockPaths == null || mMapBlockPaths.Length <= 0)
            return;

        string savePath = "Assets/Scene/Share/Custom/MapData/SimplifyMapData.bytes";
        MapSimplifyDatas saveData = new MapSimplifyDatas();
        
        for (int a = 0; a < mMapBlockPaths.Length; a++)
        {
            string tMapPath = "Assets/Scene/Share/Custom/MapData/" + mMapIds[a] + ".bytes";
            if (File.Exists(tMapPath) == false)
            {
                continue;
            }

            if (LoadBinaryMap(mMapIds[a]) == false)
            {
                Debug.LogError("No map data !!! ");
                continue;
            }
            else
            {
                SimplifyMap tSM = new SimplifyMap();
                tSM.mapId = mPathfinder.MapId;
                tSM.tilesize = mPathfinder.Tilesize;
                tSM.startPosition = new SVector3();
                tSM.startPosition.SetVal(mPathfinder.MapStartPosition);
                tSM.endPosition = new SVector3();
                tSM.endPosition.SetVal(mPathfinder.MapEndPosition);
                saveData.mapList.Add(tSM);


                DestroyImmediate(mAreaObj);
                DestroyImmediate(mBlockObj);
                DestroyImmediate(mPortalObj);
                DestroyImmediate(mBornPotObj);
                DestroyImmediate(mDoorObj);
                DestroyImmediate(mZoneObj);
                DestroyImmediate(mLoadZoneObj);
                DestroyImmediate(mAppearCtrlObj);

                DestroyImmediate(mMapEditObjRoot);
                DestroyImmediate(mPathfinderObj);
            }
        }
        
        if (File.Exists(savePath))
        {
            File.Delete(savePath);
        }
        saveData.Save(savePath);
    }
}
