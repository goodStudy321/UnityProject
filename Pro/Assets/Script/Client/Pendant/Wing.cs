using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 翅膀
/// </summary>
public class Wing : PendantBase
{
    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        WingBase wingInfo = WingBaseManager.instance.Find(mBaseId);
        if (wingInfo == null)
            return null;
        mMountPoint = (MountPoint)wingInfo.mountPoint;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit wing = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, wingInfo.name, mtpParent.Position, angle, mtpParent.Camp, (unit) =>
        {
            mOwner = unit;
            mMtpParent.mUnitOutline.SetRenderer(mMtpParent);
            if (UnitHelper.instance.IsOwner(mtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(unit);
            SetPosition();
            ChangePendantAction(unit, (PendantStateEnum)mState);
            SetFightType();
        });
        mOwner = wing;
        wing.mPendant = this;
        mtpParent.AddChildUnit(wing);
        mtpParent.Wing = wing;
        return wing;
    }
    #endregion
}
