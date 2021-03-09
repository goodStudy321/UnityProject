using System;
using Phantom;
using ProtoBuf;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using UnityEngine.Profiling;


public static class Global
{
    private static Main main = null;

    private static PlayMode mode = PlayMode.Local;

    private static ActionSetupInfo mActionSetup = null;

    private static bool IsHideUIRoot = false;


    #region Property
    /// <summary>
    /// 入口脚本
    /// </summary>
    public static Main Main
    {
        get { return main; }
        set { main = value; }
    }

    /// <summary>
    /// 运行模式
    /// </summary>
    public static PlayMode Mode
    {
        get { return mode; }
        set { mode = value; }
    }

    /// <summary>
    /// 动作编辑信息
    /// </summary>
    public static ActionSetupInfo ActionSetupData
    {
        get { return mActionSetup; }
        set { mActionSetup = value; }
    }
    #endregion

    public static void Initialize()
    {
        SymbolMgr.Init();
        AccMgr.instance.Initialize();
        CameraMgr.Initialize();
        CollectionMgr.Initialize();
        DropMgr.Initialize();
        UISkill.instance.Initialize();
        AutoFbSkills.instance.Init();
        AutoPlaySkill.instance.Init();
        GameEventManager.instance.Initialize();
        FightModMgr.instance.Init();

        ModuleMgr.Init();
        SettingMgr.instance.Init();
#if LOONG_ENABLE_UPG
        AssetMf.SetLvs();
        AssetRepair.Instance.Init();
#endif
        PreloadAreaMgr.Instance.Init();
        BossBarMgr.instance.AddLsnr();
        //QualityMgr.instance.Initialize();
    }

    /// <summary>
    /// 更新
    /// </summary>
    public static void Update()
    {

        LuaMgr.Update();
        HeartBeat.instance.Update();
        InputMgr.instance.Update();
        UnitMgr.instance.Update(Time.deltaTime);
        UISkill.instance.Update();
        GameEventManager.instance.Update();
        MapPathMgr.instance.Update(Time.deltaTime);
        PathTool.PathMoveMgr.instance.Update(Time.deltaTime);
        HangupMgr.instance.Update();
        PendantMgr.instance.Update();
        DropMgr.Update();
        OffLineBatMgr.instance.Update();
        LockTarMgr.instance.Update();


   

        TimerMgr.Update();
        TweenMgr.Update();
        ModuleMgr.Update();
        ScreenUtil.Update();
        GestureMgr.Update();
        FlowChartMgr.Update();



        SceneGridMgr.Update();
        CollectionMgr.Update();

        Profiler.BeginSample("TestMainUpdate4");
        NetworkClient.Update();
        Profiler.EndSample();

        SceneTriggerMgr.Update();

        QualityMgr.instance.Update(Time.deltaTime);

        CameraEffMgr.instance.Update(Time.deltaTime);

        UIScreenShotMask.Instance.Update();

        if(IsHideUIRoot) HideUIRoot();

#if GAME_DEBUG
        iTrace.Update();
#endif
    }

    public static void LateUpdate()
    {
        NPCMgr.instance.LateUpdate();
        UnitMgr.instance.LateUpdate();
        CameraMgr.LateUpdate();
        LuaMgr.LateUpdate();
    }


    private static void HideUIRoot()
    {
        if (UIMgr.Root)
        {
            if (Input.GetMouseButtonDown(0)== true || Input.touchCount == 1 && Input.GetTouch(0).phase == TouchPhase.Ended)
            {
                Vector3 Pos = Vector3.zero;
                if (Application.platform == RuntimePlatform.WindowsEditor || Application.platform == RuntimePlatform.WindowsPlayer
                || Application.platform == RuntimePlatform.OSXEditor || Application.platform == RuntimePlatform.OSXPlayer)
                {
                    Pos = Input.mousePosition;
                }
                else
                {
                    Pos = Input.GetTouch(0).position;
                }
                float x = Screen.width / 2;
                float y = Screen.height / 2;
                if (Pos.x > x && Pos.y > y)
                {
                    UIMgr.Root.gameObject.SetActive(! UIMgr.Root.gameObject.activeSelf);
                }
            }
        }
    }
}