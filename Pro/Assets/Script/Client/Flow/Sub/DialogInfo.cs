using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Lang = Phantom.Localization;
using LuaInterface;

#if UNITY_EDITOR
using UnityEditor;
#endif

/*
 * CO:            
 * Copyright:   2016-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        cbb5a91b-4f43-4c3b-9484-88adb083dac0
*/

/// <summary>
/// AU:Loong
/// TM:2016/10/15 10:50:37
/// BG:对话框信息
/// </summary>
/// 
[Serializable]
public class DialogInfo
#if UNITY_EDITOR
    : IDraw
#endif
{
    #region 字段
    /// <summary>
    /// 样式
    /// </summary>
    public int style = 0;
    /// <summary>
    /// 显示名称 不删除
    /// </summary>
    public string name;

    public int nameID = 0;
    /// <summary>
    /// 对话框信息
    /// </summary>
    public string text;

    public int textID = 0;

    /// <summary>
    /// true:左边显示 false:右边显示
    /// </summary>
    public bool left = true;

    /// <summary>
    /// 模型名称/如果可转换为整数,将会从角色基础信息表中查找条目,加载指定的模型
    /// </summary>
    public string modelName;

    /// <summary>
    /// 持续时间
    /// </summary>
    public float timer = 2f;

    #endregion

    #region 属性

    #endregion

    #region 构造方法
    public DialogInfo()
    {

    }

    public DialogInfo(string name, string modelName, string text)
    {
        this.name = name;
        this.text = text;
        this.modelName = modelName;
    }
    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法

    public void Copy(DialogInfo other)
    {
        style = other.style;
        nameID = other.nameID;
        textID = other.textID;
        left = other.left;
        modelName = other.modelName;
        timer = other.timer;
    }

    public void Read(BinaryReader br)
    {
        style = br.ReadInt32();
        //TODO DELETE
        ExString.Read(ref name, br);
        ExString.Read(ref text, br);
        nameID = br.ReadInt32();
        textID = br.ReadInt32();

        left = br.ReadBoolean();
        ExString.Read(ref modelName, br);
        //modelName = br.ReadString();
        timer = br.ReadSingle();
        SetText();
    }

    public void Write(BinaryWriter bw)
    {
        bw.Write(style);
        //TODO DELETE
        ExString.Write(name, bw);
        ExString.Write(text, bw);
        bw.Write(nameID);
        bw.Write(textID);
        bw.Write(left);
        ExString.Write(modelName, bw);
        //bw.Write(modelName);
        bw.Write(timer);
    }

    public void SetText()
    {
        name = Lang.Instance.GetDes(nameID);
        text = Lang.Instance.GetDes(textID);
    }

#if UNITY_EDITOR
    [NoToLua]
    public void Draw(Object obj, IList lst, int idx)
    {
        UIEditLayout.IntField("样式:", ref style, obj);
        UIEditLayout.TextField("显示名称:", ref name, obj);
        EditorGUILayout.BeginHorizontal();
        UIEditLayout.IntField("显示名称ID:", ref nameID, obj);
        EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
        EditorGUILayout.EndHorizontal();

        UIEditLayout.FloatField("持续时间(秒):", ref timer, obj);
        UIEditLayout.TextField("模型名称:", ref modelName, obj, null, GUILayout.Height(40));
        UIEditLayout.HelpWaring("1,如果可转换为整数,将会从 角色基础信息表.xls 中查找条目,加载指定的模型\n2,如果是1,则将加载本地英雄的模型");
        UIEditLayout.Toggle("左边显示:", ref left, obj);
        EditorGUILayout.LabelField("对话信息:");
        UIEditLayout.TextArea("", ref text, obj, null, GUILayout.Height(40));

        EditorGUILayout.BeginHorizontal();
        UIEditLayout.IntField("对话信息ID:", ref textID, obj);
        EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
        EditorGUILayout.EndHorizontal();

    }
#endif
    #endregion
}