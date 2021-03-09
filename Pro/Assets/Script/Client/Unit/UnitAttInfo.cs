using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class UnitAttInfo
{
    #region ˽�б���
    RoleBase mRoleBase;
    NPCInfo mNpc;
    UInt32 mUnitTypeId;
    #endregion

    #region ����

    public NPCInfo Npc
    {
        get
        {
            if (mNpc == null) mNpc = NPCInfoManager.instance.Find(UnitTypeId);
            return mNpc;
        }
    }

    /// <summary>
    /// ��λģ�ͱ�
    /// </summary>
    public RoleBase RoleBaseTable
    {
        get
        {
            if (mRoleBase != null)
                return mRoleBase;
            SetRoleBase();
            return mRoleBase;
        }
    }

    /// <summary>
    /// ��λ����ID
    /// </summary>
    public UInt32 UnitTypeId
    {
        get { return mUnitTypeId; }
        set
        {
            mUnitTypeId = value;
            SetRoleBase();
        }
    }

    /// <summary>
    /// ��ɫ����
    /// </summary>
    public UnitType UnitType
    {
        get
        {
            if (RoleBaseTable == null)
                return UnitType.None;
            return (UnitType)RoleBaseTable.characterType;
        }
    }

    /// <summary>
    /// ��λ��
    /// </summary>
    public string RoleName
    {
        get
        {
            if (RoleBaseTable == null)
                return null;
            return RoleBaseTable.roleName;
        }
    }
    #endregion

    #region ˽�з���
    /// <summary>
    /// ���ý�ɫ������
    /// </summary>
    private void SetRoleBase()
    {
        ushort modelId = UnitHelper.instance.GetUnitModeId(UnitTypeId);
        mRoleBase = RoleBaseManager.instance.Find(modelId);
    }
    #endregion

    #region ���з���
    public void Dispose()
    {
        mUnitTypeId = 0;
        mNpc = null;
        mRoleBase = null;
    }
    #endregion
}
