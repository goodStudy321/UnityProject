using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateScript : MonoBehaviour
{
    #region 私有字段
    /// <summary>
    /// 旋转总时间
    /// </summary>
    private float mRotateTime = 0;
    /// <summary>
    /// 当前时间
    /// </summary>
    private float mCurTime = 0;
    /// <summary>
    /// 当前方向
    /// </summary>
    private Vector3 mScrForward;

    /// <summary>
    /// 目标方向
    /// </summary>
    private Vector3 mDesForward;

    /// <summary>
    /// 是否可以旋转
    /// </summary>
    private bool canRotate = false;

    #endregion

    #region 公有方法
    /// <summary>
    /// 开始旋转
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

    #region 私有方法
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
