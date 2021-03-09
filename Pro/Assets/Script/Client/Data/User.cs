using Loong.Game;
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;

public partial class User
{
    public static readonly User instance = new User();

    private User()
    {

    }
    #region 分包

    public int oriScreenWd = 0;

    public int oriScreenHt = 0;

    public bool SubAssetIsOver
    {
        get
        {
#if LOONG_SUB_ASSET
            return PackDl.Instance.IsOver;
#else
            return true;
#endif
        }
    }

    public int ScreenOrient
    {
        get { return (int)Screen.orientation; }
    }
    #endregion

    #region 服务器信息
    private string serverID = "0";
    public const string DNSKey = ".com";
    public string ServerID
    {
        get { return serverID; }
        set
        {
            if (string.IsNullOrEmpty(value))
            {
                serverID = "0";
            }
            else if (string.IsNullOrEmpty(value.Trim()))
            {
                serverID = "0";
            }
            else
            {
                serverID = value;
            }
        }
    }
    public string ServerName;
    public string IP;
    public int Port;
    public long Time;
    public long ServerTime;
    private string uid = "0";
    #endregion

    #region 第一次加載場景

    public bool IsInitLoadScene = true;

    #endregion

    #region 基础信息
    public bool IsCreateScene = true;

    public bool EnableLog
    {
        get { return iTrace.Enable; }
        set { iTrace.Enable = value; }
    }

    /// <summary>
    /// 账号
    /// </summary>
    public string Account
    {
        set
        {
            PlayerPrefs.SetString("Account", value);
        }
        get
        {
            return PlayerPrefs.GetString("Account");
        }
    }

    public string Password
    {
        set
        {
            PlayerPrefs.SetString("Password", value);
        }
        get
        {
            return PlayerPrefs.GetString("Password");
        }
    }

    public string EnterRecord
    {
        set
        {
            PlayerPrefs.SetString("EnterRecord", value);
        }
        get
        {
            return PlayerPrefs.GetString("EnterRecord");
        }
    }

    public bool InJump
    {
        get
        {
            if (InputMgr.instance.mOwner == null)
                return false;

            if (InputMgr.instance.mOwner.mUnitMove == null)
                return false;

            return InputMgr.instance.mOwner.mUnitMove.IsJumping;
        }
    }

    public string ChannelID = "0";
    public string GameChannelId = "0";

    /// <summary>
    /// 账号UID
    /// </summary>
    public string UID
    {
        get { return uid; }
        set { uid = value; }
    }

#endregion

#region 緩存信息
    public int VIPLV = 0;
    public string FamilyName = "unknown";
#endregion

#region 场景信息
    private int mSceneId;
    /// <summary>
    /// 场景Id
    /// </summary>
    public int SceneId
    {
        set
        {
            mSceneId = value;
        }
        get
        {
            return mSceneId;
        }
    }

    private long mExtraId;
    /// <summary>
    /// 场景分线Id
    /// </summary>
    public long ExtraId
    {
        set
        {
            mExtraId = value;
        }
        get
        {
            return mExtraId;
        }
    }

    public string ExtraIdStr
    {
        get
        {
            return mExtraId.ToString();
        }
    }

    private ActorData mMapData;
    /// <summary>
    /// 当前地图自己的信息
    /// </summary>
    public ActorData MapData
    {
        get
        {
            if (mMapData == null) mMapData = ObjPool.Instance.Get<ActorData>();
            return mMapData;
        }
    }

    public Vector3 Pos
    {
        get
        {
            Unit owner = InputVectorMove.instance.MoveUnit;
            if (owner != null && owner.UnitTrans != null)
            {
                return owner.UnitTrans.position;
            }
            return Vector3.zero;
        }
    }

    public string Mod
    {
        get
        {
            uint id = MapData.UnitTypeId;
            RoleAtt att = RoleAttManager.instance.Find(id);
            if (att == null)
            {
                iTrace.eError("HS", string.Format("角色配置表中没有找到Id：{0}的数据", id));
                return "";
            }
            RoleBase role = RoleBaseManager.instance.Find(att.modelId);
            if (role == null)
            {
                iTrace.eError("HS", string.Format("模型配置表中没有找到Id：{0}的数据", att.modelId));
                return "";
            }
            if (String.IsNullOrEmpty(role.uiModel))
            {
                return role.modelPath;
            }
            return role.uiModel;
            //             if (InputMgr.instance.mOwner == null || InputMgr.instance.mOwner.mUnitAttInfo == null ||
            //                 InputMgr.instance.mOwner.mUnitAttInfo.RoleBaseTable == null) return string.Empty;
            //             return InputMgr.instance.mOwner.mUnitAttInfo.RoleBaseTable.modelPath;
        }
    }

