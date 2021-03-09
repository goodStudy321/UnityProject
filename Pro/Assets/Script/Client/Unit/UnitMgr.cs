using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Loong.Game;
using Phantom.Protocal;

/// <summary>
/// 单位管理
/// </summary>
public class UnitMgr 
{
    public static readonly UnitMgr instance = new UnitMgr();

    private UnitMgr()
    {

    }
    #region 私有成员变量
    private List<Unit> mUnitList = new List<Unit>();
    #endregion

    #region 属性
    public List<Unit> UnitList
    {
        get { return mUnitList; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 添加单位
    /// </summary>
    /// <param name="unit"></param>
    public void AddUnit(Unit unit)
    {
        if (mUnitList.Contains(unit))
            return;
        mUnitList.Add(unit);
    }

    /// <summary>
    /// 删除单位
    /// </summary>
    public void RemoveUnit(Unit unit)
    {
        if (mUnitList.Contains(unit))
            mUnitList.Remove(unit);

        QualityMgr.instance.DisplayCtrl.RemoveShowUnit(unit);
    }

    /// <summary>
    /// 根据Uid删除单位
    /// </summary>
    /// <param name="Uid"></param>
    public void RemoveUnitByUid(long Uid)
    {
        for (int i = 0; i < mUnitList.Count; i++)
        {
            Unit unit = mUnitList[i];
            if (mUnitList[i].UnitUID != Uid)
                continue;
            SelectRoleMgr.instance.RemoveUnit(unit.UnitUID);
            if (unit.Dead && unit.mUnitAttInfo.UnitType != UnitType.Role)
                continue;
            unit.Destroy();
        }
    }

    /// <summary>
    /// 根据UID设置单位死亡
    /// </summary>
    /// <param name="unitUid"></param>
    public void SetUnitDeadByUid(long unitUid)
    {
        Unit unit = FindUnitByUid(unitUid);
        SetUnitDead(unit);
    }

    /// <summary>
    /// 设置死亡
    /// </summary>
    public void SetUnitDead(Unit unit)
    {
        if (unit == null)
            return;
        unit.HP = 0;
        UpdAtkUnitList(unit, false);
        SelectRoleMgr.instance.RemoveUnit(unit.UnitUID);
        BossBatMgr.instance.RemoveTarget(unit.UnitUID);
        if (InputMgr.instance.mLockTarget == unit) InputMgr.instance.mLockTarget = null;
        PendantMgr.instance.SetLocalPendantsShowState(unit, false, OpStateType.Revive);
        if (unit.ActionStatus == null)
        {
            RemoveUnitByUid(unit.UnitUID);
            return;
        }
        if (unit.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Dead)
            return;
        unit.mUnitMove.StopNav(false);
        unit.ActionStatus.ChangeDeadAction();
        UnitHelper.instance.SetDeadForward(unit);
        EventMgr.Trigger("OnUnitDead", unit.TypeId ,unit.Position);

        if (unit.UnitUID != User.instance.MapData.UID)
            return;
        User.instance.ResetCamera();
    }

    /// <summary>
    /// 设置单位复活
    /// </summary>
    /// <param name="unit"></param>
    public void SetUnitRevive(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.ActionStatus == null)
            return;
        UpdAtkUnitList(unit, true);
        unit.HP = unit.MaxHP;
        unit.ActionStatus.ChangeIdleAction();
        PendantMgr.instance.SetLocalPendantsShowState(unit, true, OpStateType.Revive);
        if(unit.UnitUID == User.instance.MapData.UID)
            EventMgr.Trigger(EventKey.UnitRevive);
    }

    /// <summary>
    /// 更新攻击单位列表
    /// </summary>
    /// <param name="unit"></param>
    public void UpdAtkUnitList(Unit unit,bool add)
    {
        if (unit == null)
            return;
        if (unit.UnitUID == User.instance.MapData.UID)
            return;
        UnitType unitType = unit.mUnitAttInfo.UnitType;
        if (unitType != UnitType.Role && unitType != UnitType.Boss)
            return;
        if (add == true)
        {
            int level = 0;
            int sex = 0;
            User user = User.instance;
            if (unitType == UnitType.Role)
            {
                if (!user.OtherRoleDic.ContainsKey(unit.UnitUID))
                    return;
                ActorData actData = user.OtherRoleDic[unit.UnitUID];
                if (actData != null)
                {
                    level = actData.Level;
                    sex = actData.Sex;
                }
            }
            else if(unitType == UnitType.Boss)
            {
                if (!user.MonsterDic.ContainsKey(unit.UnitUID))
                    return;
                BossBatMgr.instance.SetCurBossId(unit.UnitUID);
                ActorData actData = user.MonsterDic[unit.UnitUID];
                if (actData != null)
                    level = actData.Level;
            }
            EventMgr.Trigger(EventKey.OnUpdateUnit, unit, level, sex, true);
        }
        else
            EventMgr.Trigger(EventKey.OnUpdateUnit, unit, 0, 0, false);
    }

    /// <summary>
    /// 更新攻击自己的单位
    /// </summary>
    /// <param name="atker"></param>
    public void UpdateAtkSelfUnit(Unit atker)
    {
        if (atker == null)
            return;
        UnitType unitType = atker.mUnitAttInfo.UnitType;
        if (unitType != UnitType.Role)
            return;
        EventMgr.Trigger("AtkSelfUnit", atker.UnitUID);
    }

    /// <summary>
    /// 刷新单位动作数据
    /// </summary>
    public void RefreshUnitActionSetup()
    {
        for (int i = 0; i < UnitList.Count; i++)
        {
            Unit unit = UnitList[i];
            unit.RefreshUnitActionSetup();
        }
    }

    /// <summary>
    /// 创建主单位
    /// </summary>
    /// <param name="unitId"></param>
    /// <param name="pos"></param>
    /// <param name="camp"></param>
    /// <param name="callBack"></param>
    /// <returns></returns>
    public Unit CreateMainPlayer(long uid, UInt32 typeId,string name, Vector3 pos, float eulerAngleY, CampType camp, Action<Unit> callBack = null)
    {
        Unit player = CreateUnit(uid, typeId, name, pos,eulerAngleY, camp, callBack);
        ActorData actData = User.instance.MapData;
        player.MaxHP = actData.MaxHp;
        player.HP = actData.Hp;
        player.ServerId = actData.ServerID;
        UISkill.instance.InitUnit(player);
        if (Global.Mode == PlayMode.Local)
            UISkill.instance.InitSkillData();
        return player;
    }

    /// <summary>
    /// 创建单位
    /// </summary>
    public Unit CreateUnit(long uid, UInt32 typeId,string name,Vector3 pos,float eulerAngleY, CampType camp, Action<Unit> callBack = null,string bornAction = null)
    {
        Unit unit = ObjPool.Instance.Get<Unit>();
        unit.SetData(uid, typeId, name, camp);
        AddUnit(unit);
        AddSkill(unit);
        unit.LoadMod(pos,eulerAngleY,bornAction,callBack);
        return unit;
    }

    /// <summary>
    /// 创建自己
    /// </summary>
    /// <param name="name"></param>
    /// <param name="unitTypeId"></param>
    /// <param name="bornPos"></param>
    /// <param name="eulerAngleY"></param>
    public void CreateOwner(string name,uint unitTypeId,Vector3 bornPos,float eulerAngleY)
    {
        Unit owner = InputMgr.instance.mOwner;
        CampType camp = (CampType)User.instance.MapData.Camp;
        UnitOwnerLD ownerLD = UnitOwnerLD.instance;
        if (owner == null)
        {
            PendantMgr.instance.Init();
            ownerLD.SetData(name);
            Unit mainPlayer = CreateMainPlayer(User.instance.MapData.UID, unitTypeId, name, bornPos, eulerAngleY, camp, ownerLD.LoadDone);
            SkillManager.instance.InitSkill(mainPlayer);
        }
        else
        {
            ownerLD.ResetOwner(owner,camp,bornPos,eulerAngleY);
        }
    }
    /// <summary>
    /// 设置属性
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="actorData"></param>
    public void SetAttr(Unit unit,ActorData actorData)
    {
        unit.MaxHP = actorData.MaxHp;
        unit.HP = actorData.Hp;
        unit.MoveSpeed = actorData.MoveSpeed * 0.01f;
        unit.FightVal = actorData.AllFightValue;
        unit.TeamId = actorData.TeamID;
        unit.FamilyId = actorData.FamilyID;
        unit.Category = actorData.Category;
    }

    /// <summary>
    /// 从列表里面创建所有网络单位（除自己以外）
    /// </summary>
    public void CreateAllNetUnit()
    {
        foreach(KeyValuePair<long, ActorData> item in User.instance.OtherRoleDic)
            CreateNetUnit(item.Value);

        foreach (KeyValuePair<long, ActorData> item in User.instance.MonsterDic)
            CreateNetUnit(item.Value, item.Value.MonsterExtra.action_string);

        foreach (KeyValuePair<long, ActorData> item in User.instance.SummonDic)
            CreateNetUnit(item.Value);
    }

    /// <summary>
    /// 创建网络单位（除自己外）
    /// </summary>
    /// <param name="mapActor"></param>
    public void CreateNetUnit(ActorData mapActor, string bornAction = null)
    {
        if (FindUnitByUid(mapActor.UID) != null)
            return;
        CampType camp = (CampType)mapActor.Camp;
        UInt32 unitTypeId = UnitHelper.instance.GetNetUnitTypeId(mapActor);
        Vector3 bornPos = NetMove.GetPositon(mapActor.Pos);
        UnitNetLD unitNetLD = ObjPool.Instance.Get<UnitNetLD>();
        unitNetLD.SetData(mapActor);
        CreateUnit(mapActor.UID, unitTypeId, mapActor.Name, bornPos, NetMove.Getdir(mapActor.Pos), camp, unitNetLD.LoadDone,bornAction);
    }

    /// <summary>
    /// 根据Uid查找单位
    /// </summary>
    /// <param name="uid"></param>
    /// <returns></returns>
    public Unit FindUnitByUid(long uid)
    {
        Unit unit = mUnitList.Find((Unit u) => { return u.UnitUID == uid; });
        return unit;
    }

    /// <summary>
    /// 查找第一个具有指定BaseID的单位
    /// </summary>
    /// <param name="baseID"></param>
    /// <returns></returns>
    public Unit FindByBaseID(ushort baseID)
    {
        int length = UnitList.Count;
        for (int i = 0; i < length; i++)
        {
            Unit unit = UnitList[i];
            if (unit.ModelId == baseID) return unit;
        }
        return null;
    }

    /// <summary>
    /// 查找第一个具有指定BaseID的单位
    /// </summary>
    /// <param name="baseID"></param>
    /// <returns></returns>
    public Unit FindByBaseID(int baseID)
    {
        ushort ubaseID = (ushort)baseID;
        return FindByBaseID(ubaseID);
    }

    /// <summary>
    /// 根据单位类型ID查找
    /// </summary>
    /// <param name="unitTypeID"></param>
    /// <returns></returns>
    public Unit FindByTypeID(int unitTypeID)
    {
        int length = UnitList.Count;
        for (int i = 0; i < length; i++)
        {
            Unit unit = UnitList[i];
            if (unit.TypeId == unitTypeID) return unit;
        }
        return null;
    }

    /// <summary>
    /// 找出当前场景中所有敌方阵营Boss
    /// </summary>
    /// <returns></returns>
    public List<long> FindAllBoss()
    {
        List<long> list = new List<long>();
        int length = UnitList.Count;
        for (int i = 0; i < length; i++)
        {
            Unit unit = UnitList[i];
            if (unit.mUnitAttInfo.UnitType == UnitType.Boss && (int)unit.Camp != User.instance.MapData.Camp)
            {
                list.Add(unit.UnitUID);
            }
        }
        return list;
    }

    /// <summary>
    /// 添加技能
    /// </summary>
    public void AddSkill(Unit unit)
    {
        if (Global.Mode == PlayMode.Network)
            return;
        List<uint> carrySkills = UnitHelper.instance.GetTableCarrySkills(unit.TypeId);
        if (carrySkills == null)
            return;
        for (int i = 0; i < carrySkills.Count; i++)
            SkillManager.instance.AddSkill(unit, carrySkills[i],0);
    }
    
    /// <summary>
    /// 设置单位显示隐藏
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="active"></param>
    public void SetUnitActive(Unit unit, bool active, bool setTopBar = true, bool forceTopBar = false)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        unit.UnitTrans.gameObject.SetActive(active);
        Unit parentUnit = unit;
        UnitType type = unit.mUnitAttInfo.UnitType;
        if (type == UnitType.Mount)
        {
            parentUnit = unit.ParentUnit;
            parentUnit.UnitTrans.gameObject.SetActive(active);
        }
        PendantMgr.instance.SetLocalPendantsShowState(parentUnit, active, OpStateType.SetUnitActive);

        if(forceTopBar)
        {
            if (unit.TopBar == null)
            {
                unit.TopBar = TopBarFty.Create(unit, unit.Name);
            }
            if (unit.TopBar != null)
            {
                unit.TopBar.Open();
            }
        }
        else
        {
            if (!setTopBar) return;
            if (unit.TopBar == null) return;
            if (active)
                unit.TopBar.Open();
            else
                unit.TopBar.Close();
        }
    }

