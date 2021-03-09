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
        /// ��������
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

    #region ˽�б���
    bool mState = false;
    //Vector3 mOffset = Vector3.zero;
    List<ShakeInfo> mQueuedList = new List<ShakeInfo>();
    #endregion

    #region ����
    public bool State
    {
        get { return mState; }
        set { mState = value; }
    }
    #endregion

    #region ���з���
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
    /// ����������
    /// </summary>
    /// <param name="time">ʱ��</param>
    /// <param name="frequence">Ƶ��</param>
    /// <param name="amplitude">���</param>
    public void AddCameraShakeEffectData(float time, float frequence, float amplitude)
    {
        mState = true;
        mQueuedList.Add(new ShakeInfo(time, frequence, amplitude * 0.01f, Loong.Game.CameraMgr.Main.gameObject));
    }

    /// <summary>
    /// ����������(��������)
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
