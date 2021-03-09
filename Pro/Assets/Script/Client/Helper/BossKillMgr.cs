using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BossKillMgr
{
    public static readonly BossKillMgr instance = new BossKillMgr();

    private BossKillMgr(){}
    #region 公有函数
    /// <summary>
    /// 寻找Boss寻路
    /// </summary>
    /// <param name="targetPos"></param>
    /// <param name="mapId"></param>
    /// <param name="stopDis"></param>
    /// <param name="roleId"></param>
    public void StartNavPath(Vector3 targetPos, uint mapId, float stopDis = -1f, uint roleId = 0)
    {
        HangupMgr.instance.IsSituFight = false;
        HangupMgr.instance.IsAutoSkill = false;
        InputMgr.instance.ClearTarget();
        Unit unit = InputVectorMove.instance.MoveUnit;
        if (unit == null || unit.mUnitMove == null) return;
        if (roleId != 0)
        {
            Unit attacker = InputMgr.instance.mOwner;
            float dis = 0;
            Unit target = SkillHelper.instance.GetNTarByTypeId(attacker, roleId);
            if (target == null)
                dis = ActionHelper.GetUnitBoundingW(roleId);
            else
            {
                stopDis = SkillHelper.instance.GetUnitModelRadius(target);
                targetPos = target.Position;
            }
            dis += 0.5f;
            if (stopDis > 0)
                stopDis += dis;
            else
                stopDis = dis;
        }
        unit.mUnitMove.StartNav(targetPos, stopDis, mapId, NavPathsComplete);
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
        HangupMgr.instance.IsSituFight = true;
    }

    /// <summary>
    /// 获取地面高度
    /// </summary>
    /// <param name="pos"></param>
    /// <returns></returns>
    public float GetTerrainHeight(Vector3 pos)
    {
        return UnitHelper.instance.GetTerrainHeight(pos);
    }

    /// <summary>
    /// 获取主相机的欧拉角
    /// </summary>
    /// <returns></returns>
    public Vector3 GetCamEAngls()
    {
        Camera cam = Loong.Game.CameraMgr.Main;
        if (cam == null)
            return Vector3.zero;
        return cam.transform.eulerAngles;
    }
    #endregion
}
