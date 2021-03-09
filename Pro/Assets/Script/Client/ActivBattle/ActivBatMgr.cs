using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class ActivBatMgr
{
    public static readonly ActivBatMgr instance = new ActivBatMgr();
    private ActivBatMgr() { }
    #region 私有字段
    //自己
    private Unit mOwner = null;
    //是否是活动地图
    private bool isActivMap = false;
    //玩法信息
    private MapPlayInfo mPlayInfo = null;
    //自动挂机时间
    private Timer mHgupTimer = null;
    //路点停留计时器
    private Timer mStayTimer = null;
    //停留时间
    private float mStayTime = 0;
    //巡逻方式
    private PatrolType mPatrolType = PatrolType.Linear;
    //巡逻索引
    private int mPatrolIndex = -1;
    //正在巡逻
    private bool mPatroling = false;
    //巡逻位置字典
    private Dictionary<int, Vector3> mPatrolPosDic = new Dictionary<int, Vector3>();
    #endregion

    #region 属性
    /// <summary>
    /// 是否在活动地图
    /// </summary>
    public bool IsActivMap { get { return isActivMap; } }
    #endregion

    #region 私有方法
    //设置巡逻位置字典
    private void SetPatrolPosDic()
    {
        if (mPlayInfo == null)
            return;
        mPatrolPosDic.Clear();
        List<MapPlayInfo.vector2> posList = mPlayInfo.loopPosLst.list;
        if (posList.Count == 0)
        {
            posList = mPlayInfo.linearPosLst.list;
            if (posList.Count == 0)
                return;
            mPatrolType = PatrolType.Linear;
        }
        else
        {
            mPatrolType = PatrolType.Loop;
        }
        for(int i = 0; i < posList.Count; i++)
        {
            float x = posList[i].x;
            float z = posList[i].z;
            Vector3 pos = new Vector3(x, 0, z);
            pos.y = UnitHelper.instance.GetTerrainHeight(pos);
            mPatrolPosDic[i] = pos;
        }
        mPatrolIndex = 0;
        StartHgupTimer(mPlayInfo.hangupTime * 0.001f);
    }

    /// <summary>
    /// 检查动作状态
    /// </summary>
    /// <returns></returns>
    private bool CanChangeActionState()
    {
        if (mOwner == null)
            return false;
        ActionStatus.EActionStatus actionState = mOwner.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Dead)
            return false;
        if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return false;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return false;
        return true;
    }

    /// <summary>
    /// 根据类型Id获取目标
    /// </summary>
    /// <param name="typeId"></param>
    /// <returns></returns>
    private Unit GetTarByTypeId(Unit finder)
    {
        if (mPlayInfo == null)
            return null;
        int count = mPlayInfo.attTypeIdLst.list.Count;
        if (count == 0)
            return null;
        Unit target = null;
        for (int i = 0; i < count; i++)
        {
            target = SkillHelper.instance.GetNTarByTypeId(finder, mPlayInfo.attTypeIdLst.list[i]);
            if (target == null)
                continue;
            UnitType unitType = target.mUnitAttInfo.UnitType;
            if (!SkillHelper.instance.CannotHitUnitType(unitType))
                continue;
            if (!SkillHelper.instance.InViewDis(finder, target))
                continue;
            if (!SkillHelper.instance.CanHit(target))
                continue;
            if (SkillHelper.instance.CompaireCamp(finder, target, UnitCamp.Enemy))
                continue;
            return target;
        }
        return null;
    }

    /// <summary>
    /// 根据类型获取目标
    /// </summary>
    /// <param name="type"></param>
    /// <returns></returns>
    private Unit GetTarByType(Unit finder)
    {
        if (mPlayInfo == null)
            return null;
        int count = mPlayInfo.attTypeList.list.Count;
        if (count == 0)
            return null;
        Unit target = null;
        for (int i = 0; i < count; i++)
        {
            UnitType unitType = (UnitType)mPlayInfo.attTypeList.list[i];
            target = SkillHelper.instance.GetNTarByType(finder, unitType);
            if (target == null)
                continue;
            if (!SkillHelper.instance.CannotHitUnitType(unitType))
                continue;
            if (!SkillHelper.instance.InViewDis(finder, target))
                continue;
            if (!SkillHelper.instance.CanHit(target))
                continue;
            if (!SkillHelper.instance.CompaireCamp(finder, target, UnitCamp.Enemy))
                continue;
            return target;
        }
        return null;
    }

    private void PathfindingCB(Unit unit,AsPathfinding.PathResultType PRType)
    {
        NavMoveBuff.instance.StopMoveBuff(unit);
        mPatroling = false;
        if (PRType != AsPathfinding.PathResultType.PRT_PATH_SUC)
            StopStayTimer();
        else
        {
            StartStayTimer();
            ChangePatrolIndex();
        }
    }

    /// <summary>
    /// 改变巡逻路点索引
    /// </summary>
    private void ChangePatrolIndex()
    {
        int count = mPatrolPosDic.Count;
        if(mPatrolType == PatrolType.Linear)
        {
            if (mPatrolIndex + 1 >= count)
                mPatrolIndex = -1;
            else
                mPatrolIndex++;
        }
        else if(mPatrolType == PatrolType.Loop)
        {
            if (mPatrolIndex + 1 >= count)
                mPatrolIndex = 0;
            else
                mPatrolIndex++;
        }
        else if(mPatrolType == PatrolType.radom)
        {
            mPatrolIndex = Random.Range(0, count);
        }
    }

    /// <summary>
    /// 重置路点停留计时器
    /// </summary>
    private void StartStayTimer()
    {
        if (mStayTimer == null)
            mStayTimer = ObjPool.Instance.Get<Timer>();
        else
            mStayTimer.Stop();
        mStayTimer.Seconds = mStayTime;
        mStayTimer.Start();
    }

    /// <summary>
    /// 停止陆路点停留计时器
    /// </summary>
    private void StopStayTimer()
    {
        if (mStayTimer == null)
            return;
        if (!mStayTimer.Running)
            return;
        mStayTimer.Stop();
    }
    #endregion

    #region 公有方法

    /// <summary>
    /// 开始挂机计时器
    /// </summary>
    public void StartHgupTimer(float seconds)
    {
        if (mHgupTimer == null)
            mHgupTimer = ObjPool.Instance.Get<Timer>();
        else
            mHgupTimer.Stop();
        mHgupTimer.Seconds = seconds;
        mHgupTimer.complete += HgupCmp;
        mHgupTimer.Start();
    }

    /// <summary>
    /// 停止挂机计时器
    /// </summary>
    public void StopHgupTimer()
    {
        if (mHgupTimer == null)
            return;
        if (!mHgupTimer.Running)
            return;
        mHgupTimer.Stop();
    }

    /// <summary>
    /// 自动挂机计时完成
    /// </summary>
    public void HgupCmp()
    {
        HangupMgr.instance.IsSituFight = true;
    }
    /// <summary>
    /// 设置活动地图数据
    /// </summary>
    /// <param name="sceneId"></param>
    public void SetActivMapData(int sceneId)
    {
        SceneInfo sceneInfo = SceneInfoManager.instance.Find((uint)sceneId);
        if(sceneInfo == null)
        {
            ClearData();
            return;
        }
        MapPlayInfo playInfo = MapPlayInfoManager.instance.Find(sceneInfo.playId);
        if(playInfo == null)
        {
            ClearData();
            return;
        }
        mOwner = InputMgr.instance.mOwner;
        isActivMap = sceneInfo.playId != 0;
        mPlayInfo = playInfo;
        mPatroling = false;
        mStayTime = playInfo.stayTime * 0.001f;
        SetPatrolPosDic();
    }

    /// <summary>
    /// 获取活动地图目标
    /// </summary>
    /// <returns></returns>
    public Unit GetActivTarget(Unit owner)
    {
        Unit target = GetTarByTypeId(owner) == null ? GetTarByType(owner):null;
        if (target != null)
            return target;
        return null;
    }

    /// <summary>
    /// 清除数据
    /// </summary>
    public void ClearData()
    {
        isActivMap = false;
        mPlayInfo = null;
    }

    public void MoveToPos()
    {
        if (!isActivMap)
            return;
        if (mPatrolIndex == -1)
            return;
        if (mPatroling)
            return;
        if (mHgupTimer == null)
            return;
        if (mHgupTimer.Running)
            return;
        if (!CanChangeActionState())
            return;
        if (mStayTimer != null && mStayTimer.Running)
            return;
        Vector3 targetPos = mPatrolPosDic[mPatrolIndex];
        if (!mOwner.mUnitMove.StartNav(targetPos, -1, 0, PathfindingCB, true))
            return;
        mPatroling = true;
    }
    #endregion
}
