#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System.Xml;
using System.Xml.Serialization;

using PathTool;


public class LoadBezierEditorWin : EditorWindow
{
    //private static string filePath = "Assets/Scene/Share/Custom/MapData/BezierPathData.asset";
    private static string binaryFilePath = "Assets/Scene/Share/Custom/MapData/BezierPathData.bytes";

    //private static string savePath = "Assets/Scene/Share/Custom/MapData/";
    //private static string fileName = "BezierPathData.asset";

    /// <summary>
    /// 曲线数据
    /// </summary>
    //private static BezierPathSaveData bezierData = null;
    private static List<BinaryBezierRecord> mPathDataList;

    private static BezierPathSaveData mSaveData;

    private Vector2 scrollPosition;

    /// <summary>
    /// 指定删除曲线Id列表
    /// </summary>
    private static List<uint> mDelPathIds = new List<uint>();


    [MenuItem("Developer Tools/打开曲线编辑工具")]
    private static void ShowWindow()
    {
        LoadBezierEditorWin editWin = GetWindow<LoadBezierEditorWin>();
        editWin.minSize = new Vector2(300, 500);
        editWin.Show();

        Debug.Log("LY : 打开曲线编辑器窗口 ！！！ ");

        mPathDataList = null;
        mDelPathIds.Clear();
        PreLoadBezierData();
    }

    /// <summary>
    /// 销毁窗口调用
    /// </summary>
    void OnDestroy()
    {
        mDelPathIds.Clear();
    }


    private void OnGUI()
    {
        DrawDataBtns();

        GUILayout.BeginVertical();

        if (GUILayout.Button("创建曲线", GUILayout.Height(60)))
        {
            CreateBezierPath();
        }
        if (GUILayout.Button("保存所有曲线（二进制）", GUILayout.Height(60)))
        {
            SaveBinaryBezierPath();
        }
        //if (GUILayout.Button("转换到二进制数据", GUILayout.Height(60)))
        //{
        //    ChangeDataToBinary();
        //}
        if (GUILayout.Button("清除场景中所有曲线", GUILayout.Height(60)))
        {
            ClearBezierPath();
        }

        GUILayout.EndVertical();
    }

    private static void PreLoadBezierData()
    {
        if (mPathDataList != null)
            return;

        mPathDataList = new List<BinaryBezierRecord>();
        if (File.Exists(binaryFilePath) == true)
        {
            BezierPathBinaryData loadData = LoadBinaryBezierData(binaryFilePath);
            if (loadData != null)
            {
                for (int a = 0; a < loadData.mPathDataList.Count; a++)
                {
                    mPathDataList.Add(loadData.mPathDataList[a].Clone());
                }
            }
        }
        //else
        //{
        //    BezierPathSaveData bezierData = AssetDatabase.LoadAssetAtPath(filePath, typeof(BezierPathSaveData)) as BezierPathSaveData;
        //    mPathDataList = bezierData.mPathDataList;
        //}

        if (mPathDataList == null)
        {
            Debug.Log("No bezier data !!!  LoadBezierEditorWin::PreLoadBezierData");
        }
        else
        {
            mPathDataList.Sort(Compare);
        }
    }

    private static int Compare(BinaryBezierRecord bezier1, BinaryBezierRecord bezier2)
    {
        if (bezier1.mId < bezier2.mId)
            return -1;
        else if (bezier1.mId == bezier2.mId)
            return 0;
        else
            return 1;
    }

    private void DrawDataBtns()
    {
        if (mPathDataList == null || mPathDataList.Count <= 0)
            return;

        scrollPosition = GUILayout.BeginScrollView(scrollPosition, /*GUILayout.Width(100), */GUILayout.Height(300));

        GUILayout.BeginVertical();
        //if (GUILayout.Button("读取所有曲线"))
        //{

        //    return;
        //}
        for (int a = 0; a < mPathDataList.Count; a++)
        {
            GUILayout.BeginHorizontal();
            if (GUILayout.Button(mPathDataList[a].mId.ToString(), GUILayout.Width(200)))
            {
                LoadBezierPath(mPathDataList[a].mId);
                //return;
            }
            if (GUILayout.Button("删除", GUILayout.Width(50)))
            {
                mDelPathIds.Add(mPathDataList[a].mId);

                string rootName = "(๑*◡*๑) PATHS";
                GameObject root = GameObject.Find(rootName);
                if(root != null)
                {
                    for (int b = 0; b < root.transform.childCount; a++)
                    {
                        BezierPath checkPath = root.transform.GetChild(b).GetComponent<BezierPath>();
                        if (checkPath != null && checkPath.id == mPathDataList[a].mId)
                        {
                            DestroyImmediate(checkPath.gameObject);
                            break;
                        }
                    }
                }

                mPathDataList.RemoveAt(a);
                break;
            }
            GUILayout.EndHorizontal();
        }
        GUILayout.EndVertical();

        GUILayout.EndScrollView();
    }

