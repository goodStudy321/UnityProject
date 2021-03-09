using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using UnityEditor.SceneManagement;

using NPOI.SS.UserModel;
using Loong.Game;
using Loong.Edit;


public class QualityTool : Editor
{
    private static Dictionary<string, string> map_HRes = new Dictionary<string, string>();
    private static Dictionary<string, string> map_LRes = new Dictionary<string, string>();

    [MenuItem("Developer Tools/导出品质资源表")]
    private static void ExportQualityExcel()
    {
        map_HRes.Clear();
        map_LRes.Clear();

        string filePath = Path.GetFullPath("../table/Z 质量资源配置.xls");
        Debug.Log("              " + filePath);

        GetQualityMats();

        IWorkbook resWorkbook = ExcelTool.GetWrokBook(filePath, "Sheet1");
        try
        {
            ISheet resSheet = resWorkbook.GetSheet("Sheet1");
            int bRow = resSheet.FirstRowNum;
            int eRow = resSheet.LastRowNum;

            int snCol = ExcelTool.GetColumn(resSheet, 0, "场景名称");
            int hCol = ExcelTool.GetColumn(resSheet, 0, "高质量材质");
            int lCol = ExcelTool.GetColumn(resSheet, 0, "低质量材质");

            for (int a = bRow; a <= eRow; a++)
            {
                string tSName = ExcelTool.ReadString(resSheet.GetRow(a), snCol);
                if (map_HRes.ContainsKey(tSName) == true)
                {
                    ExcelTool.WriteString(resSheet.GetRow(a), hCol, map_HRes[tSName]);
                    ExcelTool.WriteString(resSheet.GetRow(a), lCol, map_LRes[tSName]);
                }
            }

            ExcelTool.Save(resWorkbook, filePath);
        }
        catch (System.Exception e)
        {
            UIEditTip.Error("LY,写入Excel发生错误:{0}", e.Message);
        }
        finally
        {
            if (resWorkbook != null) resWorkbook.Close();
        }
    }

    /// <summary>
    /// 销毁窗口调用
    /// </summary>
    void OnDestroy()
    {

    }

    private static void GetQualityMats()
    {
        Dictionary<string, List<string>> retRes = new Dictionary<string, List<string>>();

        string parPath = Application.dataPath + "/Scene";
        foreach (string path in Directory.GetDirectories(parPath))
        {
            string foName = path.Replace(parPath + "\\", "");
            //Debug.Log("=========================     : " + foName);
            if (foName == "Share")
            {
                continue;
            }

            List<string> tResList = new List<string>();
            if (Directory.Exists(path + "/Material") == true)
            {
                foreach (string filePath in Directory.GetFiles(path + "/Material"))
                {
                    //获取所有文件夹中包含后缀为 .prefab 的路径  
                    if (System.IO.Path.GetExtension(filePath) == ".mat")
                    {
                        string fileName = Path.GetFileName(filePath);
                        if (fileName.Contains("_low") == true)
                        {
                            //Debug.Log("----------------     : " + fileName);
                            tResList.Add(fileName);
                        }
                    }
                }
            }
            else if (Directory.Exists(path + "/Materials") == true)
            {
                foreach (string filePath in Directory.GetFiles(path + "/Materials"))
                {
                    //获取所有文件夹中包含后缀为 .prefab 的路径  
                    if (System.IO.Path.GetExtension(filePath) == ".mat")
                    {
                        string fileName = Path.GetFileName(filePath);
                        if (fileName.Contains("_low") == true)
                        {
                            //Debug.Log("----------------     : " + fileName);
                            tResList.Add(fileName);
                        }
                    }
                }
            }

            if (tResList.Count > 0)
            {
                retRes.Add(foName, tResList);
            }
        }

        foreach (var item in retRes)
        {
            string tHRS = "";
            string tLRS = "";
            for (int a = 0; a < item.Value.Count; a++)
            {
                if (a == 0)
                {
                    tHRS = tHRS + item.Value[a].Replace("_low", "");
                    tLRS = tLRS + item.Value[a];
                }
                else
                {
                    tHRS = tHRS + "|" + item.Value[a].Replace("_low", "");
                    tLRS = tLRS + "|" + item.Value[a];
                }
            }

            map_HRes.Add(item.Key, tHRS);
            map_LRes.Add(item.Key, tLRS);
        }
    }

