using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Loong.Game;

public class CameraPull
{
    #region ˽���ֶ�
    /// <summary>
    /// ����ʱ��
    /// </summary>
    private float mTime;
    /// <summary>
    /// ��ǰʱ��
    /// </summary>
    private float mCurTime;
    /// <summary>
    /// ��ʼλ��
    /// </summary>
    private Vector3 mStartPos;
    /// <summary>
    /// ����λ��
    /// </summary>
    private Vector3 mEndPos;
    /// <summary>
    /// �Ƿ�������
    /// </summary>
    private bool isPulling = false;
    #endregion

    #region ����
    /// <summary>
    /// �Ƿ��������������
    /// </summary>
    public bool IsPullingCam
    {
        get { return mTime > 0 || isPulling; }
    }
    #endregion

    #region ���з���
    /// <summary>
    /// �������������
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
    /// ����
    /// </summary>
    public void ResetTime()
    {
        mTime = 0;
        mCurTime = 0;
    }

    /// <summary>
    /// ���
    /// </summary>
    public void Clear()
    {
        ResetTime();
        isPulling = false;
    }

    /// <summary>
    /// ����
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