    private void LoadAllBezierPath()
    {

    }

    private void LoadBezierPath(uint id)
    {
        if (mPathDataList == null)
            return;

        string rootName = "(๑*◡*๑) PATHS";
        GameObject root = GameObject.Find(rootName);
        if (root != null)
        {
            for (int a = 0; a < root.transform.childCount; a++)
            {
                BezierPath checkPath = root.transform.GetChild(a).GetComponent<BezierPath>();
                if (checkPath != null && checkPath.id == id)
                {
                    Debug.Log("Bezier path has been loaded !!! " + id.ToString());
                    return;
                }
            }
        }

        for (int a = 0; a < mPathDataList.Count; a++)
        {
            BinaryBezierRecord tRec = mPathDataList[a];
            if (tRec.mId == id)
            {
                if (root == null)
                {
                    root = new GameObject(rootName);
                    root.hideFlags = HideFlags.DontSaveInEditor;
                }

                BezierPath path = new GameObject(id.ToString()).AddComponent<BezierPath>();
                path.transform.SetParent(root.transform, false);
                path.transform.localPosition = Vector3.zero;
                path.transform.localRotation = Quaternion.identity;

                path.hideFlags = HideFlags.DontSaveInEditor;
                Selection.activeGameObject = path.gameObject;

                path.id = tRec.mId;
                path.Resolution = tRec.mResolution;
                if (path.Resolution <= 0 && tRec.mBezierPoints.Count >= 2)
                {
                    path.Resolution = 20;
                }
                path.drawColor = tRec.mColor.GetColor();
                if (path.drawColor.a <= 0)
                {
                    path.drawColor = Color.white;
                }
                path.transform.position = tRec.mPathPos.GetVector3();
                List<BezierPoint> tBPList = new List<BezierPoint>();
                for (int b = 0; b < tRec.mBezierPoints.Count; b++)
                {
                    BezierPoint tBP = new BezierPoint(path, tRec.mBezierPoints[b].mPosition.GetVector3());
                    tBP.handleStyle = (BezierPoint.HandleStyle)tRec.mBezierPoints[b].mHandleStyle;
                    //tBP.handle1 = tRec.mBezierPoints[b].mHandle1;
                    //tBP.handle2 = tRec.mBezierPoints[b].mHandle2;
                    tBP.globalHandle1 = tRec.mBezierPoints[b].mHandle1.GetVector3();
                    tBP.globalHandle2 = tRec.mBezierPoints[b].mHandle2.GetVector3();
                    tBPList.Add(tBP);
                }
                path.points = tBPList;

                List<Vector3> tSPs = new List<Vector3>();
                for(int b = 0; b < tRec.mSampledPoint.Count; b++)
                {
                    tSPs.Add(tRec.mSampledPoint[b].GetVector3());
                }
                path.sampledPoints = tSPs;
                //path.sampledPoints = new List<Vector3>(tRec.mSampledPoint);
                break;
            }
        }
    }

    /// <summary>
    /// 创建新的曲线
    /// </summary>
    public static void CreateBezierPath()
    {
        string rootName = "(๑*◡*๑) PATHS";
        GameObject root = null;

        root = GameObject.Find(rootName);
        if (root == null)
        {
            root = new GameObject(rootName);
            root.hideFlags = HideFlags.DontSaveInEditor;
        }

        BezierPath path = new GameObject("UnSaveBezierPath").AddComponent<BezierPath>();
        path.transform.SetParent(root.transform, false);
        path.transform.localPosition = Vector3.zero;
        path.transform.localRotation = Quaternion.identity;

        path.gameObject.hideFlags = HideFlags.DontSaveInEditor;
        Selection.activeGameObject = path.gameObject;
    }

    /// <summary>
    /// 清除场景中所有曲线
    /// </summary>
    public static void ClearBezierPath()
    {
        string rootName = "(๑*◡*๑) PATHS";
        GameObject root = GameObject.Find(rootName);
        if (root == null)
        {
            return;
        }

        if (EditorUtility.DisplayDialog("清除",
                        "是否清除场景中所有曲线  ?？？",
                        "Yes",
                        "No") == true)
        {
            DestroyImmediate(root);
        }
    }

