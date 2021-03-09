using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class BezierCurveScript : MonoBehaviour
{
    #region 私有字段
    //开始位置
    private Vector3 mStartPos;
    //中间位置
    private Vector3 mMidPos;
    //终点位置
    private Vector3 mEndPos;
    //贝塞尔时间
    private float mTime = 0;
    //当前时间
    private float mCurTime = 0;
    //掉落完成
    private Action<object> mDropDone;
    //回调数据
    private object mData;
    //是否完成
    private bool isDone = false;
    #endregion

    #region 私有变量
    // Update is called once per frame
    void Update ()
    {
        if (isDone) return;
        if (mTime <= 0)
            mTime = 0.01f;
        float radio = mCurTime / mTime;
        Vector3 pos = BezierTool.GetQuadraticCurvePoint(mStartPos, mMidPos, mEndPos, radio);
        transform.position = pos;
        mCurTime += Time.deltaTime;
        if (radio < 1)
            return;
        isDone = true;
        if (mDropDone == null)
            return;
        mDropDone(mData);
        mDropDone = null;
	}
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置贝塞尔
    /// </summary>
    /// <param name="startPos">开始位置</param>
    /// <param name="endPos">终点位置</param>
    /// <param name="midPos">中间位置</param>
    /// <param name="time">时间</param>
    public void SetBezier(Vector3 startPos, Vector3 endPos,Vector3 midPos, float time = 0, Action<object> dropDone = null,object dataob = null)
    {
        mStartPos = startPos;
        mEndPos = endPos;
        mTime = time;
        mCurTime = 0;
        mDropDone = dropDone;
        mData = dataob;
        isDone = false;
        mMidPos = midPos;
        if (midPos != Vector3.zero)
            return;
        midPos = (startPos + endPos) * 0.5f;
        midPos.y += 1;
        mMidPos = midPos;
    }
    #endregion
}
