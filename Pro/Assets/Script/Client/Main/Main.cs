#define OPTIMISE_NGUI_GC_ALLOC

using System;
using Phantom;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

/*
 * CO:            
 * Copyright:   2017-forever
 * CLR Version: 4.0.30319.42000  
 * GUID:        42fe9440-1bdc-43e5-b14b-ed66692c2db2
*/

/// <summary>
/// AU:Loong
/// TM:2017/5/15 10:19:34
/// BG:入口
/// </summary>
public class Main : MonoBehaviour, DebugListener
{
    #region 字段

    private bool started = false;

#if LOONG_ENABLE_UPG
    /// <summary>
    /// 更新入口
    /// </summary>
    private UpgEntry upgEntry = new UpgEntry();

    
    /// <summary>
    /// 启动动画
    /// </summary>
    private SplashScreen splash = new SplashScreen();
#endif

    //private int mClientId = 0;

    //#if GAME_DEBUG
    /// <summary>
    /// Debug输出
    /// </summary>
    //public PlayDebugService mDebugInstance = new PlayDebugService();
    //#endif
    #endregion

    #region 属性

    #endregion

    #region 构造方法

    #endregion

    #region 私有方法
    private void Awake()
    {
        DontDestroyOnLoad(gameObject);
        Settting();
        Global.Main = this;
        App.Init();
        Phantom.Localization.Instance.Init();
        MonoEvent.Init();
        iTrace.Init();
        SetDebug();
#if LOONG_ENABLE_UPG
        splash.Init();
        upgEntry.Init();
#endif

        SdkFty.Init();

#if UNITY_EDITOR
        OpenGUILoad();
#else
        StartSDK();
#endif
        //LOONG_CONFUSE_MAIN_AWAKE
        /// LY add begin ///
        QualityMgr.SetDesignContentScale();
        /// LY add end ///

#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
        /// GS add begin///
        SdkPanelInit();
        /// GS add end ///
#endif      
    }
#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
    private void SdkPanelInit()
    {
        GameObject sdkPanelGbj = TransTool.Find(UIMgr.Root,"SdkPanel");
        if (sdkPanelGbj)
        {
            SdkPanel sdkPanel = sdkPanelGbj.transform.GetComponent<SdkPanel>();
            if (sdkPanel == null)
            {
                sdkPanel = sdkPanelGbj.AddComponent<SdkPanel>();
            }
            int permissionState = Sdk.Instance.GetPermissionResult();
            int termIndex = PlayerPrefs.GetInt("TermIndex");
            if (permissionState == 0 || termIndex <=1)
            {
                sdkPanel.gameObject.SetActive(true);
            }
        }
    }
#endif
    private void OpenGUILoad()
    {
        GUIMgr.Switch<GUILoadRes>();
        GUIMgr.close += CloseGUILoadRes;
    }

    private void CloseGUILoadRes(GUIBase ui)
    {
        if (ui is GUILoadRes)
        {
            StartSDK();
            GUIMgr.close -= CloseGUILoadRes;
            //var guiMain = GUIMgr.Switch<GUIMain>();
            //guiMain.selectSingle += SelectSingle;
            //guiMain.selectServer += SelectServer;
        }
    }

    private void SelectSingle()
    {
        SwitchEntry(BegSingle);
    }

    private void SelectServer()
    {
        SwitchEntry(BegServer);
    }


    private void Settting()
    {
        //LOONG_CONFUSE_MAIN_SETTING
        Screen.fullScreen = true;
        Screen.sleepTimeout = SleepTimeout.NeverSleep;
        Application.runInBackground = true;
        QualitySettings.vSyncCount = 0;
        Application.targetFrameRate = 30;
    }

    private bool HasSDK()
    {
        if (Application.isEditor) return false;

#if SDK_ANDROID_NONE || SDK_IOS_NONE
        return false;
#else
        return true;
#endif
    }

    private void StartSDK()
    {
        if (HasSDK())
        {
            if (App.SdkInit)
            {
                StartUp();
            }
            else
            {
                EventMgr.Add("Sdk_InitSuc_1", StartUp);
            }
        }
        else
        {
            StartUp();
        }
    }

#if LOONG_ENABLE_UPG
    private void StartUpg(Action cb)
    {
        upgEntry.complete += cb;
        if (splash.EnableSplash())
        {
            splash.Start(upgEntry.Start);
        }
        else
        {
            upgEntry.Start();
        }
    }
#endif

    private void SetDebug()
    {
        if (!App.IsDebug) return;
        ServeTime.Create();
        ServeTime.Instance.SetActive(false);
    }

