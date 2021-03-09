using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InputMgr
{
    public static readonly InputMgr instance = new InputMgr();

    private InputMgr()
    {

    }
    #region 私有变量
    /// <summary>
    /// 是否可输入
    /// </summary>
    private bool mCanInput = true;
    /// <summary>
    /// 是否是摇杆模式
    /// </summary>
    private bool mJoyStickControlMdl = true;
    #endregion

    #region 公有变量
    /// <summary>
    /// 操控单位
    /// </summary>
    public Unit mOwner;

    /// <summary>
    /// 主角当前锁定目标
    /// </summary>
    public Unit mLockTarget = null;
    /// <summary>
    /// 已击中单位列表
    /// </summary>
    public List<Unit> mHitedList = new List<Unit>();
    /// <summary>
    /// 开始自动挂机那一刻范围内的单位列表
    /// </summary>
    public List<Unit> mHgupList = new List<Unit>();
    #endregion

    #region 属性
    /// <summary>
    /// 是否可输入
    /// </summary>
    public bool CanInput
    {
        get { return mCanInput; }
        set
        {
            mCanInput = value;
            if (value)
                return;
            StopAllAction();
        }
    }

    /// <summary>
    /// 是否是摇杆模式
    /// </summary>
    public bool JoyStickControlMdl
    {
        get { return mJoyStickControlMdl; }
        set
        {
            mJoyStickControlMdl = value;
            if (value == true)
                return;
            Reset();
        }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 初始化
    /// </summary>
    public void Init(Unit unit)
    {
        mOwner = unit;
        KeyInput.instance.Init();
        JoyStickCtrl.instance.Init();
        MSFrameCount.instance.Init();
        HangupMgr.instance.Init(unit);
    }

    /// <summary>
    /// 重置
    /// </summary>
    public void Reset()
    {
        InputVectorMove.instance.Clear();
        JoyStickCtrl.instance.Reset();
        KeyInput.instance.Reset();
    }

    /// <summary>
    /// 停止所有行为
    /// </summary>
    public void StopAllAction()
    {
        Reset();
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner == null)
            return;
        owner.ActionStatus.ChangeIdleAction();
    }

    /// <summary>
    /// 清除所有控制数据
    /// </summary>
    public void ClearAllCtrlData()
    {
        //重置摇杆,停止行为,停止寻路
        Unit owner = InputVectorMove.instance.MoveUnit;
        if (owner != null)
            owner.mUnitMove.StopNav();
        StopAllAction();
        mLockTarget = null;
        mHitedList.Clear();
        //清除自动挂机数据
        HangupMgr.instance.ClearInfo();
        //清除战斗数据
        UnitAttackCtrl.instance.Clear();
        UnitWildRush.instance.Clear();
    }

    /// <summary>
    /// 清除锁定目标
    /// </summary>
    public void ClearTarget(bool bClearList = true)
    {
        if (mOwner != null)
        {
            if (mOwner.ActionStatus == null) return;
            if (mOwner.ActionStatus.FTtarget != null)
                mOwner.ActionStatus.FTtarget = null;
        }
        if (bClearList) mHitedList.Clear();
        if (mLockTarget == null) return;
        mLockTarget = null;
    }

    public void Clear(bool all = true)
    {
        ClearAllCtrlData();
        ClearTarget();
        mCanInput = true;
        if (!all)
            return;
        mOwner = null;
    }

    public void Update()
    {
        if (!CanInput)
            return;
        JoyStickCtrl.instance.Update();
        InputVectorMove.instance.Update();
        UnitAttackCtrl.instance.UpdateAttackAction();
        //mKeyInput.UpdateKeyStatus(Time.deltaTime);
    }
    #endregion
}
