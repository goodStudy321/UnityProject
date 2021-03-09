using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;
using System.Diagnostics;
using UnityEngine.SceneManagement;

using Loong.Game;


/// <summary>
/// 摄像机特效管理器
/// </summary>
public class CameraEffMgr:IModule
{
    public static readonly CameraEffMgr instance = new CameraEffMgr();

    private Camera _mainCam = null;

    /// <summary>
    /// 模糊效果对象池
    /// </summary>
    private List<EffMotionBlur> mEffBlurPool = new List<EffMotionBlur>();

    /// <summary>
    /// 运行中的模糊效果
    /// </summary>
    private List<EffMotionBlur> mRunEffBlurs = new List<EffMotionBlur>();


    public Camera MainCam
    {
        get
        {
            if(_mainCam == null)
            {
                _mainCam = CameraMgr.Main;
            }

            return _mainCam;
        }
    }


    private CameraEffMgr()
    {

    }

    public void Init()
    {
        Initialize();
    }

    public void Initialize()
    {
        
    }

    public void Clear(bool reconnect = false)
    {
        StopEffBlur();
    }

    public void Dispose()
    {

    }

    public void BegChgScene()
    {
        StopEffBlur();
    }

    public void EndChgScene()
    {
        StopEffBlur();
    }

    
    public void Update(float dTime)
    {
        if(mRunEffBlurs != null && mRunEffBlurs.Count > 0)
        {
            for(int a = 0; a < mRunEffBlurs.Count; a++)
            {
                mRunEffBlurs[a].Update(dTime);
            }
        }
    }

    public void StartEffBlur(float lastTime, Vector2 blurCen, float strength)
    {
        /// 判断质量等级，是否播放 ///
        if(QualityMgr.instance.TotalQuality <= QualityMgr.TotalQualityType.TQT_1)
        {
            return;
        }
        
        for(int a = mRunEffBlurs.Count - 1; a >= 0; a--)
        {
            mRunEffBlurs[a].Stop();
        }

        CoolMotionBlur tCMB = MainCam.GetComponent<CoolMotionBlur>();
        if (tCMB == null)
        {
            iTrace.eError("LY", "CoolMotionBlur miss !!! ");
            return;
        }

        EffMotionBlur playEff = GetBlur();
        mRunEffBlurs.Add(playEff);
        playEff.Play(tCMB, lastTime, blurCen, strength, RecyclePlayingBlur);
    }

    public void StopEffBlur()
    {
        for (int a = mRunEffBlurs.Count - 1; a >= 0; a--)
        {
            mRunEffBlurs[a].Stop();
        }
    }



    /// <summary>
    /// 
    /// </summary>
    /// <returns></returns>
    private EffMotionBlur GetBlur()
    {
        if(mEffBlurPool == null)
        {
            mEffBlurPool = new List<EffMotionBlur>();
        }

        EffMotionBlur retBlur = null;
        if (mEffBlurPool.Count > 0)
        {
            retBlur = mEffBlurPool[mEffBlurPool.Count - 1];
            mEffBlurPool.Remove(retBlur);
        }
        else
        {
            retBlur = new EffMotionBlur();
        }
        
        return retBlur;
    }

    private void RecycleBlur(EffMotionBlur effBlur)
    {
        mEffBlurPool.Add(effBlur);
    }

    private void RecyclePlayingBlur(EffMotionBlur effBlur)
    {
        if(mRunEffBlurs == null || mRunEffBlurs.Count <= 0)
        {
            return;
        }

        if(mRunEffBlurs.Contains(effBlur))
        {
            mRunEffBlurs.Remove(effBlur);
            RecycleBlur(effBlur);
        }

    }


    public void LocalChanged()
    {
        //TODO
    }
}
