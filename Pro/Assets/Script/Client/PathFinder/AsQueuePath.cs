using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// 普通寻路队列
/// </summary>
public class AsQueuePath 
{
    /// <summary>
    /// 起始位置
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// 结束位置
    /// </summary>
    public Vector3 endPos;
    /// <summary>
    /// 返回路径结构
    /// </summary>
    public Action<WalkPath> storeRef;

    public AsQueuePath(Vector3 sPos, Vector3 ePos, Action<WalkPath> theRefMethod)
    {
        startPos = sPos;
        endPos = ePos;
        storeRef = theRefMethod;
    }
}

/// <summary>
/// 跟随路径寻路队列
/// </summary>
public class AsQueueFallowPath
{
    /// <summary>
    /// 起始位置
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// 路径点
    /// </summary>
    public List<FigPathPotInfo> mPathPoints;
    /// <summary>
    /// 返回路径结构
    /// </summary>
    public Action<WalkPath> storeRef;

    public AsQueueFallowPath(Vector3 sPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> theRefMethod)
    {
        startPos = sPos;
        mPathPoints = pathPoints;
        storeRef = theRefMethod;
    }
}