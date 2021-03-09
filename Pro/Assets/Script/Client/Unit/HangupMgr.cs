using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class HangupMgr
{
    public static readonly HangupMgr instance = new HangupMgr();
    private HangupMgr() { }

    #region 私有字段
    /// <summary>
    /// 挂机单位
    /// </summary>
    private Unit mOwner;
    /// <summary>
    /// 是否自动挂机(任务自动挂机）
    /// </summary>
    private bool isAutoHangup = false;
    /// <summary>
    /// 原地自动技能
    /// </summary>
    private bool isSituFight = false;
    /// <summary>
    /// 自动技能
    /// </summary>
    private bool isAutoSkill = false;
    /// <summary>
    /// 是否暂停
    /// </summary>
    private bool isPause = false;
    /// <summary>
    /// 任务击杀
    /// </summary>
    private bool isMisKill = false;
    /// <summary>
    /// 是否在移动拾取
    /// </summary>
    private bool isMovetoPickup = false;
    /// <summary>
    /// 是否在自动导航玩家
    /// </summary>
    private bool isAutoNavPlayer = false;
    /// <summary>
    /// 掉落物ID
    /// </summary>
    private ulong mDropID = 0;
    /// <summary>
    /// 掉落物位置
    /// </summary>
    private Vector3 mDropPos = Vector3.zero;
    /// <summary>
    /// 自动挂机时间
    /// </summary>
    private float mAutoTime = 5f;
    private float mAutoHangupTime = 5f;
    /// <summary>
    /// 任务ID
    /// </summary>
    private int mMissionId = 0;
    /// <summary>
    /// 任务状态
    /// </summary>
    private MissionStatus mMissionStatus = MissionStatus.None;
    /// <summary>
    /// 计时器
    /// </summary>
    private Timer mTime = null;
    #endregion
    
    #region 属性
    public float AutoHangupTime
    {
        get { return mAutoTime; }
        set { mAutoTime = mAutoHangupTime = value; }
    }
    /// <summary>
    /// 自动技能
    /// </summary>
    public bool IsAutoSkill
    {
        get { return isAutoSkill; }
        set
        {
            isAutoSkill = value;
            ResetHangupTime();
            HgupPoint.instance.ResetTime();
            if (IsSituFight)
                return;
            if (!isAutoHangup && value == true) return;
            UnitAutoFight.instance.SetAutoFightTip(Owner, value);
        }
    }

    /// <summary>
    /// 是否原地挂机
    /// </summary>
    public bool IsSituFight
    {
        get { return isSituFight; }
        set
        {
            isSituFight = value;
            IsAutoHangup = false;
            isAutoSkill = false;
            IsMisKill = false;
            if (!value)
            {
                FightModMgr.instance.ClearFMAutoTargets();
                return;
            }
            if (mOwner == null)
                return;
            User.instance.ResetMisTarID();
            UnitAutoFight.instance.SetAutoFightTip(mOwner, true);
            FightModMgr.instance.SetFMAutoTargets(mOwner);
            if (!mOwner.mUnitMove.InPathFinding)
                return;
            mOwner.mUnitMove.StopNav();
        }
    }

    /// <summary>
    /// 自动挂机(自动任务）
    /// </summary>
    public bool IsAutoHangup
    {
        get { return isAutoHangup; }
        set
        {
            isAutoHangup = value;
            ResetHangupTime();
            HgupPoint.instance.ResetTime();
            if (value == true)
                isSituFight = false;
        }
    }

    /// <summary>
    /// 是否暂停
    /// </summary>
    public bool IsPause
    {
        get { return isPause; }
        set
        {
            isPause = value;
            if (value == false)
                return;
            InputMgr.instance.mOwner.mUnitMove.StopNav();
            ResetMovePickup();
        }
    }

    /// <summary>
    /// 任务击杀
    /// </summary>
    public bool IsMisKill
    {
        get { return isMisKill; }
        set { isMisKill = value; }
    }

    /// <summary>
    /// 挂机单位
    /// </summary>
    public Unit Owner
    {
        get { return mOwner; }
        set { mOwner = value; }
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 场景初始化条件
    /// </summary>
    /// <returns></returns>
    private bool SceneInitCon()
    {
        if (GameSceneManager.instance.SceneLoadState != SceneLoadStateEnum.SceneDone)
            return false;
        if (GameSceneManager.instance.CurCopyType == CopyType.Offl1v1)
            return false;
        if (GameSceneManager.instance.SceneStatus != SceneStatus.Normal)
            return false;
        if (!MapPathMgr.instance.MapInit)
            return false;
        if (!User.instance.MapData.HasInitPos)
            return false;
        if (CutscenePlayMgr.instance.IsPlaying)
            return false;
        return true;
    }

    /// <summary>
    /// 自动挂机计数更新
    /// </summary>
    private void TimeCountUpdate()
    {
        if (ActivBatMgr.instance.IsActivMap) return;//活动对战地图不需检测要进入挂机流程
        if (!HangupHelper.instance.ChkIdleState(mOwner))
            return;
        HgupPoint.instance.UpdateHgPoint();
        if (HangupHelper.instance.ChkHgLv())
            return;
        mAutoHangupTime -= Time.deltaTime;
        if (mAutoHangupTime > 0)
            return;
        IsAutoHangup = true;
        isAutoSkill = false;
        User.instance.MissionState = false;
        ResetMovePickup();
    }

    /// <summary>
    /// 重置挂机时间
    /// </summary>
    private void ResetHangupTime()
    {
        if (mAutoHangupTime == mAutoTime)
            return;
        mAutoHangupTime = mAutoTime;
    }

    /// <summary>
    /// 检查动作状态
    /// </summary>
    /// <returns></returns>
    private bool CheckActionState()
    {
        ActionStatus.EActionStatus actionState = mOwner.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Idle)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Move)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return true;
        return false;
    }

    /// <summary>
    /// 是否技能状态
    /// </summary>
    /// <returns></returns>
    private bool IsSkillState()
    {
        ActionStatus.EActionStatus actionState = mOwner.ActionStatus.ActionState;
        if (actionState == ActionStatus.EActionStatus.EAS_Attack)
            return true;
        else if (actionState == ActionStatus.EActionStatus.EAS_Skill)
            return true;
        return false;
    }

    /// <summary>
    /// 是否在拾取掉落物
    /// </summary>
    /// <returns></returns>
    private bool IsPickupDrop()
    {
        if (!isAutoHangup && !isSituFight)
            return false;
        if (isMovetoPickup)
        {
            if (!CheckDropInfo())
            {
                ResetMovePickup();
                return false;
            }
            if (DropMgr.isFull)
            {
                ResetMovePickup();
                return false;
            }
            return true;
        }
        if (CheckDrop())
            return true;
        return false;
    }
    
    /// <summary>
    /// 检查掉落物操作
    /// </summary>
    /// <returns></returns>
    private bool CheckDrop()
    {
        DropInfo drop = DropMgr.GetCanPickupDrop();
        if(drop != null && drop.data != null)
        {
            mDropID = drop.data.dropId;
            mDropPos = drop.Position;
        }
        if (CheckDropInfo())
        {
            if (IsSkillState())
                return true;
            MoveToPick();
            return true;
        }
        return false;
    }

    /// <summary>
    /// 检查掉落物信息
    /// </summary>
    /// <returns></returns>
    private bool CheckDropInfo()
    {
        if (mDropID == 0)
            return false;
        return true;
    }

    /// <summary>
    /// 移动拾取
    /// </summary>
    private void MoveToPick()
    {
        DropMgr.pickScs += PickupCallback;
        isMovetoPickup = true;
        InputMgr.instance.ClearTarget(false);
        Unit unit = InputVectorMove.instance.MoveUnit;
        unit.mUnitMove.StartNav(mDropPos, -1, 0, NavCom);
    }

    /// <summary>
    /// 寻路完成
    /// </summary>
    /// <param name="unit"></param>
    /// <param name="PRType"></param>
    private void NavCom(Unit unit, AsPathfinding.PathResultType PRType)
    {
        UnitHelper.instance.ResetUnitData(unit);
    }

    /// <summary>
    /// 成功拾取回调
    /// </summary>
    /// <param name="dropId"></param>
    private void PickupCallback(ulong dropId)
    {
        if (mDropID != dropId)
            return;
        ResetMovePickup();
        DropMgr.pickScs -= PickupCallback;
        DropInfo nextDrop = DropMgr.GetCanPickupDrop();
        if (nextDrop != null)
            return;
        if (isPause)
            return;
        ExcuteMission();
    }

    /// <summary>
    /// 移除掉落回调
    /// </summary>
    private void RemoveDropCB(ulong dropId)
    {
        if (mDropID != dropId)
            return;
        ResetMovePickup();
    }

    /// <summary>
    /// 重置移动拾取
    /// </summary>
    public void ResetMovePickup()
    {
        isMovetoPickup = false;
        ResetDrop();
    }

    /// <summary>
    /// 重置掉落
    /// </summary>
    public void ResetDrop()
    {
        mDropID = 0;
        mDropPos = Vector3.zero;
    }

    /// <summary>
    /// 执行任务
    /// </summary>
    private void ExcuteMission()
    {
        if (isPause)
            return;
        if (!SceneInitCon())
            return;
        if (!isAutoHangup)
            return;
        if (mTime != null && mTime.Running)
            return;
        if (isAutoNavPlayer)
            return;
        DropInfo drop = DropMgr.GetCanPickupDrop();
        if (drop != null)
            return;
        GameSceneType sceneType = (GameSceneType)GameSceneManager.instance.CurSceneType;
        if (sceneType == GameSceneType.GST_Copy)
            return;
        if (sceneType == GameSceneType.GST_Unknown)
            return;
        //如果是特殊地图
        if (GameSceneManager.instance.MapSubType != SceneSubType.None)
        {
            if (IsAutoSkill)
                return;
            IsAutoSkill = true;
            FightModMgr.instance.SetFMAutoTargets(mOwner);
            return;
        }
        //任务地图
        if (mMissionStatus == MissionStatus.None)
        {
            IsAutoSkill = true;
            return;
        }
        else
        {
            IsAutoSkill = false;
            ResetMovePickup();
            mOwner.mUnitMove.StopNav();
            if (CollectionMgr.State == CollectionState.Req)
                return;
            else if (CollectionMgr.State == CollectionState.Run)
                return;
            UnitAttackCtrl.instance.Clear();
            UnitWildRush.instance.Clear();
            EventMgr.Trigger("ExcuteMission", 1);
        }
    }

    /// <summary>
    /// 执行时间计数
    /// </summary>
    /// <param name="args"></param>
    private void ExcTimeCount(params object[] args)
    {
        if (mTime == null)
        {
            mTime = ObjPool.Instance.Get<Timer>();
            mTime.Seconds = 0.5f;
            //mTime.complete += ExcuteMission;
        }
        else
        {
            mTime.Stop();
            mTime.Seconds = 0.5f;
        }
        mTime.Start();
        IsMisKill = false;
    }
    
    /// <summary>
    /// 是否可执行任务
    /// </summary>
    /// <param name="nextMId"></param>
    /// <param name="nextMS"></param>
    /// <returns></returns>
    private bool CanExcMission(int nextMId, MissionStatus nextMS)
    {
        if (mMissionId != nextMId)
            return true;
        if (mMissionStatus != nextMS)
            return true;
        return false;
    }

    /// <summary>
    /// 单位死亡
    /// </summary>
    /// <param name="unit"></param>
    private void UnitDie(Unit unit)
    {
        if (unit != mOwner)
            return;
        ClearAutoInfo();
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    /// <param name="unit"></param>
    public void Init(Unit unit)
    {
        mOwner = unit;
        EventMgr.Add(EventKey.AllAnimFinish, ExcTimeCount);
        UnitEventMgr.die += UnitDie;
        DropMgr.removeAct += RemoveDropCB;
        DropMgr.PAllDropAct += ResetMovePickup;
    }
    /// <summary>
    /// 更新(处理正常任务挂机、原地挂机、玩家pk地图玩法的自动挂机)
    /// </summary>
    public void Update()
    {
        if (HeartBeat.bConnectOverTime)
            return;
        if (isPause)
            return;
        if (!SceneInitCon())
            return;
        if (User.instance.ShoesStatus)
        {
            return;
        }
        if (!UnitHelper.instance.PreConCanPass(mOwner))
            return;
        if (!CheckActionState())
            return;
        if (IsPickupDrop())
            return;
        if(isSituFight)
        {
            UnitAutoFight.instance.ActionUpdate(Owner);
            return;
        }
        TimeCountUpdate();
        if (!isAutoHangup)
            return;
        if (isAutoSkill || IsMisKill)
        {
            UnitAutoFight.instance.ActionUpdate(Owner);
            return;
        }
        if (HgupPoint.instance.IsHgupPoint)
            return;
        if (User.instance.MissionState)
            return;
        ExcuteMission();
    }

    /// <summary>
    /// 任务更新
    /// </summary>
    public void MissionUpdate(int missionId, int nextState)
    {
        MissionStatus nextMS = (MissionStatus)nextState;
        if (!CanExcMission(missionId, nextMS))
            return;
        mMissionId = missionId;
        mMissionStatus = nextMS;
        if (mOwner == null)
            return;
        //mOwner.mUnitMove.StopNav();
        ExcTimeCount();
    }

    /// <summary>
    /// 设置挂机点挂机
    /// </summary>
    /// <param name="hguppoint"></param>
    public void SetHgupPoint(bool hguppoint)
    {
        HgupPoint.instance.IsHgupPoint = hguppoint;
    }

    /// <summary>
    /// 开启系统停止挂机或者自动战斗（有播放动画才停止）
    /// </summary>
    /// <param name="systemid"></param>
    public void OpenSysStopHg(ushort systemid)
    {
        systemopen sysOpen = systemopenManager.instance.Find(systemid);
        if (sysOpen == null)
            return;
        if (sysOpen.openAnimeTime == 0)
            return;
        ClearAutoInfo();
        if (mOwner == null)
            return;
        if (mOwner.ActionStatus == null)
            return;
        mOwner.ActionStatus.ChangeIdleAction();
        mOwner.mUnitMove.StopNav();
    }

    /// <summary>
    /// 清除自动信息
    /// </summary>
    public void ClearAutoInfo()
    {
        IsAutoHangup = false;
        IsMisKill = false;
        Clear();
    }

    /// <summary>
    /// 清楚数据
    /// </summary>
    public void Clear()
    {
        isSituFight = false;
        User.instance.MissionState = false;
        mAutoHangupTime = mAutoTime;
        ActivBatMgr.instance.StopHgupTimer();
        ClearInfo();
    }

    /// <summary>
    /// 清除信息
    /// </summary>
    public void ClearInfo()
    {
        IsAutoSkill = false;
        ResetMovePickup();
    }

    /// <summary>
    /// 设置信息
    /// </summary>
    public void SetInfo(bool bNav)
    {
        isAutoNavPlayer = bNav;
        if (!bNav)
            return;
        IsAutoSkill = false;
    }

    public void Dispose()
    {
        ClearAutoInfo();
        IsPause = false;
        if (mTime != null)
            mTime.Stop();
        HgupPoint.instance.Clear();
    }
    #endregion
}
