using System;
using System.Collections.Generic;

/// <summary>
/// /免疫buff,免疫一切的减益buff
/// </summary>
public class ImmunityBuff : BuffUnit
{
    public ImmunityBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.IsImmunity = true;
    }

     public override void OnDestroy()
     {
         mOwner.mUnitBuffStateInfo.IsImmunity = false;
     }
}

