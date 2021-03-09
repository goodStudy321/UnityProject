using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using Loong.Game;


/// <summary>
/// 转换场景
/// </summary>
public class PFChangeScene : PFActionBase
{
    /// <summary>
    /// 转换状态类型
    /// </summary>
    //protected enum StateType
    //{
    //    ST_Unknown = 0,
    //    ST_PreWait,                 /* 转换前等待 */
    //    ST_Changing,                /* 转换中 */
    //    ST_AfterWait,               /* 转换后等待 */
    //    ST_Num
    //}

    /// <summary>
    /// 目标场景Id
    /// </summary>
    protected int mToSceneId = 0;
    /// <summary>
    /// 
    /// </summary>
    protected uint mCurPortalId = 0;
    /// <summary>
    /// 目标跳转点Id
    /// </summary>
    protected uint mToPortalId = 0;
    /// <summary>
    /// 目的地坐标
    /// </summary>
    protected long mDesPos = 0;
    /// <summary>
    /// 跳转前等待时间
    /// </summary>
    protected float mPreWaitTime = 0f;
    /// <summary>
    /// 跳转后等待时间
    /// </summary>
    protected float mAfterWaitTime = 0f;
    /// <summary>
    /// 显示倒计时窗口
    /// </summary>
    protected bool mShowTipWnd = false;
    /// <summary>
    /// 当前转换状态
    /// </summary>
    //protected StateType mCurState = StateType.ST_Unknown;

    /// <summary>
    /// 计时器
    /// </summary>
    //protected float mTimer = 0f;


    public PFChangeScene() : base()
    {

    }
    