    //[MenuItem("Developer Tools/转换当前场景到低材质")]
    //private static void ChangeCurSceneToLowMat()
    //{
    //    Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
    //    if (tRenderers == null || tRenderers.Length <= 0)
    //        return;

    //    for (int a = 0; a < tRenderers.Length; a++)
    //    {
    //        Renderer tRen = tRenderers[a];
    //        if (tRen != null)
    //        {
    //            Material[] tMats = tRen.sharedMaterials;
    //            if (tMats == null || tMats.Length <= 0)
    //                continue;

    //            Material[] newMats = new Material[tMats.Length];
    //            for (int b = 0; b < tMats.Length; b++)
    //            {
    //                if (tMats[b] == null)
    //                {
    //                    newMats[b] = null;
    //                }
    //                else
    //                {
    //                    if (tMats[b].name.Contains("_Height") == true)
    //                    {
    //                        string lowName = tMats[b].name.Replace("_Height", "_low");
    //                        string[] guids = AssetDatabase.FindAssets(lowName);
    //                        if (guids == null || guids.Length == 0)
    //                        {
    //                            iTrace.Error("LY", "res error !!! " + lowName);
    //                            newMats[b] = tMats[b];
    //                        }
    //                        else
    //                        {
    //                            for (int c = 0; c < guids.Length; c++)
    //                            {
    //                                string guidPath = AssetDatabase.GUIDToAssetPath(guids[c]);
    //                                string fName = Path.GetFileNameWithoutExtension(guidPath);
    //                                if (fName == lowName)
    //                                {
    //                                    Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
    //                                    newMats[b] = newMat;
    //                                    break;
    //                                }
    //                            }
    //                        }
    //                    }
    //                    else
    //                    {
    //                        newMats[b] = tMats[b];
    //                    }
    //                }
    //            }
    //            tRen.sharedMaterials = newMats;
    //        }
    //    }

    //    EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
    //}

    //[MenuItem("Developer Tools/转换当前场景到高材质")]
    //private static void ChangeCurSceneToHighMat()
    //{
    //    Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
    //    if (tRenderers == null || tRenderers.Length <= 0)
    //        return;

    //    for (int a = 0; a < tRenderers.Length; a++)
    //    {
    //        Renderer tRen = tRenderers[a];
    //        if (tRen != null)
    //        {
    //            Material[] tMats = tRen.sharedMaterials;
    //            if (tMats == null || tMats.Length <= 0)
    //                continue;

    //            Material[] newMats = new Material[tMats.Length];
    //            for (int b = 0; b < tMats.Length; b++)
    //            {
    //                if (tMats[b] == null)
    //                {
    //                    newMats[b] = null;
    //                }
    //                else
    //                {
    //                    if (tMats[b].name.Contains("_low") == true)
    //                    {
    //                        string highName = tMats[b].name.Replace("_low", "_Height");
    //                        string[] guids = AssetDatabase.FindAssets(highName);
    //                        if (guids == null || guids.Length == 0)
    //                        {
    //                            iTrace.Error("LY", "res error !!! " + highName);
    //                            newMats[b] = tMats[b];
    //                        }
    //                        else
    //                        {
    //                            for (int c = 0; c < guids.Length; c++)
    //                            {
    //                                string guidPath = AssetDatabase.GUIDToAssetPath(guids[c]);
    //                                string fName = Path.GetFileNameWithoutExtension(guidPath);
    //                                if (fName == highName)
    //                                {
    //                                    Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
    //                                    newMats[b] = newMat;
    //                                    break;
    //                                }
    //                            }
    //                        }
    //                    }
    //                    else
    //                    {
    //                        newMats[b] = tMats[b];
    //                    }
    //                }
    //            }
    //            tRen.sharedMaterials = newMats;
    //        }
    //    }

