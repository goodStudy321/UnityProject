using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        30a0662f-37c6-4bfa-8e0b-f675905ed995
*/

/// <summary>
/// AU:Loong
/// TM:2017/3/13 14:50:06
/// BG:静态批处理工具
/// </summary>
public static class StaticBatchTool
{
    #region 字段

    #endregion

    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法

    #endregion

    #region 保护方法

    #endregion

    #region 公开方法
    /// <summary>
    /// 设置静态批处理
    /// </summary>
    public static IEnumerator YeildSet()
    {
        yield return new WaitForEndOfFrame();
        GameObject[] gos = GameObject.FindGameObjectsWithTag(TagTool.StaticObject);
        GameObject go = null;
        GameObject root = null;
        for (int i = 0; i < gos.Length; i++)
        {
            go = gos[i];
            if (go == null) continue;
            root = TransTool.Find(go, "Root/Static");
            if (root == null) continue;
            bool active = root.activeSelf;
            root.SetActive(true);
            StaticBatchingUtility.Combine(root);
            root.SetActive(active);
        }
    }

    public static void Set()
    {
        MonoEvent.Start(YeildSet());
    }
    #endregion
}