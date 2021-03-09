#if UNITY_EDITOR

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.12.03
    /// CO:DefaultCompany.Timer
    /// BG:
    /// </summary>
    public class TestTimerMgr : TestMonoBase
    {
        #region 字段

        private DateTimer timer1 = null;

        private DateTimer timer2 = null;

        private UISlider timerSlider = null;

        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private void Awake()
        {

        }

        private void Start()
        {
            timerSlider = GetComponent<UISlider>();
        }

        private void TimeEnd()
        {
            iTrace.Log("Loong", "Time  结束");
        }

        private void Time1End()
        {

            iTrace.Log("Loong", "Time 1 结束");
        }

        private void Time1Interval()
        {
            iTrace.Log("Loong", "Time1间隔回调");
        }

        private void Time2End()
        {

            iTrace.Log("Loong", "Time 2 结束");
        }

        private void Update()
        {

            if (timer1 != null) if (timerSlider != null) timerSlider.value = timer1.Pro;

        }


        private void DrawTimer(DateTimer timer)
        {
            if (timer == null) return;
            GUILayout.BeginVertical(GUILayout.Width(200));
            GUILayout.Label("剩余时间:" + timer.Remain, lblOpts);
            GUILayout.Label("目标时间:" + timer.EndTime.ToString("yyyy.MM.dd HH:mm:ss fff"), lblOpts);
            if (GUILayout.Button("暂停"))
            {
                timer.Pause();
            }
            else if (GUILayout.Button("恢复"))
            {
                timer.Resume();
            }
            else if (GUILayout.Button("重置"))
            {
                timer.Reset();
                timer.Start();
            }
            else if (GUILayout.Button("停止"))
            {
                timer.Stop();
            }
            GUILayout.EndVertical();
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            GUILayout.BeginHorizontal();
            if (GUILayout.Button("启动Time", btnOpts))
            {
                Timer timer = TimerMgr.Create<Timer>(4, true);
                timer.complete += TimeEnd;
            }
            else if (GUILayout.Button("启动Time1", btnOpts))
            {
                if (timer1 == null)
                {
                    timer1 = TimerMgr.Create<DateTimer>(4, false);
                    timer1.complete += Time1End;
                }
                if (!timer1.Running)
                {
                    timer1.Start();
                }
            }

            else if (GUILayout.Button("启动Time2", btnOpts))
            {
                if (timer2 == null)
                {
                    timer2 = TimerMgr.Create<DateTimer>(5, false);
                    timer2.complete += Time2End;
                }
                if (!timer2.Running)
                {
                    timer2.Start();
                }
            }
            GUILayout.EndHorizontal();

            GUILayout.BeginHorizontal();
            DrawTimer(timer1);
            DrawTimer(timer2);
            GUILayout.EndHorizontal();


        }

        #endregion

        #region 公开方法

        #endregion
    }
}
#endif