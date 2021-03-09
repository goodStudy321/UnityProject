using System;
using System.Collections.Generic;

/// <summary>
/// //无敌buff
/// </summary>
public class InvincibleBuff : BuffUnit
{
    public InvincibleBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.IsInvincible = true;
    }

     public override void OnDestroy()
     {
         mOwner.mUnitBuffStateInfo.IsInvincible = false;
     }
}

