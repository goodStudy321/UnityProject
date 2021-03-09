using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InvertCampBuf : BuffUnit
{
    #region ���з���
    public InvertCampBuf(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.InvertCamp = true;
    }

    public override void OnDestroy()
    {
        mOwner.mUnitBuffStateInfo.InvertCamp = false;
    }
    #endregion
}