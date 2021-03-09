using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine.SceneManagement;

using Loong.Game;


/// <summary>
/// 动态模糊效果
/// </summary>
public class EffMotionBlur
{
    /// <summary>
    /// 模糊控件
    /// </summary>
    private CoolMotionBlur mMotionBlur = null;
    /// <summary>
    /// 模糊中心
    /// </summary>
    private Vector2 mBlurCenter = new Vector2(0.5f, 0.5f);
    /// <summary>
    /// 模糊强度
    /// </summary>
    private float mStrength = 0f;
    /// <summary>
    /// 效果持续时间
    /// </summary>
    private float mLastTime = 0f;
    /// <summary>
    /// 完成回调
    /// </summary>
    private Action<EffMotionBlur> mFinCb = null;

    /// <summary>
    /// 原始中心
    /// </summary>
    private Vector2 mOriCenter = new Vector2(0.5f, 0.5f);
    private float mOriStrength = 0f;
    private float mTimer = 0f;
    

    public EffMotionBlur()
    {
        Init();
    }

    public void Init()
    {
        
    }
    
    public void Update(float dTime)
    {
        mTimer += dTime;
        if(mTimer >= mLastTime)
        {
            Finish();
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="blurCom"></param>
    /// <param name="center"></param>
    /// <param name="stren"></param>
    /// <param name="lastTime"></param>
    public void Play(CoolMotionBlur blurCom, float lastTime, Vector2 center, float stren = 1, Action<EffMotionBlur> finCb = null)
    {
        mFinCb = finCb;
        if (blurCom == null)
        {
            Finish();
            return;
        }
        mMotionBlur = blurCom;
        mBlurCenter = center;
        mStrength = stren;
        mLastTime = lastTime;

        mOriCenter = mMotionBlur.BlurCenter;
        mOriStrength = mMotionBlur.BlurStrength;

        mMotionBlur.BlurCenter = mBlurCenter;
        mMotionBlur.BlurStrength = mStrength;
        mMotionBlur.enabled = true;

        mTimer = 0f;
    }

    public void Stop()
    {
        Finish();
    }

    private void Reset()
    {
        mMotionBlur = null;
        mBlurCenter = new Vector2(0.5f, 0.5f);
        mStrength = 0f;
        mLastTime = 0f;
        mFinCb = null;
        mTimer = 0f;
    }

    private void Finish()
    {
        mMotionBlur.enabled = false;
        mMotionBlur.BlurCenter = mOriCenter;
        mMotionBlur.BlurStrength = mOriStrength;

        if (mFinCb != null)
        {
            mFinCb(this);
            mFinCb = null;
        }
        Reset();
    }
}
