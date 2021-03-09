using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using Phantom.Protocal;
using System;

public class HeartBeat
{
    public static readonly HeartBeat instance = new HeartBeat();

    private HeartBeat()
    {
        SocketReceive.onLsnr += SocketReceive_onLsnr;
        MonoEvent.onPause += OnAppPause;
#if LOONG_ENABLE_UPG
        AssetRepair.Instance.start += OnRepairBeg;
        AssetRepair.Instance.complete += OnRepairEnd;
#endif
    }

    #region 私有变量
    //发送心跳包时间
    private static float mSendPackTime = 0;
    //断开连接判断时间
    private static float mDisCnntTime = 0;
    //是否收到请求心跳包
    private static bool bRecievePack = true;
    //自动重连中
    private static bool bAutoCnnting = false;
    //是否已经在登陆状态
    private bool bLoginGame = false;
    //是否全速下载中
    private bool bFSpDLing = false;
    //开始挂起时间
    private float mBgPTime;
    private bool isStop = false;
    #endregion

    #region 公有变量
    /// <summary>
    /// 连接超时
    /// </summary>
    public static bool bConnectOverTime = false;
    /// <summary>
    /// 时间差（毫秒）
    /// </summary>
    public static double mTimeDefference = 0;
    /// <summary>
    /// 运行状态
    /// </summary>
    public bool mRunState = false;
    /// <summary>
    /// 挂起超时
    /// </summary>
    public bool mPTimeout = false;


    public bool IsStop
    {
        get { return isStop; }
        set
        {
            isStop = value;
            if (value == true)
                mDisCnntTime = 0;
        }
    }

    #endregion

    #region 属性
    /// <summary>
    /// 是否登录了游戏
    /// </summary>
    public bool LoginGame
    {
        get { return bLoginGame; }
        set
        {
            bLoginGame = value;
            if (value == true)
                return;
            Reset();
        }
    }

    /// <summary>
    /// 是否全速下载中
    /// </summary>
    public bool FSpDLing
    {
        get { return bFSpDLing; }
        set { bFSpDLing = value; }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 协议接收监听
    /// </summary>
    private void SocketReceive_onLsnr()
    {
        CDisCnntT();
    }
    /// <summary>
    /// 应用挂起状态回调
    /// </summary>
    private void OnAppPause(bool pause)
    {
        if (!ChkHrtCon())
            return;
        if (mRunState == true)
            return;
        if (pause == true)
        {
            mBgPTime = Time.realtimeSinceStartup;
        }
        else
        {
            float pTime = Time.realtimeSinceStartup - mBgPTime;
            if (pTime < 90)
                return;
            mPTimeout = true;
            SetRcnn();
        }
    }

    /// <summary>
    /// 检查心跳条件
    /// </summary>
    /// <returns></returns>
    private bool ChkHrtCon()
    {
#if UNITY_EDITOR
        if (Global.Mode == PlayMode.Local)
            return false;
#endif
        if (!bLoginGame)
            return false;
        if (bFSpDLing)
            return false;
        //if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneLoading)
        //return false;
        if (isStop)
            return false;
        if (bConnectOverTime)
            return false;
        return true;
    }

    /// <summary>
    /// 检查重连
    /// </summary>
    private void ChkRcnn()
    {
        //float deltaTime = Time.unscaledDeltaTime;
        var deltaTime = GetDeltaTime();
        mSendPackTime += deltaTime;
        mDisCnntTime += deltaTime;
        if (!bAutoCnnting && mDisCnntTime > 5f)
        {
            iTrace.Log("Trigger 5 seconds auto connect", "----------------");
            bAutoCnnting = true;
            ReConnectMgr.ReConnect();
            return;
        }
        if (mSendPackTime > 1 && bRecievePack)
        {
            ReqHeartbeat();
            bRecievePack = false;
            mSendPackTime = 0;
        }
    }

    /// <summary>
    /// 获取增量时间
    /// 如果出现卡顿(耗时超过理想帧数范围,暂定0.03秒)情况,将卡顿帧耗时重新计算为理想帧数耗时
    /// </summary>
    /// <returns></returns>
    private float GetDeltaTime()
    {
        var targetFrame = Application.targetFrameRate * 1f;
        var targetDelta = 1f / targetFrame;
        var deltaTime = Time.unscaledDeltaTime;
        if (deltaTime - targetDelta > 0.01f)
        {
            return targetDelta;
        }
        return deltaTime;
    }

    /// <summary>
    /// 开始资源修复时
    /// </summary>
    private void OnRepairBeg()
    {
        FSpDLing = true;
#if UNITY_EDITOR
        Debug.Log("Loong, OnRepairBeg");
#endif
    }

    /// <summary>
    /// 结束资源修复时
    /// </summary>
    /// <param name="isQuit"></param>
    private void OnRepairEnd(bool isQuit)
    {
        FSpDLing = false;
#if UNITY_EDITOR
        Debug.Log("Loong, OnRepairEnd");
#endif
    }

    /// <summary>
    /// 关闭重连弹框
    /// </summary>
    private static void CloseMsgBox()
    {
        if (bConnectOverTime == false)
            return;
        UIMgr.Close(UIName.MsgBox);
    }
    #endregion


    #region 公有方法
    /// <summary>
    /// 心跳请求
    /// </summary>
    /// <param name="time"> </param>
    /// <param name="serverTime"></param>
    public static void ReqHeartbeat()
    {
        m_system_hb_tos req = ObjPool.Instance.Get<m_system_hb_tos>();
        NetworkClient.Send<m_system_hb_tos>(req);
    }

    /// <summary>
    /// 心跳响应
    /// </summary>
    /// <param name="obj"></param>
    public static void RespHeartbeat(object obj)
    {
        m_system_hb_toc resp = obj as m_system_hb_toc;
        User.instance.ServerTime = resp.server_time;
        double localTime = Utility.GetCurTime();
        mTimeDefference = localTime - resp.server_time;

        Clear();
        //CSndPT();
    }

    /// <summary>
    /// 重置数据
    /// </summary>
    public void Reset()
    {
        bLoginGame = false;
        mPTimeout = false;
        Clear();
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public static void Clear()
    {
        CSndPT();
        CDisCnntT();
    }

    /// <summary>
    /// 清理心跳发送时间
    /// </summary>
    public static void CSndPT()
    {
        CloseMsgBox();
        bRecievePack = true;
        mSendPackTime = 0;
    }

    /// <summary>
    /// 清理断线连接时间
    /// </summary>
    public static void CDisCnntT()
    {
        CloseMsgBox();
        bConnectOverTime = false;
        bAutoCnnting = false;
        mDisCnntTime = 0;
    }

    /// <summary>
    /// 设置重连
    /// </summary>
    public static void SetRcnn()
    {
        EventMgr.Trigger("HideLoading");
        bConnectOverTime = true;
        ReConnectMgr.instance.ShowRcnn();
        mDisCnntTime = 0;
    }

    public void Update()
    {
        if (!ChkHrtCon())
            return;
        ChkRcnn();
    }
    #endregion
}
