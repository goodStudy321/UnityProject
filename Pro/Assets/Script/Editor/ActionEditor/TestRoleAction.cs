using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System.Diagnostics;

public class TestRoleAction
{
    [MenuItem("Developer/LJF/改变角色 #%c")]
    public static void ChangeRole()
    {
        SlectCreateUnit scu = EditorWindow.GetWindow<SlectCreateUnit>();
        scu.Init();
    }

    [MenuItem("Developer/LJF/打开动作编辑器文件所在文件夹")]
    public static void OpenActionEditorToolFolder()
    {
        string folder = "/Assets/action";
        string path = Application.dataPath;
        while (!Directory.Exists(path + folder))
        {
            DirectoryInfo dirInfo = Directory.GetParent(path);
            if (dirInfo == null)
            {
                if (EditorUtility.DisplayDialog("提示", "没有此文件夹", "确定"))
                    return;
            }
            path = dirInfo.FullName;
        }
        path += folder;
        Process.Start(path);
    }

    [MenuItem("Developer/LJF/打开动作编辑器")]
    public static void OpenActionEditorTool()
    {
        string folder = "/ActionEditor";
        string path = Application.dataPath;
        while (!Directory.Exists(path + folder))
        {
            DirectoryInfo dirInfo = Directory.GetParent(path);
            if (dirInfo == null)
            {
                if (EditorUtility.DisplayDialog("提示", "没有此文件夹", "确定"))
                    return;
            }
            path = dirInfo.FullName;
        }
        ProcessStartInfo psi = new ProcessStartInfo();
        string fileName = path + folder + "/ActionEditor.exe";
        psi.FileName = fileName;
        psi.WorkingDirectory = path + folder;
        Process.Start(psi);
        EditorWindow.mouseOverWindow.ShowNotification(new GUIContent("打开成功"));
    }

    [MenuItem("Developer/LJF/创建预制件")]
    public static void CreatePrefab()
    {
        string name = "NewPrefab";
        string path = EditorUtility.SaveFilePanelInProject("保存预制体", name, "prefab", "", "Assets/Resources");
        if (string.IsNullOrEmpty(path))
            return;
        GameObject go = AssetDatabase.LoadAssetAtPath<GameObject>(path);
        if(go != null)
            AssetDatabase.DeleteAsset(path);
        go = new GameObject(Path.GetFileNameWithoutExtension(path));
        go.AddComponent<HitComponent>();
        PrefabUtility.SaveAsPrefabAsset(go, path);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Object.DestroyImmediate(go);
    }
}
