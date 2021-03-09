using System;
using ProtoBuf;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

public static class ActionHelper
{
    public const string action_file_ext = ".act";
    /// <summary>
    /// 获取动作编辑器数据
    /// </summary>
    /// <param name="name"></param>
    /// <returns></returns>
    public static ActionSetupInfo GetActionSetupDataFromFile()
    {
        ActionSetupInfo data = null;
        string name = "setup.act";

#if UNITY_EDITOR
        if (Application.isEditor)
        {
            string url = null;
            if (AssetPath.ExistInPersistent)
            {
                url = AssetPath.Persistent + "/action/" + name;
            }
            else
            {
                url = Directory.GetParent(Application.dataPath).Parent + "/Assets/action/" + name;
            }
            FileStream stream = File.OpenRead(url);
            data = Serializer.Deserialize<ActionSetupInfo>(stream);
            stream.Close();
            stream.Dispose();
        }
        else
#endif
        {
            name = "setup.act";
            string fullname = Loong.Game.AssetPath.WwwCommen + "action/" + name;
            UnityWebRequest request = UnityWebRequest.Get(fullname);
            var UWRAsynOp = request.SendWebRequest();
            while (!UWRAsynOp.isDone)
            {

            }
            string error = request.error;
            if (!string.IsNullOrEmpty(error))
            {
                Loong.Game.iTrace.Warning("LJF", string.Format("加载动作数据发生错误,路径:{0},错误信息:{1}", fullname, error));
            }
            MemoryStream stream = new MemoryStream(request.downloadHandler.data);
            data = Serializer.Deserialize<ActionSetupInfo>(stream);
            request.Dispose();
        }
        return data;
    }

    /// <summary>
    /// 获取动作组数据
    /// </summary>
    /// <param name="roleID"></param>
    /// <param name="index"></param>
    /// <returns></returns>
    public static ActionGroupData GetGroupData(uint roleID, int index)
    {
        if (Global.ActionSetupData == null)
        {
#if UNITY_EDITOR
            Debug.Log("Global.ActionSetupData == null");
#endif
            return null;
        }

        int Count = Global.ActionSetupData.Units.Count;
        for (int i = 0; i < Count; i++)
        {
            UnitActionInfo actinfo = Global.ActionSetupData.Units[i];
            if (actinfo.ID != roleID)
                continue;
            int GroupCount = actinfo.ActionGroupList.Count;
            for (int idx = 0; idx < GroupCount; idx++)
            {
                if (actinfo.ActionGroupList[idx].GroupNum != index)
                    continue;
                return actinfo.ActionGroupList[idx];
            }
            return null;
        }
        return null;
    }

    /// <summary>
    /// 获取动作总时间
    /// </summary>
    /// <param name="data"></param>
    /// <returns></returns>
    public static int GetActionTotalTime(ActionData data)
    {
        return data.AnimTime + data.PoseTime;
    }

    /// <summary>
    /// 根据动作ID获取动作
    /// </summary>
    /// <param name="data"></param>
    /// <param name="animID"></param>
    /// <returns></returns>
    public static ActionData GetActionByID(ActionGroupData data, string animID)
    {
        if (data == null)
            return null;

        foreach (ActionData act in data.ActionDataList)
        {
            if (act.AnimID != animID)
                continue;
            return act;
        }
        return null;
    }

    /// <summary>
    /// 获取动作索引
    /// </summary>
    /// <param name="data"></param>
    /// <param name="name"></param>
    /// <returns></returns>
    public static int GetActionIndex(ActionGroupData data, string animID)
    {
        if (data == null)
            return -1;

        for (int i = 0; i < data.ActionDataList.Count; ++i)
        {
            if (data.ActionDataList[i].AnimID != animID)
                continue;
            return i;
        }

        return -1;
    }

    /// <summary>
    /// 获取摄像机组数据
    /// </summary>
    /// <param name="CameraID"></param>
    /// <returns></returns>
    public static CameraGroup GetCameraGroupData(int CameraID)
    {
        if (Global.ActionSetupData == null)
            return null;

        foreach (CameraGroup cg in Global.ActionSetupData.Cameras)
        {
            if (cg.ID != CameraID)
                continue;
            return cg;
        }
        return null;
    }

    /// <summary>
    /// 根据技能Id获取中断动画名
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="skillId"></param>
    /// <returns></returns>
    public static string GetInterruptAnimIDBySkillID(Unit unit, uint skillId)
    {
        if (unit == null) return null;
        if (unit.ActionStatus == null) return null;
        if (unit.ActionStatus.ActionGroupData == null) return null;
        ActionData actionData = ActionHelper.GetActionByID(unit.ActionStatus.ActionGroupData, "A0000");
        if (actionData == null) return null;
        for (int i = 0; i < actionData.InterruptList.Count; i++)
        {
            if (actionData.InterruptList[i].SkillID != skillId)
                continue;
            return actionData.InterruptList[i].ActionID;
        }
        return null;
    }

    /// <summary>
    /// 是否是点对点子弹类型
    /// </summary>
    /// <param name="actData"></param>
    /// <param name="animID"></param>
    /// <returns></returns>
    public static bool IsPTPAttDefType(Unit unit, string animID)
    {
        if (unit == null)
            return false;
        if (unit.ActionStatus == null)
            return false;
        ActionData actData = GetActionByID(unit.ActionStatus.ActionGroupData, animID);
        if (actData == null)
            return false;
        ActionStatus.EActionStatus eas = (ActionStatus.EActionStatus)actData.ActionStatus;
        if (eas != ActionStatus.EActionStatus.EAS_Attack && eas != ActionStatus.EActionStatus.EAS_Skill)
            return false;
        for(int i = 0; i < actData.AttackDefList.Count; i++)
        {
            int attDefType = actData.AttackDefList[i].AttackDefType;
            if (attDefType != (int)ActionStatus.Attack_Def_Type.PointToPointBullet)
                continue;
            return true;
        }
        if (actData.DefaultLinkActionID == "N0000")
            return false;
        return IsPTPAttDefType(unit, actData.DefaultLinkActionID);
    }

