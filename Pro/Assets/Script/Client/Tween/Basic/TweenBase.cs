using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.15
    /// BG:补间动画基类
    /// </summary>
    [Serializable]
    public abstract class TweenBase : IDisposable
    {
        #region 字段
        private bool isPause = true;

        private bool running = false;

        private bool autoReturnPool = false;

        [SerializeField]
        private bool ignoreTimeScale = false;

        [SerializeField]
        private LoopMode mode = LoopMode.Once;
        #endregion

        #region 属性

        /// <summary>
        /// true:暂停中
        /// </summary>
        public bool IsPause
        { get { return isPause; } }

        /// <summary>
        /// true:运行中
        /// </summary>
        public bool Running
        { get { return running; } }

        /// <summary>
        /// 循环模式
        /// </summary>
        public LoopMode Mode
        {
            get { return mode; }
            set { mode = value; }
        }

        /// <summary>
        /// true:忽略时间缩放
        /// </summary>
        public bool IgnoreTimeScale
        {
            get { return ignoreTimeScale; }
            set { ignoreTimeScale = value; }
        }

        /// <summary>
        /// true:释放时 自动放入对象池,此时不要保留对此实例的引用
        /// </summary>
        public bool AutoReturnPool
        {
            get { return autoReturnPool; }
            set { autoReturnPool = value; }
        }

        #endregion

        #region 委托事件
        /// <summary>
        /// 结束事件
        /// 循环模式为Once时:调用一次
        /// 循环模式为Loop或者Pingpong时,每循环调用一次
        /// </summary>
        public Action complete = null;
        #endregion

        #region 构造方法
        public TweenBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        protected void Complete()
        {
            if (complete != null) complete();
        }

        /// <summary>
        /// 自定义更新
        /// </summary>
        protected virtual void UpdateCustom() { }

        /// <summary>
        /// 自定义开始
        /// </summary>
        protected virtual void StartCustom() { }

        /// <summary>
        /// 自定义暂停
        /// </summary>
        protected virtual void PauseCustom() { }

        /// <summary>
        /// 自定义重启
        /// </summary>
        protected virtual void ResumeCustom() { }


        /// <summary>
        /// 自定义重置
        /// </summary>
        protected virtual void ResetCustom() { }

        /// <summary>
        /// 自定义释放
        /// </summary>
        protected virtual void DisposeCustom() { }
        #endregion

        #region 公开方法

        /// <summary>
        /// 启动;添加到管理器中
        /// </summary>
        public void Start()
        {
            if (running) return;
            TweenMgr.Add(this);
            running = true;
            isPause = false;
            StartCustom();
        }

        /// <summary>
        /// 更新信息
        /// </summary>
        public void Update()
        {
            if (isPause) return;
            if (!running) return;
            UpdateCustom();
        }

        /// <summary>
        /// 暂停
        /// </summary>
        public void Pause()
        {
            if (isPause) return;
            isPause = true;
            PauseCustom();
        }

        /// <summary>
        /// 继续
        /// </summary>
        public void Resume()
        {
            if (!isPause) return;
            isPause = false;
            ResumeCustom();
        }

        /// <summary>
        /// 重置,非配置数据
        /// </summary>
        public void Reset()
        {
            isPause = false;
            running = false;
            ResetCustom();
        }

        /// <summary>
        /// 停止;
        /// 如果自动返回对象池,将调用释放
        /// 反之调用重置,并从管理器中移除
        /// </summary>
        public void Stop()
        {
            if (AutoReturnPool)
            {
                Dispose();
            }
            else
            {
                Reset();
                TweenMgr.Remove(this);
            }
        }

        public void Dispose()
        {
            ObjPool.Instance.Add(this);
            TweenMgr.Remove(this);
            AutoReturnPool = false;
            Mode = LoopMode.Once;
            complete = null;
            DisposeCustom();
            Reset();
        }
        #endregion

#if UNITY_EDITOR
        public virtual void Draw(Object obj)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("忽略时间缩放:", ref ignoreTimeScale, obj);
            mode = (LoopMode)UIEditLayout.Popup("播放模式:", mode, DisplayOption.loopMode, obj);
            EditorGUILayout.EndVertical();
        }
#endif
    }
}