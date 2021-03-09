using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 寻路行为基础
/// </summary>
public class PFActionBase
{
    public delegate void PreActionFun(params object[] args);

    /// <summary>
    /// 行动类型
    /// </summary>
    public enum ActionState
    {
        FS_UNKNOWN = 0,
        FS_WALK,                    /* 行走 */
        FS_WAIT,                    /* 等待 */
        FS_JUMP,                    /* 传送点跳转 */
        FS_CHANGEMAP,               /* 等待转换地图 */
        FS_MAX
    }

    /// <summary>
    /// 行动结果
    /// </summary>
    public enum ResultType
    {
        RT_Unknown = 0,
        RT_CallBreak,               /* 主动打断 */
        RT_PassiveBreak,            /* 被动打断 */
        RT_Success,                 /* 成功 */
        RT_Unexpect,                /* 意外情况 */
        RT_Max
    }

    /// <summary>
    /// 寻路动作单位
    /// </summary>
    protected Unit mUnit = null;
    /// <summary>
    /// 当前行动类型
    /// </summary>
    protected ActionState mActionState = ActionState.FS_UNKNOWN;
    /// <summary>
    /// 是否可以打断
    /// </summary>
    protected bool mCanBreak = true;
    /// <summary>
    /// 需要前置状态操作回调
    /// </summary>
    protected PreActionFun mPreActionNeed = null;
    /// <summary>
    /// 恢复回调
    /// </summary>
    protected Action mRecoveryCB = null;
    /// <summary>
    /// 完成回调
    /// </summary>
    protected Action<ActionState, ResultType> mFinCB = null;

    /// <summary>
    /// 移动旋转速度
    /// </summary>
    protected readonly float mRotateSpeed = 9f;


    public bool CanBreak
    {
        get { return mCanBreak; }
    }
    public ActionState ActionType
    {
        get { return mActionState; }
    }
    public Unit Vehicle
    {
        get { return mUnit; }
        set
        {
            mUnit = value;
        }
    }

    public PFActionBase()
    {

    }

    public PFActionBase(Unit unit, PreActionFun preActCB, Action<ActionState, ResultType> finCB)
    {
        SetInitVal(unit, preActCB, finCB);
    }

    public void SetInitVal(Unit unit, PreActionFun preActCB, Action<ActionState, ResultType> finCB)
    {
        mUnit = unit;
        mPreActionNeed = preActCB;
        mFinCB = finCB;
    }

    /// <summary>
    /// 清理工作
    /// </summary>
    public virtual void Clear()
    {
        mUnit = null;
        mPreActionNeed = null;
        mFinCB = null;

        mActionState = ActionState.FS_UNKNOWN;
        mRecoveryCB = null;
    }

    public virtual void Start()
    {

    }

    public virtual void Update(float dTime)
    {

    }

    public virtual void Break(ResultType bType)
    {
        if (mFinCB != null)
        {
            mFinCB(mActionState, bType);
            mFinCB = null;
        }
    }

    /// <summary>
    /// 挂起
    /// </summary>
    public virtual void Hangup()
    {

    }

    /// <summary>
    /// 恢复
    /// </summary>
    public virtual void Recovery()
    {
        if(mRecoveryCB != null)
        {
            mRecoveryCB();
            mRecoveryCB = null;
        }
    }

    protected virtual void Finish()
    {
        if (mFinCB != null)
        {
            mFinCB(mActionState, ResultType.RT_Success);
            mFinCB = null;
        }
    }

    /// <summary>
    /// 设置单位方向
    /// </summary>
    /// <param name="tarPos"></param>
    protected void SetUnitRot(Vector3 tarPos)
    {
        if (mUnit == null || mUnit.UnitTrans == null)
        {
            return;
        }

        Vector3 tUnitForward = mUnit.UnitTrans.forward;
        tarPos.y = tUnitForward.y = mUnit.Position.y;
        Vector3 tDir = tarPos - mUnit.Position;


        //float angle = Vector3.Angle(tDir, mUnit.UnitTrans.forward);
        //if (Mathf.Abs(angle) < 0.2f)
        //    return;

        if (tDir.sqrMagnitude < 0.01f)
            return;


         Vector3 tNorDir = tDir.normalized;
        float tOri = Mathf.Atan2(tNorDir.x, tNorDir.z);
        mUnit.SetOrientation(tOri, mRotateSpeed);
    }

    /// <summary>
    /// 设置移动速度
    /// </summary>
    /// <param name="spd"></param>
    public virtual void SetMoveSpd(float spd)
    {

    }
}