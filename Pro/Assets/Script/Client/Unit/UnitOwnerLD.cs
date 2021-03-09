using UnityEngine;
using Loong.Game;

public class UnitOwnerLD
{
    public static readonly UnitOwnerLD instance = new UnitOwnerLD();

    private UnitOwnerLD() { }
    #region 字段
    private string name = null;
    #endregion

    #region 私有方法
    /// <summary>
    /// 重置动作
    /// </summary>
    /// <param name="unit"></param>
    private void ReSetAct(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.ActionStatus == null)
            return;
        if(unit.ActionStatus.ActionState != ActionStatus.EActionStatus.EAS_Dead)
        {
            if (unit.Mount != null)
                return;
            unit.ActionStatus.ChangeAction("N0000", 0);
            return;
        }
        if (unit.HP <= 0)
        {
            unit.ActionStatus.ChangeDeathAction();
            return;
        }
        unit.ActionStatus.ChangeIdleAction();
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置数据
    /// </summary>
    /// <param name="mapActor"></param>
    public void SetData(string name)
    {
        this.name = name;
    }
    /// <summary>
    /// 加载完成
    /// </summary>
    /// <param name="obj"></param>
    public void LoadDone(Unit unit)
    {
        int sceneId = User.instance.SceneId;
        ActorData mapActor = User.instance.MapData;
        UnitMgr.instance.SetUnitAllAssetsPersist(unit);
        InputMgr.instance.Init(unit);
        name = UnitHelper.instance.GetUnitFullName(mapActor);
        //string title = TitleHelper.instance.GetTitleStr(mapActor);
        //TopBarFty.Create(unit, name, title, mapActor.Title, mapActor);
        TopBarFty.Create(unit, name, string.Empty, mapActor.Title, mapActor);
        UnitMgr.instance.SetAttr(unit, mapActor);
        unit.mBuffManager.InitBuff(mapActor);
        CameraMgr.UpdateOperation(CameraType.Player, unit.UnitTrans);
        PendantMgr.instance.CreatePendants(unit, mapActor);
        OrnamentsMgr.instance.CreateOrnaments(unit, mapActor);
        ActivBatMgr.instance.SetActivMapData(sceneId);
        OffLineBatMgr.instance.AddBatControl(unit);
        CopyBatMgr.instance.Init(unit);
        CameraMgr.RefreshOperation();
        EventMgr.Trigger(EventKey.InitOwner);
        SettingMgr.instance.InitLsnr();
        SettingMgr.instance.StartTimer();

        //#if CS_HOTFIX_ENABLE
        /// LY add begin ///
        PJShadowMgr.Instance.FSShadow.FollowTarget = unit.UnitTrans.gameObject;
        /// LY add end ///
        //#endif

        Dispose();
    }

    /// <summary>
    /// 重置玩家数据
    /// </summary>
    public void ResetOwner(Unit owner, CampType camp,Vector3 bornPos,float eulerAngleY)
    {
        int sceneId = User.instance.SceneId;
        ActorData actorData = User.instance.MapData;
        ActivBatMgr.instance.SetActivMapData(sceneId);
        owner.Camp = camp;
        UnitMgr.instance.SetAttr(owner, actorData);
        Unit moveUnit = InputVectorMove.instance.MoveUnit;
        if (moveUnit != owner)
        {
            moveUnit.Camp = camp;
            moveUnit.Position = bornPos;
            moveUnit.UnitTrans.localEulerAngles = new Vector3(0, eulerAngleY, 0);
            moveUnit.DirectlySetOrientation();
            UnitMgr.instance.SetAttr(moveUnit, actorData);
        }
        else
        {
            owner.Position = bornPos;
            owner.UnitTrans.localEulerAngles = new Vector3(0, eulerAngleY, 0);
            owner.DirectlySetOrientation();
        }
        if (owner.TopBar != null)
        {
            CommenNameBar bar = owner.TopBar as CommenNameBar;
            if (bar != null)
            {
                bar.Server = string.IsNullOrEmpty(actorData.ServerName) ? string.Empty : string.Format("[{0}]", actorData.ServerName);
                bar.UpdateFlamily(TitleHelper.instance.GetTitleStr(actorData));
                bar.UpdateMarry(TitleHelper.instance.GetMarryStr(actorData.MarryName));
                bar.UpdateConfine(actorData.Confine);
                bar.UpdateRebirthStatus(actorData.Level, actorData.ReliveLV);
            }
        }
        CopyBatMgr.instance.Init(owner);
        OffLineBatMgr.instance.AddBatControl(owner);
        OrnamentsMgr.instance.CreateOrnaments(owner, actorData);
        PendantMgr.instance.CreatePendants(owner, actorData);
        CameraMgr.RefreshOperation();
        ReSetAct(owner);
    }

    /// <summary>
    /// 释放资源
    /// </summary>
    public void Dispose()
    {
        name = null;
    }
    #endregion
}
