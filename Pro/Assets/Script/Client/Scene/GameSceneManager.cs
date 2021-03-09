using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

using Loong.Game;


/// 场景管理器 ///
public class GameSceneManager
{
    public static readonly GameSceneManager instance = new GameSceneManager();


    //private bool first = true;
    #region 是否在主城中
    /// 是否在主城中 ///
    public bool IsInMainScene
    {
        get
        {
            return mGameSceneType == GameSceneType.GST_MainScene;
        }
    }

    //     /// <summary>
    //     /// 第一次load完成之后设置为false
    //     /// </summary>
    //     public bool First
    //     {
    //         get { return first; }
    //         set { first = value; }
    //     }

    #endregion

    #region 当前加载进入的场景类型

    protected GameSceneType mGameSceneType;
    /// <summary>
    /// 场景类型
    /// </summary>
    public int CurSceneType
    {
        get
        {
            return (int)mGameSceneType;
        }
    }
    #endregion

    #region 场景子类型
    protected SceneSubType mMapSubType = SceneSubType.None;
    /// <summary>
    /// 场景子类型
    /// </summary>
    public SceneSubType MapSubType
    {
        get { return mMapSubType; }
        set { mMapSubType = value; }
    }
    #endregion

    #region 副本类型
    protected CopyType mCurCopyType = CopyType.None;
    /// <summary>
    /// 当前副本类型
    /// </summary>
    public CopyType CurCopyType
    {
        get
        {
            if (gameScene != null) mCurCopyType = gameScene.SceneCopyType;
            return mCurCopyType;
        }
    }
    #endregion

    #region 当前加载进入的场景配置表
    private SceneInfo mSceneInfo;
    /// <summary>
    /// 场景table属性
    /// </summary>
    public SceneInfo SceneInfo
    {
        get { return mSceneInfo; }
    }
    #endregion

    #region 当前场景加载
    private GameSceneBase gameScene;
    #endregion

    #region 当前加载场景的加载状态

    /// <summary>
    /// 场景加载状态
    /// </summary>
    public SceneLoadStateEnum SceneLoadState
    {
        get { return gameScene != null ? gameScene.SceneLoadState : SceneLoadStateEnum.SceneDone; }
    }

    public int SceneLoadStateToInt { get { return (int)SceneLoadState; } }
    #endregion

    //public bool IsLoadScene = false;
    public SceneStatus SceneStatus = SceneStatus.Normal;
    public int SceneStatusToInt
    {
        get
        {
            return (int)SceneStatus;
        }
    }
    private bool IsUpdateUI = true;

    #region 计时器
    private bool IsDownCount = false;
    private DateTimer DownCount;
    #endregion

    #region 构造函数
    public GameSceneManager()
    {
        DownCount = new DateTimer();
        DownCount.IgnoreTimeScale = true;
        //DownCount.invl += InvDownCount;
        DownCount.complete += CompleteDownCount;
        DownCount.Seconds = 15;
        EventMgr.Add(EventKey.OnChangeScene, OnChangeScene);
    }
    #endregion

    #region 加载场景

    private void PlayEffect()
    {
        Unit tUnit = InputVectorMove.instance.MoveUnit;
        if (tUnit != null)
        {
            AssetMgr.LoadPrefab("FX_ChuanSong01", PlayEffectCb);

        }
    }

    private void PlayEffectCb(GameObject go)
    {
        Unit tUnit = InputVectorMove.instance.MoveUnit;
        if (tUnit == null)
        {
            iTool.Destroy(go);
        }
        else
        {
            go.transform.position = tUnit.Position;
            go.SetActive(true);
        }
    }

    /// <summary>
    /// 改变场景
    /// 检测目标场景资源是否与当前场景资源相同
    /// </summary>
    /// <param name="sceneid"></param>
    public void ChangeScene(int sceneid)
    {
        iTrace.eLog("hs", "改变场景" + sceneid);
        SceneInfo scene = SceneInfoManager.instance.Find((uint)sceneid);
        if (scene == null)
        {
            iTrace.eError("HS", string.Format("场景id[{0}]数据不存在", sceneid));
            return;
        }
        bool loadScene = true;
        if (SceneManager.GetActiveScene().name == scene.resName.list[0])
        {
            loadScene = false;
        }
        //CopyInfo curCopy = null;
        //if (mSceneInfo != null && (GameSceneType)mSceneInfo.sceneType == GameSceneType.GST_Copy)
        //    curCopy = CopyInfoManager.instance.Find((uint)mSceneInfo.id);
        CopyInfo copy = CopyInfoManager.instance.Find((uint)sceneid);
        if (SceneStatus == SceneStatus.Normal)
            IsUpdateUI = loadScene;
        else
            IsUpdateUI = true;

        //淡入淡出 begin
        var exist = SceneTool.Exist(scene.resName.list[0]);
        //var gspd = gameScene as GameScenePartDispos;
        //1.非第一次进入
        //2 要进入的场景资源已存在
        //3 传入的切场景参数是true -- 针对流程树场景
        if (!User.instance.IsInitLoadScene &&
            exist &&
            loadScene)
        {
            //应策划需求,暂时屏蔽飞鞋
            //Global.Main.StartCoroutine(YieldBegin(loadScene, scene, copy));
            UIMgr.Open(UIName.UIMaskFade, LoadMaskFadeCallback);
            Begin(loadScene, scene, copy);
        }
        else
        {
            Begin(loadScene, scene, copy);
        }
    }

