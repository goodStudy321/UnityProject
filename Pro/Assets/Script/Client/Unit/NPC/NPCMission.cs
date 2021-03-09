using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public partial class NPCMgr 
{
    #region 列表
    /**
    private Dictionary<UInt32, List<int>> mMissionNpcList = new Dictionary<UInt32, List<int>>();
    /// <summary>
    /// npc对应的任务
    /// </summary>
    public Dictionary<UInt32, List<int>> MissionNpcList { get { return mMissionNpcList; } }
        */
    #endregion

    #region 对象
 //   private MissionData TargetMission;
    #endregion

    #region 检查npc关联的任务
    /**
    /// <summary>
    /// 检查npc关联的任务
    /// </summary>
    public void CheckNPCRelatedMission(UInt32 npcid)
    {
        int id = 0;
        if (mMissionNpcList.ContainsKey(npcid))
        {
            if(mMissionNpcList[npcid].Count > 0)
            {
                id = mMissionNpcList[npcid][0];
            }
        }
        TargetMission = User.instance.GetMissionForID(id);
        if (TargetMission != null && TargetMission.CheckTalkNPC()) return;
        this.OpenUI(npcid);
    }
      */
    #endregion

    #region 切断NPC任务关联
    /**
    public void CutOffRelated(uint id)
    {
        MissionInfo mission = MissionInfoManager.instance.Find(id);
        if (mission == null) return;
        UInt32 receiveNPC = mission.npcReceive;
        CutOffRelated(receiveNPC, (int)mission.id);
        UInt32 submitNPC = mission.npcSubmit;
        CutOffRelated(submitNPC, (int)mission.id);
        if ((MissionTargetType)mission.target == MissionTargetType.TALK)
        {
            List<MissionInfo.data> param = mission.targetParam.list;
            for (int i = 0; i < param.Count; i++)
            {
                List<Int32> pList = param[i].list;
                for (int j = 0; j < pList.Count; j++)
                {
                    CutOffRelated((UInt32)pList[j], (int)mission.id);
                }
            }
        }

    }
    /// <summary>
    /// 完成任务后 切断npc与该任务关联
    /// </summary>
    /// <param name="npcid"></param>
    /// <param name="missionID"></param>
    public void CutOffRelated(MissionData data)
    {
        UInt32 receiveNPC = data.Info.npcReceive;
        CutOffRelated(receiveNPC, data.MissionID);
        UInt32 submitNPC = data.Info.npcSubmit;
        CutOffRelated(submitNPC, data.MissionID);
        if ((MissionTargetType)data.Info.target == MissionTargetType.TALK)
        {
            List<MissionInfo.data> param = data.Info.targetParam.list;
            for (int i = 0; i < param.Count; i++)
            {
                List<Int32> pList = param[i].list;
                for (int j = 0; j < pList.Count; j++)
                {
                    CutOffRelated((UInt32)pList[j], data.MissionID);
                }
            }
        }
    }

    /// <summary>
    /// 移除NPC时候 切断与任务的关联
    /// </summary>
    private void CutOffRelatedToNPCID(UInt32 npcid)
    {
        if (mMissionNpcList.ContainsKey(npcid))
        {
            mMissionNpcList[npcid].Clear();
            mMissionNpcList.Remove(npcid);
        }
    }

    /// <summary>
    /// 切断关联
    /// </summary>
    /// <param name="npcid">npc id</param>
    /// <param name="missionid"> mission id</param>
    private void CutOffRelated(UInt32 npcid, Int32 missionid)
    {
        if (!mMissionNpcList.ContainsKey(npcid)) return;
        if (mNPCClickDic.ContainsKey(npcid)) mNPCClickDic[npcid].SetMissionEffect(null);
        if (!mMissionNpcList[npcid].Contains(missionid)) return;
        mMissionNpcList[npcid].Remove(missionid);
    }
        */
    #endregion

    #region NPC关联任务
    /**
    /// <summary>
    /// NPC关联任务
    /// </summary>
    private void NPCRelatedMission(Unit unit)
    {
        EventMgr.Trigger("NPCRelatedMission", unit.TypeId);
        MissionData data = User.instance.IsMissionNpc(unit.TypeId);
        if (data != null)
        {
            NPCRelatedMission((uint)data.MissionID, data.Status);
            
        }
    }

    public void NPCRelatedMission(UInt32 id, int status)
    {
        MissionInfo info = MissionInfoManager.instance.Find(id);
        if(info == null)
        {
            Loong.Game.iTrace.eError("hs", string.Format("任务ID不存在", id));
            return;
        }
        UInt32 receiveNPC = info.npcReceive;
        Related(receiveNPC, info, (MissionStatus)status == MissionStatus.NOT_RECEIVE ? MissionStatus.NOT_RECEIVE : MissionStatus.None);
        UInt32 submitNPC = info.npcSubmit;
        Related(submitNPC, info, (MissionStatus)status == MissionStatus.ALLOW_SUBMIT ? MissionStatus.ALLOW_SUBMIT : MissionStatus.None);

        List<MissionInfo.data> param = info.targetParam.list;
        for (int i = 0; i < param.Count; i++)
        {
            List<Int32> idList = param[i].list;
            Related((UInt32)idList[0], info, MissionStatus.None);
        }
    }
    */
// 
//     /// <summary>
//     /// NPC关联任务
//     /// </summary>
//     public void NPCRelatedMission(MissionData data)
//     {
//         UInt32 receiveNPC = data.Info.npcReceive;
//         Related(receiveNPC, data, (MissionStatus)data.Status == MissionStatus.NOT_RECEIVE ? MissionStatus.NOT_RECEIVE : MissionStatus.None);
//         UInt32 submitNPC = data.Info.npcSubmit;
//         Related(submitNPC, data, (MissionStatus)data.Status == MissionStatus.ALLOW_SUBMIT ? MissionStatus.ALLOW_SUBMIT : MissionStatus.None);
//         if ((MissionTargetType)data.Info.target == MissionTargetType.TALK)
//         {
//             List<MissionInfo.data> param = data.Info.targetParam.list;
//             for (int i = 0; i < param.Count; i++)
//             {
//                 List<Int32> idList = param[i].list;
//                 Related((UInt32)idList[0], data, MissionStatus.None);
//             }
//         }
//     }
/**
    /// <summary>
    /// 关联
    /// </summary>
    /// <param name="npcid"> npc id </param>
    /// <param name="data"> 任务 id </param>
    private void Related(UInt32 npcid, MissionInfo mission, MissionStatus status)
    {
        if (npcid == 0) return;
        if (!mMissionNpcList.ContainsKey(npcid)) mMissionNpcList.Add(npcid, new List<Int32>());
        if (!mMissionNpcList[npcid].Contains((int)mission.id)) mMissionNpcList[npcid].Add((int)mission.id);
        if (mNPCClickDic.ContainsKey(npcid)) mNPCClickDic[npcid].SetMissionEffect(mission, status);
    }

    /// <summary>
    /// 关联
    /// </summary>
    /// <param name="npcid"> npc id </param>
    /// <param name="data"> 任务 id </param>
    private void Related(UInt32 npcid, MissionData data, MissionStatus status)
    {
        if (npcid == 0) return;
        if (!mMissionNpcList.ContainsKey(npcid)) mMissionNpcList.Add(npcid, new List<Int32>());
        if (!mMissionNpcList[npcid].Contains(data.MissionID)) mMissionNpcList[npcid].Add(data.MissionID);
        if (mNPCClickDic.ContainsKey(npcid)) mNPCClickDic[npcid].SetMissionEffect(data);
    }
    */
    #endregion

    #region 播放任务领取/完成特效
    /// <summary>
    /// 播放特效
    /// </summary>
    /// <param name="status"></param>
    public void PlayMissionEffect(MissionStatus status)
    {
        string effectName = string.Empty;
        if (status == MissionStatus.EXECUTE)
        {
            effectName = PreloadName.UI_Task_Accept;
        }
        else if (status == MissionStatus.COMPLETE)
        {
            effectName = PreloadName.UI_Task_Finish;
        }
        Loong.Game.AssetMgr.LoadPrefab(effectName, LoadEffectComplete);
    }


    /// <summary>
    /// 加载特效完成
    /// </summary>
    /// <param name="go"></param>
    private static void LoadEffectComplete(GameObject go)
    {
        if (go != null)
        {
            CapsuleCollider collider = null;
            if (InputMgr.instance.mOwner != null)
            {
                go.transform.parent = InputMgr.instance.mOwner.UnitTrans;
                collider = Loong.Game.ComTool.Get<CapsuleCollider>(InputMgr.instance.mOwner.UnitTrans);
            }
            go.transform.localPosition = collider != null ? Vector3.up * (collider.height + collider.center.y) : Vector3.zero;
            //go.transform.eulerAngles = Vector3.zero;
            go.transform.localScale = Vector3.one;
            go.SetActive(true);
        }
    }
    #endregion

    #region 任务完成隐藏npc
    public void SetNPC(int missionid)
    {
        if (User.instance.IsInitLoadScene) return;
        MissionInfo mission = MissionInfoManager.instance.Find((uint)missionid);
        if (mission == null) return;
        HideNPC(mission);
        ShowNPC(mission);
    }
    /// <summary>
    /// 任务完成后隐藏npc
    /// </summary>
    public void HideNPC(MissionInfo mission)
    {
        if (mission == null) return;
        Dictionary<uint,NPC>.ValueCollection list = NPCClickDic.Values;
        foreach(NPC npc in list)
        {
            npc.MisssionHideNPC((int)mission.id);
        }
    }

    public bool IsHideNPC(NPCInfo info)
    {
        if (info == null) return true;
        int missionid = User.instance.MainMissionId;
        List<NPCInfo.hide> hlist = info.hList.list;
        NPCInfo.hide hide = null;
        for (int i = 0; i < hlist.Count; i++)
        {
            hide = hlist[i];
            if (hide == null) continue;
            if (hide.sceneId != User.instance.SceneId) return true;
            if (hide.missionId < missionid)
            {
                return true;
            }
        }
        return false;
    }

    public void ShowNPC(MissionInfo mission)
    {
        if (mission == null) return;
        SceneInfo info = GameSceneManager.instance.SceneInfo;
        if (info == null) return;
        if((GameSceneType)info.sceneType == GameSceneType.GST_Copy ||
            (GameSceneType)info.sceneType == GameSceneType.GST_Unknown ||
            (GameSceneType)info.sceneType == GameSceneType.GST_Three)
        {
            return;
        }
        //Dictionary<uint, NPCInfo> dic = mInfoDic;
        foreach (KeyValuePair<uint, NPCInfo> data in mInfoDic)
        {
            uint id = data.Key;
            if (NPCClickDic.ContainsKey(id)) continue;
            if (!IsShow(mInfoDic[id])) continue;
            if (IsHideNPC(mInfoDic[id])) continue;
            NPCInfo npc = NPCInfoManager.instance.Find(id);
            if (npc != null && npc.mapId != GameSceneManager.instance.SceneInfo.id) continue;
            CreateNPC(mInfoDic[id]);
        }
    }

    #endregion
}
