using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;
using System;

public class BossBarMgr
{
    public static readonly BossBarMgr instance = new BossBarMgr();
    #region 变量
    /// <summary>
    /// bossActior
    /// </summary>
    public long bossOnr = 0;
    #endregion

    public void upOnr(params object[] obj)
    {
        bossOnr= Convert.ToInt64(obj[0]);
    }
 
    public void AddLsnr()
    {
        EventMgr.Add(EventKey.MonsterExtra, upOnr);
    }
    //public void RemoveLsnr()
    //{
    //    EventMgr.Add(EventKey.MonsterExtra, upOnr);
    //}
}