    private IEnumerator YieldBegin(bool loadScene, SceneInfo scene, CopyInfo copy)
    {
        PlayEffect();
        yield return new WaitForSeconds(1f);
        UIMgr.Open(UIName.UIMaskFade, LoadMaskFadeCallback);
        Begin(loadScene, scene, copy);
    }

    private void Begin(bool loadScene,SceneInfo scene,CopyInfo copy)
    {
        if (loadScene)
        {
            SceneStatus = SceneStatus.LoadMod;
            LoadScene(scene, (GameSceneType)scene.sceneType);
            EventMgr.Trigger(EventKey.BegChgScene);
        }
        else
        {
            SceneStatus = SceneStatus.LoadData;
            EnterMissionClearScene();
            if (copy != null)
            {
                if ((CopyType)copy.copyType == CopyType.Light)
                {
                    ChangeSceneModel(scene, copy);
                }
            }
            EventMgr.Trigger("UIMaskFadeOut");
            NetworkMgr.EnterScene((Int32)scene.id);
        }
    }

    /// <summary>
    /// 读取打开场景
    /// </summary>
    /// <param name="loadType">场景类型</param>
    /// <param name="cb">回调</param>
    public void LoadScene(SceneInfo info, GameSceneType loadType)
    {
        if (info == null)
        {
            iTrace.Log("LY", "Main scene info can not find !!! ");
            return;
        }
        var exist = SceneTool.Exist(info.resName.list[0]);
        var gspd = gameScene as GameScenePartDispos;
        //可以打开进度
        //条件1:第一次进入gameScene为空
        //条件2:当前的gameScene不等于GameScenePartDispos
        //条件3:当前的gameScene是GameScenePartDispos并且BackScene为false不是返回野外
        var delay = 0f;
        if (gameScene == null || (!exist && (gspd == null || (gspd.BackScene == false)|| (info.dontDestroy == 1))))
        {
            HeartBeat.instance.IsStop = true;
            UIMgr.Open(UIName.UILoading);
            AssetMgr.Instance.AutoCloseIPro = false;
        }
        else
        {
            delay = 0.5f;
        }
        Global.Main.StartCoroutine(YieldLoad(info, loadType, delay, LoadSceneFinish));
    }

    private IEnumerator YieldLoad(SceneInfo info, GameSceneType loadType,float delay, Action cb)
    {
        for (int i = 0; i < 3; ++i) yield return null;
        if(delay>0) yield return new WaitForSeconds(delay);
        mSceneInfo = info;
        mGameSceneType = loadType;
        mMapSubType = (SceneSubType)info.sceneSubType;

        bool dontDestroy = false;
        if (info.dontDestroy == 1) dontDestroy = true;

        if (dontDestroy == false)
        {
            if(gameScene != null && gameScene is GameScenePartDispos && (gameScene as GameScenePartDispos).IsReuse(info))
            {
                gameScene.Dispose();
            }
            else
            {
                DisposeCurScene();
                switch (mGameSceneType)
                {
                    case GameSceneType.GST_Copy:
                        gameScene = new GameSceneCopy();
                        break;
                    default:
                        gameScene = new GameSceneCommon();
                        break;
                }
            }
        }
        else
        {
            DisposeCurScene(false, true);
            gameScene = new GameScenePartDispos();
        }
        if (gameScene == null)
        {
            iTrace.eError("HS", string.Format("需要加载的场景ID:{0} 的场景类型不存在", info.id));
            yield break;
        }
        gameScene.OpenScene(info, cb);
    }
    private void LoadMaskFadeCallback(string name)
    {
        if (name.Contains("UIMaskFade"))
        {
            //MonoEvent.Start(YildFade());
            EventMgr.Trigger("UIMaskFadeIn");
        }
    }
    private IEnumerator YildFade()
    {
        yield return new WaitForSeconds(2f);
        UIMgr.Close(UIName.UIMaskFade);
    }
    #endregion

    #region 进入场景

    private void ChangeSceneModel(SceneInfo info, CopyInfo copy)
    {
        if (info.resName.list.Count > 0)
        {
            string activeResName = info.resName.list[0];
            if (!string.IsNullOrEmpty(activeResName))
            {
                Scene scene = SceneManager.GetSceneByName(activeResName);
                SceneManager.SetActiveScene(scene);
                GameObject go = GameObject.Find(activeResName);
                GameObject root = TransTool.Find(go, "Root");
                if (root != null) root.SetActive(true);
            }
            if (info.resName.list.Count > 1)
            {
                string hideResName = info.resName.list[1];
                if (!string.IsNullOrEmpty(hideResName))
                {
                    GameObject go = GameObject.Find(activeResName);
                    GameObject root = TransTool.Find(go, "Root");
                    if (root != null) root.SetActive(false);
                }
            }
        }
    }
    #endregion

