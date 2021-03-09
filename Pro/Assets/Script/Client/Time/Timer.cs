using System;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     *  1,必须通过Start函数启动;
     *  2,尽量不要通过New实例化,而是通过对象池获取
     *  3,回调事件仅在释放时滞空,停止时不清空
     *  4,当需要释放(将引用滞空,并将实例放入对象池),应该调用AutoToPool方法,而不要调用Dispose
     * 
     */
    /// <summary>
    /// AU:Loong
    /// TM:2013.12.03
    /// BG:计时器类

    /// </summary>
    public class Timer : IDisposable
    {
        #region 字段
        private float pro = 0;
        private float delta = 0;
        protected float count = 0;
        private float invlCnt = 0;
        private float seconds = 1;
        private float interval = 1;
        private bool loop = false;
        private bool isLock = false;
        private bool running = false;
        private bool isPause = true;
        private bool autoPool = false;
        private bool ignoreTimeScale = false;

        #endregion

        #region 属性
        /// <summary>
        /// 进度
        /// </summary>
        public float Pro
        {
            get { return pro; }
        }

        /// <summary>
        /// 间隔时间
        /// </summary>
        public float Interval
        {
            get { return interval; }
            set { interval = value; }
        }

        /// <summary>
        /// 时间
        /// </summary>
        public float Seconds
        {
            get { return seconds; }
            set { seconds = value; }
        }

        /// <summary>
        /// 通过时间刻度设置时间
        /// </summary>
        public long Ticks
        {
            set { seconds = value * 0.0000001f; }
        }

        /// <summary>
        /// true:循环
        /// </summary>
        public bool Loop
        {
            get { return false; }
            set { loop = value; }
        }

        /// <summary>
        /// true:暂停中
        /// </summary>
        public bool IsPause
        {
            get { return isPause; }
        }

        /// <summary>
        /// true:运行中
        /// </summary>
        public bool Running
        {
            get { return running; }
        }

        /// <summary>
        /// true:被管理器占有
        /// </summary>
        public bool IsLock
        {
            get { return isLock; }
            set { isLock = value; }
        }

        /// <summary>
        /// true:管理器将此实例放入对象池,此时不要保留对此实例的引用
        /// </summary>
        public bool AutoPool
        {
            get { return autoPool; }
            set { autoPool = value; }
        }

        /// <summary>
        /// true:忽略时间缩放
        /// </summary>
        public bool IgnoreTimeScale
        {
            get { return ignoreTimeScale; }
            set { ignoreTimeScale = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 间隔事件
        /// </summary>
        public event Action invl = null;

        /// <summary>
        /// 结束事件
        /// </summary>
        public event Action complete = null;
        #endregion

        #region 构造方法
        public Timer()
        {

        }

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 更新信息
        /// </summary>
        public void Update()
        {
            if (!running) return;
            if (isPause) return;
            delta = (ignoreTimeScale) ? Time.unscaledDeltaTime : Time.deltaTime;
            if (invl != null)
            {
                invlCnt += delta;
                if (invlCnt > interval)
                {
                    invl();
                    invlCnt = 0;
                }
            }
            count += delta;
            pro = (count / seconds);
            if (count > seconds)
            {
                if (loop)
                {
                    count = 0;
                }
                else
                {
                    Stop();
                }
                if (complete != null) complete();
            }
        }

        /// <summary>
        /// 启动
        /// </summary>
        public virtual void Start()
        {
            if (running) return;
            TimerMgr.Add(this);
            running = true;
            isPause = false;
        }

        /// <summary>
        /// 暂停
        /// </summary>
        public virtual void Pause()
        {
            if (isPause) return;
            isPause = true;
        }

        /// <summary>
        /// 重新开始
        /// </summary>
        public virtual void Resume()
        {
            if (!isPause) return;
            isPause = false;
        }

        /// <summary>
        /// 停止
        /// </summary>
        public virtual void Stop()
        {
            if (!running) return;
            running = false;
            Reset();
        }

        /// <summary>
        /// 重置
        /// </summary>
        public virtual void Reset()
        {
            pro = 0;
            count = 0;
            invlCnt = 0;
            isPause = false;
            running = false;
        }

        public virtual void Dispose()
        {
            Reset();
            seconds = 1;
            isLock = false;
            running = false;
            AutoPool = false;
            complete = null;
            invl = null;
        }

        public void AutoToPool()
        {
            if (running)
            {
                autoPool = true;
                Stop();
            }
            else
            {
                Dispose();
                ObjPool.Instance.Add(this);
            }
        }

        #endregion
    }
}