    /// <summary>
    /// 整理贝塞尔曲线
    /// </summary>
    public static List<BezierPath> CleanUpBezierPath()
    {
        string rootName = "(๑*◡*๑) PATHS";
        GameObject root = null;
        root = GameObject.Find(rootName);
        if (root == null)
        {
            root = new GameObject(rootName);
            root.hideFlags = HideFlags.DontSaveInEditor;
        }

        BezierPath[] tPath = FindObjectsOfType<BezierPath>();
        if (tPath != null && tPath.Length > 0)
        {
            for (int a = 0; a < tPath.Length; a++)
            {
                if (tPath[a].transform.parent == null)
                {
                    tPath[a].transform.parent = root.transform;
                }
                tPath[a].hideFlags = HideFlags.DontSaveInEditor;
            }
        }

        List<BezierPath> retList = new List<BezierPath>();
        for (int a = 0; a < root.transform.childCount; a++)
        {
            BezierPath tBPath = root.transform.GetChild(a).GetComponent<BezierPath>();
            if (tBPath != null)
            {
                retList.Add(tBPath);
                tBPath.SetDirty();
            }
        }

        return retList;
    }

    //public static void SaveAllBezierPath()
    //{
    //    List<BezierPath> newData = CleanUpBezierPath();
    //    if (newData == null || newData.Count <= 0)
    //    {
    //        Debug.LogError("No bezier path !!! ");
    //        return;
    //    }

    //    bool hasData = false;
    //    BezierPathSaveData oldData = null;

    //    oldData = AssetDatabase.LoadAssetAtPath(filePath, typeof(BezierPathSaveData)) as BezierPathSaveData;
    //    if (oldData != null)
    //    {
    //        hasData = true;
    //        //AssetDatabase.DeleteAsset(tPath);
    //    }

    //    List<BezierRecord> tSaveBezier = new List<BezierRecord>();
    //    for (int a = 0; a < newData.Count; a++)
    //    {
    //        newData[a].gameObject.name = newData[a].id.ToString();
    //        Vector3 tPathPos = newData[a].transform.position;

    //        BezierRecord tRec = new BezierRecord();
    //        tRec.mId = newData[a].id;
    //        tRec.mResolution = newData[a].resolution;
    //        tRec.mColor = newData[a].drawColor;
    //        tRec.mPathPos = tPathPos;
    //        tRec.mBezierPoints = new List<BezierSavePoint>();
    //        for (int b = 0; b < newData[a].points.Count; b++)
    //        {
    //            BezierSavePoint tBSP = new BezierSavePoint();
    //            //tBSP.mPosition = newData[a].points[b]._position;
    //            //tBSP.mHandle1 = newData[a].points[b].handle1;
    //            //tBSP.mHandle2 = newData[a].points[b].handle2;
    //            tBSP.mPosition = newData[a].points[b].position;
    //            tBSP.mHandle1 = newData[a].points[b].globalHandle1;
    //            tBSP.mHandle2 = newData[a].points[b].globalHandle2;
    //            tBSP.mHandleStyle = (int)newData[a].points[b].handleStyle;

    //            tRec.mBezierPoints.Add(tBSP);
    //        }
    //        tRec.mSampledPoint = newData[a].sampledPoints;
    //        tSaveBezier.Add(tRec);
    //    }

    //    if (hasData == true)
    //    {
    //        for (int a = 0; a < oldData.mPathDataList.Count; a++)
    //        {
    //            bool insertP = true;
    //            for (int b = 0; b < tSaveBezier.Count; b++)
    //            {
    //                if (oldData.mPathDataList[a].mId == tSaveBezier[b].mId)
    //                {
    //                    insertP = false;
    //                    break;
    //                }
    //            }

    //            if (insertP == true)
    //            {
    //                tSaveBezier.Add(oldData.mPathDataList[a].Clone());
    //            }
    //        }
    //        AssetDatabase.DeleteAsset(filePath);
    //    }

    //    mSaveData = ScriptableObject.CreateInstance<BezierPathSaveData>();
    //    mSaveData.mPathDataList = tSaveBezier;
    //    AssetDatabase.CreateAsset(mSaveData, filePath);

    //    mPathDataList = null;
    //    PreLoadBezierData();
    //}

