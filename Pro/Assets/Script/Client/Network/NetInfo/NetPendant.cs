using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Phantom.Protocal;
using Loong.Game;

public class NetPendant
{
    #region Client --> Server
    /// <summary>
    /// ����ı�����״̬(0 ����� 1 �����
    /// </summary>
    /// <param name="status"></param>
    public static void RequestChangeMount(int status)
    {
        m_mount_status_change_tos mountStatusChange = ObjPool.Instance.Get<m_mount_status_change_tos>();
        mountStatusChange.status = status;
        NetworkClient.Send<m_mount_status_change_tos>(mountStatusChange);
    }
    #endregion
}
