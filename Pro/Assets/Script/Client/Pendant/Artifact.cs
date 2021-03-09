using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 神兵
/// </summary>
public class Artifact : PendantBase
{
    #region 私有变量
    /// <summary>
    /// 脱掉神兵
    /// </summary>
    private void TakeOffFashionWp(Unit mtpParent)
    {
        if (mtpParent == null)
            return;
        if (mtpParent.Dead)
            return;
        if (mtpParent.FashionWp == null)
            return;
        mtpParent.FashionWp.mPendant.TakeOff(null);
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state,ActorData data=null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        TakeOffFashionWp(mtpParent);
        ArtifactInfo artifactInfo = ArtifactInfoManager.instance.Find(mBaseId);
        if (artifactInfo == null)
            return null;
        mMountPoint = (MountPoint)artifactInfo.mountPoint;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit artifact = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, artifactInfo.name, mtpParent.Position, angle, mtpParent.Camp, (unit) =>
        {
            mOwner = unit;
            mMtpParent.mUnitOutline.SetRenderer(mMtpParent);
            if (UnitHelper.instance.IsOwner(mtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(unit);
            PendantHelper.instance.DestroyDefaultWeapon(mtpParent);
            SetPosition();
            ChangePendantAction(unit, (PendantStateEnum)mState);
            SetFightType();
        });
        mOwner = artifact;
        artifact.mPendant = this;
        mtpParent.AddChildUnit(artifact);
        mtpParent.Artifact = artifact;
        return artifact;
    }
    #endregion
}