    public static void SaveBinaryBezierPath()
    {
        List<BezierPath> newData = CleanUpBezierPath();
        //if (newData == null || newData.Count <= 0)
        //{
        //    Debug.LogError("No bezier path !!! ");
        //    return;
        //}

        bool hasData = false;

        BezierPathBinaryData oldData = null;
        if (File.Exists(binaryFilePath) == true)
        {
            oldData = LoadBinaryBezierData(binaryFilePath);
            hasData = true;
        }

        for(int a = oldData.mPathDataList.Count - 1; a >= 0; a--)
        {
            if(mDelPathIds.Contains(oldData.mPathDataList[a].mId))
            {
                oldData.mPathDataList.RemoveAt(a);
            }
        }
        mPathDataList.Clear();

        
        List<BinaryBezierRecord> tSaveBezier = new List<BinaryBezierRecord>();
        for (int a = 0; a < newData.Count; a++)
        {
            newData[a].gameObject.name = newData[a].id.ToString();
            Vector3 tPathPos = newData[a].transform.position;

            BinaryBezierRecord tRec = new BinaryBezierRecord();
            tRec.mId = newData[a].id;
            tRec.mResolution = newData[a].Resolution;
            tRec.mColor = new SVector4(newData[a].drawColor);
            tRec.mPathPos = new SVector3();
            tRec.mPathPos.SetVal(tPathPos);
            tRec.mBezierPoints = new List<BinaryBezierSavePoint>();
            for (int b = 0; b < newData[a].points.Count; b++)
            {
                BinaryBezierSavePoint tBSP = new BinaryBezierSavePoint();
                tBSP.mPosition = new SVector3();
                tBSP.mPosition.SetVal(newData[a].points[b].position);
                tBSP.mHandle1 = new SVector3();
                tBSP.mHandle1.SetVal(newData[a].points[b].globalHandle1);
                tBSP.mHandle2 = new SVector3();
                tBSP.mHandle2.SetVal(newData[a].points[b].globalHandle2);
                tBSP.mHandleStyle = (int)newData[a].points[b].handleStyle;

                tRec.mBezierPoints.Add(tBSP);
            }
            //tRec.mSampledPoint = newData[a].sampledPoints;
            List<Vector3> saveSPs = newData[a].sampledPoints;
            for (int b = 0; b < saveSPs.Count; b++)
            {
                SVector3 tSV3 = new SVector3();
                tSV3.SetVal(saveSPs[b]);
                tRec.mSampledPoint.Add(tSV3);
            }
            tSaveBezier.Add(tRec);
        }

        if (hasData == true)
        {
            for (int a = 0; a < oldData.mPathDataList.Count; a++)
            {
                bool insertP = true;
                for (int b = 0; b < tSaveBezier.Count; b++)
                {
                    if (oldData.mPathDataList[a].mId == tSaveBezier[b].mId)
                    {
                        insertP = false;
                        break;
                    }
                }

                if (insertP == true)
                {
                    tSaveBezier.Add(oldData.mPathDataList[a].Clone());
                }
            }

            File.Delete(binaryFilePath);
        }

        BezierPathBinaryData tBPBData = new BezierPathBinaryData();
        for (int a = 0; a < tSaveBezier.Count; a++)
        {
            tBPBData.mPathDataList.Add(tSaveBezier[a]);
        }
        SaveBinaryBezierData(tBPBData, binaryFilePath);

        mPathDataList = null;
        PreLoadBezierData();
    }

    /// <summary>
    /// 转换数据到二进制
    /// </summary>
    //private static void ChangeDataToBinary()
    //{
    //    if (File.Exists(binaryFilePath) == true)
    //    {
    //        File.Delete(binaryFilePath);
    //    }

    //    BezierPathBinaryData tBPBData = new BezierPathBinaryData();
    //    for (int a = 0; a < mPathDataList.Count; a++)
    //    {
    //        tBPBData.mPathDataList.Add(new BinaryBezierRecord(mPathDataList[a]));
    //    }
    //    SaveBinaryBezierData(tBPBData, binaryFilePath);
    //}

    /// <summary>
    /// 序列化二进制曲线数据
    /// </summary>
    /// <param name="bezierData"></param>
    /// <param name="savePath"></param>
    private static void SaveBinaryBezierData(BezierPathBinaryData bezierData, string savePath)
    {
        ////文件流
        //FileStream fileStream = new FileStream(savePath, FileMode.Create, FileAccess.ReadWrite, FileShare.ReadWrite);
        ////新建二进制格式化程序
        //BinaryFormatter bf = new BinaryFormatter();
        ////序列化
        //bf.Serialize(fileStream, bezierData);
        //fileStream.Dispose();

        bezierData.Write(savePath);
    }

    /// <summary>
    /// 反序列化
    /// </summary>
    /// <param name="path"></param>
    /// <returns></returns>
    private static BezierPathBinaryData LoadBinaryBezierData(string path)
    {
        ////文件流
        //FileStream fileStream = new FileStream(path, FileMode.Open, FileAccess.ReadWrite, FileShare.ReadWrite);
        ////新近二进制格式化程序
        //BinaryFormatter bf = new BinaryFormatter();
        ////反序列化
        //BezierPathBinaryData loadData = (BezierPathBinaryData)bf.Deserialize(fileStream);
        //fileStream.Dispose();
        //return loadData;

        BezierPathBinaryData loadData = new BezierPathBinaryData();
        loadData.Read(path);
        return loadData;
    }
}

#endif