using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitShadowMgr
{
    public static readonly UnitShadowMgr instance = new UnitShadowMgr();
    private UnitShadowMgr() { }
    #region 公有方法
    /// <summary>
    /// 设置阴影
    /// </summary>
    /// <param name="unit"></param>
    public void SetShadow(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        if (!ChkUnitType(unit))
            return;
        if (unit.UnitUID == User.instance.MapData.UID)
        {
            SetSdState(unit, true);
            return;
        }
        if (unit.ParentUnit != null && unit.ParentUnit.UnitUID == User.instance.MapData.UID)
        {
            SetSdState(unit, true);
            return;
        }
        SetSdState(unit, false);

        if (InputMgr.instance.mOwner != null && InputMgr.instance.mOwner == unit && PJShadowMgr.Instance.FSShadow != null)
        {
            PJShadowMgr.Instance.FSShadow.FollowTarget = unit.UnitTrans.gameObject;
        }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 检查单位类型
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    private bool ChkUnitType(Unit unit)
    {
        UnitType unitType = UnitHelper.instance.GetUnitType(unit.TypeId);
        if (unitType == UnitType.Role)
            return true;
        if (unitType == UnitType.Mount)
            return true;
        if (unitType == UnitType.Pet)
            return true;
        return false;
    }
    /// <summary>
    /// 设置阴影脚本状态
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="owner"></param>
    private void SetSdState(Unit unit, bool owner)
    {
        Transform trans = unit.UnitTrans;
        DShadowCaster[] dscs = trans.GetComponentsInChildren<DShadowCaster>();
        ShadowProjector[] sps = trans.GetComponentsInChildren<ShadowProjector>();
        SetState(dscs, sps,owner);
    }

    /// <summary>
    /// 设置状态
    /// </summary>
    /// <param name="dscs"></param>
    /// <param name="sps"></param>
    /// <param name="owner"></param>
    private void SetState(DShadowCaster[] dscs, ShadowProjector[] sps, bool owner)
    {
        if (dscs != null)
        {
            for (int i = 0; i < dscs.Length; i++)
            {
                dscs[i].ShowSign = owner;
            }
        }
        if (sps != null)
        {
            for (int i = 0; i < sps.Length; i++)
            {
                sps[i].enabled = !owner;
            }
        }
    }
    #endregion
}
