using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class FootPrint : PendantBase
{
    #region 字段
    /// <summary>
    /// 足迹变换对象
    /// </summary>
    private Transform mTrans = null;
    /// <summary>
    /// 模型名
    /// </summary>
    private string mModName;
    #endregion

    #region 属性
    /// <summary>
    /// 模型名
    /// </summary>
    public string ModName
    {
        get { return mModName; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    /// <param name="unitTypeId"></param>
    /// <param name="state"></param>
    /// <param name="data"></param>
    /// <returns></returns>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state, data);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        ushort modelId = UnitHelper.instance.GetUnitModeId(unitTypeId, data);
        RoleBase roleInfo = RoleBaseManager.instance.Find(modelId);
        if (roleInfo != null) mModName = roleInfo.modelPath;
        if (string.IsNullOrEmpty(mModName))
            return null;
        AssetMgr.LoadPrefab(mModName, (obj) =>
        {
            if (mMtpParent == null || mMtpParent.DestroyState)
            {
                GbjPool.Instance.Add(obj);
                return;
            }
            if (obj == null)
                return;
            mTrans = obj.transform;
            mTrans.parent = null;
            obj.SetActive(true);
            SetPersist(obj, mModName);
            mMtpParent.mFootPrint = this;
        });
        return null;
    }

    /// <summary>
    /// 脱下
    /// </summary>
    /// <param name="data"></param>
    public override void TakeOff(ActorData data)
    {
        if (UnitHelper.instance.UnitIsNull(mMtpParent))
            return;
        mMtpParent.mFootPrint = null;
        mModName = null;
        if (mTrans == null)
            return;
        GameObject.Destroy(mTrans.gameObject);
    }

    /// <summary>
    /// 是否可以播放特效
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    public static FootPrint GetPlayEff(Unit unit)
    {
        if (!UnitHelper.instance.CanUseUnit(unit))
            return null;
        FootPrint fp = unit.mFootPrint;
        if (fp != null)
            return fp;
        Unit parent = unit.ParentUnit;
        if (parent == null)
            return null;
        fp = parent.mFootPrint;
        if (fp == null)
            return null;
        return fp;
    }
    #endregion
}
