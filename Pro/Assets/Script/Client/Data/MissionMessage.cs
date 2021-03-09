using System;
using Phantom;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;

public partial class User 
{
    private int mainMissionId;
    /// <summary>
    /// 主线任务ID
    /// </summary>
    public int MainMissionId
    {
        get { return mainMissionId; }
        set
        {
            mainMissionId = value;
            UserBridge.Instance.mainMissionId = value;
            if (IsInitLoadScene == true) return;
            Loong.Game.CameraMgr.ChangeMissionCameraInfo(false);
        }
    }
    /// <summary>
    /// 任务流程树
    /// </summary>
    public bool IsMissionFlowChart = false;

    public void SetMissionID(int id)
    {
        MissionInfo info = MissionInfoManager.instance.Find((uint)id);
        if (info == null) return;
        if ((MissionType)info.type == MissionType.Main)
        {
            MainMissionId = id;
            NPCMgr.instance.SetNPC(id);
            EventMgr.Trigger("MssnChange", id);
        }
    }

    public void RelatedNPC(int id, byte status)
    {
        Dictionary<uint, NPC> dic = NPCMgr.instance.NPCClickDic;
        MissionInfo info = null;
        foreach (KeyValuePair<uint, NPC> npc in dic)
        {
            if (npc.Value == null || npc.Value.name == "null")
                continue;
            bool isRelated = false;
            info = MissionInfoManager.instance.Find((uint)id);
            if (info == null) continue;
            if(info.npcReceive == npc.Key)
            {
                if ((MissionStatus)status == MissionStatus.NOT_RECEIVE ||
                    (MissionStatus)status == MissionStatus.EXECUTE ||
                    (MissionStatus)status == MissionStatus.COMPLETE)
                {
                    npc.Value.SetMissionStatus(id, status);
                    isRelated = true;
                }
                else
                {
                    npc.Value.CleanMissionStatus(id);
                    isRelated = true;
                }
            }
             if(info.npcSubmit == npc.Key)
            {
                if((MissionStatus)status == MissionStatus.ALLOW_SUBMIT)
                {
                    npc.Value.SetMissionStatus(id, status);
                    isRelated = true;
                }
                else
                {
                    npc.Value.CleanMissionStatus(id);
                    isRelated = true;
                }
            }
            if(isRelated)       //有关联就更新状态特效
            {
                npc.Value.UpdateMissionStatus();
            }
        }
    }
    /**
    /// <summary>
    /// 主线任务
    /// </summary>
    public MissionData MainMission;

    /// <summary>
    /// 循环任务
    /// </summary>
    public Dictionary<int, MissionData> TurnMission = new Dictionary<int, MissionData>();

    #region 流程树副本相关数据
    public int FlowChartQuitSceneId;
    /// <summary>
    /// 当前执行的任务流程树 场景ID
    /// </summary>
    public int CurMissionFlowChartSceneId;
    /// <summary>
    /// 等待场景加载完后启动的流程树名
    /// </summary>
    public string WaitStartName { get; set; }
    /// <summary>
    /// 等待加载的场景
    /// 任务流程树结束后加载返回的场景
    /// </summary>
    public int WaitLoadSceneId;
    /// <summary>
    /// 是否有等待执行的流程树
    /// </summary>
    public bool IsWaitLoadFlowChart = false;
    #endregion

    private int MissionEndWaitEnterSceneID = 0;

    /// <summary>
    /// 任务初始化
    /// </summary>
    public void MissionInit()
    {
        EventMgr.Add("RunMssn", AutoExecuteAction);
    }

    public void SingleEntryMissionInit()
    {
        MissionInfo info = MissionInfoManager.instance.Get(0);
        MainMission = new MissionData(info);
    }

    /// <summary>
    /// 更新任务
    /// </summary>
    /// <param name="list"></param>
    public void UpdateMission(List<p_mission> list)
    {
        MissionData data = null;
        for (int i = 0; i < list.Count; i++)
        {
            data = new MissionData(list[i]);
            if (data.Info == null) continue;
            UpdateMission(data);
            NPCMgr.instance.NPCRelatedMission((uint)data.MissionID, data.Status);
        }
    }

    /// <summary>
    /// 更新任务
    /// </summary>
    /// <param name="data"></param>
    public void UpdateMission(MissionData data)
    {
        MissionType type = (MissionType)data.Info.type;
        if (type == MissionType.Main)
            UpdateMainMission(data);
        else if(type == MissionType.Turn)
            UpdateOtherMission(data, ref TurnMission);
    }

    /// <summary>
    /// 更新主线任务
    /// </summary>
    /// <param name="data"></param>
    public void UpdateMainMission(MissionData data)
    {
        if (MainMission != null)
        {
            MainMission.Dispose();
        }
        MainMission = null;
        MainMission = data;
        EventMgr.Trigger("OnUpdateMission", MainMission.MissionID, MainMission);
        if (MainMission.Info.autoReceive == 0) MainMission.AutoExecuteAction();
    }

    /// <summary>
    /// 更新任务目标
    /// </summary>
    /// <param name="id"></param>
    /// <param name="list"></param>
    public void UpdateMissionTarget(int id, List<p_listen> list)
    {
        MissionData data = null;
        if (MainMission != null && MainMission.MissionID == id)
        {
            MainMission.UpdateTarget(list);
            data = MainMission;
        }
        else
        {
            data = UpdateOtherMissionTarget(id, list, ref TurnMission);
        }
        if (data == null) return;
        EventMgr.Trigger("OnUpdateMission", data.MissionID, data);
    }

    /// <summary>
    /// 领取任务
    /// </summary>
    /// <param name="id"> 任务 id </param>
    public void ReceiveMission(int id)
    {
        MissionData data = null;
        if (MainMission != null && MainMission.MissionID == id)
        {
            MainMission.Status = (int)MissionStatus.EXECUTE;
            data = MainMission;
        }
        else
        {
            data = ReceiveOtherMission(id, ref TurnMission);
        }
        if (data == null) return;
        if(data.Info.autoReceive == 0)EventMgr.Trigger("OnPlayMissionEffect", 2);
        EventMgr.Trigger("OnUpdateMission", data.MissionID, data);
    }

    /// <summary>
    /// 提交任务
    /// </summary>
    /// <param name="missionId"> 任务id </param>
    public void MissionSubmit(int id)
    {
        EventMgr.Trigger("MssnEnd", id);
        NPCMgr.instance.SetNPC(id);
        MissionCancel(id, true);
    }

    /// <summary>
    /// 取消任务
    /// </summary>
    /// <param name="id"> 任务id </param>
    public void MissionCancel(int id, bool isSubmit = false)
    {
        EventMgr.Trigger("OnPlayMissionEffect", 4);
        MissionData data = null;
        if (MainMission != null && MainMission.MissionID == id)
        {
            NPCMgr.instance.CutOffRelated(MainMission);
            MainMission.Cancel();
            MainMission.Dispose();
            MainMission = null;
        }
        else
        {
            if (isSubmit)
            {
                data = OtherMissionSubmit(id, ref TurnMission);
            }
            else
            {
                MissionOtherCancel(id, ref TurnMission);
            }
        } 
        EventMgr.Trigger("OnUpdateMission", id, data);
    }

    /// <summary>
    /// 删除任务
    /// </summary>
    public void MissionDelete(List<int> list)
    {
        int id = 0;
        for (int i = 0; i < list.Count; i++)
        {
            id = list[i];
            MissionCancel(id);
        }
    }

    /// <summary>
    /// 判断是否是任务npc 是的话返回任务数据
    /// </summary>
    /// <param name="npcid"></param>
    /// <returns></returns>
    public MissionData IsMissionNpc(ulong npcid)
    {
        if (MainMission != null && MainMission.IsEquals(npcid)) return MainMission;
        MissionData data = IsOtherMissionNpc(npcid, TurnMission);
        if (data != null) return data;
        return null;
    }

    /// <summary>
    /// 通过任务id获得id对象
    /// </summary>
    public MissionData GetMissionForID(int missionID)
    {
        if (MainMission != null && MainMission.MissionID == missionID) return MainMission;
        MissionData data = GetOtherMissionForID(missionID, TurnMission);
        if (data != null) return data;
        return null;
    }

    #region 处理其他任务
    /// <summary>
    /// 更新其他任务
    /// </summary>
    /// <param name="data"></param>
    private void UpdateOtherMission(MissionData data, ref Dictionary<int, MissionData> dic)
    {
        if (!dic.ContainsKey(data.MissionID))
        {
            dic.Add(data.MissionID, data);
            return;
        }
        dic[data.MissionID] = data;
    }

    private MissionData UpdateOtherMissionTarget(int id, List<p_listen> list, ref Dictionary<int, MissionData> dic)
    {
        if (dic.ContainsKey(id))
        {
            dic[id].UpdateTarget(list);
            return dic[id];
        }
        return null;
    }

    private MissionData ReceiveOtherMission(int id, ref Dictionary<int, MissionData> dic)
    {
        if (dic.ContainsKey(id))
        {
            dic[id].Status = (int)MissionStatus.EXECUTE;
            return dic[id];
        }
        return null;
    }

    private MissionData OtherMissionSubmit(int id, ref Dictionary<int, MissionData> dic)
    {
        if (dic.ContainsKey(id))
        {
            dic[id].Status = (int)MissionStatus.COMPLETE;
            return dic[id];
        }
        return null;
    }

    private void MissionOtherCancel(int id, ref Dictionary<int, MissionData> dic)
    {
        if (dic.ContainsKey(id))
        {
            NPCMgr.instance.CutOffRelated(dic[id]);
            dic[id].Cancel();
            dic[id].Dispose();
            dic[id] = null;
            dic.Remove(id);
        }
    }

    private MissionData IsOtherMissionNpc(ulong npcid, Dictionary<int, MissionData> dic)
    {
        foreach (MissionData data in dic.Values)
        {
            if (data != null && data.IsEquals(npcid)) return data;
        }
        return null;
    }

    private MissionData GetOtherMissionForID(int missionid, Dictionary<int, MissionData> dic)
    {
        if (dic.ContainsKey(missionid)) return dic[missionid];
        return null;
    }
    #endregion

    /// <summary>
    /// 打开任务UI
    /// </summary>
    public string GetMissionTalk(ulong unitID, MissionData data)
    {
//         if (data == null || data.Info == null) return string.Empty;
//         if ((MissionStatus)data.Status == MissionStatus.NOT_RECEIVE && !string.IsNullOrEmpty(data.Info.talkResceive) && unitID == data.Info.npcReceive)
//         {
//             return string.IsNullOrEmpty(data.Info.talkResceive) ? "......" : data.Info.talkResceive;
//         }
//         else 
        if((MissionStatus)data.Status == MissionStatus.EXECUTE && (MissionTargetType)data.Info.target == MissionTargetType.TALK && data.IsTargetEquals(unitID))
        {
            return string.IsNullOrEmpty(data.Info.missionTalk) ? "......" : data.Info.missionTalk;
        }
//         else if ((MissionStatus)data.Status == MissionStatus.ALLOW_SUBMIT && !string.IsNullOrEmpty(data.Info.talkSubmit) && unitID == data.Info.npcSubmit && data.Info.showTalk == 0)
//         {
//             return string.IsNullOrEmpty(data.Info.talkSubmit) ? "......" : data.Info.talkSubmit;
//         }
        return string.Empty;
    }

    /// <summary>
    /// 流程树结束返回
    /// </summary>
    /// <param name="name"></param>
    /// <param name="isWin"></param>
    public void FlowChartComplete(string name, bool isWin)
    {
        //判断结束的流程树是单人副本 切换场景的时候不进行加载
        if(WaitStartName == name)
        {
            Loong.Game.iTrace.eWarning("HS", string.Format("任务{0}目标流程树：结束流程树场景{1}", name, User.instance.SceneId));
            Loong.Game.iTrace.eWarning("HS", "----------------------------------> MissionMessage");
            Loong.Game.DropMgr.CleanDropList();
            Phantom.EndGame.end -= User.instance.FlowChartComplete;
            EventMgr.Trigger(EventKey.MissionFlowChartEnd, name, isWin);
            Loong.Game.SceneTriggerMgr.Stoping = false;
            User.instance.IsWaitLoadFlowChart = false;
            if (User.instance.WaitLoadSceneId != 0)
            {
                NetworkMgr.ReqPreEnter(FlowChartQuitSceneId, false);
                NPCMgr.instance.SetNPCActive(true);
                WaitLoadSceneId = 0;
                WaitStartName = string.Empty;
                CurMissionFlowChartSceneId = 0;
            }
//             else
//             {
//                 NetworkMgr.QuitScene();
//             }
        }
    }

    public int IsInFlowChartScene()
    {
        int sceneId = 0;
        sceneId = IsExecuteThree(MainMission);
        if (sceneId != 0) return sceneId;
//         foreach (MissionData data in OtherMission.Values)
//         {
//             sceneId = IsExecuteThree(data);
//             if (sceneId != 0) return sceneId;
//         }
        return 0;
    }

    private int IsExecuteThree(MissionData data)
    {
        if(data != null && data.Info != null && (MissionStatus)data.Status == MissionStatus.EXECUTE && data.Info.threeId.list.Count >= 2)
        {
            return (int)data.Info.threeId.list[1];
        }
        return 0;
    }

    /// <summary>
    /// 变更流程树场景
    /// </summary>
    /// <param name="sceneId"></param>
    public bool ChangeFlowChart()
    {
        CopyInfo info = CopyInfoManager.instance.Find((uint)User.instance.SceneId);
        if (info != null && (GameSceneType)info.copyType != GameSceneType.GST_Unknown) return false;

        if (GameSceneManager.instance.IsLoadFlowChartScene)
        { 
            if (CurMissionFlowChartSceneId == 0) return false;  
            if (CurMissionFlowChartSceneId != User.instance.SceneId)
            {
                NetworkMgr.ReqPreEnter(CurMissionFlowChartSceneId, false);
            }
            else
            {
                GameSceneManager.instance.OnChangeScene(null);
            }
            return true;
        }
        return false;
    }

    private void AutoExecuteAction(params object[] args)
    {
        if(MainMission != null)
            MainMission.AutoExecuteAction();
    }

    public void MissionEndChangeScence(int sceneid)
    {
        EventMgr.Add(EventKey.OnChangeScene, OnMissionEndChangeScence);
        MissionEndWaitEnterSceneID = sceneid;
    }

    private void OnMissionEndChangeScence(params object[] args)
    {
        if (IsWaitLoadFlowChart == true) return;
        if (!string.IsNullOrEmpty(WaitStartName)) return;
        EventMgr.Remove(EventKey.OnChangeScene, OnMissionEndChangeScence);
        if (MissionEndWaitEnterSceneID == 0) return;
        NetworkMgr.ReqPreEnter(MissionEndWaitEnterSceneID);
    }
    */
}