    /// <summary>
    /// 其他角色
    /// </summary>
    public Dictionary<long, ActorData> OtherRoleDic = new Dictionary<long, ActorData>();
    /// <summary>
    /// 怪物队列
    /// </summary>
    public Dictionary<long, ActorData> MonsterDic = new Dictionary<long, ActorData>();
    /// <summary>
    /// 召唤体列表
    /// </summary>
    public Dictionary<long, ActorData> SummonDic = new Dictionary<long, ActorData>();
    //     /// <summary>
    //     /// 所有属性的数据
    //     /// </summary>
    //     public List<ActorData> AllList = new List<ActorData>();
#endregion

#region 系统开启状态
    private List<int> mSystemOpenList;
    public List<int> SystemOpenList
    {
        get
        {
            if (mSystemOpenList == null) mSystemOpenList = new List<int>();
            return mSystemOpenList;
        }

        set
        {
            if (mSystemOpenList == null) mSystemOpenList = new List<int>();
            mSystemOpenList = value;
        }
    }
    public void AddSystemOpen(int systemId)
    {
        if (SystemOpenList.Contains(systemId))
            return;
        SystemOpenList.Add(systemId);
    }

    private List<int> mCurOpenSystem = new List<int>();
    public List<int> CurOpenSystem
    {
        set { mCurOpenSystem = value; }
        get { return mCurOpenSystem; }
    }
#endregion

    /// <summary>
    /// 是否锁死摄像机旋转
    /// </summary>
    public bool IsLockCameraRota = false;


    /// <summary>
    /// 是否显示其他玩家称号
    /// </summary>
    private bool isShowTitle = true;
    /// <summary>
    /// 是否显示其他玩家称号
    /// </summary>
    public bool IsShowTitle
    {
        set
        {
            isShowTitle = value;
            EventMgr.Trigger(EventKey.OnChgTtileState, isShowTitle);
        }
        get
        {
            return isShowTitle;
        }
    }

#region 初始化
    public void Init()
    {
        // MissionInit();
    }
#endregion

#region 更新地图里的数据
    public void UpdateSliceMapActor(List<p_map_actor> actors)
    {
        if (actors == null || IsMissionFlowChart || actors.Count == 0) return;
        p_map_actor actor;
        for (int i = 0; i < actors.Count; i++)
        {
            actor = actors[i];
            UnitType unitType = (UnitType)actor.actor_type;
            if (unitType == UnitType.Role)
            {
                //自己
                if (actor.actor_id == MapData.UID)
                {
                    MapData.UpdateActor(actor);
                }
                else
                {
                    UpateActorList(actor, ref OtherRoleDic);
                }
            }
            else if (unitType == UnitType.Monster)
            {
                UpateActorList(actor, ref MonsterDic);
            }
            else if (unitType == UnitType.Collection)
            {
                CollectionMgr.Create(actor);
            }
            else if (unitType == UnitType.Summon)
            {
                UpateActorList(actor, ref SummonDic);
            }
            else if (unitType == UnitType.DropItem)
            {
                DropMgr.Create(actor);
            }
        }
        if ((UnitType)actors[0].actor_type == UnitType.DropItem)
            DropMgr.CreateHitEff();
    }

    public void DeleteSliceMapActor(List<long> list)
    {
        for (int i = 0; i < list.Count; i++)
        {
            long uid = list[i];
            ActorData actData = null;
            if (OtherRoleDic.ContainsKey(uid))
            {
                actData = OtherRoleDic[uid];
                OtherRoleDic.Remove(uid);
                UnitMgr.instance.RemoveUnitByUid(uid);
                AddObjToPool(actData);
                continue;
            }
            if (MonsterDic.ContainsKey(uid))
            {
                actData = MonsterDic[uid];
                PickIcon.DestroyPickIcon(uid);
                MonsterDic.Remove(uid);
                UnitMgr.instance.RemoveUnitByUid(uid);
                AddObjToPool(actData);
                continue;
            }
            if (SummonDic.ContainsKey(uid))
            {
                actData = SummonDic[uid];
                SummonDic.Remove(uid);
                UnitMgr.instance.RemoveUnitByUid(uid);
                AddObjToPool(actData);
                continue;
            }

            if (CollectionMgr.Remove(uid)) continue;

            if (DropMgr.DisposeDrop((ulong)uid)) continue;
        }
    }

