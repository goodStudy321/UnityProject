using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

using Loong.Game;


/// <summary>
/// 唤醒型传送口
/// </summary>
public class AwakenPortalFig : MonoBehaviour
{
    /// <summary>
    /// 传送口Id
    /// </summary>
    [SerializeField]
    public uint mPortalId = 0;
    /// <summary>
    /// 链接地图Id
    /// </summary>
    [SerializeField]
    public uint mLinkMapId = 0;

    /// <summary>
    /// 时间显示Label
    /// </summary>
    private UILabel mTimeShowLabel;

    /// <summary>
    /// 是否已经打开
    /// </summary>
    private bool mOpen = false;
    /// <summary>
    /// 倒计时时间
    /// </summary>
    private float disCountTime = 0f;

    //private float countTimer = 0f;
    private bool mPause = false;

    /// <summary>
    /// 判断点击是否是UI
    /// </summary>
    private bool isCanClick = false;


    public bool IsOpen
    {
        get { return mOpen; }
    }
    public bool Pause
    {
        get { return mPause; }
        set { mPause = value; }
    }
    public UILabel ShowLabel
    {
        get { return mTimeShowLabel; }
    }


    public void SetActive(bool isActive)
    {
        mOpen = isActive;
        gameObject.SetActive(isActive);
    }


    private void Awake()
    {
        disCountTime = 0f;

        GameObject panelObj = Utility.FindNode(gameObject, "Panel");
        GameObject labelObj = Utility.FindNode(panelObj, "TimeShowLabel");
        mTimeShowLabel = labelObj.GetComponent<UILabel>();
    }

    private void Start()
    {

    }

    private void Update()
    {
        if(disCountTime > 0 && mPause == false)
        {
            disCountTime -= Time.deltaTime;
            if(disCountTime <= 0)
            {
                disCountTime = 0;
                SetActive(false);
            }
            ShowTimeStr();
        }
    }

    private void OnDestroy()
    {

    }

    /// <summary>
    /// 点击鼠标
    /// </summary>
    void OnMouseDown()
    {
        isCanClick = UITool.On;
        if (isCanClick)
        {
            return;
        }
        EventMgr.Trigger("ClickCtrlPortal", mPortalId);
    }

    private void ShowTimeStr()
    {
        string showStr = "";
        int minNum = (int)Mathf.Ceil(disCountTime) / 60;
        int secNum = (int)Mathf.Ceil(disCountTime) % 60;

        if(minNum > 0)
        {
            showStr = showStr + minNum + ":";
        }
        showStr = showStr + secNum;

        mTimeShowLabel.text = showStr;
    }

    private float GetCurrentTimeUnix()
    {
        TimeSpan cha = (DateTime.Now - TimeZone.CurrentTimeZone.ToLocalTime(new System.DateTime(1970, 1, 1)));
        float t = (float)cha.TotalSeconds;
        return t;
    }

    public void GoToLinkScene()
    {
        if (InputMgr.instance.mOwner == null)
            return;

        /// 跳转地图 ///
        if (mLinkMapId != MapPathMgr.instance.CurMapId)
        {
            if (SceneInfoManager.instance.Find(mLinkMapId) == null)
            {
                iTrace.Error("LY", "Scene id errror !!! " + mLinkMapId);
                return;
            }

            InputMgr.instance.CanInput = false;
            InputVectorMove.instance.MoveUnit.ActionStatus.ChangeIdleAction();

            InputVectorMove.instance.MoveUnit.mUnitMove.Pathfinding.FindPathAndMove(mLinkMapId, mPortalId, 0, false, 0.5f, 1f, AwakenPortalComplete);
        }
    }

    public void AwakenPortalComplete(Unit unit, AsPathfinding.PathResultType type)
    {
        //iTrace.Warning("hs", "################ 寻路回调 NavPathsComplete");
        UnitHelper.instance.ResetUnitData(unit);
        HangupMgr.instance.IsAutoSkill = false;
        switch (type)
        {
            case AsPathfinding.PathResultType.PRT_PATH_SUC:
                //EventMgr.Trigger(EventKey.NavPathComplete, (int)type, MissID);
                break;
            case AsPathfinding.PathResultType.PRT_CALL_BREAK:
                //HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_PASSIVEBREAK:
                //HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_ERROR_BREAK:
                //HangupMgr.instance.Clear();
                break;
            case AsPathfinding.PathResultType.PRT_FORBIDEN:
                //HangupMgr.instance.Clear();
                break;
            default:
                {
                    //HangupMgr.instance.Clear();
                    iTrace.eError("LY", "AwakenPortalComplete result error !!! " + type);
                }
                break;
        }
        EventMgr.Trigger("AwakenPortalComplete", (int)type);
    }

    public void LabelShow(string strShow)
    {
        if (mTimeShowLabel == null)
            return;

        mTimeShowLabel.text = strShow;
    }

    /// <summary>
    /// 开始倒计时
    /// </summary>
    /// <param name="countTime"></param>
    public void StartDiscount(float countTime)
    {
        //float cur = GetCurrentTimeUnix();
        //disCountTime = countTime - cur;
        disCountTime = countTime;
    }
}
