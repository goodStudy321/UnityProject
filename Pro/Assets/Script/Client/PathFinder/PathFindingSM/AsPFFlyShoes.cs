using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Phantom;
using Loong.Game;


/// <summary>
/// 小飞鞋
/// </summary>
public class AsPFFlyShoes : AsPFBase
{
    /// <summary>
    /// 转换状态类型
    /// </summary>
    protected enum StateType
    {
        ST_Unknown = 0,
        ST_Begin,
        ST_PreWait,                 /* 跳转前等待 */
        ST_Jumping,                 /* 正在跳转 */
        ST_AfterWait,               /* 跳转后等待 */
        ST_End,
        ST_Num
    }

    /// <summary>
    /// 当前状态
    /// </summary>
    protected StateType mCurState = StateType.ST_Unknown;

    /// <summary>
    /// 飞鞋调用范围
    /// </summary>
    public static float canFlyDis = 15f;

    protected int mSceneId = 0;
    private Vector3 shoesDesPos;
    private float shoesDis = -1;


    private Vector3 newPos = Vector3.zero;


    public AsPFFlyShoes() : base()
    {

    }

    public AsPFFlyShoes(Unit pfUnit, ReqPathFinding info, Action callback) : base(pfUnit, info, callback)
    {
        mSceneId = (int)pfInfo.mapId;
        shoesDesPos = pfInfo.endPos;
        shoesDis = pfInfo.stopDis;

        EventMgr.Add("ChangeSceneFail", FailChangeScene);
    }

    public override void Clear()
    {
        base.Clear();

        mCurState = StateType.ST_Unknown;
        mSceneId = 0;
        shoesDesPos = Vector3.zero;
        shoesDis = -1;
    }

    public override void SetInitVal(Unit pfUnit, ReqPathFinding info, Action callback)
    {
        base.SetInitVal(pfUnit, info, callback);

        mSceneId = (int)pfInfo.mapId;
        shoesDesPos = pfInfo.endPos;
        shoesDis = pfInfo.stopDis;

        EventMgr.Add("ChangeSceneFail", FailChangeScene);
    }

    public override void Start()
    {
        mCurState = StateType.ST_Begin;
        base.Start();

        /// 播放特效并等待 ///
        if(pfInfo.preTime > 0)
        {
            mCurState = StateType.ST_PreWait;
            GameEventManager.instance.EnQueue(
                        new PlayEffectEvent("FX_ChuanSong01", mUnit, Vector3.zero, Vector3.one, Vector3.forward, 1, 0), true);

            PFWait pfWait = ObjPool.Instance.Get<PFWait>();
            pfWait.SetInitVal(mUnit, pfInfo.preTime, InsertPreAction, OverCurAction, false);
            mCurAction = pfWait;
            mCurAction.Start();
        }
        /// 直接跳转 ///
        else
        {
            GoToJump();
        }
    }

    protected override void OverCurAction(PFActionBase.ActionState actState, PFActionBase.ResultType type)
    {
        switch(actState)
        {
            case PFActionBase.ActionState.FS_WAIT:
                {
                    if(mCurState == StateType.ST_PreWait)
                    {
                        GoToJump();
                    }
                    else
                    {
                        iTrace.Error("LY", "Fly shoes state error !!! " + mCurState);
                    }
                }
                break;
            case PFActionBase.ActionState.FS_CHANGEMAP:
                {
                    ClearCurAction();
                    if (mSceneId == User.instance.SceneId)
                    {
                        //FlySameScene();
                        Finish();
                    }
                    else
                    {
                        //Break(AsPathfinding.PathResultType.PRT_CHANGE_SCENE_BREAK);
                        Break(AsPathfinding.PathResultType.PRT_PASSIVEBREAK);
                    }
                }
                break;
            default:
                {
                    iTrace.Log("LY", "AsPFSample::OverCurAction type error !!! " + actState);
                }
                break;
        }

        //base.OverCurAction(actState, type);
    }

