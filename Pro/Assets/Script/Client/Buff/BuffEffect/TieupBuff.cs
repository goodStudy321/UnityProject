using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TieupBuff : BuffUnit
{
    #region 公有方法
    public TieupBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.IsTieUp = true;
        mOwner.mUnitMove.StopNav();
        mOwner.ActionStatus.ChangeIdleAction();
    }

    public override void OnDestroy()
    {
        mOwner.mUnitBuffStateInfo.IsTieUp = false;
    }
    #endregion
}
