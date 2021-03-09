using System;
using Phantom;
using Loong.Game;
using Loong.Edit;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;



/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        961f7ff5-c668-40d1-bff2-19cce465a5a4
*/

/// <summary>
/// AU:Loong
/// TM:2017/6/3 12:17:57
/// BG:
/// </summary>
[Serializable]
public class SelectTriggerInfo : SelectInfo
{
    #region 字段
    [SerializeField]
    private string flowTree;

    #endregion

    #region 属性

    /// <summary>
    /// 流程树
    /// </summary>
    public string FlowTree
    {
        get { return flowTree; }
        set { flowTree = value; }
    }


    #endregion

    #region 构造方法
    public SelectTriggerInfo()
    {

    }
    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    public override void OnGUI(UnityEngine.Object obj)
    {
        if (FlowTree == null)
        {
            EditorGUILayout.LabelField("流程树为空");
        }
        else
        {
            EditorGUILayout.LabelField(FlowTree);
        }
    }
    #endregion
}