//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/16 15:04:27
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit.Confuse
{
    [Serializable]
    public class ConfuseCodeCfg
    {
        #region 字段
        public string flag = "_0x";

        public string srcTypePath = "./Assets/Mod/Editor/Confuse/SrcType.txt";

        public string destTypePath = "./Assets/Mod/Editor/Confuse/DestType.txt";

        public string funcNamePath = "./Assets/Mod/Editor/Confuse/FuncName.txt";

        public string fieldNamePath = "./Assets/Mod/Editor/Confuse/FieldName.txt";

        public string cacheDir = "../Confuse/Code";

        public string unusedDir = "Assets/Script/Client/0x0";

        public string mainPath = "Assets/Script/Client/Main/Main.cs";

        public string unusedFlag = "_good";

        public int unusedTypeMin = 100;

        public int unusedTypeMax = 300;

        public int unusedPropMin = 1;

        public int unusedPropMax = 10;

        public int unusedFuncMin = 1;

        public int unusedFuncMax = 5;

        public int unusedFuncArgMin = 0;

        public int unusedFuncArgMax = 9;


        public List<string> scriptDirs = new List<string>()
        {
            "Assets/Mod",
            "Assets/Script",
            "Assets/Source",
        };


        public List<string> baseClasses = new List<string>()
        {
            UnityObj,
            UnityMono,
            UnityScripObj,
        };

        public const string UnityObj = "UnityEngine.Object";
        public const string UnityMono = "UnityEngine.MonoBehaviour";
        public const string UnityScripObj = "UnityEngine.ScriptableObject";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void OnGUI(Object o)
        {
            if (!UIEditTool.DrawHeader("代码混淆", "ConfuseCode", StyleTool.Host)) return;

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetPath("原类型文件:", ref srcTypePath, o, "txt");
            UIEditLayout.SetPath("目标类型文件:", ref destTypePath, o, "txt");
            UIEditLayout.SetPath("方法名称文件:", ref funcNamePath, o, "txt");
            UIEditLayout.SetPath("字段名称文件:", ref fieldNamePath, o, "txt");
            UIEditLayout.SetFolder("代码缓存目录:", ref cacheDir, o);
            UIEditLayout.SetPath("入口代码路径:", ref mainPath, o, "cs");
            UIEditLayout.TextField("混肴标记:", ref flag, o);
            EditorGUILayout.Space();

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("无用代码目录:", ref unusedDir, o);
            UIEditLayout.TextField("无用代码标记:", ref unusedFlag, o);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("无用代码类型数量范围, 最小:", ref unusedTypeMin, o);
            EditorGUILayout.Space();
            UIEditLayout.IntField("最大:", ref unusedTypeMax, o);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("无用代码类型属性数量, 最小:", ref unusedPropMin, o);
            EditorGUILayout.Space();
            UIEditLayout.IntField("最大:", ref unusedPropMax, o);
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("无用代码类型方法数量, 最小:", ref unusedFuncMin, o);
            EditorGUILayout.Space();
            UIEditLayout.IntField("最大:", ref unusedFuncMax, o);
            EditorGUILayout.EndHorizontal();


            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("无用代码方法参数数量, 最小:", ref unusedFuncArgMin, o);
            EditorGUILayout.Space();
            UIEditLayout.IntField("最大:", ref unusedFuncArgMax, o);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.EndVertical();
            UIDrawTool.StringLst(o, scriptDirs, "ConfuseCodeScripDir", "混淆脚本目录");

            UIDrawTool.StringLst(o, baseClasses, "ConfuseCodeBaseClasses", "混淆脚本基类");
            EditorGUILayout.EndVertical();

        }

        public string GetMainPathExter()
        {
            var path = Path.Combine(cacheDir, mainPath);
            return Path.GetFullPath(path);
        }


        public string GetMainPathInPro()
        {
            var path = Path.Combine("./", mainPath);
            return Path.GetFullPath(path);
        }
        #endregion
    }
}