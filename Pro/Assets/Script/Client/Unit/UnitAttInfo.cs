using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class UnitAttInfo
{
    #region 私有变量
    RoleBase mRoleBase;
    NPCInfo mNpc;
    UInt32 mUnitTypeId;
    #endregion

    #region 属性

    public NPCInfo Npc
    {
        get
        {
            if (mNpc == null) mNpc = NPCInfoManager.instance.Find(UnitTypeId);
            return mNpc;
        }
    }

    /// <summary>
    /// 单位模型表
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
    /// 单位类型ID
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
    /// 角色类型
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
    /// 单位名
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

    #region 私有方法
    /// <summary>
    /// 设置角色基础表
    /// </summary>
    private void SetRoleBase()
    {
        ushort modelId = UnitHelper.instance.GetUnitModeId(UnitTypeId);
        mRoleBase = RoleBaseManager.instance.Find(modelId);
    }
    #endregion

    #region 公有方法
    public void Dispose()
    {
        mUnitTypeId = 0;
        mNpc = null;
        mRoleBase = null;
    }
    #endregion
}
