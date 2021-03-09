using UnityEngine;
//using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// ���Ϳ�
/// </summary>
public class PathPortal
{
    public enum PortalType
    {
        PT_Unknown = 0,
        PT_Inside,                  /* ͼ�� */
        PT_Outside,                 /* ͼ�� */
        PT_Max
    }

    /// <summary>
    /// ���Ϳ�����
    /// </summary>
    public PortalType mType = PortalType.PT_Unknown;
    /// <summary>
    /// ����ID
    /// </summary>
    public uint mIndex = 0;
    /// <summary>
    /// ���Ϳ�����
    /// </summary>
    public string mProtalName = "";
    /// <summary>
    /// ���Ϳ�λ��
    /// </summary>
    public Vector3 mPostion = Vector3.zero;

    /// <summary>
    /// ���ӵ�ͼId
    /// </summary>
    public uint mLinkMapId = 0;
    /// <summary>
    /// ���Ӵ��Ϳ�Id
    /// </summary>
    public uint mLinkPortalId = 0;
}