    //// LY add begin ////
    /// <summary>
    /// 只设置Unit显示隐藏
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="active"></param>
    public void SetUnitActiveOnly(Unit unit, bool active)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        unit.UnitTrans.gameObject.SetActive(active);
        Unit parentUnit = unit;
        UnitType type = unit.mUnitAttInfo.UnitType;
        if (type == UnitType.Mount)
        {
            parentUnit = unit.ParentUnit;
            parentUnit.UnitTrans.gameObject.SetActive(active);
        }
    }

    //// LY add end ////

    /// <summary>
    /// 单位更新
    /// </summary>
    /// <param name="deltaTime"></param>
    public void Update(float deltaTime)
    {
        for (int i = 0; i < mUnitList.Count; i++)
        {
            Unit unit = mUnitList[i];
            if (unit == null) continue;
            unit.Update(deltaTime);
        }
    }

    /// <summary>
    /// 单位更新
    /// </summary>
    /// <param name="deltaTime"></param>
    public void LateUpdate()
    {
        for (int i = 0; i < mUnitList.Count; i++)
        {
            Unit unit = mUnitList[i];
            if (unit == null) continue;
            unit.LateUpdate();
        }
    }

    /// <summary>
    /// 释放资源
    /// </summary>
    public void Dispose(bool isAll = false)
    {
        InputMgr.instance.ClearAllCtrlData();
        for(int i = 0; i < mUnitList.Count;)
        {
            Unit unit = mUnitList[i];
            if (unit == null)
            {
                mUnitList.RemoveAt(i); continue;
            }
            if (!isAll)
            {
                if(UnitHelper.instance.IsOwner(unit))
                {
                    unit.DestroySmmn();
                    unit.DestroyHitDef();
                    unit.mUnitEffects.Destroy();
                    i++; continue;
                }
            }

            mUnitList.RemoveAt(i);
            unit.Destroy();
        }
    }

    /// <summary>
    /// 切换创建时创建场景对象
    /// </summary>
    /// <param name="isCreateOther"></param>
    public void CreateSceneUnit(bool isCreateOther = true)
    {
        Vector3 bornPos = Vector3.zero;
        float eulerAngleY = 0;
        string name = "Hero";
        UInt32 unitTypeId = 0;
        if (User.instance.MapData != null)
        {
            ActorData data = User.instance.MapData;
            bornPos = NetMove.GetPositon(data.Pos);
            eulerAngleY = NetMove.Getdir(data.Pos);
            name = data.Name;
            unitTypeId = data.UnitTypeId;
        }
        if (Global.Mode == PlayMode.Local)
        {
            unitTypeId = 10001;
            bornPos = new Vector3(27, 10, 36);
            eulerAngleY = 38;
        }
        CreateOwner(name,unitTypeId,bornPos,eulerAngleY);
        CreateAllNetUnit();
    }

    //// LY add begin ////

    /// <summary>
    /// 预创建主角
    /// </summary>
    /// <param name="pos"></param>
    public void PreCreateOwner(long pos)
    {
        Vector3 bornPos = NetMove.GetPositon(pos);
        float eulerAngleY = NetMove.Getdir(pos);

        Unit owner = InputVectorMove.instance.MoveUnit;
        if(owner != null)
        {
            owner.Position = bornPos;
            owner.UnitTrans.localEulerAngles = new Vector3(0, eulerAngleY, 0);
            owner.DirectlySetOrientation();
        }
    }

    /// <summary>
    /// 重置称号和境界
    /// </summary>
    public void ResetTtlAndCfn()
    {
        Unit owner = InputMgr.instance.mOwner;
        ActorData actData = User.instance.MapData;
        SetTtlAndCfn(owner, actData);
        Dictionary<long, ActorData> dic = User.instance.OtherRoleDic;
        foreach(KeyValuePair<long,ActorData> item in dic)
        {
            Unit unit = FindUnitByUid(item.Key);
            SetTtlAndCfn(unit, item.Value);
        }
    }

    /// <summary>
    /// 设置称号和境界
    /// </summary>
    /// <param name="actData"></param>
    /// <param name="unit"></param>
    public void SetTtlAndCfn(Unit unit, ActorData actData)
    {
        if (UnitHelper.instance.UnitIsNull(unit))
            return;
        if (actData == null)
            return;
        TitleHelper.instance.ChgConfine(unit, actData.Confine);
        actData.Title = actData.Title;
    }

    /// <summary>
    /// 设置主角到指定子节点位置
    /// </summary>
    /// <param name="childName"></param>
    public void SetOwnerToChildNodePos(string childName)
    {
        Unit ownerUnit = InputVectorMove.instance.MoveUnit;
        if(ownerUnit == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Owner unit miss !!! ");
#endif
            return;
        }

        GameObject childObj = Utility.FindNode(ownerUnit.UnitTrans.gameObject, childName);
        if(childObj == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "Can not find child node !!! " + childName);
#endif
            return;
        }
        
        RaycastHit hitTerrain;
        Vector3 position = new Vector3(childObj.transform.position.x, 10 + childObj.transform.position.y, childObj.transform.position.z);
        Ray ray = new Ray(position, Vector3.down);
        if (Physics.Raycast(ray, out hitTerrain, 100, 1 << LayerMask.NameToLayer("Ground")))
        {
            position = new Vector3(position.x, hitTerrain.point.y, position.z);
        }
        NetMove.RequestChangePosDir(ownerUnit, position);
        ownerUnit.Position = position;
    }

    //// LY add end ////

    /// <summary>
    /// 设置单位资源永久保存
    /// </summary>
    /// <param name="unit"></param>
    public void SetUnitAllAssetsPersist(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.UnitTrans == null)
            return;
        if (unit.mUnitAttInfo == null)
            return;
        RoleBase roleBase = unit.mUnitAttInfo.RoleBaseTable;
        if (roleBase == null)
            return;
        UnityEngine.Object.DontDestroyOnLoad(unit.UnitTrans.gameObject);
        AssetMgr.Instance.SetPersist(roleBase.modelPath, Suffix.Prefab);
    }
#endregion
}