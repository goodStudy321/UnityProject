//using System;
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;

//#if UNITY_EDITOR
//using UnityEditor;
//#endif

//using Loong.Game;


///// <summary>
///// 转换场景过程
///// </summary>
//public class ChangeSceneBase
//{
//    protected float mPreWaitTime = 0.5f;
//    protected float mAfterWaitTime = 0.5f;

//    /// <summary>
//    /// 转换状态类型
//    /// </summary>
//    protected enum StateType
//    {
//        ST_Unknown = 0,
//        ST_PreWait,                 /* 转换前等待 */
//        ST_Changing,                /* 转换中 */
//        ST_AfterWait,               /* 转换后等待 */
//        ST_Num
//    }

//    /// <summary>
//    /// 目标场景
//    /// </summary>
//    protected int mSceneId = 0;
//    /// <summary>
//    /// 完成回调
//    /// </summary>
//    protected Action mFinCB = null;
//    /// <summary>
//    /// 当前转换状态
//    /// </summary>
//    protected StateType mCurState = StateType.ST_Unknown;
//    /// <summary>
//    /// 计时器
//    /// </summary>
//    protected float mWaitTimer = 0f;


//    /// <summary>
//    /// 是否可以打断转换场景
//    /// </summary>
//    public bool CanBreak
//    {
//        get
//        {
//            return mCurState == StateType.ST_PreWait;
//        }
//    }


//    public ChangeSceneBase()
//    {

//    }

//    public virtual void Start(int sceneId, float preTime = 0, float afterTime = 0, Action finCB = null)
//    {
//        mSceneId = sceneId;

//        if (preTime > 0)
//        {
//            mPreWaitTime = preTime;
//        }
//        if(afterTime > 0)
//        {
//            mAfterWaitTime = afterTime;
//        }
//        mFinCB = finCB;

//        EventMgr.Add(EventKey.OnChangeScene, FinChangScene);

//        mWaitTimer = 0f;
//        MonoEvent.update += OnUpdate;
//        mCurState = StateType.ST_PreWait;
//    }

//    /// <summary>
//    /// 结束转换前等待
//    /// </summary>
//    protected virtual void FinPreWait()
//    {
//        mWaitTimer = 0f;
//        if (mSceneId > 0)
//        {
//            mCurState = StateType.ST_Changing;
//        }
//        else
//        {
//            mCurState = StateType.ST_AfterWait;
//        }
//    }

//    /// <summary>
//    /// 读取场景完成
//    /// </summary>
//    protected virtual void FinChangScene(params object[] args)
//    {
//        if (mCurState != StateType.ST_Changing)
//        {
//            iTrace.Warning("LY", "Other call change scene !!!");
//            EventMgr.Trigger("BreakChangeScene");
//            if (mFinCB != null)
//            {
//                mFinCB();
//            }
//            return;
//        }
        
//        mWaitTimer = 0f;
//        mCurState = StateType.ST_AfterWait;
//    }

//    /// <summary>
//    /// 结束转换后等待
//    /// </summary>
//    protected virtual void FinAfterWait()
//    {
//        if (mFinCB != null)
//        {
//            mFinCB();
//            mFinCB = null;
//        }
//    }

//    /// <summary>
//    /// 打断切换场景
//    /// </summary>
//    public virtual bool BreakChangeScene()
//    {
//        if (mCurState != StateType.ST_PreWait)
//            return false;
        
//        if (mFinCB != null)
//        {
//            mFinCB();
//            mFinCB = null;
//        }

//        return true;
//    }

//    /// <summary>
//    /// 释放
//    /// </summary>
//    public virtual void Dispose()
//    {
//        EventMgr.Remove(EventKey.OnChangeScene, FinChangScene);
//        MonoEvent.update -= OnUpdate;
//        mFinCB = null;
//        mWaitTimer = 0f;
//    }

//    /// <summary>
//    /// 等待转换时添加到更新
//    /// </summary>
//    protected virtual void OnUpdate()
//    {
//        mWaitTimer += Time.deltaTime;

//        switch (mCurState)
//        {
//            case StateType.ST_PreWait:
//                {
//                    if(mWaitTimer >= mPreWaitTime)
//                    {
//                        FinPreWait();
//                    }
//                }
//                break;
//            case StateType.ST_Changing:
//                {
                    
//                }
//                break;
//            case StateType.ST_AfterWait:
//                {
//                    if (mWaitTimer >= mAfterWaitTime)
//                    {
//                        FinAfterWait();
//                    }
//                }
//                break;
//            default:
//                {
//                    //iTrace.Error("LY", "Change scene state error !!! ");
//                }
//                break;
//        }
//    }
//}