    /// <summary>
    /// 获取攻击定义
    /// </summary>
    /// <param name="actionData"></param>
    /// <returns></returns>
    public static AttackDefData GetAttackDefDataByIndex(ActionData actionData, int index)
    {
        if (actionData.AttackDefList.Count <= index)
        {
            if (actionData.AttackDefList.Count > 0)
                return actionData.AttackDefList[0];
            return null;
        }
        return actionData.AttackDefList[index];
    }

    public static void Decode(int x, int y, int z, Int16 dir, ref Vector3 pos, ref float rotate)
    {
        pos.x = x * 0.01f;
        pos.y = (y + 1) * 0.01f;
        pos.z = z * 0.01f;
        rotate = DecodeRotate(dir);
    }

    public static float DecodeRotate(Int16 dir)
    {
        return dir * Mathf.Deg2Rad;
    }

    public static void Encode(Vector3 pos, float rotate, ref int x, ref int y, ref int z, ref Int16 dir)
    {
        x = (int)(pos.x * 100.0f + 0.5f);
        y = (int)(pos.y * 100.0f + 0.5f);
        z = (int)(pos.z * 100.0f + 0.5f);
        dir = EncodeRotate(rotate);
    }

    public static Int16 EncodeRotate(float rotate)
    {
        return (Int16)(rotate * Mathf.Rad2Deg + 0.5f);
    }

    /// <summary>
    /// 获取单位包围盒宽度
    /// </summary>
    /// <param name="roleId"></param>
    /// <returns></returns>
    public static float GetUnitBoundingW(uint roleId)
    {
        roleId = UnitHelper.instance.GetUnitModeId(roleId);
        ActionGroupData data = GetGroupData(roleId, 0);
        if (data == null)
            return 0;
        return data.BoundingWidth * 0.01f/2;
    }

    /// <summary>
    /// 是否可以播放受击动作
    /// </summary>
    /// <returns></returns>
    public static bool CanPlayHitAction(Unit unit)
    {
        if (unit.ActionStatus == null)
            return false;
        ActionStatus.EActionStatus actionStatus = unit.ActionStatus.ActionState;
        if (actionStatus == ActionStatus.EActionStatus.EAS_BeHit)
            return false;
        if (actionStatus == ActionStatus.EActionStatus.EAS_Attack)
            return false;
        if (actionStatus == ActionStatus.EActionStatus.EAS_Skill)
            return false;
        if (actionStatus == ActionStatus.EActionStatus.EAS_Dead)
            return false;
        if (actionStatus == ActionStatus.EActionStatus.EAS_Move)
            return false;
        if (actionStatus == ActionStatus.EActionStatus.EAS_Born)
            return false;
        return true;
    }

    /// <summary>
    /// 播放乘骑动作
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="running"></param>
    public static void PlayRidingAnim(Unit unit, bool running)
    {
        if (unit == null)
            return;
        if (unit.mUnitAttInfo.UnitType != UnitType.Mount)
            return;
        Unit parent = unit.ParentUnit;
        if (parent == null)
            return;
        if (parent.ActionStatus == null)
            return;
        Mount mount = unit.mPendant as Mount;
        if (mount == null)
            return;
        string animID = mount.RoleRdMove;
        if (!running)
            animID = mount.RoleRdIdle;
        if (parent.ActionStatus.ActiveAction.AnimID == animID)
            return;
        parent.ActionStatus.ChangeAction(animID,0);
    }

    /// <summary>
    /// 获取动作外发光参数
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="actionId"></param>
    /// <param name="eventName"></param>
    /// <returns></returns>
    public static float[] GetActOutlineParam(Unit unit, string actionId, string eventName)
    {
        if (unit == null)
            return null;
        ActionStatus actSt = unit.ActionStatus;
        if (actSt == null)
            return null;
        ActionData actData = unit.ActionStatus.GetActionData(actionId);
        if (actData == null)
            return null;
        List<ActionEventData> eList = actData.EventList;
        if (eList == null)
            return null;
        for(int i = 0; i < eList.Count; i++)
        {
            EventData eData = eList[i].EventDetailData;
            if (eData == null)
                continue;
            if ((ActionCommon.EventType)eData.EventType != ActionCommon.EventType.ExeScript)
                continue;
            string scriptCmd = eData.ScriptCmd;
            if (string.IsNullOrEmpty(scriptCmd))
                continue;
            string[] strs = scriptCmd.Split('(');
            int len = strs.Length;
            if (len != 2)
                return null;
            string scriptname = strs[0];
            if (scriptname != eventName)
                continue;
            string parameter = strs[1];
            string mParam = parameter.Remove(parameter.Length - 1);
            if (string.IsNullOrEmpty(mParam))
                continue;
            string[] args = mParam.Split(", ".ToCharArray(), System.StringSplitOptions.RemoveEmptyEntries);
            if (args.Length != 2)
                return null;
            float[] vals = new float[] { float.Parse(args[0]), float.Parse(args[1]) };
            return vals;
        }
        return null;
    }
}