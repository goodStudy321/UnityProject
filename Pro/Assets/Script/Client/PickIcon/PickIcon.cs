using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
public class PickIcon
{
    private const string Name = "PickIcon";
    private static Dictionary<Int64, GameObject> Icons = new Dictionary<Int64, GameObject>();
    private static Int64 MonsterId;

    public static void CheckShowIcon(Int64 monsterid, Int64 id)
    {
        if (monsterid == 0 || id == 0)
        {
            DestroyPickIcon();
            return;
        }
        SceneInfo info = SceneInfoManager.instance.Find((uint)User.instance.SceneId);
        if (info != null && ((SceneSubType)info.sceneSubType == SceneSubType.WordBoss || 
            (SceneSubType)info.sceneSubType == SceneSubType.HomeOfBoss) || 
            (SceneSubType)info.sceneSubType == SceneSubType.WildFBoss||
            (SceneSubType)info.sceneSubType == SceneSubType.WorldBossGuid ||
            (SceneSubType)info.sceneSubType == SceneSubType.DemonBoss)
        {
            DestroyPickIcon();
            MonsterId = monsterid;
            List<ActorData> actors = new List<ActorData>();
            if (User.instance.MapData != null)
            {
                if (User.instance.MapData.UID == id || User.instance.MapData.TeamID == id)
                {
                    actors.Add(User.instance.MapData);
                    //actor = User.instance.MapData;
                }
            }
            foreach (KeyValuePair<long, ActorData> kv in User.instance.OtherRoleDic)
            {
                if (kv.Value.UID == id || kv.Value.TeamID == id)
                    actors.Add(kv.Value);
            }
            if (actors.Count > 0)
            {
                foreach(ActorData data in actors)
                {
                    Unit unit = UnitMgr.instance.FindUnitByUid(data.UID);
                    if (unit != null && unit.UnitTrans != null && unit.UnitTrans.name != "name")
                    {
                        CreatePickIcon(data.UID, unit);
                    }
                }
            }
            else
            {
                foreach(KeyValuePair<long, ActorData> data in User.instance.OtherRoleDic)
                {
                    if(data.Value.TeamID == id)
                    {
                        Unit unit = UnitMgr.instance.FindUnitByUid(data.Value.UID);
                        if (unit != null && unit.UnitTrans != null && unit.UnitTrans.name != "name")
                        {
                            CreatePickIcon(data.Value.UID, unit);
                        }
                    }
                }
            }
        }
    }

    private static void CreatePickIcon(long uid, Unit unit)
    {
        if (Icons.ContainsKey(uid)) return;
        AssetMgr.LoadPrefab(Name, (obj) =>
        {

            if (unit != null && unit.TopBar != null)
            {
                obj.transform.parent = unit.TopBar.transform;
                obj.transform.localScale = Vector3.one * 0.005f;
                obj.transform.localEulerAngles = Vector3.zero;
                obj.transform.localPosition = Vector3.up * 0.8f;
                Icons.Add(uid, obj);
                obj.SetActive(true);
            }
            else
            {
                GameObject.Destroy(obj);
            }
        });
    }

    public static void DestroyPickIcon()
    {
        MonsterId = 0;
        List<long> list = new List<long>();
        foreach (long uid in Icons.Keys)
        {
            list.Add(uid);
        }
        foreach (long uid in list)
        {
            GameObject icon = Icons[uid];
            Icons.Remove(uid);
            icon.transform.parent = null;
            GameObject.Destroy(icon);
            AssetMgr.Instance.Unload(Name, ".png", false);
        }
    }

    public static void DestroyPickIcon(Int64 id)
    {
        if (id != - 1 && MonsterId != id) return;
        DestroyPickIcon();
    }
}
