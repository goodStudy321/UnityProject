using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using LuaInterface;


public class GameSceneInitTrigger
{
    public static readonly GameSceneInitTrigger instance = new GameSceneInitTrigger();

    private Action StartCallback;
    private Action Callback;
    private Timer timer;
    private bool isStartTimer = false;

    private GameSceneInitTrigger()
    {
        timer = new Timer();
        timer.complete += OnComplete;
    }

    public void StartTrigger(Action startCallback, Action callback)
    {
        this.StartCallback = startCallback;
        Callback = callback;
        CutscenePlayMgr.instance.OpenUIMask = true;
        CutscenePlayMgr.instance.RegisterEventAtStart(OnStarCutsceneCallback);
        Phantom.EndGame.end += TriggerEndGame;
        FlowChartMgr.Start("Start");
        if (isStartTimer) return;
        isStartTimer = true;
        timer.Seconds = 5.0f;
        timer.Start();
    }

    public void CloseMaskUI()
    {
        if(CutscenePlayMgr.instance.OpenUIMask)
        {
            CutscenePlayMgr.instance.OpenUIMask = false;
            UIMgr.Close(UIName.UIMask);
        }
    }

    /// <summary>
    /// 正式开始播放过场动画回调
    /// </summary>
    private void OnStarCutsceneCallback()
    {
        if (timer != null && timer.Running)
        {
            timer.Stop();
            isStartTimer = false;
        }
        CutscenePlayMgr.instance.UnregisterEventAtStart(OnStarCutsceneCallback);
        if (StartCallback != null)
        {
            StartCallback();
            StartCallback = null;
        }
    }

    /// <summary>
    /// 流程树结束回调
    /// </summary>
    private void TriggerEndGame(string name, bool isWin)
    {
        Phantom.EndGame.end -= TriggerEndGame;
        if (Callback != null)
        {
            Callback();
            Callback = null;
        }
    }

    private void OnComplete()
    {
        isStartTimer = false;
        OnStarCutsceneCallback();
        TriggerEndGame(string.Empty, false);
    }
}