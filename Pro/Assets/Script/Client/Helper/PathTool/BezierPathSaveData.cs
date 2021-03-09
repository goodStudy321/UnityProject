using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 贝塞尔曲线保存数据
/// </summary>
[Serializable]
public class BezierPathSaveData : ScriptableObject
{
    /// <summary>
    /// 曲线数据
    /// </summary>
    [SerializeField]
    public List<BinaryBezierRecord> mPathDataList;

    public BezierPathSaveData()
    {

    }
}