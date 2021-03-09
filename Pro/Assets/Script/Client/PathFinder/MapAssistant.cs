using System;
using UnityEngine;
//using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 地图物体助手
/// </summary>
public class MapAssistant
{
    /// <summary>
    /// 传送口列表
    /// </summary>
    private List<PortalFig> mPortalList = null;
    /// <summary>
    /// 操控传送口列表
    /// </summary>
    private List<AwakenPortalFig> mAwakenPortalList = null;
    /// <summary>
    /// 动态阻挡物
    /// </summary>
    private List<DoorBlock> mDoorBlockList = null;


    /// <summary>
    /// 赋值跳转口列表
    /// </summary>
    public List<PortalFig> PortalList
    {
        set { mPortalList = value; }
    }

    public List<AwakenPortalFig> AwakenPortalList
    {
        set { mAwakenPortalList = value; }
    }


    /// <summary>
    /// 赋值动态阻挡门列表
    /// </summary>
    public List<DoorBlock> DoorBlockList
    {
        get { return mDoorBlockList; }
        set { mDoorBlockList = value; }
    }


    /// <summary>
    /// 初始化
    /// </summary>
    private void Init()
    {
        //iTrace.Log("LY", "Create MapAssistant !!! ");
        //mPortalList = new List<PortalFig>();
        //mDoorBlockList = new List<DoorBlock>();
    }


    public MapAssistant()
    {
        Init();
    }

    /// <summary>
    /// 重置助手工具
    /// </summary>
    public void ResetAssistant()
    {
        mPortalList = null;
        mAwakenPortalList = null;
        mDoorBlockList = null;
    }

    /// <summary>
    /// 根据Id查找动态阻挡物
    /// </summary>
    /// <param name="dbId"></param>
    /// <returns></returns>
    public DoorBlock FindDoorBlockById(uint dbId)
    {
        if (mDoorBlockList == null)
        {
            return null;
        }

        for (int a = 0; a < mDoorBlockList.Count; a++)
        {
            if (mDoorBlockList[a].mDoorBlockId == dbId)
            {
                return mDoorBlockList[a];
            }
        }
        return null;
    }

    /// <summary>
    /// 获取传送口配置
    /// </summary>
    /// <param name="portalId"></param>
    /// <returns></returns>
    public PortalFig GetPortalFigById(uint portalId)
    {
        for (int a = 0; a < mPortalList.Count; a++)
        {
            if (mPortalList[a].mPortalId == portalId)
            {
                return mPortalList[a];
            }
        }

        return null;
    }

    public AwakenPortalFig GetAwakenPortalFigById(uint portalId)
    {
        for(int a = 0; a < mAwakenPortalList.Count; a++)
        {
            if (mAwakenPortalList[a].mPortalId == portalId)
            {
                return mAwakenPortalList[a];
            }
        }

        return null;
    }

    /// <summary>
    /// 根据跳转口链接的目的地图Id查找跳转口
    /// </summary>
    /// <param name="portalId"></param>
    /// <returns></returns>
    public PortalFig FindPortalByLinkMapId(uint mapId)
    {
        if (mPortalList == null)
        {
            return null;
        }

        for (int a = 0; a < mPortalList.Count; a++)
        {
            if (mPortalList[a].mLinkMapId == mapId)
            {
                return mPortalList[a];
            }
        }

        return null;
    }

    /// <summary>
    /// 获取场景跳转口
    /// </summary>
    /// <returns></returns>
    public List<PTLuaInfo> GetChangeMapPortals()
    {
        if(mPortalList == null || mPortalList.Count <= 0)
        {
            return null;
        }

        int sceneId = User.instance.SceneId;
        List<PTLuaInfo> retList = new List<PTLuaInfo>();

        for(int a = 0; a < mPortalList.Count; a++)
        {
            if(mPortalList[a] != null && mPortalList[a].mLinkMapId > 0 && mPortalList[a].mLinkMapId != sceneId)
            {
                PTLuaInfo tInfo = new PTLuaInfo();
                tInfo.id = (int)mPortalList[a].mPortalId;
                tInfo.pos = mPortalList[a].transform.position;
                tInfo.unlock = mPortalList[a].UnLock;
                if(tInfo.unlock == false)
                {
                    tInfo.unlockLv = (int)mPortalList[a].mUnlockCharLv;
                    tInfo.unlockMissId = (int)mPortalList[a].mUnlockMissionId;
                }

                retList.Add(tInfo);
            }
        }
        
        return retList;
    }
}
