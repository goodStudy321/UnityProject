using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2014.4.20
    /// BG:音效工具
    /// </summary>
    public static class AudioTool
    {
        #region 字段
        private static AudioListener listener = null;
        #endregion

        #region 属性
        public static AudioListener Listener
        {
            get { return listener; }
            set { listener = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 设置2D音源
        /// </summary>
        /// <param name="source"></param>
        public static void Set2DSource(AudioSource source)
        {
            if (source == null) return;
            source.playOnAwake = false;
            source.rolloffMode = AudioRolloffMode.Linear;
            source.spatialBlend = 0;
        }

        /// <summary>
        /// 设置3D音源
        /// </summary>
        /// <param name="source"></param>
        public static void Set3DSource(AudioSource source)
        {
            if (source == null) return;
            source.rolloffMode = AudioRolloffMode.Logarithmic;
            source.spatialBlend = 1;
        }

        /// <summary>
        /// 创建音源
        /// </summary>
        /// <param name="parent">音源的父体</param>
        /// <param name="name">音源的名称</param>
        /// <returns></returns>
        public static AudioSource CreateSource(Transform parent, string name)
        {
            if (parent == null) return null;
            if (string.IsNullOrEmpty(name)) name = "audio";
            GameObject go = new GameObject(name);
            go.transform.parent = parent;
            go.transform.localPosition = Vector3.zero;
            return go.AddComponent<AudioSource>();
        }

        /// <summary>
        /// 创建2D音源
        /// </summary>
        /// <param name="parent">音源的父体</param>
        /// <param name="name">音源的名称</param>
        public static void Create2DSource(Transform parent, string name)
        {
            AudioSource source = CreateSource(parent, name);
            Set2DSource(source);
        }

        /// <summary>
        /// 创建3D音源
        /// </summary>
        /// <param name="parent">音源的父体</param>
        /// <param name="name">音源的名称</param>
        public static void Create3DSource(Transform parent, string name)
        {
            AudioSource source = CreateSource(parent, name);
            Set3DSource(source);
        }


        /// <summary>
        /// 检查AudioListener的唯一性
        /// </summary>
        public static void CheckUniqueListener()
        {
            if (Camera.main == null) return;
            if (listener == null) listener = ComTool.Get<AudioListener>(Camera.main.gameObject);
            AudioListener[] lss = Object.FindObjectsOfType<AudioListener>();
            if (lss == null) return;
            int length = lss.Length;
            for (int i = 0; i < length; i++)
            {
                AudioListener ls = lss[i];
                if (Object.ReferenceEquals(ls, listener)) continue;
                Object.DestroyImmediate(ls);
            }
        }
        #endregion
    }
}