using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FashionWp : PendantBase
{
    #region 私有变量
    /// <summary>
    /// 脱掉神兵
    /// </summary>
    private void TakeOffArtifact(Unit mtpParent)
    {
        if (mtpParent == null)
            return;
        if (mtpParent.Dead)
            return;
        if (mtpParent.Artifact == null)
            return;
        if (mtpParent.Artifact.mPendant == null)
            return;
        mtpParent.Artifact.mPendant.TakeOff(null);
    }
    #endregion

    #region 公有方法
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {

        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        TakeOffArtifact(mtpParent);
        FashionInfo fashionInfo = FashionInfoManager.instance.Find(mBaseId);
        if (fashionInfo == null)
            return null;
        mMountPoint = (MountPoint)fashionInfo.mountPoint;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit fshWp = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, fashionInfo.name, mtpParent.Position, angle, mtpParent.Camp, (unit) =>
        {
            mOwner = unit;
            mMtpParent.mUnitOutline.SetRenderer(mMtpParent);
            if (UnitHelper.instance.IsOwner(mtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(unit);
            PendantHelper.instance.DestroyDefaultWeapon(mtpParent);
            SetPosition();
            SetFightType();
        });
        mOwner = fshWp;
        fshWp.mPendant = this;
        mtpParent.AddChildUnit(fshWp);
        mtpParent.FashionWp = fshWp;
        return fshWp;
    }
    #endregion
}
