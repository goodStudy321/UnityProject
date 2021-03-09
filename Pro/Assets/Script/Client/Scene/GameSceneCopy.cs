using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;

/// <summary>
/// 
/// </summary>
public class GameSceneCopy : GameSceneBase
{

    public override void OpenScene(SceneInfo info, Action cb)
    {
        base.OpenScene(info, cb);
    }

    protected override void PreloadScene()
    {
        if (SceneManager.GetActiveScene().name != mSceneInfo.resName.list[0]) base.PreloadScene();
    }

    protected override void PreloadFinish()
    {
        if (SceneManager.GetActiveScene().name == mSceneInfo.resName.list[0])
        {
            mIsLoadScene = false;
            LoadSceneFinish(SceneManager.GetActiveScene(), LoadSceneMode.Additive);
        }
        else
        {
            base.PreloadFinish();
        }
    }
   
    public override void LoadSceneFinish(Scene scene, LoadSceneMode model)
    {
        if(!mIsLoadScene)
        {
            UIMgr.Close(UIName.UILoading);
            mIsLoadScene = true;
            LoadSceneUpdateData();
        }
        else
        {
            base.LoadSceneFinish(scene, model);
        }
    }
}