    public PFChangeScene(Unit unit, int toMapId, uint curPortalId = 0, uint toPortalId = 0, long desPos = 0, bool showTipWnd = false, float preTime = 0, float afterTime = 0, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
        : base(unit, preActCB, finCB)
    {
        mActionState = ActionState.FS_CHANGEMAP;
        mToSceneId = toMapId;
        mCurPortalId = curPortalId;
        mToPortalId = toPortalId;
        mDesPos = desPos;
        mShowTipWnd = showTipWnd;
        mPreWaitTime = preTime;
        mAfterWaitTime = afterTime;
        mCanBreak = false;
    }

    public void SetInitVal(Unit unit, int toMapId, uint curPortalId = 0, uint toPortalId = 0, long desPos = 0, 
        bool showTipWnd = false, float preTime = 0, float afterTime = 0, PreActionFun preActCB = null, Action<ActionState, ResultType> finCB = null)
    {
        base.SetInitVal(unit, preActCB, finCB);

        mActionState = ActionState.FS_CHANGEMAP;
        mToSceneId = toMapId;
        mCurPortalId = curPortalId;
        mToPortalId = toPortalId;
        mDesPos = desPos;
        mShowTipWnd = showTipWnd;
        mPreWaitTime = preTime;
        mAfterWaitTime = afterTime;
        mCanBreak = false;
    }

    public override void Clear()
    {
        base.Clear();

        mToSceneId = 0;
        mCurPortalId = 0;
        mToPortalId = 0;
        mDesPos = 0;
        mPreWaitTime = 0f;
        mAfterWaitTime = 0f;
        mShowTipWnd = false;
    }

    public override void Start()
    {
        SceneInfo tInfo = SceneInfoManager.instance.Find((uint)mToSceneId);
        if(tInfo == null)
        {
            Break( ResultType.RT_Unexpect);
            return;
        }
        var lst = tInfo.resName.list;
        var res = (lst.Count > 0 ? lst[0] : null);
        if (res==null)
        {
            UITip.LocalError(690008);
        }
        string nextMapData = string.Concat(tInfo.mapId.ToString(), ".bytes");
        string nextMapBlock = string.Concat(tInfo.mapId.ToString(), "_block.prefab");
        if (AssetMgr.Instance.Exist(res + ".unity") == false
            || AssetMgr.Instance.Exist(nextMapData) == false
            || AssetMgr.Instance.Exist(nextMapBlock) == false)
        {
            UITip.LocalError(690007);
            UIMgr.Open("UIDownload");
            Break(ResultType.RT_Unexpect);
            return;
        }
        
        base.Start();
        EventMgr.Add(EventKey.OnChangeScene, FinishChangScene);

        //mTimer = 0f;
        if (mPreWaitTime > 0)
        {
            if(mShowTipWnd == true)
            {
                EventMgr.Trigger("WaitChangeScene", mPreWaitTime);
            }
            //mCurState = StateType.ST_PreWait;
            mRecoveryCB = FinPreWait;
            mPreActionNeed(ActionState.FS_WAIT, mUnit, mPreWaitTime);
        }
        else
        {
            FinPreWait();
        }
    }

    public override void Update(float dTime)
    {
        base.Update(dTime);

        ////mTimer += Time.deltaTime;
        //switch (mCurState)
        //{
        //    case StateType.ST_PreWait:
        //        {
        //            if (mTimer >= mPreWaitTime)
        //            {
        //                FinPreWait();
        //            }
        //        }
        //        break;
        //    case StateType.ST_Changing:
        //        {

        //        }
        //        break;
        //    case StateType.ST_AfterWait:
        //        {
        //            if (mTimer >= mAfterWaitTime)
        //            {
        //                FinAfterWait();
        //            }
        //        }
        //        break;
        //    default:
        //        {
        //            //iTrace.Error("LY", "Change scene state error !!! ");
        //        }
        //        break;
        //}
    }

    /// <summary>
    /// 结束转换前等待
    /// </summary>
    protected virtual void FinPreWait()
    {
        EventMgr.Trigger("PreChangeScene");
        //mTimer = 0f;
        if (mToSceneId > 0)
        {
            if (mToPortalId > 0 || mDesPos > 0)
            {
                if(NetworkMgr.PortalPreChangeScene(mToSceneId, (int)mCurPortalId, (int)mToPortalId, true, mDesPos) == false)
                {
                    if(mFinCB != null)
                    {
                        Break(ResultType.RT_PassiveBreak);
                    }
                }
            }
            else
            {
                if(NetworkMgr.ReqPreEnter(mToSceneId) == false)
                {
                    Break(ResultType.RT_PassiveBreak);
                }
            }
            
            //mCurState = StateType.ST_Changing;
        }
        else
        {
            if (mAfterWaitTime > 0)
            {
                //mCurState = StateType.ST_AfterWait;
                mRecoveryCB = Finish;
                mPreActionNeed(ActionState.FS_WAIT, mUnit, mAfterWaitTime);
            }
            else
            {
                Finish();
            }
        }
        //mCanBreak = false;
    }

    /// <summary>
    /// 完成转换场景
    /// </summary>
    protected virtual void FinishChangScene(params object[] args)
    {
        int sceneId = (int)args[0];
        if (sceneId != mToSceneId /*|| mCurState != StateType.ST_Changing*/)
        {
            Break( ResultType.RT_Unexpect );
            return;
        }

        if(mToPortalId > 0)
        {
            PortalFig tToFig = MapPathMgr.instance.MapAssis.GetPortalFigById(mToPortalId);
            if (tToFig != null)
            {
                mUnit.Position = tToFig.transform.position;
            }
            else
            {
                iTrace.Error("LY", "Can not find portal in this map !!! " + mToPortalId);
            }
            mToPortalId = 0;
        }

        //mTimer = 0f;
        if (mAfterWaitTime > 0)
        {
            //mCurState = StateType.ST_AfterWait;

            mRecoveryCB = Finish;
            mPreActionNeed(ActionState.FS_WAIT, mUnit, mAfterWaitTime);
        }
        else
        {
            Finish();
        }
    }

    /// <summary>
    /// 结束转换后等待
    /// </summary>
    protected virtual void FinAfterWait()
    {
        Finish();
    }

    protected override void Finish()
    {
        EventMgr.Remove(EventKey.OnChangeScene, FinishChangScene);
        base.Finish();
    }

    public override void Break(ResultType bType)
    {
        EventMgr.Trigger("BreakChangeScene");
        EventMgr.Remove(EventKey.OnChangeScene, FinishChangScene);
        base.Break(bType);
    }
}