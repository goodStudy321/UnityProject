using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;


/// <summary>
/// 位移动画
/// </summary>

[AddComponentMenu("Component/SampleAnim/Tween Position")]
public class AnimMove : AnimTweener
{
    [HideInInspector]
    public bool worldSpace = false;

    /// <summary>
    /// 移动方向
    /// </summary>
    [SerializeField]
    public Vector3 mMoveDir = Vector3.up;
    /// <summary>
    /// 移动距离
    /// </summary>
    [SerializeField]
    public float mMoveLength = 0;

    
    
    private Transform mTrans;
    private float mLastFactor = 0f;


    public Transform cachedTransform
    {
        get
        {
            if (mTrans == null)
            {
                mTrans = transform;
            }
            return mTrans;
        }
    }

    public Vector3 value
    {
        get
        {
            return worldSpace ? cachedTransform.position : cachedTransform.localPosition;
        }
        set
        {
            if (worldSpace)
            {
                cachedTransform.position = value;
            }
            else
            {
                cachedTransform.localPosition = value;
            }
        }
    }


    private void Awake()
    {
        mLastFactor = 0f;
    }

    /// <summary>
    /// Tween the value.
    /// </summary>
    protected override void OnUpdate(float factor, bool isFinished)
    {
        float tDFactor = factor - mLastFactor;

        value += tDFactor * mMoveLength * mMoveDir.normalized;
        mLastFactor = factor;

        //value = from * (1f - factor) + to * factor;
    }
}