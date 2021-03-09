//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/21 17:22:58
//=============================================================================
#if UNITY_ANDROID
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// JavaUtil
    /// </summary>
    public static class JavaUtil
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
        /// 创建Java类型实例
        /// </summary>
        /// <param name="className"></param>
        /// <returns></returns>
        public static AndroidJavaObject Create(string className)
        {
            if (Application.isEditor) return null;
            AndroidJavaObject jo = null;
            try
            {
                jo = new AndroidJavaObject(className);
            }
            catch (Exception e)
            {

                Debug.LogErrorFormat("Loong, Create JavaObject:{0} err:{1}", className, e.Message);
            }
            return jo;
        }

        public static void Call(AndroidJavaObject jo, string fn, params object[] args)
        {
            if (jo == null) return;
            try
            {
                jo.Call(fn, args);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong,call {0}, err:{1}", fn, e.Message);
            }
        }

        public static T CallGenneric<T>(AndroidJavaObject jo, string fn, T defaultVal, params object[] args)
        {
            if (jo == null) return defaultVal;
            T res = defaultVal;
            try
            {
                res = jo.Call<T>(fn, args);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong,call {0}, err:{1}", fn, e.Message);
            }
            return res;
        }

        public static T CallStaticGenneric<T>(AndroidJavaObject jo, string fn, T defaultVal, params object[] args)
        {
            if (jo == null) return defaultVal;
            T res = defaultVal;
            try
            {
                res = jo.CallStatic<T>(fn, args);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong,call {0}, err:{1}", fn, e.Message);
            }
            return res;
        }

        public static void CallStatic(AndroidJavaObject jo, string fn, params object[] args)
        {
            if (jo == null) return;
            try
            {
                jo.CallStatic(fn, args);
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong,call {0}, err:{1}", fn, e.Message);
            }
        }

        /// <summary>
        /// 获取Unity当前活动
        /// </summary>
        /// <returns></returns>
        public static AndroidJavaObject GetUnityPlayer()
        {
            if (Application.isEditor) return null;
            AndroidJavaObject jo = null;
            using (var jc = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                jo = jc.GetStatic<AndroidJavaObject>("currentActivity");
            }
            if (jo == null)
            {
                iTrace.Error("Loong", "currentActivity为空");
            }
            return jo;
        }
        #endregion
    }
}

#endif