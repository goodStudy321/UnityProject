using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class PdAssetCheck
{
    #region 单例
    public static readonly PdAssetCheck instance = new PdAssetCheck();

    private PdAssetCheck() { }
    #endregion

    #region 私有方法
    /// <summary>
    /// 获取挂件状态
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="tarTypeId"></param>
    /// <returns></returns>
    private PendantStateEnum GetPdtState(Unit unit, uint tarTypeId)
    {
        PendantStateEnum state = PendantStateEnum.Normal;
        uint baseId = tarTypeId / 100;
        Unit child = unit.Children.Find((ch) => { return ch.TypeId / 100 == baseId; });
        if (child == null)
            return state;
        PendantBase pdb = child.mPendant as PendantBase;
        if (pdb == null)
            return state;
        state = pdb.mState;
        return state;
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 添加挂件资源监听
    /// </summary>
    public void AddPdAssetLsnr(Unit unit)
    {
        if (unit == null)
            return;
        if (unit.UnitUID != User.instance.MapData.UID)
            return;
        if (unit.OldPendantDic.Count > 0)
            return;
#if LOONG_SUB_ASSET
        PackDl.Instance.complete += PackDlCB;
#endif
    }

    /// <summary>
    /// 资源下载完成回调
    /// </summary>
    /// <param name="args"></param>
    public void PackDlCB()
    {
        Unit unit = InputMgr.instance.mOwner;
        if (unit == null)
            return;
        if (unit.OldPendantDic.Count == 0)
            return;
#if LOONG_SUB_ASSET
        PackDl.Instance.complete -= PackDlCB;
#endif
        List<uint> keys = new List<uint>(unit.OldPendantDic.Keys);
        for (int i = 0; i < keys.Count; i++)
        {
            PendantStateEnum state = GetPdtState(unit, keys[i]);
            PendantMgr.instance.TakeOff(unit, keys[i], User.instance.MapData);
            PendantMgr.instance.PutOn(unit, keys[i], state, User.instance.MapData);
        }
    }
#endregion
}
