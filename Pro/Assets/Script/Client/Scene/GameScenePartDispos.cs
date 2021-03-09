using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using UnityEngine;
using Phantom;
using Loong.Game;
using LuaInterface;

/// <summary>
/// 
/// </summary>
public class GameScenePartDispos : GameSceneBase
{

    public bool BackScene = false;

    public override void OpenScene(SceneInfo info, Action cb)
    {
        //AccMgr.instance.Unload();
        SetCopyType(info.id);
        ///
        /// 留白 冻结寻路路径
        /// 
        elapsed.Beg();
        mSceneInfo = info;
        mPreloadRes = true;
        mSceneLoadState = SceneLoadStateEnum.SceneLoading;
        if (cb != null) mOpenSceneCallBack += cb;
        //if (User.instance.IsWaitLoadFlowChart && info.id == User.instance.WaitLoadSceneId)

        if (mLuaOpenScene != null) LuaTool.Call(mLuaOpenScene, info.id);
        PreloadAreaMgr.Instance.Clear();
        GetUIConfig();
        BeforePreload();
        Unit unit = InputMgr.instance.mOwner;
        CamBatMgr.instance.Initialize();
        ShowEffectMgr.instance.SetShowEffNum(info);
        PendantMgr.instance.SetLocalPendantsShowState(unit, false, OpStateType.ChangeScene);
    }

    protected override void BeforePreload()
    {
        if (mLuaBeforePreload != null) LuaTool.Call(mLuaBeforePreload);
        SceneTriggerMgr.Preload(mSceneInfo);
        FlowChartMgr.PreloadMission(mSceneInfo);

        if(BackScene == false)
        {
            /// LY add begin ///
            /// 预预加载地图资源 ///
            if ((GameSceneType)mSceneInfo.sceneType != GameSceneType.GST_Unknown)
            {
                BinaryMapData tMapData = MapDataStore.Instance.GetPersistMapData(mSceneInfo.mapId);
                if(tMapData == null)
                {
                    tMapData = MapDataStore.Instance.GetTempPersistMapData(mSceneInfo.mapId);
                }
                if(tMapData != null)
                {
                    MapPathMgr.instance.SetPreloadMapData(tMapData);
                }
                else
                {
                    string dataRes = mSceneInfo.mapId.ToString() + ".bytes";
                    AssetMgr.Instance.Add(dataRes, LoadMapDataCB);
                    AssetMgr.Instance.Add(mSceneInfo.mapId + "_block", Suffix.Prefab, null);
                }
            }
            /// LY add end ///
            UIMgr.Open(UIName.UILoading, OpenLoadingCallback);
        }
        else
        {
            OpenLoadingCallback();
        }
    }

    /// <summary>
    /// 打开UILoading回调
    /// </summary>
    /// <param name="args"></param>
    protected override void OpenLoadingCallback(string uiName = null)
    {
        /// LY add begin ///
        CameraMgr.SetActive(true);
        /// LY add end ///
#if GAME_DEBUG
        iTrace.Log("Loong", "switch clear scene");
#endif
        AssetMgr.Instance.complete += Preload;
        AssetMgr.Start(null);
    }

    protected override void PreloadScene()
    {
        if (!BackScene) base.PreloadScene();
    }

    protected override void PreloadRes()
    {
        if (mSceneInfo == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "SceneInfo miss !!! ");
#endif
            return;
        }
        PreloadUI();

        SymbolMgr.Preload();
        TopBarFty.Preload();
        SceneGridMgr.Preload(mSceneInfo);

        PreloadMgr.audio.Add(mSceneInfo.bgm);

