using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class NPC : MonoBehaviour {

    private Unit unit = null;
    public DisplayZone dz = null;
    public float orignScale = 1;
    private GameObject acceptEffect;
    private GameObject finishEffect;
    private Dictionary<int, byte> missionStatus = new Dictionary<int, byte>();
    #region 初始化

    /// <summary>
    /// 初始化 创建任务UI
    /// </summary>
    public virtual void SetEffect()
    {
        acceptEffect = new GameObject(PreloadName.FX_Npc_Accept);
        acceptEffect.transform.parent = this.transform;
        acceptEffect.transform.localPosition = Vector3.zero;
        acceptEffect.SetActive(false);
        acceptEffect.transform.localPosition = Vector3.zero;
        finishEffect = new GameObject(PreloadName.FX_Npc_Finish);
        finishEffect.transform.parent = this.transform;
        finishEffect.transform.localPosition = Vector3.zero;
        finishEffect.SetActive(false);
        AssetMgr.LoadPrefab(PreloadName.FX_Npc_Accept, OnComplete);
        AssetMgr.LoadPrefab(PreloadName.FX_Npc_Finish, OnComplete);
    }
    public void UpdateUnit(Unit u)
    {
        this.unit = u;
        SetEffect();
    }
    #endregion

        #region 关联Unit
        /// <summary>
        /// 设置任务状态
        /// </summary>
        /// <param name="id"></param>
        /// <param name="status"></param>
    public void SetMissionStatus(int id, byte status)
    {
        if(!missionStatus.ContainsKey(id))
        {
            missionStatus.Add(id, status);
        }
        else
        {
            if ((MissionStatus)status != MissionStatus.None && missionStatus[id] > status) return;
            missionStatus[id] = status;
        }
    }

    /// <summary>
    /// 清除任务状态
    /// </summary>
    public void CleanMissionStatus(int id)
    {
        if (!missionStatus.ContainsKey(id)) return;
        missionStatus[id] = (byte)MissionStatus.None;
    }

    /// <summary>
    /// 更新状态特效
    /// </summary>
    public void UpdateMissionStatus()
    {
        int status = 0;
        foreach(int value in missionStatus.Values)
        {
            if (value > status) status = value;
        }
        UpdateEffect((MissionStatus)status);
    }
    /**
    /// <summary>
    /// 关联Unit
    /// </summary>
    public void UpdateUnit(Unit u)
    {
        this.unit = u;
        if(User.instance.MainMission != null)
            MisssionHideNPC(User.instance.MainMission.MissionID, true);
        SetMissionEffect(User.instance.MainMission);
        Dictionary<int ,MissionData> dic = User.instance.TurnMission;
        foreach (MissionData data in dic.Values)
        {
            SetMissionEffect(data);
        }
    }
    **/
    #endregion

    #region 头上的任务特效

    private void OnComplete(GameObject go)
    {
        if (unit == null || unit.UnitTrans == null) return;
        if (go == null) return;
        if (go.name == PreloadName.FX_Npc_Accept)
        {
            go.transform.parent = acceptEffect.transform;
        }
        else if (go.name == PreloadName.FX_Npc_Finish)
        {
            go.transform.parent = finishEffect.transform;
        }
        CapsuleCollider collider = Loong.Game.ComTool.Get<CapsuleCollider>(unit.UnitTrans);
        go.transform.localPosition = collider != null ? Vector3.up * (collider.height + 0.3f) : Vector3.zero;
        go.transform.localScale = Vector3.one;
        go.SetActive(true);
    }

    private void UpdateEffect(MissionStatus status)
    {
        if (acceptEffect)
        {
            if(acceptEffect.name == "null")
            {
                GameObject.Destroy(acceptEffect);
                return;
            }
            acceptEffect.SetActive(false);
            if (status == MissionStatus.NOT_RECEIVE)
            {
                acceptEffect.SetActive(true);
            }
        }
        if(finishEffect)
        {
            if (finishEffect.name == "null")
            {
                GameObject.Destroy(finishEffect);
                return;
            }
            finishEffect.SetActive(false);
            if(status == MissionStatus.ALLOW_SUBMIT)
            {
                finishEffect.SetActive(true);
            }
        }
        
    }

    /**
    public void SetMissionEffect(MissionInfo mission, MissionStatus status)
    {
        if (mission != null)
        {
            if (!isLoadFinshEffect && mission.npcSubmit == unit.mUnitAttInfo.Npc.id && status == MissionStatus.ALLOW_SUBMIT)
            {
                isLoadFinshEffect = true;
                UpdateMissionEffect(finishEffect, PreloadName.FX_Npc_Accept);
                return;
            }
            else if (!isLoadAcceptEffect && mission.npcReceive == unit.mUnitAttInfo.Npc.id && status == MissionStatus.NOT_RECEIVE)
            {
                isLoadAcceptEffect = true;
                UpdateMissionEffect(acceptEffect, PreloadName.FX_Npc_Finish);
                return;
            }
            return;
        }
        if (acceptEffect != null) acceptEffect.SetActive(false);
        if (finishEffect != null) finishEffect.SetActive(false);
    }
    public void SetMissionEffect(MissionData data)
    {
        if(data != null)
        {
            if (!isLoadFinshEffect && data.Info.npcSubmit == unit.mUnitAttInfo.Npc.id && (MissionStatus)data.Status == MissionStatus.ALLOW_SUBMIT)
            {
                isLoadFinshEffect = true;
                UpdateMissionEffect(finishEffect, PreloadName.FX_Npc_Accept);
                return;
            }
            else if (!isLoadAcceptEffect && data.Info.npcReceive == unit.mUnitAttInfo.Npc.id && (MissionStatus)data.Status == MissionStatus.NOT_RECEIVE)
            {
                isLoadAcceptEffect = true;
                UpdateMissionEffect(acceptEffect, PreloadName.FX_Npc_Finish);
                return;
            }
            return;
        }
        if (acceptEffect != null) acceptEffect.SetActive(false);
        if (finishEffect != null) finishEffect.SetActive(false);
    }

    private void UpdateMissionEffect(GameObject go, string effectName)
    {
        if (go == null)
        {
            AssetMgr.LoadPrefab(effectName, OnComplete);
        }
        else
        {
            go.SetActive(true);
        }
    }
    **/
    #endregion

    #region 点击模型
    /// <summary>
    /// 点击模型
    /// </summary>
    protected virtual void OnClick()
    {
        NPCMgr.instance.SetClickNPC(unit.TypeId, true);
    }
    #endregion

    #region 隐藏NPC
    /// <summary>
    /// 隐藏NPC
    /// </summary>
    public virtual void MisssionHideNPC(int missionid, bool isCreate = false)
    {
        if (unit == null) return;
        NPCInfo info = unit.mUnitAttInfo.Npc;
        if (info == null) return;
        List<NPCInfo.hide> hlist = info.hList.list;
        NPCInfo.hide hide = null;
        for (int i = 0; i < hlist.Count; i++)
        {
            hide = hlist[i];
            if (hide == null) continue;
            if (hide.sceneId != User.instance.SceneId) continue;
            if (!isCreate && hide.missionId == missionid)
            {
                UnitMgr.instance.SetUnitActive(unit, false);
            }
            else if (isCreate && hide.missionId < missionid)
            {
                UnitMgr.instance.SetUnitActive(unit, false);
            }
        }
    }
    #endregion

    public void DestoryObj()
    {
        unit = null;
        if(acceptEffect != null)
        {
            acceptEffect.transform.parent = null;
            GbjPool.Instance.Add(acceptEffect);
            //GameObject.Destroy(acceptEffect);
            //AssetMgr.Instance.Unload(PreloadName.FX_Npc_Accept, ".prefab", false);
        }
        if (finishEffect != null)
        {
            finishEffect.transform.parent = null;
            GbjPool.Instance.Add(finishEffect);
            //GameObject.Destroy(finishEffect);
            //AssetMgr.Instance.Unload(PreloadName.FX_Npc_Finish, ".prefab", false);
        }
        if(dz != null)
        {
            dz.SetChildShow(true);
            GameObject.Destroy(dz.gameObject);
            dz = null;
        }
        if (gameObject != null)
        {
            gameObject.transform.parent = null;
        }
    }
}