    //    EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
    //}

    //[MenuItem("Developer Tools/转换选择Prefab到低材质")]
    //private static void ChangeSelectionToLowMat()
    //{
    //    //PrefabUtility.GetPrefabType() == PrefabType.Prefab
    //    Object[] selObjs = Selection.GetFiltered<Object>(SelectionMode.DeepAssets);
    //    if (selObjs == null || selObjs.Length <= 0)
    //    {
    //        iTrace.Error("LY", "No selection !!! ");
    //        return;
    //    }

    //    for (int a = 0; a < selObjs.Length; a++)
    //    {
    //        if (PrefabUtility.GetPrefabType(selObjs[a]) == PrefabType.Prefab)
    //        {
    //            iTrace.Log("LY", "Prefab name    :  " + selObjs[a].name);
    //            GameObject tObj = selObjs[a] as GameObject;
    //            List<Renderer> tRens = new List<Renderer>(tObj.GetComponentsInChildren<Renderer>());
    //            Renderer tRen = tObj.GetComponent<Renderer>();
    //            if (tRen != null && tRens.Contains(tRen) == false)
    //            {
    //                tRens.Add(tRen);
    //            }

    //            for (int b = 0; b < tRens.Count; b++)
    //            {
    //                Renderer checkRen = tRens[b];
    //                Material[] mats = checkRen.sharedMaterials;
    //                if (mats != null && mats.Length > 0)
    //                {
    //                    Material[] newMats = new Material[mats.Length];
    //                    for (int c = 0; c < mats.Length; c++)
    //                    {
    //                        if (mats[c] == null)
    //                        {
    //                            newMats[c] = mats[c];
    //                        }
    //                        else
    //                        {
    //                            if (mats[c].name.Contains("_Height") == true)
    //                            {
    //                                string lowName = mats[c].name.Replace("_Height", "_low");
    //                                string[] guids = AssetDatabase.FindAssets(lowName);
    //                                if (guids == null || guids.Length > 1)
    //                                {
    //                                    string guidPath = AssetDatabase.GUIDToAssetPath(guids[0]);
    //                                    if (guids.Length > 1 && guidPath.Contains(lowName))
    //                                    {
    //                                        Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
    //                                        newMats[c] = newMat;
    //                                    }
    //                                    else
    //                                    {
    //                                        iTrace.Error("LY", "res error !!! " + lowName);
    //                                        newMats[c] = mats[c];
    //                                    }
    //                                }
    //                                else
    //                                {
    //                                    if (guids.Length > 0)
    //                                    {
    //                                        string guidPath = AssetDatabase.GUIDToAssetPath(guids[0]);
    //                                        Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
    //                                        newMats[c] = newMat;
    //                                    }
    //                                    else
    //                                    {
    //                                        newMats[c] = mats[c];
    //                                    }
    //                                }
    //                            }
    //                            else
    //                            {
    //                                newMats[c] = mats[c];
    //                            }
    //                        }
    //                    }

    //                    tRens[b].sharedMaterials = newMats;
    //                }
    //            }
    //        }
    //    }

    //    AssetDatabase.SaveAssets();
    //    AssetDatabase.Refresh();
    //}

    //[MenuItem("Developer Tools/打印所有材质名称")]
    //private static void ShowAllMatName()
    //{
    //    Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
    //    if (tRenderers == null || tRenderers.Length <= 0)
    //        return;

    //    List<string> matNames = new List<string>();

