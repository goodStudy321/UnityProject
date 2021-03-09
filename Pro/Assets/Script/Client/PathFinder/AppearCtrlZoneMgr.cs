using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Loong.Game;

/// <summary>
/// 显示控制区域管理器
/// </summary>
public class AppearCtrlZoneMgr
{
    /// <summary>
    /// 搜索根节点
    /// </summary>
    public static string rootObjName1 = "Scene_object";
    public static string rootObjName2 = "Scene_Object";
    public static string rootObjName3 = "scene_object";
    public static string rootObjName4 = "scene_Object";

    /// <summary>
    /// 单件指针
    /// </summary>
    public static readonly AppearCtrlZoneMgr instance = new AppearCtrlZoneMgr();

    /// <summary>
    /// 搜索根节点
    /// </summary>
    private GameObject mObjRoot = null;
    /// <summary>
    /// 当前加载地图ID
    /// </summary>
    private int mMapId = -1;
    /// <summary>
    /// 进入显示控制区域列表（带排序，最后一个为最新进入）
    /// </summary>
    private List<AppearCtrlZone> mEnterZoneList = new List<AppearCtrlZone>();

    private bool isInit = false;
    private AppearCtrlZone preEnterZone = null;


    public AppearCtrlZoneMgr()
    {
        //Initialize();
    }
    
    public void Initialize()
    {
        EventMgr.Add(EventKey.OnChangeScene, ChangeSceneInit);
        EventMgr.Add(EventKey.BegChgScene, ChangeSceneClear);
    }

    /// <summary>
    /// 转换场景完成初始化资源
    /// </summary>
    /// <param name="agrs"></param>
    private void ChangeSceneInit(params object[] agrs)
    {
        isInit = true;
        mMapId = (int)agrs[0];
        if (mMapId == MapPathMgr.instance.CurMapId)
        {
            return;
        }

        mObjRoot = GameObject.Find(rootObjName1);
        if(mObjRoot == null)
        {
            mObjRoot = GameObject.Find(rootObjName2);
        }
        if (mObjRoot == null)
        {
            mObjRoot = GameObject.Find(rootObjName3);
        }
        if (mObjRoot == null)
        {
            mObjRoot = GameObject.Find(rootObjName4);
        }

        if (mObjRoot == null)
        {
#if UNITY_EDITOR
            iTrace.Log("LY", "Current scene can not find all Scene_Object node, scene id : " + MapPathMgr.instance.CurMapId);
#endif
        }

        if(preEnterZone != null)
        {
            EnterAppearZone(preEnterZone);
            preEnterZone = null;
        }
    }

    /// <summary>
    /// 清理工作
    /// </summary>
    private void ChangeSceneClear(params object[] agrs)
    {
        mEnterZoneList.Clear();
        isInit = false;
    }

    public void EnterAppearZone(AppearCtrlZone acZone)
    {
        if(isInit == false)
        {
            preEnterZone = acZone;
            return;
        }

        if(mEnterZoneList.Contains(acZone))
        {
            mEnterZoneList.Remove(acZone);
        }
        mEnterZoneList.Add(acZone);
        acZone.EnterZone(mObjRoot);
    }

    public void ExitAppearZone(AppearCtrlZone acZone)
    {
        if(mEnterZoneList.Contains(acZone))
        {
            mEnterZoneList.Remove(acZone);
        }

        if(mEnterZoneList != null && mEnterZoneList.Count > 0)
        {
            int listNum = mEnterZoneList.Count;
            mEnterZoneList[listNum - 1].EnterZone(mObjRoot);
        }
    }
}
