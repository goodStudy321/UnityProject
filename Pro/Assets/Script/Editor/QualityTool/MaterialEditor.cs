using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using System.IO;
using System.Xml;
using System.Xml.Serialization;
using UnityEditor.SceneManagement;

using NPOI.SS.UserModel;
using Loong.Edit;
using Loong.Game;


public class MaterialEditor : EditorWindow 
{
    private Vector2 scrollPosition;

    [MenuItem("Developer Tools/打开材质转换面板")]
    private static void ShowWindow()
    {
        MaterialEditor matWin = GetWindow<MaterialEditor>();
        matWin.Show();
        matWin.minSize = new Vector2(200, 400);
    }

    private void OnGUI()
    {
        scrollPosition = GUILayout.BeginScrollView(scrollPosition);
        GUILayout.BeginVertical();

        if (GUILayout.Button("打印所有材质名称", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            ShowAllMatName();
        }
        if (GUILayout.Button("检查场景是否有高材质", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            CheckHighMatInScene();
        }
        if (GUILayout.Button("输出场景所有Shader名称", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            ShowAllShaderInScene();
        }
        if (GUILayout.Button("转换当前场景到低材质", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            ChangeCurSceneToLowMat();
        }
        if (GUILayout.Button("转换当前场景到高材质", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            ChangeCurSceneToHighMat();
        }
        if (GUILayout.Button("转换选择Prefab到低材质", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            ChangeSelectionToLowMat();
        }
        if (GUILayout.Button("处理选中物体下粒子双材质问题", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            FixParticleDoubleMat();
        }
        if (GUILayout.Button("处理粒子资源双材质球问题", /*GUILayout.Width(150f),*/ GUILayout.Height(50f)))
        {
            FixParticlePrefabDoubleMat();
        }

        GUILayout.EndVertical();
        GUILayout.EndScrollView();
    }

    private void OnDestroy()
    {
        
    }

    private static void ShowAllMatName()
    {
        Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
        if (tRenderers == null || tRenderers.Length <= 0)
            return;

        List<string> matNames = new List<string>();

        for (int a = 0; a < tRenderers.Length; a++)
        {
            Renderer tRen = tRenderers[a];
            if (tRen != null)
            {
                Material[] tMats = tRen.sharedMaterials;
                if (tMats == null || tMats.Length <= 0)
                    continue;

                for (int b = 0; b < tMats.Length; b++)
                {
                    string matName = "null";
                    if (tMats[b] != null)
                    {
                        matName = tMats[b].name;
                    }
                    if (matName == "null")
                    {
                        Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
                    }
                    else
                    {
                        if (matNames.Contains(matName) == false)
                        {
                            matNames.Add(matName);
                        }
                    }
                }
            }
        }

        for (int a = 0; a < matNames.Count; a++)
        {
            Debug.Log("-------------------------------------------    Material               : " + matNames[a]);
        }
    }

    private static void CheckHighMatInScene()
    {
        Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
        if (tRenderers == null || tRenderers.Length <= 0)
        {
            Debug.Log("没有高材质。");
            return;
        }

        List<string> objNames = new List<string>();
        List<string> matNames = new List<string>();

        for (int a = 0; a < tRenderers.Length; a++)
        {
            Renderer tRen = tRenderers[a];
            if (tRen != null)
            {
                Material[] tMats = tRen.sharedMaterials;
                if (tMats == null || tMats.Length <= 0)
                    continue;

                for (int b = 0; b < tMats.Length; b++)
                {
                    string matName = "null";
                    if (tMats[b] != null)
                    {
                        matName = tMats[b].name;
                    }
                    if (matName == "null")
                    {
                        //Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
                    }
                    else
                    {
                        if (matName.Contains("_Height") && matNames.Contains(matName) == false)
                        {
                            objNames.Add(tRen.name);
                            matNames.Add(matName);
                        }
                    }
                }
            }
        }

        if (matNames.Count > 0)
        {
            for (int a = 0; a < matNames.Count; a++)
            {
                Debug.Log("---------------------------------    Object Name : " + objNames[a] + "    Mat Name : " + matNames[a]);
            }
        }
        else
        {
            Debug.Log("没有高材质。");
        }
    }

    private static void ShowAllShaderInScene()
    {
        Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
        if (tRenderers == null || tRenderers.Length <= 0)
            return;

        List<string> objNames = new List<string>();
        List<string> matNames = new List<string>();

        List<string> shaderObjNames = new List<string>();
        List<string> shaderNames = new List<string>();

        for (int a = 0; a < tRenderers.Length; a++)
        {
            Renderer tRen = tRenderers[a];
            if (tRen != null)
            {
                Material[] tMats = tRen.sharedMaterials;
                if (tMats == null || tMats.Length <= 0)
                    continue;

                for (int b = 0; b < tMats.Length; b++)
                {
                    string matName = "null";
                    string shaderName = "";
                    if (tMats[b] != null)
                    {
                        matName = tMats[b].name;
                        shaderName = tMats[b].shader.name;
                    }
                    if (matName == "null")
                    {
                        //Debug.Log("GameObj  : " + tRen.name + "        Mat name  : " + matName);
                    }
                    else
                    {
                        if (matName.Contains("_Height") && matNames.Contains(matName) == false)
                        {
                            objNames.Add(tRen.name);
                            matNames.Add(matName);
                        }

                        shaderObjNames.Add(tRen.name);
                        shaderNames.Add(shaderName);
                    }
                }
            }
        }

        if (matNames.Count > 0)
        {
            for (int a = 0; a < matNames.Count; a++)
            {
                Debug.Log("---------------------------------    Object Name : " + objNames[a] + "    Mat Name : " + matNames[a]);
            }

            Debug.Log("");
            Debug.Log("");
            Debug.Log("");
            Debug.Log("");
        }
        else
        {
            Debug.Log("没有高材质。");
        }

        for (int a = 0; a < shaderNames.Count; a++)
        {
            Debug.Log(".............................         Shader Name :  " + shaderNames[a] + "              Object Name : " + shaderObjNames[a]);
        }
    }

    private static void ChangeCurSceneToLowMat()
    {
        Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
        if (tRenderers == null || tRenderers.Length <= 0)
            return;

        for (int a = 0; a < tRenderers.Length; a++)
        {
            Renderer tRen = tRenderers[a];
            if (tRen != null)
            {
                Material[] tMats = tRen.sharedMaterials;
                if (tMats == null || tMats.Length <= 0)
                    continue;

                Material[] newMats = new Material[tMats.Length];
                for (int b = 0; b < tMats.Length; b++)
                {
                    if (tMats[b] == null)
                    {
                        newMats[b] = null;
                    }
                    else
                    {
                        if (tMats[b].name.Contains("_Height") == true)
                        {
                            string lowName = tMats[b].name.Replace("_Height", "_low");
                            string[] guids = AssetDatabase.FindAssets(lowName);
                            if (guids == null || guids.Length == 0)
                            {
                                iTrace.Error("LY", "res error !!! " + lowName);
                                newMats[b] = tMats[b];
                            }
                            else
                            {
                                for (int c = 0; c < guids.Length; c++)
                                {
                                    string guidPath = AssetDatabase.GUIDToAssetPath(guids[c]);
                                    string fName = Path.GetFileNameWithoutExtension(guidPath);
                                    if (fName == lowName)
                                    {
                                        Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
                                        newMats[b] = newMat;
                                        break;
                                    }
                                }
                            }
                        }
                        else
                        {
                            newMats[b] = tMats[b];
                        }
                    }
                }
                tRen.sharedMaterials = newMats;
            }
        }

        EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
    }

    private static void ChangeCurSceneToHighMat()
    {
        Renderer[] tRenderers = GameObject.FindObjectsOfType<Renderer>();
        if (tRenderers == null || tRenderers.Length <= 0)
            return;

        for (int a = 0; a < tRenderers.Length; a++)
        {
            Renderer tRen = tRenderers[a];
            if (tRen != null)
            {
                Material[] tMats = tRen.sharedMaterials;
                if (tMats == null || tMats.Length <= 0)
                    continue;

                Material[] newMats = new Material[tMats.Length];
                for (int b = 0; b < tMats.Length; b++)
                {
                    if (tMats[b] == null)
                    {
                        newMats[b] = null;
                    }
                    else
                    {
                        if (tMats[b].name.Contains("_low") == true)
                        {
                            string highName = tMats[b].name.Replace("_low", "_Height");
                            string[] guids = AssetDatabase.FindAssets(highName);
                            if (guids == null || guids.Length == 0)
                            {
                                iTrace.Error("LY", "res error !!! " + highName);
                                newMats[b] = tMats[b];
                            }
                            else
                            {
                                for (int c = 0; c < guids.Length; c++)
                                {
                                    string guidPath = AssetDatabase.GUIDToAssetPath(guids[c]);
                                    string fName = Path.GetFileNameWithoutExtension(guidPath);
                                    if (fName == highName)
                                    {
                                        Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
                                        newMats[b] = newMat;
                                        break;
                                    }
                                }
                            }
                        }
                        else
                        {
                            newMats[b] = tMats[b];
                        }
                    }
                }
                tRen.sharedMaterials = newMats;
            }
        }

        EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
    }

    private static void ChangeSelectionToLowMat()
    {
        //PrefabUtility.GetPrefabType() == PrefabType.Prefab
        Object[] selObjs = Selection.GetFiltered<Object>(SelectionMode.DeepAssets);
        if (selObjs == null || selObjs.Length <= 0)
        {
            iTrace.Error("LY", "No selection !!! ");
            return;
        }

        for (int a = 0; a < selObjs.Length; a++)
        {
            PrefabAssetType type = PrefabUtility.GetPrefabAssetType(selObjs[a]);
            //if (PrefabUtility.GetPrefabType(selObjs[a]) == PrefabType.Prefab)
            if (type != PrefabAssetType.NotAPrefab && type != PrefabAssetType.MissingAsset)
            {
                iTrace.Log("LY", "Prefab name    :  " + selObjs[a].name);
                GameObject tObj = selObjs[a] as GameObject;
                List<Renderer> tRens = new List<Renderer>(tObj.GetComponentsInChildren<Renderer>());
                Renderer tRen = tObj.GetComponent<Renderer>();
                if (tRen != null && tRens.Contains(tRen) == false)
                {
                    tRens.Add(tRen);
                }

                for (int b = 0; b < tRens.Count; b++)
                {
                    Renderer checkRen = tRens[b];
                    Material[] mats = checkRen.sharedMaterials;
                    if (mats != null && mats.Length > 0)
                    {
                        Material[] newMats = new Material[mats.Length];
                        for (int c = 0; c < mats.Length; c++)
                        {
                            if (mats[c] == null)
                            {
                                newMats[c] = mats[c];
                            }
                            else
                            {
                                if (mats[c].name.Contains("_Height") == true)
                                {
                                    string lowName = mats[c].name.Replace("_Height", "_low");
                                    string[] guids = AssetDatabase.FindAssets(lowName);
                                    if (guids == null || guids.Length > 1)
                                    {
                                        string guidPath = AssetDatabase.GUIDToAssetPath(guids[0]);
                                        if (guids.Length > 1 && guidPath.Contains(lowName))
                                        {
                                            Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
                                            newMats[c] = newMat;
                                        }
                                        else
                                        {
                                            iTrace.Error("LY", "res error !!! " + lowName);
                                            newMats[c] = mats[c];
                                        }
                                    }
                                    else
                                    {
                                        if (guids.Length > 0)
                                        {
                                            string guidPath = AssetDatabase.GUIDToAssetPath(guids[0]);
                                            Material newMat = AssetDatabase.LoadAssetAtPath(guidPath, typeof(Material)) as Material;
                                            newMats[c] = newMat;
                                        }
                                        else
                                        {
                                            newMats[c] = mats[c];
                                        }
                                    }
                                }
                                else
                                {
                                    newMats[c] = mats[c];
                                }
                            }
                        }

                        tRens[b].sharedMaterials = newMats;
                    }
                }
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
    }

    private static void FixParticleDoubleMat()
    {
        GameObject[] gObjs = Selection.gameObjects;
        if (gObjs == null || gObjs.Length <= 0)
        {
            return;
        }

        for (int a = 0; a < gObjs.Length; a++)
        {
            GameObject tObj = gObjs[a];
            if (tObj == null)
            {
                continue;
            }

            ParticleSystem[] checkPSs = tObj.GetComponentsInChildren<ParticleSystem>(true);
            for (int b = 0; b < checkPSs.Length; b++)
            {
                ParticleSystem tPS = checkPSs[b];
                if (tPS.trails.enabled == false)
                {
                    Renderer tR = tPS.GetComponent<Renderer>();
                    if (tR != null)
                    {
                        Material[] tMs = tR.sharedMaterials;
                        if (tMs != null && tMs.Length > 1)
                        {
                            for (int c = 1; c < tMs.Length; c++)
                            {
                                tMs[c] = null;
                            }
                            tR.sharedMaterials = tMs;
                        }
                    }
                }
            }
        }
    }

    private static void FixParticlePrefabDoubleMat()
    {
        var selPres = Selection.GetFiltered(typeof(UnityEngine.Object), SelectionMode.DeepAssets);
        for (int a = 0; a < selPres.Length; a++)
        {
            if (selPres[a] is GameObject)
            {
                //string path = AssetDatabase.GetAssetPath(selPres[a]);
                //Debug.Log(" +++++++++       " + selPres[a].name + "      path : " + path);

                bool needSave = false;
                GameObject checkGo = GameObject.Instantiate(selPres[a]) as GameObject;
                ParticleSystem[] checkPSs = checkGo.GetComponentsInChildren<ParticleSystem>(true);
                for (int b = 0; b < checkPSs.Length; b++)
                {
                    ParticleSystem tPS = checkPSs[b];
                    if (tPS.trails.enabled == false)
                    {
                        Renderer tR = tPS.GetComponent<Renderer>();
                        if (tR != null)
                        {
                            Material[] tMs = tR.sharedMaterials;
                            if (tMs != null && tMs.Length > 1)
                            {
                                needSave = true;
                                for (int c = 1; c < tMs.Length; c++)
                                {
                                    tMs[c] = null;
                                }
                                tR.sharedMaterials = tMs;
                            }
                        }
                    }
                }

                if (needSave == true)
                {
                    string path = AssetDatabase.GetAssetPath(selPres[a]);
                    Debug.Log(" +++++++++       " + selPres[a].name + "      path : " + path);
                    //PrefabUtility.ReplacePrefab(checkGo, selPres[a], ReplacePrefabOptions.ConnectToPrefab);
                    PrefabUtility.SavePrefabAsset(checkGo);
                }
                GameObject.DestroyImmediate(checkGo);
            }
        }
    }
}