    //    for (int a = 0; a < tRenderers.Length; a++)
    //    {
    //        Renderer tRen = tRenderers[a];
    //        if (tRen != null)
    //        {
    //            Material[] tMats = tRen.sharedMaterials;
    //            if (tMats == null || tMats.Length <= 0)
    //                continue;

    //            for (int b = 0; b < tMats.Length; b++)
    //            {
    //                string matName = "null";
    //                if (tMats[b] != null)
    //                {
    //                    matName = tMats[b].name;
    //                }
    //                if (matName == "null")
    //                {
    //                    Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
    //                }
    //                else
    //                {
    //                    if (matNames.Contains(matName) == false)
    //                    {
    //                        matNames.Add(matName);
    //                    }
    //                }
    //            }
    //        }
    //    }

    //    for (int a = 0; a < matNames.Count; a++)
    //    {
    //        Debug.Log("-------------------------------------------    Material               : " + matNames[a]);
    //    }
    //}

    //[MenuItem("Developer Tools/检查场景是否有高材质")]
    //private static void CheckHighMatInScene()
    //{
    //    Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
    //    if (tRenderers == null || tRenderers.Length <= 0)
    //        return;

    //    List<string> objNames = new List<string>();
    //    List<string> matNames = new List<string>();

    //    for (int a = 0; a < tRenderers.Length; a++)
    //    {
    //        Renderer tRen = tRenderers[a];
    //        if (tRen != null)
    //        {
    //            Material[] tMats = tRen.sharedMaterials;
    //            if (tMats == null || tMats.Length <= 0)
    //                continue;

    //            for (int b = 0; b < tMats.Length; b++)
    //            {
    //                string matName = "null";
    //                if (tMats[b] != null)
    //                {
    //                    matName = tMats[b].name;
    //                }
    //                if (matName == "null")
    //                {
    //                    //Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
    //                }
    //                else
    //                {
    //                    if (matName.Contains("_Height") && matNames.Contains(matName) == false)
    //                    {
    //                        objNames.Add(tRen.name);
    //                        matNames.Add(matName);
    //                    }
    //                }
    //            }
    //        }
    //    }

    //    if (matNames.Count > 0)
    //    {
    //        for (int a = 0; a < matNames.Count; a++)
    //        {
    //            Debug.Log("---------------------------------    Object Name : " + objNames[a] + "    Mat Name : " + matNames[a]);
    //        }
    //    }
    //    else
    //    {
    //        Debug.Log("没有高材质。");
    //    }
    //}





    //[MenuItem("Developer Tools/输出场景所有Shader名称")]
    //private static void ShowAllShaderInScene()
    //{
    //    Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
    //    if (tRenderers == null || tRenderers.Length <= 0)
    //        return;

    //    List<string> objNames = new List<string>();
    //    List<string> matNames = new List<string>();

    //    List<string> shaderObjNames = new List<string>();
    //    List<string> shaderNames = new List<string>();

    //    for (int a = 0; a < tRenderers.Length; a++)
    //    {
    //        Renderer tRen = tRenderers[a];
    //        if (tRen != null)
    //        {
    //            Material[] tMats = tRen.sharedMaterials;
    //            if (tMats == null || tMats.Length <= 0)
    //                continue;

    //            for (int b = 0; b < tMats.Length; b++)
    //            {
    //                string matName = "null";
    //                string shaderName = "";
    //                if (tMats[b] != null)
    //                {
    //                    matName = tMats[b].name;
    //                    shaderName = tMats[b].shader.name;
    //                }
    //                if (matName == "null")
    //                {
    //                    //Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
    //                }
    //                else
    //                {
    //                    if (matName.Contains("_Height") && matNames.Contains(matName) == false)
    //                    {
    //                        objNames.Add(tRen.name);
    //                        matNames.Add(matName);
    //                    }

    //                    shaderObjNames.Add(tRen.name);
    //                    shaderNames.Add(shaderName);
    //                }
    //            }
    //        }
    //    }