    protected void GoToJump()
    {
        mCurState = StateType.ST_Jumping;
        if (mSceneId > 0 && mSceneId != User.instance.SceneId)
        {
            //mCurAction = new PFChangeScene(mUnit, mSceneId, 0, false, 0.5f, 0, OverCurAction);
            long desPos = NetMove.GetPointInfo(shoesDesPos, mUnit.UnitTrans.localEulerAngles.y, false, (uint)mSceneId);

            PFChangeScene pfChangeScene = ObjPool.Instance.Get<PFChangeScene>();
            pfChangeScene.SetInitVal(mUnit, mSceneId, 0, 0, desPos, false, 0, pfInfo.afterTime, InsertPreAction, OverCurAction);
            mCurAction = pfChangeScene;
            mCurAction.Start();
        }
        else
        {
            Unit playerUnit = InputVectorMove.instance.MoveUnit;
            if (playerUnit != null)
            {
                FlySameScene();
            }
        }
    }

    /// <summary>
    /// 同场景飞鞋
    /// </summary>
    /// <param name="playerUnit"></param>
    /// <param name="desPos"></param>
    protected void FlySameScene()
    {
        if (shoesDis < 0.01)
        {
            mUnit.Position = shoesDesPos;
            NetMove.RequestChangePosDir(mUnit, shoesDesPos);
            Finish();
            return;
        }

        float desDis = Vector3.Distance(mUnit.Position, shoesDesPos);
        if (desDis < shoesDis)
        {
            Finish();
            return;
        }

        /// 飞鞋 ///
        if (desDis > canFlyDis)
        {
            Vector3 oriVec = new Vector3(1, 0, 0);
            oriVec = oriVec.normalized;
            AsNode desNode = null;
            for (int a = 0; a < 8; a++)
            {
                Vector3 newVec = Quaternion.Euler(0, 45 * a, 0) * oriVec;
                newPos = shoesDesPos + newVec * shoesDis;
                desNode = MapPathMgr.instance.FindClosestNode(newPos, false);
                if (desNode != null && desNode.CanWalk == true)
                {

                    if (GameSceneManager.instance.EnablePrealodArea())
                    {
                        uint resId = MapPathMgr.instance.GetPreLoadResIdByZoneId(desNode.baseData.loadZoneId);
                        if (resId > 0)
                        {
                            PreloadAreaMgr.Instance.Start(resId, FinishPreload);
                        }
                        else
                        {
                            FinishPreload();
                        }
                    }
                    else
                    {
                        FinishPreload();
                    }
                    //mUnit.Position = newPos;
                    ////iTrace.eError("hs", "---------------------------->> sdfsd "+ User.instance.Pos.ToString() +"/" + newPos.ToString());
                    //NetMove.RequestChangePosDir(mUnit, newPos);

                    //Finish();
                    return;
                }
            }

            iTrace.eError("LY", "No little fly shoes pos !!! ");
            Finish();
        }
        /// 寻路 ///
        else
        {
            Unit ownUnit = mUnit;
            ReqPathFinding tPF = pfInfo.Copy();
            Vector3 tSDP = shoesDesPos;
            float tSD = shoesDis;
            Finish();

            if (ownUnit != null && tPF != null)
            {
                ownUnit.mUnitMove.StartNav(tSDP, tSD, 0, tPF.finCB);
            }
        }
    }

    public override void Update(float dTime)
    {
        base.Update(dTime);


    }

    protected virtual void FinishPreload()
    {
        mUnit.Position = newPos;
        //iTrace.eError("hs", "---------------------------->> sdfsd "+ User.instance.Pos.ToString() +"/" + newPos.ToString());
        NetMove.RequestChangePosDir(mUnit, newPos);

        Finish();
    }

    protected override void Finish()
    {
        User.instance.ResetCameraImd();
        EventMgr.Remove("ChangeSceneFail", FailChangeScene);
        //base.Finish();

        AutoMountMgr.instance.StartTimer(mUnit);
        NavMoveBuff.instance.StartTimer(mUnit);

        if (pfInfo != null && pfInfo.finCB != null)
        {
            pfInfo.finCB(mUnit, AsPathfinding.PathResultType.PRT_PATH_SUC);
        }

        if (finCB != null)
        {
            finCB();
            finCB = null;
        }

        mCurState = StateType.ST_End;
    }

    public override void Break(AsPathfinding.PathResultType resultType)
    {
        EventMgr.Remove("ChangeSceneFail", FailChangeScene);
        //base.Break(resultType);
        base.Break(resultType);
    }
}