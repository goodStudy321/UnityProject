using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class DefaultWpCB
{
    #region 私有字段
    private Unit unit;
    private string name;
    #endregion

    #region 公有方法
    public void Set(Unit unit,string name)
    {
        this.unit = unit;
        this.name = name;
    }
    /// <summary>
    /// 加载完成回调
    /// </summary>
    /// <param name="obj"></param>
    public void LoadCB(GameObject obj)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        if (obj == null)
            return;
        Transform trans = obj.transform;
        trans.parent = null;
        obj.SetActive(true);
        if (!PendantMgr.instance.MountPointDic.ContainsKey(MountPoint.RightHand)) return;
        string mountPoint = PendantMgr.instance.MountPointDic[MountPoint.RightHand];
        Transform parent = Utility.FindNode<Transform>(unit.UnitTrans.gameObject, mountPoint);
        TransTool.AddChild(parent, trans);
        unit.DefaultWeaponMod = trans;
        if (unit.UnitUID != User.instance.MapData.UID)
            return;
        AssetMgr.Instance.SetPersist(name, Suffix.Prefab);
    }
    #endregion
}
