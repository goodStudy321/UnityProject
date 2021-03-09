using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using Loong.Game;

public class NetRevive
{
    #region Client --> Server
    /// <summary>
    /// 请求复活
    /// </summary>
    /// <param name="reviveType"></param>
    public static void RequestRoleRevive(int reviveType)
    {
        m_role_relive_tos roleRevive = ObjPool.Instance.Get<m_role_relive_tos>();
        roleRevive.op_type = reviveType;
        NetworkClient.Send<m_role_relive_tos>(roleRevive);
    }
    #endregion

    #region Server --> Client
    /// <summary>
    /// 单位死亡
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeRoleDead(object obj)
    {
        m_role_dead_toc roleDead = obj as m_role_dead_toc;
        killerName = roleDead.src_name;
        reviveTime = roleDead.normal_relive_time;
        freeReviveCount = roleDead.normal_times;
        NetPendant.RequestChangeMount(0);
        BossBatMgr.instance.ResetData();
        EventMgr.Trigger(EventKey.SelfDead);
        SceneInfo info = SceneInfoManager.instance.Find((uint)User.instance.SceneId);
        if (info == null)
            return;
        if (info.isNorRevive == 0 && info.isOrigRevive == 0)
            return;
        //UIMgr.Open(UIName.UIRevive, OpenCallBack);
        OpenCallBack();
    }

    /// <summary>
    /// 单位复活
    /// </summary>
    /// <param name="obj"></param>
    public static void ResponeRoleRevive(object obj)
    {
        m_role_relive_toc roleRevive = obj as m_role_relive_toc;
        if(roleRevive.err_code != 0)
        {
            return;
        }
        EventMgr.Trigger(EventKey.ReLife);
        //UIMgr.Close(UIName.UIRevive);
    }
    #endregion

    #region 私有变量
    /// <summary>
    /// 击杀者
    /// </summary>
    private static string killerName = null;
    /// <summary>
    /// 复活时间
    /// </summary>
    private static int reviveTime = 0;
    /// <summary>
    /// 免费复活次数
    /// </summary>
    private static int freeReviveCount = 0;
    #endregion

    #region 私有方法
    /// <summary>
    /// 复活界面打开回调
    /// </summary>
    /// <param name="args"></param>
    private static void OpenCallBack()
    {
        EventMgr.Trigger(EventKey.RefreshReviveData, killerName, reviveTime, freeReviveCount);
    }
    #endregion
}
