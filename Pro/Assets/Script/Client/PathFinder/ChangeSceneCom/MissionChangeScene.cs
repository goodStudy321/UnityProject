//using System;
//using System.Collections;
//using System.Collections.Generic;
//using UnityEngine;

//#if UNITY_EDITOR
//using UnityEditor;
//#endif

//using Loong.Game;


///// <summary>
///// 任务转换场景
///// </summary>
//public class MissionChangeScene : ChangeSceneBase
//{
//    public MissionChangeScene()
//    {
//        mAfterWaitTime = 0f;
//    }

//    public override void Start(int sceneId, float preTime = 0, float afterTime = 0, Action finCB = null)
//    {
//        base.Start(sceneId, preTime, afterTime, finCB);

//        EventMgr.Trigger("WaitChangeScene", mPreWaitTime);
//    }

//    protected override void FinPreWait()
//    {
//        EventMgr.Trigger("PreChangeScene");

//        if (mSceneId > 0)
//        {
//            NetworkMgr.ReqPreEnter(mSceneId);
//        }
//        base.FinPreWait();
//    }

//    protected override void FinChangScene(params object[] args)
//    {
//        base.FinChangScene(args);
//    }
//}
