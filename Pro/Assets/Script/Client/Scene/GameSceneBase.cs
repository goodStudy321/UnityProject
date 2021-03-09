using System;
using Phantom;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;
using Loong.Game;
using LuaInterface;

/// <summary>
/// 场景管理基类
/// </summary>
public partial class GameSceneBase
{

    #region 构造函数
    public GameSceneBase()
    {
        //SceneManager.sceneLoaded += LoadSceneFinish;
        SceneTool.onloaded += LoadSceneFinish;
        mOpenSceneCallBack += LoadSceneFinishFun;
        GetLua();
    }

    #endregion

    #region 打开场景
    /// <summary>
    /// 打开场景
    /// </summary>
    public virtual void OpenScene(SceneInfo info, Action cb)
    {
        //AccMgr.instance.Unload();
        SetCopyType(info.id);
        elapsed.Beg();
        mSceneInfo = info;
        ClearPathData();

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

    #endregion

    #region 预加载
    /// <summary>
    /// 预加载资源之前加载资源,有些资源的预加载必须在其它资源加载完才能获取
    /// </summary>
    protected virtual void BeforePreload()
    {
        if (mLuaBeforePreload != null) LuaTool.Call(mLuaBeforePreload);
        SceneTriggerMgr.Preload(mSceneInfo);
        FlowChartMgr.PreloadMission(mSceneInfo);

        /// LY add begin ///
        /// 预预加载地图资源 ///
        if ((GameSceneType)mSceneInfo.sceneType != GameSceneType.GST_Unknown)
        {
            BinaryMapData tMapData = MapDataStore.Instance.GetPersistMapData(mSceneInfo.mapId);
            if (tMapData == null)
            {
                tMapData = MapDataStore.Instance.GetTempPersistMapData(mSceneInfo.mapId);
            }
            if (tMapData != null)
            {
                MapPathMgr.instance.SetPreloadMapData(tMapData);
            }
            else
            {
                string dataRes = mSceneInfo.mapId.ToString() + ".bytes";
                AssetMgr.Instance.Add(dataRes, LoadMapDataCB);
                AssetMgr.Instance.Add(mSceneInfo.mapId + "_block", Suffix.Prefab, null);
                //AssetMgr.Instance.complete += LoadMapSourceFin;
            }
        }
        /// LY add end ///
        
        UIMgr.Open(UIName.UILoading, OpenLoadingCallback);
    }

    /// <summary>
    /// 预加载资源
    /// </summary>
    /// <returns></returns>
    protected void Preload()
    {
        AssetMgr.Instance.complete -= Preload;
        if (mPreloadRes)
        {
            if (mLuaPreload != null) LuaTool.Call(mLuaPreload);
            PreloadRes();
            PreloadScene();
            AssetMgr.Instance.complete += PreloadFinish;
            AssetMgr.Start();
        }
        else
        {
            PreloadFinish();
        }
    }

    protected virtual void PreloadScene()
    {
        List<Table.String> list = mSceneInfo.resName.list;
        for (int i = 0; i < list.Count; i++)
        {
            string resName = list[i];
            if (string.IsNullOrEmpty(resName)) continue;
            PreloadMgr.scene.Add(resName);
        }
    }

    /// <summary>
    /// 预加载资源
    /// </summary>
    protected virtual void PreloadRes()
    {
        if (mSceneInfo == null)
        {
#if UNITY_EDITOR
            iTrace.Error("LY", "SceneInfo miss !!! ");
#endif
            return;
        }

        if (mSceneInfo.resName != null && mSceneInfo.resName.list != null && mSceneInfo.resName.list.Count > 0)
        {
            List<Table.String> list = mSceneInfo.resName.list;
            for (int i = 0; i < list.Count; i++)
            {
                string resName = list[i];
                if (string.IsNullOrEmpty(resName)) continue;
                AssetMgr.Instance.LoadSceneCount++;
                LoadSceneCount++;
            }
        }
        PreloadUI();
        /// 地图数据 ///
        //if ((GameSceneType)mSceneInfo.sceneType != GameSceneType.GST_Unknown)
        //{
        //    AssetMgr.Instance.Add(mSceneInfo.mapId + "_block", Suffix.Prefab, LoadMapDataCallback);
        //}

        
        SymbolMgr.Preload();
        TopBarFty.Preload();
        SceneGridMgr.Preload(mSceneInfo);
        
        PreloadMgr.audio.Add(mSceneInfo.bgm);
        
        MapPathMgr.instance.LoadMapData(mSceneInfo.mapId);
        //LoadMapSourceFin();
        if (EnablePrealodArea())
        {
            LoadMapSourceFin();
        }
        else
        {
            FlowChartMgr.Preload();
            CollectionMgr.Preload(mSceneInfo);
            UnitPreLoad.instance.PreloadAllUnits(mSceneInfo);
        }
    }

    protected bool EnablePrealodArea()
    {
        if (mSceneInfo == null) return false;
        return mSceneInfo.enablePreload > 0;
    }

    /// <summary>
    /// 预加载UI
    /// </summary>
    protected void PreloadUI()
    {
        if (mConfigs == null) return;
        for (int i = 0; i < mConfigs.Count; i++)
        {
            PreloadMgr.UI(mConfigs[i]);
        }
    }
    #endregion

    #region 加载完成回调
    /// <summary>
    /// 读取场景完成调用方法
    /// </summary>
    protected virtual void LoadSceneFinishFun()
    {
        mSceneLoadState = SceneLoadStateEnum.SceneDone;
        GC.Collect();
        InitEnterScene();
    }

    /// <summary>
    /// 初始化登入场景数据
    /// 向服务器请求进入场景 
    /// </summary>
    protected virtual void InitEnterScene()
    {
        EventMgr.Trigger("UIMaskFadeOut");
        ushort camid = mSceneInfo.camSet;
        CameraMgr.SetActive(camid != 0);
        if (mSceneInfo != null && (GameSceneType)mSceneInfo.sceneType == GameSceneType.GST_Unknown)
        {
            //CreatePlayerMgr.instance.Init();
            if (CameraMgr.ChangeMissionCameraInfo(true) == false)
            {
                if (camid != 0) CameraMgr.UpdatePostprocessing(mSceneInfo.camSet);
            }
            OnChangeScene(true, (int)mSceneInfo.id);
            return;
        }
        if (CameraMgr.ChangeMissionCameraInfo(true) == false)
        {
            if (camid != 0) CameraMgr.UpdatePostprocessing(mSceneInfo.camSet);
        }
        GameSceneManager.instance.StarDownCount();

        //// LY add begin ////
        UnitMgr.instance.PreCreateOwner(MapPathMgr.instance.GetOriWantPos());
        if(CameraMgr.CamOperation != null)
        {
            ((CameraPlayerNewOperation)CameraMgr.CamOperation).ResetCamToDefPosImd();
        }
        if (User.instance.IsInitLoadScene == false)
        {
            //UpdateConfigsUI();

            if (!AssetMgr.Instance.AutoCloseIPro)
            {
                UIMgr.Close(UIName.UILoading);
                AssetMgr.Instance.AutoCloseIPro = true;
            }
        }
        //// LY add end ////
        NetworkMgr.EnterScene((Int32)mSceneInfo.id);
    }

    /// <summary>
    /// 打开UILoading回调
    /// </summary>
    /// <param name="args"></param>
    protected virtual void OpenLoadingCallback(string uiName)
    {
        MonoEvent.Start(LoadClearScene());
    }

    /// <summary>
    /// 加载过度场景
    /// </summary>
    /// <returns></returns>
    protected IEnumerator LoadClearScene()
    {
        /// LY add begin ///
        CameraMgr.SetActive(true);
        /// LY add end ///
        /// 
        if (mSceneInfo.resName.list.Count > 0)
        {
            yield return SceneTool.SwitchClear(mSceneInfo.resName.list[0]);
        }

        for (int i = 0; i < 2; i++)
        {
            yield return null;
        }
        AssetMgr.Instance.complete += Preload;
        AssetMgr.Start(null);
    }


    /// <summary>
    /// 预加载完成
    /// </summary>
    protected virtual void PreloadFinish()
    {
        AssetMgr.Instance.complete -= PreloadFinish;
        SceneInfo.res_screen resName = mSceneInfo.resName;
        if (resName != null && resName.list != null && resName.list.Count > 0)
        {
            LoadSceneMode type = LoadSceneMode.Additive;
            for (int i = 0; i < resName.list.Count; i++)
            {
                if (i != 0) type = LoadSceneMode.Additive;
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

        if (mLuaPreloadFinish != null) LuaTool.Call(mLuaPreloadFinish);
    }

    protected void LoadMapDataCB(Object obj)
    {
        if(obj == null || obj is TextAsset == false)
        {
            iTrace.Error("LY", " Map data error !!! ");
            return;
        }

        TextAsset textAsset = obj as TextAsset;
        if (textAsset == null)
        {
            iTrace.Error("LY", " No map data !!! ");
            return;
        }

        //BinaryMapData loadData = new BinaryMapData();
        BinaryMapData loadData = ObjPool.Instance.Get<BinaryMapData>();
        loadData.Read(textAsset.bytes);
        if(MapDataStore.Instance.CheckSceneMapPersist(loadData.mapId) == true)
        {
            MapDataStore.Instance.AddPersistMapData(loadData.mapId, loadData);
        }
        MapPathMgr.instance.SetPreloadMapData(loadData);
    }

    /// <summary>
    /// 加载地图资源完成回调
    /// </summary>
    /// <param name="obj"></param>
    protected void LoadMapSourceFin()
    {
        //AssetMgr.Instance.complete -= LoadMapSourceFin;
        uint resId = MapPathMgr.instance.GetWantResId();
        if(resId > 0)
        {
            PreloadAreaMgr.Instance.Preload(resId);
        }
    }

    /// <summary>
    /// 读取场景完成
    /// </summary>
    public virtual void LoadSceneFinish(Scene scene, LoadSceneMode mode)
    {
        LoadSceneCount--;
        if (LoadSceneCount > 0)
        {
            return;
        }
        LoadSceneCount = 0;
        SceneTool.Switch(scene.name);
        if (mLuaLoadSceneFinish != null) LuaTool.Call(mLuaLoadSceneFinish);
        LoadSceneUpdateData();
        elapsed.End("load scene id:{0}, name:{1}", mSceneInfo.id, mSceneInfo.resName.list[0]);
    }

    protected virtual void LoadSceneUpdateData()
    {
        SceneTool.onloaded -= LoadSceneFinish;
        Music.Instance.Play(mSceneInfo.bgm);
        CameraMgr.Refresh();
        SceneGridMgr.Start();
        SceneTriggerMgr.Create(mSceneInfo);
        if (mOpenSceneCallBack != null)
        {
            mOpenSceneCallBack();
        }

        //Global.Main.StartCoroutine(PreloadAfterEnterScene(mSceneInfo));
    }


    public IEnumerator PreloadAfterEnterScene(SceneInfo sceneInfo)
    {
        for (int i = 0; i < 2; i++) yield return null;
        FlowChartMgr.PreloadAfterEnterScene(sceneInfo);
        PreloadMgr.Execute();
        AssetMgr.Instance.Start();
    }

    #endregion

    /// <summary>
    /// 当obj == null  前端调用函数 不进行Unit创建
    /// </summary>
    /// <param name="obj"></param>
    public virtual void OnChangeScene(bool isLoadScene, params object[] obj)
    {
        //InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.ForceStopPathFinding(true);
        if (obj != null)
        {
            User.instance.SceneId = (int)obj[0];
            iTrace.eLog("hs", string.Format("进入场景[{0}]成功!", User.instance.SceneId));
        }
        if (obj != null)
        {
            //             if (!User.instance.ChangeFlowChart())
            //             {
            //             }
            //NPCMgr.instance.InstantiationNpc(mSceneInfo.npcList);
        }
        //         else
        //         {
        //             ChangeMissionScene();
        //         }
        if (User.instance.IsInitLoadScene)
        {
            UpdateConfigsUI();
        }
        else
        {
            uint sceneid = (uint)User.instance.SceneId;
            SceneInfo info = SceneInfoManager.instance.Find(sceneid);
            if (info != null)
            {
                CopyInfo copy = CopyInfoManager.instance.Find(sceneid);
                if ((GameSceneType)info.sceneType != GameSceneType.GST_Copy || copy != null && (CopyType)copy.copyType != CopyType.FlowChart)
                {
                    SceneTriggerMgr.Stoping = false;
                    if (isLoadScene || !mLoadOpen) UpdateConfigsUI();
                    if (EnablePrealodArea())
                    {
                        PreloadAreaMgr.Instance.InsNpc();
                    }
                    else
                    {
                        NPCMgr.instance.InstantiationNpc(info.npcList);
                    }
                }
                User.instance.MissionState = false;
            }
        }
        UnitMgr.instance.CreateSceneUnit();
        OtherUpdate();
        User.instance.MissionState = false;
        if (mLuaOnChangeScene != null) LuaTool.Call(mLuaOnChangeScene, isLoadScene);
        CameraMgr.Lock = false;
        CameraMgr.ClearPullCam();
        ShowEffectMgr.instance.Clear();
    }

    /// <summary>
    /// 打开配置UI
    /// </summary>
    protected virtual void UpdateConfigsUI()
    {
        mLoadOpen = true;
        //打开UI
        if (mConfigs != null)
        {
            for (int i = 0; i < mConfigs.Count; i++)
            {
                if (mConfigs[i] == null) continue;
                UIMgr.Open(mConfigs[i].typeName, null);
            }
        }
        if (!AssetMgr.Instance.AutoCloseIPro)
        {
            UIMgr.Close(UIName.UILoading);
            AssetMgr.Instance.AutoCloseIPro = true;
        }
    }

    protected virtual void OtherUpdate()
    {

    }

    public void Clear()
    {
    }

    /// <summary>
    /// 释放场景
    /// </summary>
    public virtual void Dispose(bool destroyAll = false)
    {
        SceneManager.sceneLoaded -= LoadSceneFinish;
        mOpenSceneCallBack = null;
        Loong.Game.DisposeTool.CurScene(destroyAll);
        if (mLuaChangeDispose != null) LuaTool.Call(mLuaChangeDispose);
        GC.Collect();
    }

    /// <summary>
    /// 释放部分资源
    /// </summary>
    public virtual void PartDispose(string unloadName = null)
    {
        //SceneManager.sceneLoaded -= LoadSceneFinish;
        //mOpenSceneCallBack = null;
        Loong.Game.DisposeTool.CurPartScene(unloadName);
        if (mLuaChangeDispose != null) LuaTool.Call(mLuaChangeDispose);
        GC.Collect();
    }

    /// <summary>
    /// 帧更新
    /// </summary>
    /// <param name="dTime"></param>
    public virtual void Update(float dTime)
    {
    }
}