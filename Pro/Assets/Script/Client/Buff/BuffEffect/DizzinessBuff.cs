using System;

/// <summary>
/// 眩晕buff
/// </summary>
public class DizzinessBuff: BuffUnit
{
    public DizzinessBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        mOwner.mUnitBuffStateInfo.IsDizziness = true;
        owner.mUnitMove.StopNav();
        mOwner.ActionStatus.ChangeIdleAction();
    }

    public override void OnDestroy()
    {
        mOwner.mUnitBuffStateInfo.IsDizziness = false;
    }
}

