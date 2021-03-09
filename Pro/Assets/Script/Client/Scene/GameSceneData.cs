using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using LuaInterface;

public partial class GameSceneBase
{
    #region 工具
    protected ElapsedTime elapsed = new ElapsedTime();
    #endregion

    #region 数据
    /// <summary>
    /// 场景table
    /// </summary>
    protected SceneInfo mSceneInfo;
    /// <summary>
    /// 打开场景回调
    /// </summary>
    protected static Action mOpenSceneCallBack = null;
    /// <summary>
    /// UI配置表
    /// </summary>
    protected List<UIConfig> mConfigs = new List<UIConfig>();
    #endregion

    #region 状态类型
    /// <summary>
    /// 场景加载状态
    /// </summary>
    protected SceneLoadStateEnum mSceneLoadState;
    /// <summary>
    /// 场景加载状态
    /// </summary>
    public SceneLoadStateEnum SceneLoadState
    {
        get { return mSceneLoadState; }
    }
    /// <summary>
    /// 当前场景类型
    /// </summary>
    protected GameSceneType mCurSceneType = GameSceneType.GST_Unknown;
    /// <summary>
    /// 获得场景类型
    /// </summary>
    public GameSceneType SceneType
    {
        get
        {
            return mCurSceneType;
        }
    }

    protected CopyType mSceneCopyType = CopyType.None;
    public CopyType SceneCopyType { get { return mSceneCopyType; } }
    #endregion

    #region 开关
    /// <summary>
    /// 是否需要预加载资源
    /// </summary>
    protected bool mPreloadRes = true;
    /// <summary>
    /// 加载场景资源
    /// </summary>
    protected bool mIsLoadScene = true;
    /// <summary>
    /// 打开UI 
    /// </summary>
    protected bool mLoadOpen = false;
    #endregion

    #region 变量
    /// <summary>
    /// 加载场景的数量
    /// </summary>
    protected int LoadSceneCount = 0;
    #endregion

    #region Lua
    protected LuaTable mLuaTable;
    //private LuaFunction mLuaInit;
    protected LuaFunction mLuaOpenScene;
    protected LuaFunction mLuaBeforePreload;
    protected LuaFunction mLuaPreload;
    protected LuaFunction mLuaPreloadFinish;
    protected LuaFunction mLuaLoadSceneFinish;
    protected LuaFunction mLuaOnChangeScene;
    protected LuaFunction mLuaGetUIConfig;
    protected LuaFunction mLuaChangeDispose;

    protected void GetLua()
    {
        mLuaTable = LuaTool.GetTable(LuaMgr.Lua, "SceneMgr");
        //mLuaInit = LuaTool.GetFunc(mLuaTable, "Init");
        mLuaOpenScene = LuaTool.GetFunc(mLuaTable, "OpenScene");
        mLuaBeforePreload = LuaTool.GetFunc(mLuaTable, "BeforePreload");
        mLuaPreload = LuaTool.GetFunc(mLuaTable, "Preload");
        mLuaPreloadFinish = LuaTool.GetFunc(mLuaTable, "PreloadFinish");
        mLuaLoadSceneFinish = LuaTool.GetFunc(mLuaTable, "LoadSceneFinish");
        mLuaOnChangeScene = LuaTool.GetFunc(mLuaTable, "OnChangeScene");
        mLuaGetUIConfig = LuaTool.GetFunc(mLuaTable, "GetUIConfig");
        mLuaChangeDispose = LuaTool.GetFunc(mLuaTable, "ChangeDispose");
        //if (mLuaInit != null) LuaTool.Call(mLuaInit);
    }
    #endregion

    #region 设置副本类型

    /// <summary>
    /// 设置副本类型
    /// </summary>
    /// <param name="sceneId"></param>
    protected void SetCopyType(uint sceneId)
    {
        CopyInfo info = CopyInfoManager.instance.Find(sceneId);
        if (info == null)
        {
            mSceneCopyType = CopyType.None;
            return;
        }
        mSceneCopyType = (CopyType)info.copyType;
    }
    #endregion

    #region 清理寻路数据

    /// <summary>
    /// 清除寻路数据
    /// </summary>
    protected void ClearPathData()
    {
        if (InputMgr.instance.mOwner != null)
            InputMgr.instance.mOwner.mNetUnitMove.ClearJumpState();
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null)
            return;
        SelectRoleMgr.instance.ResetTRUId();
        SceneSubType subType = (SceneSubType)mSceneInfo.sceneSubType;
        if (subType != SceneSubType.None)
        {
            User.instance.ResetMisTarID();
            unit.mUnitMove.Pathfinding.ResetAllState(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
            return;
        }
        CopyType cType = GameSceneManager.instance.CurCopyType;
        if (cType != CopyType.None && cType != CopyType.FlowChart)
        {
            User.instance.ResetMisTarID();
            unit.mUnitMove.Pathfinding.ResetAllState(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
        }
    }
    #endregion

    #region 获得场景相关UI数据
    /// <summary>
    /// 获得UI配置信息
    /// </summary>
    protected void GetUIConfig()
    {
        if (mSceneInfo != null)
        {
            List<UInt16> list = mSceneInfo.openUI.list;
            if (mConfigs != null) mConfigs.Clear();
            for (int i = 0; i < list.Count; i++)
            {
                UIConfig config = UIConfigManager.instance.Find(list[i]);
                if (config != null) mConfigs.Add(config);
            }
        }
        if (mLuaGetUIConfig != null)
        {
            LuaTable table = LuaTool.CallFunc(mLuaGetUIConfig);
            if (table != null)
            {
                object[] list = table.ToArray();
                for (int i = 0; i < list.Length; i++)
                {
                    UInt16 id = (UInt16)list[i];
                    UIConfig config = UIConfigManager.instance.Find(id);
                    if (config != null) mConfigs.Add(config);
                }
            }
        }
    }
    #endregion
}
