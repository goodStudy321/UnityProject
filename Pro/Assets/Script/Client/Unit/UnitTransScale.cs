using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UnitTransScale
{
    #region 
    // 使用插值计算缩放
    private bool mLerp = false;
    // 模型缩放
    private float mScale = 1;
    // 模型目标缩放
    private float mCurrentScale = 1;
    #endregion

    #region 公有方法
    /// <summary>
    /// 设置单位模型缩放
    /// </summary>
    /// <param name="scale"></param>
    /// <param name="lerp"></param>
    public void SetScale(float scale, bool lerp)
    {
        this.mLerp = lerp;
        this.mCurrentScale = this.mScale * scale;
    }

    /// <summary>
    /// 更新Transform缩放
    /// </summary>
    public void Update(Transform transform,float deltaTime)
    {
        if (mScale == mCurrentScale) return;
        if (mLerp)
        {
            mScale = Utility.SmoothSlerp(ref mScale, ref mCurrentScale, deltaTime, 4);
            if (Mathf.Abs(mCurrentScale - mScale) <= 0.0001)
                mScale = mCurrentScale;
            transform.localScale = Vector3.one * mScale;
        }
        else
        {
            transform.localScale = Vector3.one * mCurrentScale;
        }
    }

    public void Dispose()
    {
        mLerp = false;
        mScale = 1;
        mCurrentScale = 1;
    }
    #endregion
}
