using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.6,00:56:41
    /// CO:
    /// BG:
    /// </summary>
    public class MonoStatic<T> : MonoBehaviour where T : MonoBehaviour
    {
        #region 字段
        private static object aLock = new object();

        protected static T instance;

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected static void CreateDummy()
        {
            if (!Application.isPlaying) return;
            if (instance != null) return;
            lock (aLock)
            {
                if (instance != null) return;
                GameObject go = new GameObject();
                go.AddComponent<T>();
            }
        }

        protected virtual void Awake()
        {
            if (instance != null)
            {
                Destroy(this);
            }
            else
            {
                instance = this as T;
                gameObject.name = typeof(T).Name;
                transform.parent = iConfig.MonoRoot;
                gameObject.hideFlags = HideFlags.NotEditable;
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}