    private void StartUp(params object[] args)
    {
        //LOONG_CONFUSE_MAIN_STARTUP
        if (started) return;
        started = true;
        iTrace.Log("Loong", "入口启动");

        AssetMgr.Init();
        Device.Instance.Init();

        AssetMgr.Instance.AutoCloseIPro = false;
        SwitchEntry(BegServer);
        //#if GAME_DEBUG
        //        ConnectDebug();
        //#endif


    }

    //    private void ConnectDebug()
    //    {
    //#if GAME_DEBUG
    //        mDebugInstance.Init();
    //        mDebugInstance.DebugListener = this;
    //        Application.logMessageReceivedThreaded += HandlerLog;
    //#endif
    //    }

    private void OnGUI()
    {
        GUIMgr.OnGUI();
    }

    /// <summary>
    /// 选择进入
    /// </summary>
    /// <param name="cb">回调</param>
    private void SwitchEntry(Action cb)
    {
#if UNITY_EDITOR

#if LOONG_TEST_UPG
        StartUpg(cb);
#else
        if (cb != null) cb();
        SetEntryDisable();
#endif

#elif LOONG_ENABLE_UPG
        StartUpg(cb);
#endif
    }

    private void SetEntryDisable()
    {
        var root = GameObject.Find("UI Root");
        TransTool.SetChildActive(root, "Splash", false);
        TransTool.SetChildActive(root, "MsgBox", false);
        TransTool.SetChildActive(root, "UILoading", false);
    }


    private void RealBeg(Action cb)
    {
        //LOONG_CONFUSE_MAIN_REALBEG
        LuaMgr.Refresh();
        var am = AssetMgr.Instance;
        am.Dispose(false);
        am.Manifest = null;
        am.complete += cb;
        UIMgr.Open(UIName.UILoading);
    }

    private void RealEnd()
    {
        //LOONG_CONFUSE_MAIN_REALEND
        MsgBoxProxy.Instance.Dispose();
        ProgressProxy.Instance.Dispose();
        LuaTable luaTable = UIMgr.Get(UIName.UILoading);
        UILoading.Instance.Refresh(luaTable);
        /// LY add begin ///

        //#if CS_HOTFIX_ENABLE
        HotfixCheckMgr.Instance.Initialize();
        UIScreenShotMask.Instance.Initialize();
        //#endif

        /// LY add end ///
    }

    /// <summary>
    /// 单机入口
    /// </summary>
    private void BegSingle()
    {
        Global.Mode = PlayMode.Local;
        iTrace.Log("Loong", "单机入口");
        RealBeg(EndSingle);

    }

    /// <summary>
    /// 结束单机入口
    /// </summary>
    private void EndSingle()
    {
        RealEnd();
        AssetMgr.Instance.complete -= EndSingle;
        Config.Load(SingleEntryCb);
    }

    /// <summary>
    /// 服务器入口
    /// </summary>
    private void BegServer()
    {
        Global.Mode = PlayMode.Network;
        iTrace.Log("Loong", "服务器入口");
        RealBeg(EndServer);
    }

    /// <summary>
    /// 结束服务器入口
    /// </summary>
    private void EndServer()
    {
        RealEnd();
        AssetMgr.Instance.complete -= EndServer;
        Config.Load(ServerEntryCb);
    }

    private void SingleEntryCb()
    {
        iTrace.Log("Loong", "加载配置完成,单机进入");
        AssetMgr.Instance.AutoCloseIPro = true;
        User.instance.Init();
        User.instance.SceneId = 10001;
        GameSceneManager.instance.ChangeScene(User.instance.SceneId);
    }

    private void ServerEntryCb()
    {
        AssetMgr.Instance.AutoCloseIPro = true;
        AccMgr.instance.EnterLoginScene();
        User.instance.Init();
#if LOONG_SUB_ASSET
        PackDl.Instance.StartUp();
#endif
    }

    private void Update()
    {
        NetObserver.Update();
        Global.Update();
    }

    private void LateUpdate()
    {
        Global.LateUpdate();
    }

#endregion

#region 保护方法

#endregion

#region 公开方法

    /// <summary>
    /// Debug接口方法（DebugListener）
    /// </summary>
    /// <param name="clientId"></param>
    public void OnRegister(int clientId)
    {
        //mClientId = clientId;
    }

    //    public void HandlerLog(string logString, string stacTrace, LogType type)
    //    {
    //#if GAME_DEBUG
    //        mDebugInstance.SendLog(logString);
    //        if (type == LogType.Exception || type == LogType.Error)
    //        {
    //            mDebugInstance.SendLog(stacTrace);
    //        }
    //#endif
    //    }

#endregion
}