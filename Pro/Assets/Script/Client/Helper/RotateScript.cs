using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateScript : MonoBehaviour
{
    #region ˽���ֶ�
    /// <summary>
    /// ��ת��ʱ��
    /// </summary>
    private float mRotateTime = 0;
    /// <summary>
    /// ��ǰʱ��
    /// </summary>
    private float mCurTime = 0;
    /// <summary>
    /// ��ǰ����
    /// </summary>
    private Vector3 mScrForward;

    /// <summary>
    /// Ŀ�귽��
    /// </summary>
    private Vector3 mDesForward;

    /// <summary>
    /// �Ƿ������ת
    /// </summary>
    private bool canRotate = false;

    #endregion

    #region ���з���
    /// <summary>
    /// ��ʼ��ת
    /// </summary>
    /// <param name="scrForward"></param>
    /// <param name="desForward"></param>
    public void BeginRotate(Vector3 scrForward, Vector3 desForward, float rotateTime = 0.3f)
    {
        mCurTime = 0;
        canRotate = true;
        mRotateTime = rotateTime;
        mScrForward = scrForward;
        mDesForward = desForward;
    }
    #endregion

    #region ˽�з���
	// Update is called once per frame
	void Update ()
    {
        if (!canRotate)
            return;
        if (mCurTime > mRotateTime)
        {
            canRotate = false;
            return;
        }
        mCurTime += Time.deltaTime;
        float radio = mCurTime / mRotateTime;
        this.transform.forward = BezierTool.GetLinearPoint(mScrForward, mDesForward, radio);
	}
    #endregion
}
