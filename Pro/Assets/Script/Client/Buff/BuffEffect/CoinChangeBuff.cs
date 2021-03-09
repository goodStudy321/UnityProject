using System;

/// <summary>
/// 金币提升buff
/// </summary>
public class CoinChangeBuff : BuffUnit
{

    public CoinChangeBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        
    }

    public override void OnDestroy()
    {

    }
}

