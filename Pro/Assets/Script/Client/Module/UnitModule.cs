using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class UnitModule:IModule
{
    public virtual void Init()
    {
        
    }

    public virtual void Clear(bool reconnect = false)
    {
        Unit unit = InputMgr.instance.mOwner;
        BuffHelper.instance.ClearBuffs(unit);
        if(unit != null)
        {
            unit.mUnitMove.StopNav();
            unit.mUnitMove.Pathfinding.ForceStopPathFinding(true);
        }
        UnitMgr.instance.Dispose();
        User.instance.CleanOtherData();
        InputMgr.instance.Clear(false);
        HangupMgr.instance.Dispose();
        AutoFbSkills.instance.Clear();
        AutoPlaySkill.instance.Clear();
        BossBatMgr.instance.Clear();
        NetWorldBoss.Clear();
    }

    public virtual void BegChgScene()
    {

    }

    public virtual void EndChgScene()
    {
        BossBatMgr.instance.Clear();
    }

    public virtual void Dispose()
    {

    }

    public void LocalChanged()
    {
        //TODO
    }
}
