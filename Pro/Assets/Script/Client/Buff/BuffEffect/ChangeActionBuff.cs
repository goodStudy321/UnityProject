using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChangeActionBuff : BuffUnit
{
    #region 公有方法
    public ChangeActionBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {

    }

    public override void OnEndHit(Unit attacker, HitAction hitDefinition, ActionCommon.HitData hitData, DamageInfo damageInfo)
    {
        mOwner.ActionStatus.ChangeAction(mBuffSetup.mBufBaseInfo.playAction, 0);
        base.OnEndHit(attacker, hitDefinition, hitData, damageInfo);
    }

    public override void OnDestroy()
    {
        mOwner.ActionStatus.ChangeIdleAction();
    }
    #endregion
}
