using System;
using UnityEngine;
using Loong.Game;

public class UnitLD
{
    #region 字段
    private Unit unit;
    private Vector3 pos;
    private float eulerAngleY;
    private string bornAction;
    private Action<Unit> callBack;
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置数据
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="pos"></param>
    /// <param name="eulerAngleY"></param>
    /// <param name="bornAction"></param>
    /// <param name="callBack"></param>
    public void SetData(Unit unit,Vector3 pos, float eulerAngleY, string bornAction, Action<Unit> callBack)
    {
        this.unit = unit;
        this.pos = pos;
        this.eulerAngleY = eulerAngleY;
        this.bornAction = bornAction;
        this.callBack = callBack;
    }
    /// <summary>
    /// 加载完成
    /// </summary>
    /// <param name="obj"></param>
    public void LoadDone(GameObject obj)
    {
        bool isNull = TransTool.IsNull(obj);
        if (isNull)
        {
            Dispose();
            return;
        }
        if(unit == null)
        {
            Dispose();
            GbjPool.Instance.Add(obj);
            return;
        }
        Unit u = UnitMgr.instance.FindUnitByUid(unit.UnitUID);
        if (u == null)
        {
            Dispose();
            GbjPool.Instance.Add(obj);
            return;
        }
        Transform trans = obj.transform;
        trans.parent = null;
        obj.SetActive(true);
        unit.Init(trans);
        unit.mUnitOutline.SetRenderer(unit);
        UnitHelper.instance.SetRayHitPosition(pos, unit);
        unit.UnitTrans.localEulerAngles = new Vector3(0, eulerAngleY, 0);
        unit.DirectlySetOrientation();
        unit.ActionStatus.ChangeActionGroup(0, bornAction);
        unit.UnitTrans.name = unit.Name + unit.UnitUID;
        SettingMgr.instance.InitRoleShwSt(unit);
        UnitEventMgr.ExecuteCreateDone(unit);
        if (callBack != null) callBack(unit);
        if (unit.UnitUID == User.instance.MapData.UID)
        {
            UnitUpLvEffect.AddUnit(obj);
            UnitStateOnline stateLine = (UnitStateOnline)User.instance.MapData.Status;
            unit.mStateOnLine = stateLine;
        }
        UnitShadowMgr.instance.SetShadow(unit);
        Dispose();
    }

    /// <summary>
    /// 释放资源
    /// </summary>
    public void Dispose()
    {
        unit = null;
        callBack = null;
        ObjPool.Instance.Add(this);
    }
    #endregion
}