    /// <summary>
    /// 清理单位数据字典
    /// </summary>
    /// <param name="dic"></param>
    private void ClearActDataDic(Dictionary<long, ActorData> dic)
    {
        if (dic == null)
            return;
        foreach (KeyValuePair<long, ActorData> item in dic)
            AddObjToPool(item.Value);
        dic.Clear();
    }

    /// <summary>
    /// 添加对象到对象池
    /// </summary>
    /// <param name="actData"></param>
    private void AddObjToPool(ActorData actData)
    {
        if (actData == null)
            return;
        actData.Clear();
        ObjPool.Instance.Add(actData);
    }

    /// <summary>
    /// 更新队列
    /// </summary>
    /// <param name="data"></param>
    /// <param name="dic"></param>
    private void UpateActorList(p_map_actor data, ref Dictionary<long, ActorData> dic)
    {
        if (!dic.ContainsKey(data.actor_id))
        {
            ActorData actData = ObjPool.Instance.Get<ActorData>();
            actData.UpdateActor(data);
            dic.Add(data.actor_id, actData);
        }
        else
        {
            dic[data.actor_id].UpdateActor(data);
        }
        if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneLoading)
            return;
        string bornAction = null;
        if (dic == User.instance.MonsterDic)
            bornAction = dic[data.actor_id].MonsterExtra.action_string;
        UnitMgr.instance.CreateNetUnit(dic[data.actor_id], bornAction);
    }

    //     /// <summary>
    //     /// 更新单个角色对象信息
    //     /// </summary>
    //     /// <param name="oldData"></param>
    //     /// <param name="newData"></param>
    //     /// <returns></returns>
    //     private p_map_actor UpdateActor(p_map_actor oldData, p_map_actor newData)
    //     {
    // 
    //         return oldData;
    //     }
#endregion

#region 更新角色属性
    public void UpdateProperty(m_map_actor_attr_change_toc resp)
    {

        if (MapData != null && MapData.UID == resp.actor_id)
        {
            MapData.UpdateProperty(resp);
            return;
        }
        if (OtherRoleDic.ContainsKey(resp.actor_id))
        {
            OtherRoleDic[resp.actor_id].UpdateProperty(resp);
            return;
        }
        if (MonsterDic.ContainsKey(resp.actor_id))
        {
            MonsterDic[resp.actor_id].UpdateProperty(resp);
        }
    }

    /// <summary>
    /// 更新个人属性
    /// </summary>
    /// <param name="resp"></param>
    public void UpdatePersonalPro(m_role_attr_change_toc resp)
    {
        if (MapData == null)
            return;
        MapData.UpdatePersonalPro(resp);
    }

    /// <summary>
    /// 获取数值属性
    /// </summary>
    /// <param name="actor"> 角色类型 </param>
    /// <param name="type"> 属性类型 </param>
    /// <returns></returns>
    public long GetValueProperty(long uid, UnitType unitType, PropertyType type)
    {
        return (long)GetProperty(uid, unitType, type, true);
    }

    /// <summary>
    /// 获取字符串属性
    /// </summary>
    /// <param name="actor"> 角色类型 </param>
    /// <param name="type"> 属性类型 </param>
    /// <returns></returns>
    public string GetStringProperty(long uid, UnitType unitType, PropertyType type)
    {
        return GetProperty(uid, unitType, type, false) as string;
    }

    private object GetProperty(long uid, UnitType unitType, PropertyType type, bool isValue)
    {
        ActorData data = null;
        switch (unitType)
        {
            case UnitType.Role:
                data = OtherRoleDic[uid];
                break;
            case UnitType.Monster:
                data = MonsterDic[uid];
                break;
        }
        if (data != null)
        {
            if (isValue)
            {
                Dictionary<long, long> property = data.ValueProperty;
                if (property != null)
                {
                    if (property.ContainsKey((long)type)) return property[(long)type];
                }
            }
            else
            {
                Dictionary<long, string> property = data.StringProperty;
                if (property != null)
                {
                    if (property.ContainsKey((long)type)) return property[(long)type];
                }
            }
        }
        return 0;
    }
