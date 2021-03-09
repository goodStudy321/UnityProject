using System;

/// <summary>
/// 经验提升buff
/// </summary>
public class ExpChangeBuff : BuffUnit
{

    private float mUpdateValue;

    public ExpChangeBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        
    }

    public override void OnDestroy()
    {

    }
}

