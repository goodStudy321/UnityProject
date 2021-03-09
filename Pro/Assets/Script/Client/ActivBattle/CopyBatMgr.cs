using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CopyBatMgr
{
    public static readonly CopyBatMgr instance = new CopyBatMgr();
    private CopyBatMgr() { }
    #region 私有字段
    /// <summary>
    /// 己方单位
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// 无位置坐标
    /// </summary>
    private Vector3 mNoPos = new Vector3(100000, 0, 100000);
    /// <summary>
    /// 目标点
    /// </summary>
    private Vector3 mDesPos = new Vector3(100000,0,100000);
    #endregion

    #region 私有方法
    /// <summary>
    /// 场景条件
    /// </summary>
    /// <returns></returns>
    private bool SceneCon()
    {
        GameSceneType curSType = (GameSceneType)GameSceneManager.instance.CurSceneType;
        if (curSType != GameSceneType.GST_Copy)
            return false;
        return true;
    }

    /// <summary>
    /// 检查动作状态
    /// </summary>
    /// <returns></returns>
    private bool CanChangeMoveState()
    {
        if (mDesPos == mNoPos)
            return false;
        if (mOwner == null)
            return false;
        if (mOwner.Mount != null)
        {
            if (IsCanMove(mOwner.Mount))
                return true;
        }
        return IsCanMove(mOwner);
    }

    /// <summary>
    /// 是否可以移动
    /// </summary>
    /// <param name="unit"></param>
    /// <returns></returns>
    private bool IsCanMove(Unit unit)
    {
        if (unit == null)
            return false;
        if (unit.ActionStatus == null)
            return false;
        ActionStatus.EActionStatus actionState = unit.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Move)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Dead)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return false;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return false;
        return true;
    }

    /// <summary>
    /// 向目的点移动
    /// </summary>
    private void MoveToDesPos()
    {
        if (mDesPos == mNoPos)
            return;
        Vector3 srcPos = mOwner.Position;
        srcPos.y = mDesPos.y;
        float dis = Vector3.Distance(srcPos, mDesPos);
        float stopDis = 0.5f;
        if (dis <= stopDis)
            return;
        mOwner.mUnitMove.StartNav(mDesPos,stopDis);
    }
    
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init(Unit unit)
    {
        if (!SceneCon())
            return;
        mDesPos = mNoPos;
        mOwner = unit;
    }

    /// <summary>
    /// 设置目标点
    /// </summary>
    /// <param name="startX"></param>
    /// <param name="startZ"></param>
    /// <param name="endX"></param>
    /// <param name="endZ"></param>
    public void SetDesPos(float startX, float startZ, float endX, float endZ)
    {
        startX = startX * 0.01f;
        startZ = startZ * 0.01f;
        endX = endX * 0.01f;
        endZ = endZ * 0.01f;
        float midX = (startX + endX) / 2;
        float midZ = (startZ + endZ) / 2;
        mDesPos.x = midX;
        mDesPos.z = midZ;
    }

    /// <summary>
    /// 移动
    /// </summary>
    public void Move()
    {
        if (!SceneCon())
            return;
        if (!CanChangeMoveState())
            return;
        MoveToDesPos();
    }
    #endregion
}
