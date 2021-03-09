using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using Loong.Game;
using System.IO;

public class soonUIwin : EditorWindow
{
    [SerializeField]
    [HideInInspector]
    private bool isUITemplate = true;
    [SerializeField]
    [HideInInspector]
    private bool isUIBase = true;
    private string SelectionName = "点击预制体";
    public static soonUIwin instance = null;
    [SerializeField]
    [HideInInspector]
    public static string ScriptName = null;
    [SerializeField]
    [HideInInspector]
    private string folderName = null;
    public static string rootLua = Path.GetFullPath("../LuaCode");
    /// 根目录
    /// </summary>
    [SerializeField]
    [HideInInspector]
    public static string root = "";

    [MenuItem("soon/soonUI")]
    static void initwin()
    {
        soonUIwin win = (soonUIwin)soonUIwin.GetWindow(typeof(soonUIwin));
        instance = win;
        if (root=="")
        {
            root = rootLua;
        }

    }
    void OnGUI()
    {
        EditorGUILayout.BeginVertical(StyleTool.Box);
        EditorGUILayout.LabelField("标识字段:", "tf_ gbj_ btn_ spr_ lab_ tog_ sld_ sv_ grid_ tex_ _end");
        EditorGUILayout.Space();
        UIEditLayout.SetFolder("根目录:", ref root, this);
        EditorGUILayout.BeginHorizontal();
        //EditorGUILayout.LabelField("创建文件夹：", GUILayout.Width(70));
        folderName = EditorGUILayout.TextField("创建文件夹：",folderName);
        if (GUILayout.Button("开始创建", UIOptUtil.btn))
        {
            if (folderName == "")
            {
                Debug.LogError("创建脚本必须存在文件名");
            }
            else
            {
                root = root + "\\" + folderName;
                ClientPrefabToScript.CreateField(root);
            }

        }
        EditorGUILayout.EndHorizontal();
        EditorGUILayout.Space();
        ScriptName = EditorGUILayout.TextField("脚本名字为：", ScriptName);
        EditorGUILayout.BeginVertical(StyleTool.Group);
        UIEditLayout.Toggle("类型是否是UI", ref isUITemplate, this);
        if (isUITemplate)
        {
            UIEditLayout.Toggle("是否继承UIbase", ref isUIBase, this);
     
            if (Selection.activeGameObject != null&& SelectionName != Selection.activeGameObject.name)
            {
                SelectionName = Selection.activeGameObject.name;
                ScriptName = SelectionName;
            }
            EditorGUILayout.LabelField("选中预制体:", SelectionName);
        }
        EditorGUILayout.EndVertical();
        if (GUILayout.Button("开始生成脚本", UIOptUtil.btn)
            )
        {
            if (ScriptName == null || ScriptName=="")
            {
                Debug.LogError("输入脚本名字");
            }
            else if (isUITemplate == false)
            {
                //创建标准格式脚本
                ClientPrefabToScript.CreateBase(ScriptName);

            }
            else if ( Selection.activeObject == null)
            {
                Debug.Log("创建ui时未选中组件，或者选中的组件未激活");
            }
            else if (((GameObject)Selection.activeObject).transform.childCount <= 0)
            {
                Debug.Log("ui应该存在子类");
            }
            else
            {
                string init = isUIBase ? "InitCustom" : "Init";
                string tem = isUIBase ? "UIBase" : "Super";
                //创建UI脚本
                ClientPrefabToScript.CreateUI(ScriptName,Selection.activeGameObject,init,tem);
            }
        }
        EditorGUILayout.EndVertical();

    }
}
