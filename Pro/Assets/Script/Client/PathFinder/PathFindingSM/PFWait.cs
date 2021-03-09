using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 等待
/// </summary>
public class PFWait : PFActionBase
{
    /// <summary>
    /// 等待时间
    /// </summary>
    protected float mWaitTime = 0f;
    /// <summary>
    /// 计时器
    /// </summary>
    protected float mTimer = 0f;


    public PFWait() : base()
    {

    }

    public PFWait(Unit unit, float waitTime, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null, bool canBreak = true)
        : base(unit, preActCB, finCB)
    {
        mActionState = ActionState.FS_WAIT;
        mWaitTime = waitTime;
        mTimer = 0f;
        mCanBreak = canBreak;
    }

    public void SetInitVal(Unit unit, float waitTime, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null, bool canBreak = true)
    {
        base.SetInitVal(unit, preActCB, finCB);

        mActionState = ActionState.FS_WAIT;
        mWaitTime = waitTime;
        mTimer = 0f;
        mCanBreak = canBreak;
    }

    public override void Clear()
    {
        base.Clear();
        mWaitTime = 0f;
        mTimer = 0f;
    }

    public override void Start()
    {
        base.Start();

        mTimer = 0f;
    }

    public override void Update(float dTime)
    {
        base.Update(dTime);

        mTimer += dTime;
        if (mTimer >= mWaitTime)
        {
            Finish();
        }
    }
}