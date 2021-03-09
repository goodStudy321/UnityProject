using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public partial class NPCMgr 
{
    #region 列表
    private List<uint> mNPCIDList = new List<uint>();
    private Dictionary<uint, NPCInfo> mInfoDic = new Dictionary<uint, NPCInfo>();
    private Dictionary<uint, Unit> mNPCDic = new Dictionary<uint, Unit>();
    /// <summary>
    /// NPCClickDic
    /// </summary>
    public Dictionary<uint, NPC> NPCClickDic = new Dictionary<uint, NPC>();  
    #endregion

    #region 对象
    private Unit mSelectNpc;
    private Vector3 mOriForward;
    #endregion

    #region 私有函数
    /// <summary>
    /// 预加载NPC
    /// </summary>
    public void PreloadNPC(List<uint> list)
    {
        NPCInfo info;
        RoleBase role;
        RoleBase uirole;
        for (int i = 0; i < list.Count; i++)
        {
            info = NPCInfoManager.instance.Find(list[i]);
            if (info == null)
            {
                UITip.eError(string.Format("NPC_ID[{0}]不存在！！", list[i]));
                continue;
            }
            AddNPCInfo(info);
            role = RoleBaseManager.instance.Find(info.modeId);
            if (role == null)
            {
                UITip.eError(string.Format("模型ID[{0}]不存在！！", info.modeId));
                continue;
            }
            PreloadMgr.prefab.Add(role.modelPath);
            if (info.uiModeId == 0) continue;
            uirole = RoleBaseManager.instance.Find(info.uiModeId);
            if(uirole != null)
            {
                PreloadMgr.prefab.Add(uirole.modelPath);
            }
        }
    }

    public void CheckLoad(uint npcid)
    {
        if (mNPCIDList.Contains(npcid) == false)
        {
            NPCInfo info = NPCInfoManager.instance.Find(npcid);
            if (info == null)
            {
                UITip.eError(string.Format("NPC_ID[{0}]不存在！！", npcid));
                return;
            }
            AddNPCInfo(info);
            CreateNPC(info);
        }
    }

    /// <summary>
    /// 创建NPC
    /// </summary>
    private void CreateNPC(NPCInfo info)
    {
        CampType camp = (CampType)User.instance.MapData.Camp;
        Unit unit = UnitMgr.instance.CreateUnit(GuidTool.GenDateLong(), info.id, info.name, new Vector3(info.pos.x, info.pos.y, info.pos.z) * 0.01f, (float)info.rot, camp, CreateNPCComplete);
        unit.HP = unit.MaxHP = 100;
        EventMgr.Trigger(EventKey.CreateNPC);
        //NPCRelatedMission(unit);
    }

    /// <summary>
    /// 创建NPC成功
    /// </summary>
    private void CreateNPCComplete(Unit unit)
    {
        NPCInfo info = unit.mUnitAttInfo.Npc;
        unit.UnitTrans.localScale = unit.UnitTrans.localScale * (info.scal / 100.0f);
        string title = unit.mUnitAttInfo.Npc.title;
        string name = unit.Name;
        TopBarFty.Create(unit, name,title);
        NPC npc = UpdateNPCCollider(unit);
        UpdateDisplayZone(npc, unit);
        if (mNPCDic.ContainsKey(unit.TypeId)) return;
        mNPCDic.Add(unit.TypeId, unit);
        mOriForward = unit.UnitTrans.forward.normalized;
        AddRotateScript(unit.UnitTrans.gameObject);
    }

    private NPC UpdateNPCCollider(Unit unit)
    {
        NPCInfo info = unit.mUnitAttInfo.Npc;
        if (info == null) return null;
        GameObject go = new GameObject(LayerTool.NPC.ToString());
        go.name = info.id.ToString();
        go.transform.parent = unit.UnitTrans;
        go.transform.localPosition = Vector3.zero;
        go.layer = LayerMask.NameToLayer("NPC");
        go.tag = TagTool.ObstacleUnit;
        NPC npc = go.AddComponent<NPC>();
        npc.UpdateUnit(unit);
        npc.orignScale = info.scal * 0.01f;
        if (!NPCClickDic.ContainsKey(info.id)) NPCClickDic.Add(info.id, npc);
        CapsuleCollider unitCollider = unit.UnitTrans.GetComponent<CapsuleCollider>();
        CapsuleCollider collider = go.AddComponent<CapsuleCollider>();
        collider.center = unitCollider.center;
        collider.radius = unitCollider.radius;
        collider.height = unitCollider.height;
        collider.direction = unitCollider.direction;
        unitCollider.enabled = false;
        SetCollider(unit, false);
        return npc;
    }

    private void UpdateDisplayZone(NPC npc, Unit unit)
    {
        if (npc == null)
            return;
        NPCInfo info = unit.mUnitAttInfo.Npc;
        if (info == null) return;
        GameObject go = new GameObject(LayerTool.NPC.ToString());
        go.name = info.id.ToString();
        go.transform.parent = unit.UnitTrans;
        go.transform.localPosition = Vector3.zero;
        npc.dz = go.AddComponent<DisplayZone>();
        if (npc.dz != null) npc.dz.ColRadius = 10.0f;
    }

    /// <summary>
    /// 添加旋转脚本
    /// </summary>
    /// <param name="go"></param>
    private void AddRotateScript(GameObject go)
    {
        if (go == null)
            return;
        RotateScript script = go.GetComponent<RotateScript>();
        if (script != null)
            return;
        script = go.AddComponent<RotateScript>();
    }

    /// <summary>
    /// 移除旋转脚本
    /// </summary>
    /// <param name="go"></param>
    private void RemoveRotateScript(GameObject go)
    {
        if (go == null)
            return;
        RotateScript script = go.GetComponent<RotateScript>();
        if (script == null)
            return;
        Object.DestroyImmediate(script);
    }

    /// <summary>
    /// 移除Npc
    /// </summary>
    /// <param name="index"> npc位置索引 </param>
    private void Remove(uint npcid)
    {
        NPC npc = null;
        Unit unit = null;
        float orignScale = 1;
        if (NPCClickDic.ContainsKey(npcid))
        {
            npc = NPCClickDic[npcid];
            NPCClickDic.Remove(npcid);
            if (npc != null && npc.name != "null")
            {
                orignScale = npc.orignScale;
                npc.DestoryObj();
                Object.Destroy(npc.gameObject);
            }
            npc = null;
        }
        if (mNPCDic.ContainsKey(npcid))
        {
            unit = mNPCDic[npcid];
//            CutOffRelatedToNPCID(unit.TypeId);
            mNPCDic.Remove(npcid);
            SetCollider(unit, true);
            if(unit.UnitTrans != null && unit.UnitTrans.name != "null")
            {
                RemoveRotateScript(unit.UnitTrans.gameObject);
            }
            if (unit.UnitTrans != null && unit.UnitTrans.name != "null")
            {
                unit.UnitTrans.localScale = unit.UnitTrans.localScale / orignScale;
            }
            //UnitMgr.instance.RemoveUnit(unit);
            //unit.Destroy();
            //unit = null;
        }
    }

    /// <summary>
    /// 设置碰撞框
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="enabled"></param>
    private void SetCollider(Unit unit, bool enabled)
    {
        if (unit == null)
            return;
        if (unit.Collider == null)
            return;
        unit.Collider.enabled = enabled;
    }

    private bool IsShow(NPCInfo info)
    {
        if (mNPCDic.ContainsKey(info.id)) return false;
        NPCInfo.hideList list = info.sList;
        if(list != null)
        {
            List<NPCInfo.hide> slit = list.list;
            if(slit != null)
            {
                NPCInfo.hide show = null;
                for (int i = 0; i < slit.Count; i ++)
                {
                    show = slit[i];
                    if (show.sceneId != User.instance.SceneId)
                     //   if (show.sceneId == User.instance.SceneId && User.instance.MainMission != null && show.missionId > User.instance.MainMission.MissionID)
                    {
                        return false;
                    }
                    else
                    {
                        if (User.instance.MainMissionId != 0 && show.missionId > User.instance.MainMissionId)
                        {
                            return false;
                        }
                    }
                }
            }
        }
        return true;
    }

#endregion

#region 公开函数
    /// <summary>
    /// 加入npc配置表
    /// </summary>
    /// <param name="info"></param>
    public void AddNPCInfo(NPCInfo info)
    {
        if (info == null) return;
        if (mNPCIDList.Contains(info.id)) return;
        mNPCIDList.Add(info.id);
        if (mInfoDic.ContainsKey(info.id)) return;
        mInfoDic.Add(info.id, info);
    }
    /// <summary>
    /// 实例化NP
    /// </summary>
    /// <param name="list"> npcid列表 </param>
    public void InstantiationNpc(SceneInfo.npcs npcs)
    {
        InstantiateNpc(npcs.list);
//         if (mInfoDic == null) return;
//         foreach(NPCInfo info in mInfoDic.Values)
//         {
//             CreateNPC(info);
//         }
        //MonoEvent.lateupdate += Update;
    }

    public void InstantiateNpc(List<uint> list)
    {
        for (int i = 0; i < list.Count; i++)
        {
            uint id = list[i];
            if (mInfoDic.ContainsKey(id))
            {
                if (!IsShow(mInfoDic[id])) continue;
                if (IsHideNPC(mInfoDic[id])) continue;
                if (mNPCDic.ContainsKey(id) == false)
                    CreateNPC(mInfoDic[id]);
            }
        }
    }

    /// <summary>
    /// 通过npcid移除npc对象
    /// </summary>
    /// <param name="id"> npcid </param>
    public void RemoveNPC(uint id)
    {
        Remove(id);
    }

    /// <summary>
    /// 通过npc配置表ID获取Unit
    /// </summary>
    /// <param name="npcID"></param>
    public Unit GetNPC(uint npcID)
    {
        if (mNPCDic.ContainsKey(npcID)) return mNPCDic[npcID];
        return null;
    }
    public void SetNPCActive(bool isActive)
    {
        foreach(Unit npc in mNPCDic.Values)
        {
            npc.UnitTrans.gameObject.SetActive(isActive);
        }
    }

    /// <summary>
    /// 清楚NPC模型数据
    /// 同时配合清除UnitMgr里NPC模型数据
    /// </summary>
    public void CleanmNPCDic()
    {
        //iTrace.eLog("hs", "调用NPCCreate.CleanmNPCDic()");
        mSelectNpc = null;
        uint id;
        //Unit unit;
        int index = 0;
        //NPC npc;
        while (mNPCIDList.Count > index)
        {
            id = mNPCIDList[index];
            RemoveNPC(id);
            index++;
        }
        NPCClickDic.Clear();
        mNPCDic.Clear();
    }

    /// <summary>
    /// 清除当前场景NPC列表
    /// 同时配合清除UnitMgr里NPC模型数据
    /// </summary>
    public void CleanNPCList()
    {
        //iTrace.eLog("hs", "调用NPCCreate.CleanNPCList()");
        uint id;
        //Unit unit;
        while(mNPCIDList.Count > 0)
        {
            id = mNPCIDList[0];
            mNPCIDList.RemoveAt(0);
            if(mInfoDic.ContainsKey(id))
            {
                mInfoDic.Remove(id);
            }
            if(mNPCDic.ContainsKey(id))
            {
                RemoveNPC(id);
                //unit = mNPCDic[id];
                //UnitMgr.instance.RemoveUnit(unit);
                //mNPCDic.Remove(id);
                //unit.Destroy();
                //unit = null;
            }
        }
        mNPCIDList.Clear();
        mInfoDic.Clear();
        mNPCDic.Clear();
       
    }
    #endregion
}
