using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class FightModFty
{
    #region 公有方法
    public static FightModBase Create(FightType type)
    {
        FightModBase ftMod = null;
        switch(type)
        {
            case FightType.PeaceMode:
                {
                    ftMod = new PeaceMode();
                    break;
                }
            case FightType.ForceMode:
                {
                    ftMod = new ForceMode();
                    break;
                }
            case FightType.AllMode:
                {
                    ftMod = new AllMode();
                    break;
                }
            case FightType.CampMode:
                {
                    ftMod = new CampMode();
                    break;
                }
            case FightType.CrossServer:
                {
                    ftMod = new CrossServer();
                    break;
                }
            case FightType.BossExclusive:
                {
                    ftMod = new BossExclusive();
                    break;
                }
            default:break;
        }
        return ftMod;
    }
    #endregion
}
