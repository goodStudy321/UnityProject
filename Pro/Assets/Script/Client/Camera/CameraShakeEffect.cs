using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class CameraShakeEffect
{
    class ShakeInfo
    {
        public float Time;
        public float Frequence;
        public float Amplitude;
        public float LeftTime;
        /// <summary>
        /// 作用物体
        /// </summary>
        public GameObject mApplyObj = null;

        public ShakeInfo(float t, float f, float a, GameObject applyObj)
        {
            Time = t;
            Frequence = f;
            Amplitude = a;
            LeftTime = 0;
            mApplyObj = applyObj;
        }
    }

    #region 私有变量
    bool mState = false;
    //Vector3 mOffset = Vector3.zero;
    List<ShakeInfo> mQueuedList = new List<ShakeInfo>();
    #endregion

    #region 属性
    public bool State
    {
        get { return mState; }
        set { mState = value; }
    }
    #endregion

    #region 公有方法
    public void Update()
    {
        bool anyShake = false;
        //mOffset = Vector2.zero;
        for (int i = 0; i < mQueuedList.Count; i++)
        {
            ShakeInfo shakeInfo = mQueuedList[i];
            if (shakeInfo.Time <= Time.deltaTime)
                continue;

            shakeInfo.LeftTime += Time.deltaTime;
            if (shakeInfo.LeftTime * shakeInfo.Frequence > 1.0f)
            {
                Vector3 offset = new Vector3(
                    Random.Range(-shakeInfo.Amplitude, shakeInfo.Amplitude),
                    Random.Range(-shakeInfo.Amplitude, shakeInfo.Amplitude),
                    Random.Range(-shakeInfo.Amplitude, shakeInfo.Amplitude));
                //mOffset += offset;
                shakeInfo.LeftTime = 0;

                if (shakeInfo.mApplyObj != null && offset != Vector3.zero)
                {
                    Vector3 camPos = Loong.Game.CameraMgr.Main.transform.position;
                    shakeInfo.mApplyObj.transform.position = camPos + offset;
                }
            }

            float newTime = shakeInfo.Time - Time.deltaTime;
            shakeInfo.Amplitude *= newTime / shakeInfo.Time;
            shakeInfo.Time = newTime;
            anyShake = true;
        }
        if (!anyShake)
        {
            mState = false;
            mQueuedList.Clear();
        }

        //if (mOffset == Vector3.zero)
        //    return;
        //Vector3 camPos = Loong.Game.CameraMgr.Main.transform.position;
        //Loong.Game.CameraMgr.Main.transform.position = camPos + mOffset;
    }
    
    /// <summary>
    /// 添加摄像机震动
    /// </summary>
    /// <param name="time">时间</param>
    /// <param name="frequence">频率</param>
    /// <param name="amplitude">振幅</param>
    public void AddCameraShakeEffectData(float time, float frequence, float amplitude)
    {
        mState = true;
        mQueuedList.Add(new ShakeInfo(time, frequence, amplitude * 0.01f, Loong.Game.CameraMgr.Main.gameObject));
    }

    /// <summary>
    /// 添加摄像机震动(带震动物体)
    /// </summary>
    /// <param name="time"></param>
    /// <param name="frequence"></param>
    /// <param name="amplitude"></param>
    /// <param name="applyObj"></param>
    public void AddCameraShakeEffWithObj(float time, float frequence, float amplitude, GameObject applyObj)
    {
        if (applyObj == null)
        {
            Loong.Game.iTrace.eError("LY", "No shake object in !!! ");
            return;
        }

        mState = true;
        mQueuedList.Add(new ShakeInfo(time, frequence, amplitude * 0.01f, applyObj));
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="applyObj"></param>
    public void RemoveCameraShakeByObj(GameObject applyObj)
    {
        for (int i = mQueuedList.Count - 1; i >= 0; i--)
        {
            if(mQueuedList[i].mApplyObj == applyObj)
            {
                mQueuedList.RemoveAt(i);
            }
        }
    }

    #endregion
}
