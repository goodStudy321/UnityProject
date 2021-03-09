using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// ���
/// </summary>
public class Artifact : PendantBase
{
    #region ˽�б���
    /// <summary>
    /// �ѵ����
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

    #region ���з���
    /// <summary>
    /// ����
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
