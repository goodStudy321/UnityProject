#if UNITY_EDITOR
using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace Loong
{
    /// <summary>
    /// 组件绑定接口
    /// </summary>
    public interface IComBind
    {
        /// <summary>
        /// 监制
        /// </summary>
        string Key { get; }
    }

    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        bd982d8b-e2a1-4429-99f8-f384a19223e3
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/2/4 17:53:31
    /// BG:组件绑定工具
    /// </summary>
    public static class ComBindTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取组件
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="key"></param>
        /// <returns></returns>
        public static T Get<T>(string key) where T : MonoBehaviour, IComBind
        {
            if (string.IsNullOrEmpty(key))
            {
                Debug.LogError("定位绑定组件时,传入的键值为空"); return null;
            }
            T[] binds = null;
            var scene = SceneManager.GetActiveScene();
            if (string.IsNullOrEmpty(scene.path))
            {
                binds = Object.FindObjectsOfType<T>();
                if (binds == null)
                {
                    Debug.LogError("没有发现绑定组件"); return null;
                }
                return Get(binds, key);
            }
            else
            {
                var gos = scene.GetRootGameObjects();
                int length = gos.Length;
                for (int i = 0; i < length; i++)
                {
                    var go = gos[i];
                    binds = go.GetComponentsInChildren<T>(true);
                    var bind = Get(binds, key);
                    if (bind != null) return bind;
                }
            }
            return null;
        }

        public static T Get<T>(T[] binds, string key) where T : MonoBehaviour, IComBind
        {
            if (binds == null) return null;
            int length = binds.Length;
            for (int i = 0; i < length; i++)
            {
                T bind = binds[i];
                if (!bind.Key.Equals(key)) continue;
                return bind;
            }
            return null;
        }

        /// <summary>
        /// 获取物体
        /// </summary>
        /// <param name="key">键值</param>
        /// <returns></returns>
        public static GameObject GetGo<T>(string key) where T : MonoBehaviour, IComBind
        {
            T cb = Get<T>(key);
            if (cb == null) return null;
            return cb.gameObject;
        }

        /// <summary>
        /// 定位物体
        /// </summary>
        public static void Ping<T>(string key) where T : MonoBehaviour, IComBind
        {
            T cb = Get<T>(key);
            if (cb == null)
            {
                Debug.LogErrorFormat("没有发现键值为{0}的绑定组件", key);
            }
            else
            {
                EditorGUIUtility.PingObject(cb);
                if (SceneView.currentDrawingSceneView != null)
                {
                    SceneView.currentDrawingSceneView.LookAt(cb.transform.position);
                }
            }
        }

        #endregion
    }
}
#endif