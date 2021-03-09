//using System;
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;

//#if UNITY_EDITOR
//using UnityEditor;
//#endif

//using Loong.Game;


///// <summary>
///// ת����������
///// </summary>
//public class ChangeSceneBase
//{
//    protected float mPreWaitTime = 0.5f;
//    protected float mAfterWaitTime = 0.5f;

//    /// <summary>
//    /// ת��״̬����
//    /// </summary>
//    protected enum StateType
//    {
//        ST_Unknown = 0,
//        ST_PreWait,                 /* ת��ǰ�ȴ� */
//        ST_Changing,                /* ת���� */
//        ST_AfterWait,               /* ת����ȴ� */
//        ST_Num
//    }

//    /// <summary>
//    /// Ŀ�곡��
//    /// </summary>
//    protected int mSceneId = 0;
//    /// <summary>
//    /// ��ɻص�
//    /// </summary>
//    protected Action mFinCB = null;
//    /// <summary>
//    /// ��ǰת��״̬
//    /// </summary>
//    protected StateType mCurState = StateType.ST_Unknown;
//    /// <summary>
//    /// ��ʱ��
//    /// </summary>
//    protected float mWaitTimer = 0f;


//    /// <summary>
//    /// �Ƿ���Դ��ת������
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
//    /// ����ת��ǰ�ȴ�
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
//    /// ��ȡ�������
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
//    /// ����ת����ȴ�
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
//    /// ����л�����
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
//    /// �ͷ�
//    /// </summary>
//    public virtual void Dispose()
//    {
//        EventMgr.Remove(EventKey.OnChangeScene, FinChangScene);
//        MonoEvent.update -= OnUpdate;
//        mFinCB = null;
//        mWaitTimer = 0f;
//    }

//    /// <summary>
//    /// �ȴ�ת��ʱ��ӵ�����
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
