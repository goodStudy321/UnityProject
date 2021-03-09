using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeSizeBuff : BuffUnit
{
    #region 公有方法

    public ChangeSizeBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        //mOwner.mUnitTransScale.SetScale(bufSetup.mBufBaseInfo.charValue / 1000.0f, true);
    }

    public override void OnDestroy()
    {
        mOwner.mUnitTransScale.SetScale(1, true);
    }
    #endregion
}