    //    if (matNames.Count > 0)
    //    {
    //        for (int a = 0; a < matNames.Count; a++)
    //        {
    //            Debug.Log("---------------------------------    Object Name : " + objNames[a] + "    Mat Name : " + matNames[a]);
    //        }

    //        Debug.Log("");
    //        Debug.Log("");
    //        Debug.Log("");
    //        Debug.Log("");
    //    }
    //    else
    //    {
    //        Debug.Log("没有高材质。");
    //    }

    //    for (int a = 0; a < shaderNames.Count; a++)
    //    {
    //        Debug.Log(".............................         Shader Name :  " + shaderNames[a] + "              Object Name : " + shaderObjNames[a]);
    //    }
    //}


    //[MenuItem("Developer Tools/处理选中物体下粒子双材质问题")]
    //private static void FixParticleDoubleMat()
    //{
    //    GameObject[] gObjs = Selection.gameObjects;
    //    if (gObjs == null || gObjs.Length <= 0)
    //    {
    //        return;
    //    }

    //    for(int a = 0; a < gObjs.Length; a++)
    //    {
    //        GameObject tObj = gObjs[a];
    //        if(tObj == null)
    //        {
    //            continue;
    //        }

    //        ParticleSystem[] checkPSs = tObj.GetComponentsInChildren<ParticleSystem>(true);
    //        for(int b = 0; b < checkPSs.Length; b++)
    //        {
    //            ParticleSystem tPS = checkPSs[b];
    //            if(tPS.trails.enabled == false)
    //            {
    //                Renderer tR = tPS.GetComponent<Renderer>();
    //                if(tR != null)
    //                {
    //                    Material[] tMs = tR.sharedMaterials;
    //                    if(tMs != null && tMs.Length > 1)
    //                    {
    //                        for(int c = 1; c < tMs.Length; c++)
    //                        {
    //                            tMs[c] = null;
    //                        }
    //                        tR.sharedMaterials = tMs;
    //                    }
    //                }
    //            }
    //        }
    //    }
    //}

    //[MenuItem("Developer Tools/处理粒子资源双材质球问题")]
    //private static void FixParticlePrefabDoubleMat()
    //{
    //    var selPres = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.DeepAssets);
    //    for(int a = 0; a < selPres.Length; a++)
    //    {
    //        if (selPres[a] is GameObject)
    //        {
    //            //string path = AssetDatabase.GetAssetPath(selPres[a]);
    //            //Debug.Log(" +++++++++       " + selPres[a].name + "      path : " + path);

    //            bool needSave = false;
    //            GameObject checkGo = GameObject.Instantiate(selPres[a]) as GameObject;
    //            ParticleSystem[] checkPSs = checkGo.GetComponentsInChildren<ParticleSystem>(true);
    //            for (int b = 0; b < checkPSs.Length; b++)
    //            {
    //                ParticleSystem tPS = checkPSs[b];
    //                if (tPS.trails.enabled == false)
    //                {
    //                    Renderer tR = tPS.GetComponent<Renderer>();
    //                    if (tR != null)
    //                    {
    //                        Material[] tMs = tR.sharedMaterials;
    //                        if (tMs != null && tMs.Length > 1)
    //                        {
    //                            needSave = true;
    //                            for (int c = 1; c < tMs.Length; c++)
    //                            {
    //                                tMs[c] = null;
    //                            }
    //                            tR.sharedMaterials = tMs;
    //                        }
    //                    }
    //                }
    //            }

    //            if(needSave == true)
    //            {
    //                string path = AssetDatabase.GetAssetPath(selPres[a]);
    //                Debug.Log(" +++++++++       " + selPres[a].name + "      path : " + path);
    //                PrefabUtility.ReplacePrefab(checkGo, selPres[a], ReplacePrefabOptions.ConnectToPrefab);
    //            }
    //            GameObject.DestroyImmediate(checkGo);
    //        }
    //    }
    //}
}
