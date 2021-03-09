using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FxMamager
{
    #region 字段
    private static FxMamager mInstance = new FxMamager();

    private float m_fLastEngineTime = 0;
    private float m_fCurrentTime;
    private float m_fLastTime = 0;
    private const int m_nSmoothCount = 10;
    private float[] m_fSmoothTimes;
    private float m_fLastSmoothDeltaTime;
    private int m_nSmoothIndex;
    private float m_fSmoothRate = 1.3f;
    private float m_fTimeScale = 1.0f;
    #endregion

    #region 构造函数
    private FxMamager() { }
    public static FxMamager GetInstance()
    {
        return mInstance;
    }

    #endregion

    #region 公有方法
    public float GetEngineTime()
    {
        if (Time.time == 0)
            return 0.000001f;
        return Time.time;
    }

    #endregion

    #region 私有方法
    public float GetSmoothDeltaTime()
    {
            if (Time.timeScale == 0)
                return 0;
            if (m_fSmoothTimes == null)
                InitSmoothTime();
            UpdateTimer();
            return m_fLastSmoothDeltaTime;
    }

    private float UpdateTimer()
    {
        if (m_fLastEngineTime != GetEngineTime())
        {
            m_fLastTime = m_fCurrentTime;
            m_fCurrentTime += (GetEngineTime() - m_fLastEngineTime) * GetTimeScale();
            m_fLastEngineTime = GetEngineTime();
            if (m_fSmoothTimes != null)
                UpdateSmoothTime(m_fCurrentTime - m_fLastTime);
        }
        return m_fCurrentTime;
    }

    private float GetTimeScale()
    {
        return m_fTimeScale;
    }

    private void InitSmoothTime()
    {
        if (m_fSmoothTimes == null)
        {
            m_fSmoothTimes = new float[m_nSmoothCount];
            for (int i = 0; i < m_nSmoothCount; i++)
                m_fSmoothTimes[i] = Time.deltaTime;
            m_fLastSmoothDeltaTime = Time.deltaTime;
        }
    }

    private float UpdateSmoothTime(float fDeltaTime)
    {
        m_fSmoothTimes[m_nSmoothIndex++] = Mathf.Min(fDeltaTime, m_fLastSmoothDeltaTime * m_fSmoothRate);
        if (m_nSmoothCount <= m_nSmoothIndex)
        {
            m_nSmoothIndex = 0;
        }

        m_fLastSmoothDeltaTime = 0;
        for (int n = 0; n < m_nSmoothCount; n++)
            m_fLastSmoothDeltaTime += m_fSmoothTimes[n];
        m_fLastSmoothDeltaTime /= m_nSmoothCount;
        return m_fLastSmoothDeltaTime;
    }

    #endregion




}
