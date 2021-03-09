using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CameraPull
{
    #region 私有字段
    /// <summary>
    /// 拉扯时间
    /// </summary>
    private float mTime;
    /// <summary>
    /// 当前时间
    /// </summary>
    private float mCurTime;
    /// <summary>
    /// 开始位置
    /// </summary>
    private Vector3 mStartPos;
    /// <summary>
    /// 结束位置
    /// </summary>
    private Vector3 mEndPos;
    /// <summary>
    /// 是否拉扯中
    /// </summary>
    private bool isPulling = false;
    #endregion

    #region 属性
    /// <summary>
    /// 是否正在拉扯摄像机
    /// </summary>
    public bool IsPullingCam
    {
        get { return mTime > 0 || isPulling; }
    }
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置摄像机拉扯
    /// </summary>
    /// <param name="distance"></param>
    /// <param name="time"></param>
    public void SetCameraPull(float distance, float time)
    {
        mTime = time * 0.001f;
        mCurTime = 0;
        isPulling = !isPulling;
        Transform canTrans = CameraMgr.Main.transform;
        mStartPos = canTrans.position;
        Vector3 forward = canTrans.forward;
        Vector3 deltaPos = forward * distance * 0.01f;
        mEndPos = mStartPos + deltaPos;
    }

    /// <summary>
    /// 重置
    /// </summary>
    public void ResetTime()
    {
        mTime = 0;
        mCurTime = 0;
    }

    /// <summary>
    /// 清除
    /// </summary>
    public void Clear()
    {
        ResetTime();
        isPulling = false;
    }

    /// <summary>
    /// 更新
    /// </summary>
    public void Update()
    {
        if (mTime == 0)
            return;
        mCurTime += Time.deltaTime;
        float t = mCurTime / mTime;
        Vector3 pos = BezierTool.GetLinearPoint(mStartPos, mEndPos, t);
        CameraMgr.Main.transform.position = pos;
        if (t < 1)
            return;
        ResetTime();
    }
    #endregion
}
