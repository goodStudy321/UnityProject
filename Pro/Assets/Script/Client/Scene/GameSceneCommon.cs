using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 普通场景切换
/// </summary>
public class GameSceneCommon : GameSceneBase
{

    public override void OpenScene(SceneInfo info, Action cb)
    {
        base.OpenScene(info, cb);
    }

    /// <summary>
    /// 加载场景模型完成回调
    /// </summary>
    protected override void LoadSceneFinishFun()
    {
        if(Global.Mode == PlayMode.Network)
        {
            if (CameraMgr.ChangeMissionCameraInfo(true) == false)
                if (mSceneInfo.camSet != 0)CameraMgr.UpdatePostprocessing(mSceneInfo.camSet);
            //等级小于1时候要播放过场动画
            if (/*!User.instance.IsCreateScene &&*/ User.instance.MapData.Level <= 1)
            {
                mSceneLoadState = SceneLoadStateEnum.SceneDone;
                GameSceneInitTrigger.instance.StartTrigger(OnStarCutsceneCallback,OnEndCallback);
                QualityMgr.instance.ChangeSceneToCurQuality();
                return;
            }
            base.LoadSceneFinishFun();
        }
        else  
        {
            //单机模式
            if (CameraMgr.ChangeMissionCameraInfo(true) == false)
                if (mSceneInfo.camSet != 0) CameraMgr.UpdatePostprocessing(mSceneInfo.camSet);
            UnitMgr.instance.CreateSceneUnit();
            UpdateConfigsUI();
        }
    }

    /// <summary>
    /// 正式开始播放过场动画了
    /// </summary>
    private void OnStarCutsceneCallback()
    {
        UIMgr.Close(UIName.UILoading);
        AssetMgr.Instance.AutoCloseIPro = true;
    }

    private void OnEndCallback()
    {
        UIMgr.Open(UIName.UIMainMenu);
        InitEnterScene();
    }

    protected override void OtherUpdate()
    {
        GameSceneInitTrigger.instance.CloseMaskUI();
    }
}
