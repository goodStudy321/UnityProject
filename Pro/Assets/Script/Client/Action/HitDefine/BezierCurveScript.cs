using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

public class BezierCurveScript : MonoBehaviour
{
    #region ˽���ֶ�
    //��ʼλ��
    private Vector3 mStartPos;
    //�м�λ��
    private Vector3 mMidPos;
    //�յ�λ��
    private Vector3 mEndPos;
    //������ʱ��
    private float mTime = 0;
    //��ǰʱ��
    private float mCurTime = 0;
    //�������
    private Action<object> mDropDone;
    //�ص�����
    private object mData;
    //�Ƿ����
    private bool isDone = false;
    #endregion

    #region ˽�б���
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

    #region ���з���
    /// <summary>
    /// ���ñ�����
    /// </summary>
    /// <param name="startPos">��ʼλ��</param>
    /// <param name="endPos">�յ�λ��</param>
    /// <param name="midPos">�м�λ��</param>
    /// <param name="time">ʱ��</param>
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
