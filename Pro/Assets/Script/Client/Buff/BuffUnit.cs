using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using Loong.Game;
using System;

public class BuffUnit
{
    #region 保护字段
    protected BufSetup mBuffSetup;
    protected Unit mOwner;
    #endregion

    public static System.Type[] sConstructorTypes = new System.Type[]
    {
        typeof(BufSetup), typeof(Unit), typeof(object[])
    };

    public BuffUnit(BufSetup bufSetup, Unit owner, object[] param)
    {
        mBuffSetup = bufSetup;
        mOwner = owner;
    }

    public virtual void Update(float DeltaTime)
    {

    }

    public virtual void OnBeginHit(Unit attacker, HitAction hitDefinition, ActionCommon.HitData hitData)
    {

    }

    public virtual void OnEndHit(Unit attacker, HitAction hitDefinition, ActionCommon.HitData hitData, DamageInfo damageInfo)
    {

    }

    public virtual void OnBeginAttack(Unit target)
    {

    }

    public virtual void OnEndAttack(Unit target, DamageInfo damageInfo)
    {

    }

    public virtual void OnDestroy()
    {

    }

    public virtual bool FilterBuff(int iEffId)
    {
        return true;
    }
}
