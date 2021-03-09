using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.25
    /// BG:Mono全局事件注册管理
    /// </summary>
    public sealed class MonoEvent : MonoBehaviour
    {
        #region 字段
        private static MonoEvent instance = null;

        /// <summary>
        /// 一次性事件队列
        /// </summary>
        private static Queue<Action> oneshots = new Queue<Action>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        /// <summary>
        /// 全局onGUI更新事件
        /// </summary>
        public static event Action onGUI = null;

        /// <summary>
        /// 全局update更新事件
        /// </summary>
        public static event Action update = null;

        /// <summary>
        /// 全局LateUpdate更新事件
        /// </summary>
        public static event Action lateupdate = null;

        /// <summary>
        /// 全局销毁事件:游戏退出时执行
        /// </summary>
        public static event Action onDestroy = null;

        /// <summary>
        /// 应用暂停时
        /// </summary>
        public static event Action<bool> onPause = null;


        #endregion

        #region 构造函数

        #endregion

        #region 私有方法
        private void Update()
        {
            if (update != null)
            {
                update();
            }
            if (oneshots.Count > 0)
            {
                lock (oneshots)
                {
                    var oneshot = oneshots.Dequeue();
                    if (oneshot != null) oneshot();
                }
            }
        }

        private void LateUpdate()
        {
            if (lateupdate != null) lateupdate();
        }

        private void OnGUI()
        {
            if (onGUI != null) onGUI();
        }

        private void OnDestroy()
        {
            if (onDestroy != null) onDestroy();
        }

        private void OnApplicationPause(bool pause)
        {
            if (onPause != null) onPause(pause);
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
            if (instance != null) return;
            Transform root = TransTool.CreateRoot(typeof(MonoEvent).Name);
            instance = root.gameObject.AddComponent<MonoEvent>();
        }

        /// <summary>
        /// 开始协程
        /// </summary>
        public static Coroutine Start(IEnumerator routine)
        {
            return instance.StartCoroutine(routine);
        }

        /// <summary>
        /// 停止协程
        /// </summary>
        /// <param name="co"></param>
        public static void Stop(Coroutine co)
        {
            if (co == null) return;
            instance.StopCoroutine(co);
        }

        /// <summary>
        /// 停止所有协程
        /// </summary>
        public static void StopAll()
        {
            instance.StopAllCoroutines();
        }

        /// <summary>
        /// 添加一次性事件
        /// </summary>
        /// <param name="handler"></param>
        public static void AddOneShot(Action handler)
        {
            if (handler == null) return;
            lock (oneshots)
            {
                oneshots.Enqueue(handler);
            }
        }
        #endregion
    }
}