//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/21 16:56:04
// 权限回调事件通过EventMgr.Trigger("onPermissionsResult", arg1, arg2)触发
// arg1代码权限的完整名称,arg2：0:同意 -1:拒绝 -2:未知
// 在请求权限之前判断下Device.SysSDKVer,若小于23不应该请求
//=============================================================================

#if UNITY_ANDROID
using System;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// Activitycs
    /// </summary>
    public class Activity : MonoBehaviour
    {
        #region 字段
        private AndroidJavaObject jo = null;

        private static Activity instance;
        private Queue<string> permissions = new Queue<string>();
        #endregion

        #region 属性
        public static Activity Instance
        {
            get { return instance; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Awake()
        {
            instance = this;
            gameObject.name = this.GetType().Name;
            try
            {
                jo = new AndroidJavaObject("loong.lib.PermissionUtil");
                if (App.IsDebug)
                {
                    iTrace.Log("Loong", "activity is create");
                }
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, set jo err:{0}", e.Message);
            }
        }

        /// <summary>
        /// 授权结果回调
        /// </summary>
        /// <param name="res"></param>
        private void onRequestPermissionsResult(String res)
        {
            if (string.IsNullOrEmpty(res) || res == "no")
            {
                MonoEvent.AddOneShot(onPermissionsResult);
            }
            lock (permissions)
            {
                permissions.Enqueue(res);
            }
        }

        private void onPermissionsResult()
        {
            EventMgr.Trigger("onPermissionsResult", "", "");
        }

        private void Update()
        {
            if (permissions.Count < 1) return;
            lock (permissions)
            {
                var per = permissions.Dequeue();
                string arg1 = null;
                int arg2 = -1;
                var arr = per.Split('|');
                var length = arr.Length;
                if (length < 1)
                {
                    arg1 = "";
                }
                else if (length < 2)
                {
                    arg1 = arr[0];
                }
                else
                {
                    arg1 = arr[0];
                    if (!int.TryParse(arr[1], out arg2))
                    {
                        arg2 = -1;
                    }
                }
                EventMgr.Trigger("onPermissionsResult", arg1, arg2);
            }
        }
        #endregion

        #region 保护方法
        /// <summary>
        /// 请求全选,默认请求码:409
        /// </summary>
        /// <param name="name">简写权限名,比如android.permission.READ_PHONE_STATE,传入READ_PHONE_STATE</param>
        public void Req(string name)
        {
            if (App.IsDebug)
            {
                iTrace.Log("Loong", "req permission name:{0}", name);
            }
            JavaUtil.CallStatic(jo, "req", name);
        }

        /// <summary>
        /// 请求权限
        /// </summary>
        /// <param name="name">同上</param>
        /// <param name="reqCode">请求码</param>
        public void Req(string name, int reqCode)
        {
            JavaUtil.CallStatic(jo, "req", name, reqCode);
        }

        /// <summary>
        /// 请求权限
        /// </summary>
        /// <param name="name">完整权限名</param>
        /// <param name="reqCode">,比如android.permission.READ_PHONE_STATE</param>
        public void ReqByFullName(string name, int reqCode)
        {
            JavaUtil.CallStatic(jo, "reqByFullName", name, reqCode);
        }

        /// <summary>
        /// 检查权限
        /// </summary>
        /// <param name="name">简写权限名,比如android.permission.READ_PHONE_STATE,传入READ_PHONE_STATE</param>
        /// <returns>0:同意 -1:拒绝 -2:未知</returns>
        public int Check(String name)
        {
            return JavaUtil.CallStaticGenneric<int>(jo, "check", -2, name);
        }

        /// <summary>
        /// 检查权限
        /// </summary>
        /// <param name="name">完整权限名</param>
        /// <returns></returns>
        public int CheckByFullName(string name)
        {
            return JavaUtil.CallStaticGenneric<int>(jo, "checkByFullName", -2, name);
        }
        #endregion

        #region 公开方法
        public static void Init()
        {
            if (Application.isEditor) return;
            var go = new GameObject();
            DontDestroyOnLoad(go);
            go.AddComponent<Activity>();
        }
        #endregion
    }

}
#endif