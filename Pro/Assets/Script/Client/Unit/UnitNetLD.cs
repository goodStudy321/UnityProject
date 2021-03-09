using System;
using UnityEngine;
using Loong.Game;

public class UnitNetLD
{
    #region 字段
    private ActorData mapActor;
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置角色
    /// </summary>
    private void SetRole(Unit u,UnitType unitType)
    {
        if (unitType != UnitType.Role)
            return;
        OrnamentsMgr.instance.CreateOrnaments(u, mapActor);
        OffLineBatMgr.instance.AddBatControl(u);
        string name = UnitHelper.instance.GetUnitFullName(mapActor);
        //string title = TitleHelper.instance.GetTitleStr(mapActor);
        //TopBarFty.Create(u, name, title, mapActor.Title, mapActor);
        TopBarFty.Create(u, name, string.Empty, mapActor.Title, mapActor);
        UnitStateOnline unitStateOnline = (UnitStateOnline)mapActor.Status;
        if (unitStateOnline == UnitStateOnline.Dead)
        {
            u.ActionStatus.ChangeDeathAction();
            return;
        }
        UnitMgr.instance.UpdAtkUnitList(u, true);
    }

    /// <summary>
    /// 设置怪物
    /// </summary>
    private void SetMons(Unit u,UnitType unitType)
    {
        if (unitType != UnitType.Monster && unitType != UnitType.Boss)
            return;
        UnitMgr.instance.UpdAtkUnitList(u, true);
        if (mapActor.MonsterExtra.battle_owner != 0)
            CamBatMgr.instance.SetPileInfo(u, long.MaxValue);
        else
        {
            if (u.Camp == (CampType)User.instance.MapData.Camp)
            {
                TopBarFty.Create(u, u.Name);
            }
        }
        if (u.Camp != (CampType)User.instance.MapData.Camp)
        {
            EventMgr.Trigger(EventKey.UpdateCopyCreate, u.TypeId);
        }
        if (mapActor.MonsterExtra.countdown != 0)
            u.mUnitTimer.Start(u, mapActor.MonsterExtra.countdown);
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置数据
    /// </summary>
    /// <param name="mapActor"></param>
    public void SetData(ActorData mapActor)
    {
        this.mapActor = mapActor;
    }
    /// <summary>
    /// 加载完成
    /// </summary>
    /// <param name="obj"></param>
    public void LoadDone(Unit u)
    {
        UnitMgr.instance.SetAttr(u, mapActor);
        u.ServerId = mapActor.ServerID;
        PendantMgr.instance.CreatePendants(u, mapActor);
        u.mBuffManager.InitBuff(mapActor);
        UnitType unitType = u.mUnitAttInfo.UnitType;
        SetRole(u, unitType);
        SetMons(u, unitType);
        QualityMgr.instance.DisplayCtrl.AddShowUnit(u);

        Dispose();
    }

    /// <summary>
    /// 释放资源
    /// </summary>
    public void Dispose()
    {
        mapActor = null;
        ObjPool.Instance.Add(this);
    }
    #endregion
}
