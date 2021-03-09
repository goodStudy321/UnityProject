using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;

using Loong.Game;


/// <summary>
/// 后期效果管理器
/// </summary>
public class PostEffMgr 
{
    //public static readonly PostEffMgr instance = new PostEffMgr();

    ///// <summary>
    ///// 进入后期域列表
    ///// </summary>
    //private List<PostEffHelper> mEnterZoneList = new List<PostEffHelper>();


    //private PostEffMgr()
    //{
    //    Init();
    //}

    //private void Init()
    //{

    //}


    ///// <summary>
    ///// 进入后期域
    ///// </summary>
    ///// <param name="he"></param>
    //public void EnterEffZone(PostEffHelper he)
    //{
    //    //if(mEnterZoneList.Contains(he) == true)
    //    //{
    //    //    iTrace.Error("LY", "Enter the same post effect zone twice !!! ");
    //    //    return;
    //    //}

    //    if(mEnterZoneList.Count > 0)
    //    {
    //        if(he.mLinkPartId > 0 && he.mLinkPartId == mEnterZoneList[mEnterZoneList.Count - 1].mLinkPartId)
    //        {
    //            he.ChangeTimer = mEnterZoneList[mEnterZoneList.Count - 1].ChangeTimer;
    //        }
    //        mEnterZoneList[mEnterZoneList.Count - 1].MainPlayerExit();
    //    }
    //    he.MainPlayerEnter();
    //    if (mEnterZoneList.Contains(he) == false)
    //    {
    //        mEnterZoneList.Add(he);
    //    }
    //}

    ///// <summary>
    ///// 退出后期域
    ///// </summary>
    ///// <param name="he"></param>
    //public void ExitEffZone(PostEffHelper he)
    //{
    //    if (mEnterZoneList.Contains(he) == false)
    //    {
    //        he.MainPlayerExit();
    //        mEnterZoneList.Remove(he);
    //        return;
    //    }

    //    if(mEnterZoneList.Count > 1 && mEnterZoneList[mEnterZoneList.Count - 1] == he)
    //    {
    //        he.MainPlayerExit();
    //        mEnterZoneList[mEnterZoneList.Count - 2].MainPlayerEnter();
    //    }
    //    mEnterZoneList.Remove(he);
    //}

    ///// <summary>
    ///// 释放地图数据
    ///// </summary>
    //public void DisposeMap()
    //{
    //    mEnterZoneList.Clear();
    //}
}
