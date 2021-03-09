using UnityEngine;
//using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// 传送口
/// </summary>
public class PathPortal
{
    public enum PortalType
    {
        PT_Unknown = 0,
        PT_Inside,                  /* 图内 */
        PT_Outside,                 /* 图外 */
        PT_Max
    }

    /// <summary>
    /// 传送口类型
    /// </summary>
    public PortalType mType = PortalType.PT_Unknown;
    /// <summary>
    /// 索引ID
    /// </summary>
    public uint mIndex = 0;
    /// <summary>
    /// 传送口名称
    /// </summary>
    public string mProtalName = "";
    /// <summary>
    /// 传送口位置
    /// </summary>
    public Vector3 mPostion = Vector3.zero;

    /// <summary>
    /// 链接地图Id
    /// </summary>
    public uint mLinkMapId = 0;
    /// <summary>
    /// 链接传送口Id
    /// </summary>
    public uint mLinkPortalId = 0;
}