    #region Loading计时
    public void StarDownCount()
    {
        //iTrace.eLog("hs", "切场景Loading 计时  开启");
        if (IsDownCount == true) return;
        IsDownCount = true;
        if (DownCount != null) DownCount.Start();
    }

    private void EndDownCount()
    {
        //iTrace.eLog("hs", "切场景Loading 计时 停止");
        if (DownCount != null) DownCount.Stop();
        IsDownCount = false;
    }

    private void InvDownCount()
    {
        //iTrace.eLog("hs", "切场景Loading 计时 中");
    }

    private void CompleteDownCount()
    {
        //iTrace.eLog("hs", "切场景Loading 计时 结束");
        EndDownCount();
        MsgBox.Show(620011, 690000, ReConnectMgr.ReLogin);
        MsgBox.closeOpt = MsgBox.CloseOpt.Yes;
    }

    #endregion

    #region 其他函数
    public void OnChangeScene(params object[] obj)
    {
        if (gameScene == null) return;
        EndDownCount();
        var ErrorMsg = Phantom.Localization.Instance.GetDes(620011);
        if (MsgBox.msgValue.Equals( ErrorMsg) == true) UIMgr.Close(UIName.MsgBox);
        gameScene.OnChangeScene(IsUpdateUI, obj);
        SceneStatus = SceneStatus.Normal;
    }

    private void LoadSceneFinish()
    {
        SceneStatus = SceneStatus.LoadData;

    }
    #endregion

    #region 释放当前场景
    /// 释放当前场景操作 ///
    /// <param name="isPart"> 销毁部分 </param>
    public void DisposeCurScene(bool value = false, bool isPart = false)
    {
        if (gameScene != null)
        {
            if (isPart == false)
            {
                gameScene.Dispose(value);
            }
            else
            {
                gameScene.PartDispose();
            }
            gameScene = null;
        }
    }

    public void EnterMissionClearScene()
    {
        try
        {
            User.instance.CleanOtherData();
            NPCMgr.instance.CleanmNPCDic();
            UnitMgr.instance.Dispose();
            CollectionMgr.Dispose();
            SceneTriggerMgr.Stoping = true;
            DropMgr.CleanDropList();
        }
        catch (Exception e)
        {
            iTrace.Error("HS", "EnterMissionClearScene err:{0}", e.Message);
        }
    }
    #endregion


    #region 检测是否类副本场景
    public bool CheckChangeScene(uint target)
    {

        return IsCopyScene((uint)User.instance.SceneId) == true && IsCopyScene(target) == true;
    }

    private bool IsCopyScene(uint sceneid)
    {
        bool value = false;
        SceneInfo tScene = SceneInfoManager.instance.Find(sceneid);
        if (tScene != null && tScene.sceneSubType != 0)
        {
            value = true;
        }
        else
        {
            CopyInfo info = CopyInfoManager.instance.Find(sceneid);
            if (info != null)
            {
                value = true;
            }
        }
        return value;
    }

    #endregion

    #region 检查场景资源是否已经下载
    public bool CheckSceneRes(uint sceneid)
    {
        if (sceneid < 1) return true;
        SceneInfo info = SceneInfoManager.instance.Find(sceneid);
        if (info == null)
        {
            iTrace.eLog("XGY", "场景配置不存在:" + sceneid);
            return false;
        }
        for (int i = 0; i < info.resName.list.Count; i++)
        {
            string nextSceneResName = string.Concat(info.resName.list[i], ".unity");
            string nextMapData = string.Concat(info.mapId.ToString(), ".bytes");
            string nextMapBlock = string.Concat(info.mapId.ToString(), "_block.prefab");
            if ( AssetMgr.Instance.Exist(nextSceneResName) == false
                || AssetMgr.Instance.Exist(nextMapData) == false
                || AssetMgr.Instance.Exist(nextMapBlock) == false )
            {
                UITip.LocalLog(690010);
                UIMgr.Open("UIDownload");
                iTrace.eError("LY", string.Format("Scene res is not exist : {0}", nextSceneResName));
                return false;
            }
        }
        return true;
    }
    #endregion

    public bool EnablePrealodArea()
    {
        if (mSceneInfo == null) return false;
        return mSceneInfo.enablePreload > 0;
    }

    /// <summary>
    /// 传入场景名  判断当前激活的场景是否 相同
    /// </summary>
    /// <param name="name"></param>
    /// <returns></returns>
    public bool CheckSceneName(string name)
    {
        return SceneManager.GetActiveScene().name == name;
    }
}
