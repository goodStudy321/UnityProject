using System;
using System.Collections.Generic;


/// <summary>
/// 隐身buff
/// </summary>
public class HidingBuff:BuffUnit
{
    public HidingBuff(BufSetup bufSetup, Unit owner, object[] param)
        : base(bufSetup, owner, param)
    {
        
    }

     public override void OnDestroy()
     {
         
     }
}

