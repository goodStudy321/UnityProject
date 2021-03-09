using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ForbidAtkBoss : BuffUnit
{
    public ForbidAtkBoss(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.ForbidAtkBoss = true;
    }

    public override void OnDestroy()
    {
        mOwner.mUnitBuffStateInfo.ForbidAtkBoss = false;
    }
}