        MapPathMgr.instance.LoadMapData(mSceneInfo.mapId);
        //LoadMapSourceFin();
        if (EnablePrealodArea())
        {
            ///
            /// 激活寻路网格
            /// 
            LoadMapSourceFin();
        }
        else
        {
            FlowChartMgr.Preload();
            CollectionMgr.Preload(mSceneInfo);
            UnitPreLoad.instance.PreloadAllUnits(mSceneInfo);
        }
    }

    /// <summary>
    /// 预加载完成
    /// </summary>
    protected override void PreloadFinish()
    {
        AssetMgr.Instance.complete -= PreloadFinish;
        SceneInfo.res_screen resName = mSceneInfo.resName;
        if (resName != null && resName.list != null && resName.list.Count > 0)
        {
            Scene cur = SceneManager.GetActiveScene();
            if (!BackScene)
            {
                if (!string.IsNullOrEmpty(cur.name))
                {
                    //HideScene(cur, true);
                    SceneTool.SetActive(cur, false);
                }
                LoadSceneMode type = LoadSceneMode.Additive;
                for (int i = 0; i < resName.list.Count; i++)
                {
                    if (i != 0 || !BackScene) type = LoadSceneMode.Additive;
                    var sceneName = resName.list[i];
                    var scene = SceneTool.Get(sceneName);
                    if (scene.IsValid())
                    {
                        SceneTool.Switch(sceneName);
                        LoadSceneFinish(scene, type);
                    }
                    else
                    {
                        SceneManager.LoadScene(sceneName, type);
                    }
                }
            }
            else
            {
                if (!string.IsNullOrEmpty(cur.name))
                {
                    if (!AssetMgr.Instance.IsPersist(cur.name + Suffix.Scene))
                    {
                        SceneManager.UnloadSceneAsync(cur);
                    }
                }
                Scene scene = SceneManager.GetSceneByName(resName.list[0]);
                if(!string.IsNullOrEmpty(scene.name))
                {
                    LoadSceneFinish(scene, LoadSceneMode.Single);
                }
            }
        }

        if (mLuaPreloadFinish != null) LuaTool.Call(mLuaPreloadFinish);
    }

    /// <summary>
    /// 读取场景完成
    /// </summary>
    public override void LoadSceneFinish(Scene scene, LoadSceneMode mode)
    {
        //HideScene(scene, false);
        //SceneManager.SetActiveScene(scene);
        SceneTool.Switch(scene.name);

        Unit mainPlayer = InputVectorMove.instance.MoveUnit;
        if(mainPlayer != null)
        {
            UnitHelper.instance.SetRayHitPosition(mainPlayer.Position, mainPlayer);
        }

        base.LoadSceneFinish(scene, mode);
    }

    public override void OnChangeScene(bool isLoadScene, params object[] obj)
    {
        Unit mainPlayer = InputVectorMove.instance.MoveUnit;
        if(mainPlayer != null)
        {
            mainPlayer.mUnitMove.Pathfinding.ForceStopPathFinding(true);
        }
        base.OnChangeScene(isLoadScene, obj);
    }

    protected override void OtherUpdate()
    {
        if(mSceneInfo != null)
            BackScene = mSceneInfo.dontDestroy == 1;
    }

    public override void Dispose(bool destroyAll = false)
    {
        if (!BackScene)
            base.Dispose(destroyAll);
        else
            PartDispose();
    }

    public override void PartDispose(string unloadName = null)
    {
        if (BackScene)
            base.PartDispose(mSceneInfo.resName.list[0]);
        else
            base.PartDispose();
    }

    public void HideScene(Scene scene, bool isHide)
    {
        isHide = !isHide;
        GameObject[] objs = scene.GetRootGameObjects();
        for(int i = 0; i < objs.Length; i ++)
        {
            objs[i].SetActive(isHide);
        }
    }

    public bool IsReuse(SceneInfo info)
    {
        bool beScene = false;
        if(info != null)
        {
            SceneInfo.res_screen resName = info.resName;
            Scene scene = SceneManager.GetSceneByName(resName.list[0]);
            beScene = !string.IsNullOrEmpty(scene.name);
        }
        return BackScene == true && beScene == true;
    }
}
