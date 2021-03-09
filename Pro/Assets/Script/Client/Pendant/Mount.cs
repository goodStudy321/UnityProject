using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

/// <summary>
/// 坐骑
/// </summary>
public class Mount : PendantBase
{
    #region 私有变量
    /// <summary>
    /// 是否已经添加子单位
    /// </summary>
    private bool bAddChild = false;
    /// <summary>
    /// 上下坐骑特效
    /// </summary>
    private GameObject mEffect = null;
    #endregion

    #region 公有变量
    /// <summary>
    /// 人物乘骑待机
    /// </summary>
    public string RoleRdIdle = "";
    /// <summary>
    /// 人物乘骑移动
    /// </summary>
    public string RoleRdMove = "";
    #endregion

    #region 私有方法
    private void SetNbHeight(bool isPuton)
    {
        if (mMtpParent == null)
            return;
        if (mMtpParent.TopBar == null)
            return;
        CommenNameBar bar = mMtpParent.TopBar as CommenNameBar;
        if (bar == null)
            return;
        bar.SetHeight(isPuton);
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 穿戴
    /// </summary>
    /// <param name="mtpParent"></param>
    public override Unit PutOn(Unit mtpParent, uint unitTypeId, PendantStateEnum state, ActorData data = null)
    {
        base.PutOn(mtpParent, unitTypeId, state);
        if (!UnitHelper.instance.CanUseUnit(mtpParent))
            return null;
        MountInfo mountInfo = MountInfoManager.instance.Find(mBaseId);
        if (mountInfo == null)
            return null;
        SetRidingAni(mountInfo);
        mMountPoint = (MountPoint)mountInfo.mountPoint;
        float angle = mtpParent.Orientation * Mathf.Rad2Deg;
        Unit mount = UnitMgr.instance.CreateUnit(mUnitTypeId, mUnitTypeId, mountInfo.name, mtpParent.Position, angle, mtpParent.Camp, (unit) =>
        {
            AddChild(unit);
            SetFightType();
            mOwner = unit;
            if (UnitHelper.instance.IsOwner(mtpParent))
                UnitMgr.instance.SetUnitAllAssetsPersist(unit);
            unit.MoveSpeed = mtpParent.MoveSpeed;
            mtpParent.mNetUnitMove.ClearMoveInfo();
            if(mtpParent.mUnitMove.IsJumping)
            {
                PendantMgr.instance.SetPendantActive(unit, false);
            }
            SetPosition();
            PlayEffect();
            SetShowState(PendantSystemEnum.Mount);
            PendantMgr.instance.ResetCameraTarget(mtpParent.UnitUID, unit);
            CheckPutOnMoveState(mtpParent, unit);
        });
        mOwner = mount;
        mount.mPendant = this;
        AddChild(mount);
        mtpParent.Mount = mount;
        AutoMountMgr.instance.StopTimer(mtpParent);
        NavMoveBuff.instance.StopMoveBuff(mtpParent);
        UnitShadowMgr.instance.SetShadow(mount);
        EventMgr.Trigger("OnTakeOffMount", false);
        return mount;
    }

    /// <summary>
    /// 脱下
    /// </summary>
    /// <param name="mountPendant"></param>
    public override void TakeOff(ActorData data)
    {
        if (mMtpParent == null)
            return;
        mMtpParent.Mount = null;
        if (mMtpParent.UnitTrans == null)
            return;
        mMtpParent.ActionStatus.ignoreGravityGlobal = false;
        AutoMountMgr.instance.StopTimer(mMtpParent);
        if (mMtpParent.UnitTrans.parent != null)
        {
            PlayEffect();
            mMtpParent.UnitTrans.parent = null;
            mMtpParent.Position = mOwner.Position;
            mMtpParent.SetOrientation(mOwner.Orientation);
        }
        PendantMgr.instance.ResetCameraTarget(mMtpParent.UnitUID, mMtpParent);
        if (mMtpParent.ActionStatus.CheckInterrupt("N0000"))
        {
            mMtpParent.ActionStatus.ChangeAction("N0000", 0);
        }
        if(mOwner.ActionStatus != null)
            mOwner.ActionStatus.ChangeAction("N0000", 0);
        CheckTakeOffMoveState();
        SetNbHeight(false);
        EventMgr.Trigger("OnTakeOffMount",true);
    }

    /// <summary>
    /// 设置位置
    /// </summary>
    /// <param name="mountParent"></param>
    /// <param name="pendant"></param>
    public override void SetPosition()
    {
        if (mMtpParent == null)
            return;
        if (mMtpParent.UnitTrans == null)
            return;
        if (mOwner == null)
            return;
        if (mOwner.UnitTrans == null)
            return;
        mMtpParent.ActionStatus.ignoreGravityGlobal = true;
        //mOwner.Position = mMtpParent.Position;
        mMtpParent.UnitTrans.parent = null;
        //mOwner.SetOrientation(mMtpParent.Orientation);
        mMtpParent.SetForward(mOwner.UnitTrans.forward);
        Transform parent = GetParent(mOwner);
        mMtpParent.UnitTrans.parent = parent;
        mMtpParent.UnitTrans.localPosition = Vector3.zero;
        mMtpParent.ActionStatus.ChangeAction(RoleRdIdle, 0);
        SetNbHeight(true);
    }

    /// <summary>
    /// 检查上坐骑移动状态
    /// </summary>
    /// <param name="parent"></param>
    /// <param name="mount"></param>
    public void CheckPutOnMoveState(Unit parent, Unit mount)
    {
        bool pathFinding = parent.mUnitMove.InPathFinding;
        parent.mUnitMove.ChangeVehicle(mount);
        if (!pathFinding)
            return;
        mOwner.ActionStatus.ChangeMoveAction();
    }

    /// <summary>
    /// 检查下坐骑移动状态
    /// </summary>
    public void CheckTakeOffMoveState()
    {
        bool pathFinding = false;
        if (mOwner.mUnitMove.Pathfinding != null)
        {
            pathFinding = mOwner.mUnitMove.InPathFinding;
            mOwner.mUnitMove.Pathfinding = null;
        }
        mMtpParent.mUnitMove.ChangeVehicle(mMtpParent);
        if (!pathFinding)
            return;
        mMtpParent.ActionStatus.ChangeMoveAction();
    }
    #endregion

    #region 私有方法
    /// <summary>
    /// 设置乘骑动作
    /// </summary>
    /// <param name="info"></param>
    private void SetRidingAni(MountInfo info)
    {
        if (info == null)
            return;
        RoleRdIdle = info.roleIdleId;
        RoleRdMove = info.roleMoveId;
    }
    /// <summary>
    /// 添加子单位
    /// </summary>
    /// <param name="child"></param>
    private void AddChild(Unit child)
    {
        if (bAddChild)
            return;
        bAddChild = true;
        mMtpParent.AddChildUnit(child);
    }

    /// <summary>
    /// 播放特效
    /// </summary>
    private void PlayEffect()
    {
        Transform trans = mMtpParent.UnitTrans;
        if (trans != null && !trans.gameObject.activeSelf)
            return;
        if (mEffect != null)
            ClearEffect();
        AssetMgr.LoadPrefab("FX_Mount_Smoke", (effect) =>
         {
             if (effect == null)
                 return;
             effect.transform.parent = null;
             effect.SetActive(true);
             if (!InvalidEffect(effect))
                 return;
             mEffect = effect;
             mEffect.transform.position = mOwner.Position;
             DelayDestroy delay = effect.GetComponent<DelayDestroy>();
             if (delay == null)
                 return;
             delay.onDestroy = DelayDstrCB;
         });
    }

    //销毁脚本返回
    private void DelayDstrCB(GameObject go,long unitUID)
    {
        if (go != mEffect)
            return;
        ClearEffect();
    }

    /// <summary>
    /// 清除特效
    /// </summary>
    private void ClearEffect()
    {
        GameObject effect = mEffect;
        mEffect = null;
        if (!InvalidEffect(effect))
            return;
        ShowEffectMgr.instance.AddToPool(effect);
    }

    /// <summary>
    /// 加载场景中出来的特效直接销毁
    /// </summary>
    /// <param name="effect"></param>
    /// <returns></returns>
    private bool InvalidEffect(GameObject effect)
    {
        if (GameSceneManager.instance.SceneLoadState == SceneLoadStateEnum.SceneDone)
            return true;
        Loong.Game.AssetMgr.Instance.Unload(effect.name, ".prefab", false);
        GameObject.Destroy(effect);
        return false;
    }
    #endregion
}