#endregion

#region 清理其他数据
    public void CleanReconnection()
    {
        ClearPlayerNavState(0);
        MissID = 0;
        MissTargetID = 0;
        MissionState = false;
        IsMissionFlowChart = false;
    }

    public void CleanOtherData(bool value = false)
    {
        ClearActDataDic(OtherRoleDic);
        ClearActDataDic(MonsterDic);
        ClearActDataDic(SummonDic);
        if (value)
        {
            IsInitLoadScene = true;
            mSceneId = 0;
            VIPLV = 0;
            FamilyName = "unknown";
            mSceneId = 0;
            if (mMapData != null) mMapData.Clear();
            if (mSystemOpenList != null) mSystemOpenList.Clear();
        }
    }
#endregion

#region 判断是否在安全区
    /// <summary>
    /// 是否在安全区内
    /// </summary>
    /// <returns></returns>
    public bool IsInSaveZone()
    {
        Unit owner = InputMgr.instance.mOwner;
        if (owner == null)
            return false;
        bool result = MapPathMgr.instance.IsSaveZone(owner.Position);
        return result;
    }

    /// <summary>
    /// 是否可攻击在安全区内单位
    /// </summary>
    /// <param name="unitId"></param>
    /// <returns></returns>
    public bool CanHitSafeUnit(long unitId)
    {
        Unit unit = UnitMgr.instance.FindUnitByUid(unitId);
        if (unit == null)
            return false;
        bool result = SkillHelper.instance.CanHitSafeMons(unit);
        return result;
    }
#endregion

    /// <summary>
    /// 根据typeId找到当前场景的所有的uid
    /// </summary>
    /// <param name="uid"></param>
    /// <returns></returns>
    public List<long> FindAllBoss()
    {
        return UnitMgr.instance.FindAllBoss();
    }
    
    /// <summary>
    /// 将九宫格内玩家字典类型转换为List
    /// </summary>
    /// <returns></returns>
    public List<ActorData> GetActorData()
    {
        List<ActorData> actorData = new List<ActorData>();
        foreach (KeyValuePair<long, ActorData> item in OtherRoleDic)
        {
            actorData.Add(item.Value);
        }
        return actorData;
    }

    /// <summary>
    /// 获取离主角最近的采集物坐标
    /// </summary>
    /// <returns></returns>
    public GameObject GetNearestColl(uint typeID, string filterName, bool isFilter = false)
    {
        return CollectionMgr.GetNearest( typeID,  filterName, isFilter);
    }

    public void ResetCamera()
    {
        if (CameraMgr.CamOperation == null)
            return;

        if (CameraMgr.CamOperation is CameraPlayerNewOperation)
        {
            CameraPlayerNewOperation cpNO = CameraMgr.CamOperation as CameraPlayerNewOperation;
            if(cpNO != null)
            {
                cpNO.ResetCamToDefPos();
            }
        }
    }

    public void ResetCameraImd()
    {
        if (CameraMgr.CamOperation == null)
            return;

        if (CameraMgr.CamOperation is CameraPlayerNewOperation)
        {
            CameraPlayerNewOperation cpNO = CameraMgr.CamOperation as CameraPlayerNewOperation;
            if (cpNO != null)
            {
                cpNO.ResetCamToDefPosImd();
            }
        }
    }

    public void UseLockHrzRot(bool useLock)
    {
        if (CameraMgr.CamOperation == null)
            return;

        if (CameraMgr.CamOperation is CameraPlayerNewOperation)
        {
            CameraPlayerNewOperation cpNO = CameraMgr.CamOperation as CameraPlayerNewOperation;
            if (cpNO != null)
            {
                cpNO.UseLockHrzRot = useLock;
            }
        }
    }

    public Unit GetUnit(long uId)
    {
        List<Unit> units = UnitMgr.instance.UnitList;
        for (int i = 0; i < units.Count; i++)
        {
            if (units[i].UnitUID == uId)
                return units[i];
        }
        return null;
    }

}
