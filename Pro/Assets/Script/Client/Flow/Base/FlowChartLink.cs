using System;
using Phantom;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

/// <summary>
/// Loong 注:这个类中包含编辑器的代码,编辑器的代码不可在运行时调用,一般以Ed_或者Edit开头
/// </summary>
[System.Serializable]
public class FlowChartLink :
#if UNITY_EDITOR
    IDraw,
#endif
    IComparer<FlowChartLink>, IComparable<FlowChartLink>
{

    #region 字段
    public string bName = "";
    public bool inTog;
    public int inWt = 100;
    public string eName = "";
    public bool outTog;
    public int outWt = 100;
    private FlowChartNode _end;
    private FlowChartNode _start;
    #endregion

    #region 属性
    public FlowChartNode start
    {
        get { return _start; }
        set
        {
            _start = value;
            bName = (value == null ? "" : value.name);
        }
    }



    public FlowChartNode end
    {
        get { return _end; }
        set
        {
            _end = value;
            eName = (value == null ? "" : value.name);
        }
    }

    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    public void Dispose()
    {
        start = null;
        end = null;
    }

    public void DrawRuntime()
    {

    }

    public int CompareTo(FlowChartLink other)
    {
        return this.end.CompareTo(other.end);
    }

    public int Compare(FlowChartLink f1, FlowChartLink f2)
    {
        return f1.CompareTo(f2);
    }

    public virtual void Read(BinaryReader br)
    {
        ExString.Read(ref bName, br);
        //bName = br.ReadString();
        inTog = br.ReadBoolean();
        inWt = br.ReadInt32();
        ExString.Read(ref eName, br);
        //eName = br.ReadString();
        outTog = br.ReadBoolean();
        outWt = br.ReadInt32();
    }

    public virtual void Write(BinaryWriter bw)
    {
        ExString.Write(bName, bw);
        //bw.Write(bName);
        bw.Write(inTog);
        bw.Write(inWt);
        ExString.Write(eName, bw);
        //bw.Write(eName);
        bw.Write(outTog);
        bw.Write(outWt);
    }


    #endregion


    #region 编辑器字段/属性/方法

#if UNITY_EDITOR
    [HideInInspector]
    [System.NonSerialized]
    public bool editSelect;

    public void Draw(Object obj, IList lst, int idx)
    {
        bName = EditorGUILayout.TextField("起始点:", bName);
        inTog = EditorGUILayout.Toggle("输入控制:", inTog);
        inWt = EditorGUILayout.IntSlider("输入权重:", inWt, 0, 100);
        eName = EditorGUILayout.TextField("结束点:", eName);
        outTog = EditorGUILayout.Toggle("输出控制:", outTog);
        outWt = EditorGUILayout.IntSlider("输出权重:", outWt, 0, 100);
    }
#endif
    #endregion


}