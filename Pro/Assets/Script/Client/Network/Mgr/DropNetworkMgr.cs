using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;
using System;

public static class DropNetworkMgr
{
    #region 监听事件
    public static void DropAddListener()
    {
        NetworkListener.Add<m_pick_drop_toc>(ResqPickDrop);

        EventMgr.Add("m_pick_drop_tos", ReqPickDrop);
    }
    #endregion

    #region 移除事件
    public static void DropRemoveListener()
    {
        NetworkListener.Add<m_pick_drop_toc>(ResqPickDrop);


        EventMgr.Remove("m_pick_drop_tos", ReqPickDrop);
    }
    #endregion

    #region Client------->Server
    /// <summary>
    /// 拾取掉落物
    /// </summary>
    /// <param name="args"></param>
    public static void ReqPickDrop(params object[] args)
    {
        m_pick_drop_tos data = ObjPool.Instance.Get<m_pick_drop_tos>();
        data.drop_id = Convert.ToInt64(args[0]);
       //Debug.Log("请求拾取掉落物   id:    " + data.drop_id);
        NetworkClient.Send<m_pick_drop_tos>(data);
    }

    #endregion

    #region Server-------->Client
    /// <summary>
    /// 拾取掉落物返回
    /// </summary>
    /// <param name="obj"></param>
    public static void ResqPickDrop(object obj)
    {
        //TODO:
        UITip.eWarning("拾取掉落物返回");
        m_pick_drop_toc data = obj as m_pick_drop_toc;
        String error = ErrorCodeMgr.GetError(data.err_code);
        if (data.err_code != 0) UITip.Log(error);
        Int64 dropId = data.drop_id;
        //Debug.LogError("拾取掉落物返回:  error: " + data.err_code + "   id:  " + dropId);
        EventMgr.Trigger("m_pickUp", data.err_code, dropId);
    }

    #endregion
}
