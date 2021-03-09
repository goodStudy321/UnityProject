using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SelectRoleMgr
{
    public static readonly SelectRoleMgr instance = new SelectRoleMgr();

    private SelectRoleMgr() { }
    #region 属性
    /// <summary>
    /// 目标角色Id
    /// </summary>
    public long TarRoleUId = 0;
    #endregion

    #region 公有方法
    /// <summary>
    /// 寻找Boss寻路
    /// </summary>
    /// <param name="targetPos"></param>
    /// <param name="mapId"></param>
    /// <param name="stopDis"></param>
    /// <param name="roleId"></param>
    public void StartNavPath(long tarUid, float stopDis = -1f)
    {
        if (tarUid == 0)
            return;
        Unit target = UnitMgr.instance.FindUnitByUid(tarUid);
        if (target == null)
            return;
        if (!SkillHelper.instance.CanHitSafeMons(target))
        {
            Loong.Game.UITip.LocalLog(690013);
            return;
        }
        if (SkillHelper.instance.BossTie(InputMgr.instance.mOwner, target))
        {
            Loong.Game.UITip.LocalLog(690014);
            return;
        }
        Clear();
        HangupMgr.instance.IsSituFight = false;
        HangupMgr.instance.IsAutoSkill = false;
        InputMgr.instance.ClearTarget();
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null) return;
        float dis = 0;
        stopDis = SkillHelper.instance.GetUnitModelRadius(target);
        dis += 0.5f;
        if (stopDis > 0)
            stopDis += dis;
        else
            stopDis = dis;
        SetKillTar(target);
        unit.mUnitMove.StartNav(target.Position, stopDis, 0, NavPathsComplete);
    }

    /// <summary>
    /// 设置击杀目标
    /// </summary>
    /// <param name="target"></param>
    public void SetKillTar(Unit target)
    {
        if (target == null)
            return;
        TarRoleUId = target.UnitUID;
        HangupMgr.instance.IsAutoHangup = true;
        HangupMgr.instance.IsMisKill = true;
    }
    /// <summary>
    /// 寻找Boss寻路完成
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="type"></param>
    public void NavPathsComplete(Unit unit, AsPathfinding.PathResultType type)
    {
        UnitHelper.instance.ResetUnitData(unit);
        if (type != AsPathfinding.PathResultType.PRT_PATH_SUC)
            return;
        Unit target = UnitMgr.instance.FindUnitByUid(TarRoleUId);
        if(target != null && !target.Dead)
        {
            StartNavPath(TarRoleUId, 1);
            return;
        }
        Clear();
        SetHgup();
    }

    /// <summary>
    /// 移除单位
    /// </summary>
    public void RemoveUnit(long uId)
    {
        if (uId != TarRoleUId)
            return;
        Clear();
        HangupMgr hgMgr = HangupMgr.instance;
        if (hgMgr.IsAutoHangup)
        {
            hgMgr.IsSituFight = true;
        }
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void Clear()
    {
        TarRoleUId = 0;
        HangupMgr.instance.IsMisKill = false;
    }

    /// <summary>
    /// 重置选择目标单位UID
    /// </summary>
    public void ResetTRUId()
    {
        TarRoleUId = 0;
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置挂机
    /// </summary>
    private void SetHgup()
    {
        HangupMgr.instance.IsAutoHangup = true;
        HangupMgr.instance.IsAutoSkill = true;
    }
    #endregion
}
