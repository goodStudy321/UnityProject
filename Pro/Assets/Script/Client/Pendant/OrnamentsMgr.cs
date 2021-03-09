using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OrnamentsMgr
{
    #region 单例
    public static readonly OrnamentsMgr instance = new OrnamentsMgr();

    private OrnamentsMgr() { }
    #endregion

    #region 公有方法
    /// <summary>
    /// 创建配饰
    /// </summary>
    public void CreateOrnaments(Unit mtpParent, ActorData actorData)
    {
        List<int> onmList = actorData.OrnamentList;
        int count = onmList.Count;
        if (count == 0)
            return;
        for (int i = 0; i < count; i++)
            AddOrnament(mtpParent, onmList[i]);
    }
    
    /// <summary>
    /// 添加配饰
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="onmId"></param>
    public void AddOrnament(Unit unit, int onmId)
    {
        if (unit == null)
            return;
        long uid = unit.UnitUID;
        Transform trans = unit.UnitTrans;
        if (trans == null)
            return;
        EventMgr.Trigger("AddOrnament", uid, trans, onmId);
    }

    /// <summary>
    /// 移除配饰
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="onmId">-1时删除所有配饰</param>
    public void RemoveOrnament(Unit unit, int onmId)
    {
        if (unit == null)
            return;
        long uid = unit.UnitUID;
        Transform trans = unit.UnitTrans;
        if (trans == null)
            return;
        EventMgr.Trigger("RemoveOrnament", uid, trans, onmId);
    }
    #endregion
}
