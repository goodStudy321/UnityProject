using System.Collections;
using System.Collections.Generic;
using System.Net;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;

public class ReConnectMgr
{
    public static readonly ReConnectMgr instance = new ReConnectMgr();

    private ReConnectMgr() { }

    #region 字段
    private static Timer waitTimer = null;
    #endregion

    #region 重连协议
    public List<string> GetCnnInfo()
    {
        List<string> infos = new List<string>();
        infos.Add(Device.Instance.Model);
        infos.Add(Device.Instance.OS);
        infos.Add(Device.Instance.SysVer);
        infos.Add(Device.Instance.NetType);
        infos.Add(Device.Instance.IMEI);
        infos.Add(Application.identifier);
        infos.Add(Screen.width.ToString());
        infos.Add(Screen.height.ToString());
        return infos;
    }
    /// <summary>
    /// 重连请求
    /// </summary>
    /// <param name="key"></param>
    /// <param name="roleId"></param>
    /// <param name="time"></param>
    public static void ReqReConnect(string key, long roleId, int time)
    {
        m_role_reconnect_tos info = ObjPool.Instance.Get<m_role_reconnect_tos>();
        info.key = key;
        info.role_id = roleId;
        info.time = time;
        List<string> infos = ReConnectMgr.instance.GetCnnInfo();
        info.device_args.AddRange(infos);
        NetworkClient.Send<m_role_reconnect_tos>(info);
    }

    /// <summary>
    /// 重连返回
    /// </summary>
    /// <param name="obj"></param>
    public static void RespReConnect(object obj)
    {
        m_role_reconnect_toc info = new m_role_reconnect_toc();
        EventMgr.Trigger("HideLoading");
        StopTimer();
        if (info.err_code == 0)
        {
            DisposeTool.Reconnection();
            HeartBeat.instance.LoginGame = true;
            return;
        }
        MsgBox.SetConDisplay(true);
        MsgBox.Show(620005, 620008, ReConnect, 690001, ExitApp);
        MsgBox.closeOpt = MsgBox.CloseOpt.No;
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 重新连接
    /// </summary>
    public static void ReConnect()
    {
        EventMgr.Trigger(EventKey.DataClear, true);
        if (HeartBeat.instance.mPTimeout)
        {
            ReLogin();
            return;
        }
        EventMgr.Trigger("ShowLoading");
        NetworkClient.Disconnect();
        NetworkClient.DisableSend = true;
        Global.Main.StartCoroutine(ReCnnt(0.2f));
    }

    /// <summary>
    /// 开始计时
    /// </summary>
    private static void StartTimer()
    {
        if(waitTimer == null)
        {
            waitTimer = ObjPool.Instance.Get<Timer>();
            waitTimer.Seconds = 8f;
            waitTimer.complete += TimerOut;
        }
        if(waitTimer.Running)
        {
            waitTimer.Stop();
        }
        waitTimer.Start();
    }

    /// <summary>
    /// 停止计时
    /// </summary>
    private static void StopTimer()
    {
        if (waitTimer == null)
            return;
        waitTimer.Stop();
    }

    /// <summary>
    /// 计时完成
    /// </summary>
    private static void TimerOut()
    {
        MsgBox.SetConDisplay(true);
        MsgBox.Show(620005, 620008, ReConnect, 690001, ExitApp);
        MsgBox.closeOpt = MsgBox.CloseOpt.No;
    }

    private static bool CanRecnnt()
    {
        //Debug.LogFormat("Loong, {0} {1}", NetworkClient.SktRecv.Running, NetworkClient.State);
        if (NetworkClient.SktRecv.Running) return false;
        if (NetworkClient.State == NetworkConnectState.Disconnecting) return false;
        return true;
    }

    /// <summary>
    /// 重连协程
    /// </summary>
    /// <param name="time"></param>
    /// <returns></returns>
    private static IEnumerator ReCnnt(float time)
    {
        yield return YeildWait();
        yield return new WaitForSeconds(time);

        //if (!User.instance.IP.Contains(User.DNSKey))
        //{
        //    NetworkClient.Connect(User.instance.IP, User.instance.Port, ConnectCallback, null, System.Net.Sockets.AddressFamily.InterNetwork);
        //    yield return null;
        //}
        /*IPHostEntry hostInfo = Dns.GetHostEntry(User.instance.IP);
        IPAddress ipAddress = hostInfo.AddressList[0];
        NetworkClient.Connect(ipAddress.ToString(), User.instance.Port, ConnectCallback, null, ipAddress.AddressFamily);*/

        NetworkMgr.Connect(User.instance.IP, User.instance.Port, ConnectCallback);
    }

    /// <summary>
    /// 连接服务器返回
    /// </summary>
    /// <param name="err"></param>
    private static void ConnectCallback(string err)
    {
        if (string.IsNullOrEmpty(err))
        {
            long roleId = User.instance.MapData.UID;
            if (roleId == 0)
            {
                NetworkClient.DisableSend = false;
                ReLogin();
                return;
            }
            int time = (int)(Utility.GetCurTime() * 0.001f);
            string key = Md5Crypto.Gen("gateway-auth-key" + time).ToLower();

            NetworkClient.DisableSend = false;
            ReqReConnect(key, roleId, time);
            NetworkClient.DisableSend = true;
            HeartBeat.instance.Reset();
            StartTimer();
        }
        else
        {
            MsgBox.SetConDisplay(true);
            MsgBox.Show(620009, 620008, ReConnect, 690001, ExitApp);
            MsgBox.closeOpt = MsgBox.CloseOpt.Yes;
        }
    }

    /// <summary>
    /// 重新登录
    /// </summary>
    public static void ReLogin()
    {
        UIMgr.Close(UIName.UILoading);
        AssetMgr.Instance.AutoCloseIPro = true;
        EventMgr.Trigger("HideLoading");
        User.instance.IsInitLoadScene = true;
        NetworkMgr.IsLoadReady = false;
        NetworkMgr.ReqPreID = 0;
        HeartBeat.instance.Reset();
        AccMgr.instance.Logout();
        CutscenePlayMgr.instance.OpenUIMask = false;
    }

    public static void ExitApp()
    {
#if UNITY_EDITOR
        ReLogin();
#else
        App.Quit();
#endif
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 显示重连
    /// </summary>
    public void ShowRcnn()
    {
        NetworkClient.Disconnect();
        MsgBox.SetConDisplay(true);
        Global.Main.StartCoroutine(YieldShowRcnn());
    }

    private IEnumerator YieldShowRcnn()
    {
        yield return YeildWait();
        MsgBox.Show(620010, 620008, ReConnect, 690001, ReLogin);
        MsgBox.closeOpt = MsgBox.CloseOpt.No;
    }

    /// <summary>
    /// 等断开线程执行完成再等待两帧
    /// </summary>
    /// <returns></returns>
    private static IEnumerator YeildWait()
    {
        while (!CanRecnnt()) yield return null;
        for (int i = 0; i < 2; ++i) yield return new WaitForEndOfFrame();
    }
    #endregion
}
