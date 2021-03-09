using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// ��ͨѰ·����
/// </summary>
public class AsQueuePath 
{
    /// <summary>
    /// ��ʼλ��
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// ����λ��
    /// </summary>
    public Vector3 endPos;
    /// <summary>
    /// ����·���ṹ
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
/// ����·��Ѱ·����
/// </summary>
public class AsQueueFallowPath
{
    /// <summary>
    /// ��ʼλ��
    /// </summary>
    public Vector3 startPos;
    /// <summary>
    /// ·����
    /// </summary>
    public List<FigPathPotInfo> mPathPoints;
    /// <summary>
    /// ����·���ṹ
    /// </summary>
    public Action<WalkPath> storeRef;

    public AsQueueFallowPath(Vector3 sPos, List<FigPathPotInfo> pathPoints, Action<WalkPath> theRefMethod)
    {
        startPos = sPos;
        mPathPoints = pathPoints;
        storeRef = theRefMethod;
    }
}