using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using Loong.Game;
using System;

public class NetWorldBoss
{
    public static int BossTie = 0;
    public static int ItemAddTimes = 0;
    public static void SetBossTie(params object[] obj)
    {
        if (obj == null)
            return;
        if (obj.Length == 0)
            return;
        BossTie = Convert.ToInt32(obj[0]);
        ItemAddTimes = Convert.ToInt32(obj[1]);
    }
    #region Server --> Client
    /// <summary>
    /// 进入地图次数列表反馈
    /// </summary>
    /// <param name="obj"></param>
    public static List<p_kv> MapEnterList = new List<p_kv>();
    public static void RespMapEnterList(object obj)
    {
        m_map_enter_list_toc info = obj as m_map_enter_list_toc;
        int count = info.enter_list.Count;
        for(int i = 0; i < count; i++)
        {
            p_kv kv = info.enter_list[i];
            p_kv kvo = MapEnterList.Find((o) => { return o.id == kv.id; });
            if(kvo != null)
            {
                kvo.val = kv.val;
                continue;
            }
            p_kv kvn = ObjPool.Instance.Get<p_kv>();
            kvn.id = kv.id;
            kvn.val = kv.val;
            MapEnterList.Add(kvn);
        }
    }
    #endregion

    #region 协议监听
    public static void AddListener()
    {
        EventMgr.Add(EventKey.BossTie, SetBossTie);
        NetworkListener.Add<m_map_enter_list_toc>(RespMapEnterList);
    }

    public static void RemoveListener()
    {
        EventMgr.Remove(EventKey.BossTie, SetBossTie);
        NetworkListener.Remove<m_map_enter_list_toc>(RespMapEnterList);
    }
    #endregion
    #region 协议监听
    public static void Clear()
    {
        MapEnterList.Clear();
    }
    #endregion
}
