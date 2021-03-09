//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2018/8/20 17:52:15
// SDK运行时基类
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    public abstract class SdkBase : MonoBehaviour
    {
        #region 字段

        protected string des = null;

        protected string paySucArg = null;

        protected string payFailArg = null;

        protected string initSucArg = null;

        protected string initFailArg = null;

        protected string loginSucArg = null;

        protected string loginFailArg = null;

        protected string logoutSucArg = null;

        protected string logoutFailArg = null;

        protected string deleteSucArg = null;

        protected string deleteFailArg = null;

        protected string realNameArg = null;

        protected string permissionArg = null;

        #endregion

        #region 属性


        /// <summary>
        /// 登录成功参数
        /// </summary>
        public string LoginSucArg
        {
            get { return loginSucArg; }
            set { loginSucArg = value; }
        }

        /// <summary>
        /// 登出成功参数
        /// </summary>
        public string LogoutSucArg
        {
            get { return logoutSucArg; }
            set { logoutSucArg = value; }
        }

        public virtual int ID
        {
            get { throw new Exception("未重写ID"); }
        }

        public string RealNameArg
        {
            get { return realNameArg; }
        }

        /// <summary>
        /// 授权状态参数
        /// </summary>
        public string PermissionArg
        {
            get { return permissionArg; }
        }

        /// <summary>
        /// 支付成功参数
        /// </summary>
        public string PaySucArg
        {
            get { return paySucArg; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private IEnumerator CheckInit()
        {
            Debug.Log("unity 开始调用sdk初始化  init beg");
            while (true)
            {
                for (int i = 0; i < 3; i++)
                {
                    yield return null;
                }
                var result = GetInitResult();
                Debug.Log("unity 开始调用sdk初始化  result: "+ result);
                if (result == 0) continue;
                if (result == 1)
                {
                    OnInitSuc();
                }
                else
                {
                    OnInitFail();
                }
                break;
            }
            Debug.Log("unity 开始调用sdk初始化  init end");
        }
        #endregion

        #region 保护方法
        protected void Log(string fmt, params object[] args)
        {
            if (App.IsDebug || App.IsReleaseDebug || App.IsEditor)
            {
                iTrace.Log(des, fmt, args);
            }
        }

        protected virtual void Awake()
        {
            gameObject.name = "Sdk";
            DontDestroyOnLoad(gameObject);
            des = string.Format("Loong CS-SDK:{0}", ID);
            Log("Awake");
            StartCoroutine(CheckInit());
        }

        #region 初始化

        protected virtual void InitSdk()
        {
            Debug.Log("unity 开始调用sdk初始化");
            StartCoroutine(CheckInit());
        }

        /// <summary>
        /// 获取初始化结果
        /// </summary>
        /// <returns></returns>
        protected abstract int GetInitResult();

        /// <summary>
        /// 全部授权成功
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void PermissionSuc(string arg)
        {
            permissionArg = arg;
            MonoEvent.AddOneShot(OnPermissionSuc);
        }

        protected virtual void OnPermissionSuc()
        {
            Log("PermissionSuc:{0}", permissionArg);
            EventMgr.Trigger("SdkPermissionSuc");
        }

        /// <summary>
        /// 授权失败
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void PermissionFail(string arg)
        {
            permissionArg = arg;
            MonoEvent.AddOneShot(OnPermissionFail);
        }

        protected virtual void OnPermissionFail()
        {
            Log("PermissionFail:{0}", permissionArg);
            EventMgr.Trigger("SdkPermissionFail");
        }

        /// <summary>
        /// 初始化成功
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void InitSuc(string arg)
        {
            initSucArg = arg;
            MonoEvent.AddOneShot(OnInitSuc);
        }

        protected virtual void OnInitSuc()
        {
            if (App.SdkInit) return;
            App.SdkInit = true;
            Debug.Log("sdk 初始化成功");
            EventMgr.Trigger("Sdk_InitSuc_1");
        }

        /// <summary>
        /// 初始化失败
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void InitFail(string arg)
        {
            initFailArg = arg;
            MonoEvent.AddOneShot(OnInitFail);
        }

        protected virtual void OnInitFail()
        {
            var result = GetInitResult();
            if (result == 2)
            {
                return;
            }
            if (App.SdkInit) return;
            App.SdkInit = true;
            Debug.Log("sdk 初始化失败");
            EventMgr.Trigger("Sdk_InitFail_1");
        }

        #endregion


        #region 登录

        /// <summary>
        /// 登陆成功
        /// </summary>
        /// <param name="arg">uid</param>
        protected virtual void LoginSuc(string arg)
        {
            loginSucArg = arg;
            MonoEvent.AddOneShot(OnLoginSuc);

        }

        protected virtual void OnLoginSuc()
        {
            Log("LoginSuc:{0}", loginSucArg);
            EventMgr.Trigger("SdkSuc", loginSucArg);
        }


        /// <summary>
        /// 登陆失败
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void LoginFail(string arg)
        {
            loginFailArg = arg;
            MonoEvent.AddOneShot(OnLoginFail);
        }

        protected virtual void OnLoginFail()
        {
            Log("LoginFail:{0}", loginFailArg);
            EventMgr.Trigger("SdkFail");
        }

        #region 切换账号
        /// <summary>
        /// 切换账号成功
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void SwitchSuc(string arg)
        {
            MonoEvent.AddOneShot(OnSwitchSuc);
        }


        protected virtual void OnSwitchSuc()
        {
            Log("SwitchSuc");
            EventMgr.Trigger("SdkSwitchSuc");
        }


        /// <summary>
        /// 切换账号失败
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void SwitchFail(string arg)
        {
            MonoEvent.AddOneShot(OnSwitchFail);
        }


        protected virtual void OnSwitchFail()
        {
            Log("SwitchFail");
            EventMgr.Trigger("SdkSwitchFail");
        }

        /// <summary>
        /// 切换账号用户取消
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void SwitchCancel(string arg)
        {
            MonoEvent.AddOneShot(OnSwitchCancel);
        }


        protected virtual void OnSwitchCancel()
        {
            Log("SwitchCancel");
            EventMgr.Trigger("SdkSwitchCancel");
        }
        #endregion


        #endregion


        #region 登出

        /// <summary>
        /// 登出成功
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void LogoutSuc(string arg)
        {
            logoutSucArg = arg;
            MonoEvent.AddOneShot(OnLogoutSuc);
        }

        protected virtual void OnLogoutSuc()
        {
            Log("LogoutSuc:{0}", logoutSucArg);
            EventMgr.Trigger("LogoutSuc");
        }

        /// <summary>
        /// 登出失败
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void LogoutFail(string arg)
        {
            logoutFailArg = arg;
            MonoEvent.AddOneShot(OnLogoutFail);
        }

        protected virtual void OnLogoutFail()
        {
            Log("LogoutFail:{0}", logoutFailArg);
            EventMgr.Trigger("LogoutFail");
        }

        protected virtual void DeleteSuc(string arg)
        {
            deleteSucArg = arg;
            MonoEvent.AddOneShot(OnDeleteSuc);
        }

        protected virtual void OnDeleteSuc()
        {
            Log("DeleteSuc:{0}", deleteSucArg);
            EventMgr.Trigger("DeleteSuc");
        }

        protected virtual void DeleteFail(string arg)
        {
            deleteFailArg = arg;
            MonoEvent.AddOneShot(OnDeleteFail);
        }

        protected virtual void OnDeleteFail()
        {
            Log("DeleteFail:{0}", deleteFailArg);
            EventMgr.Trigger("DeleteFail");
        }
        #endregion


        #region 支付
        protected virtual void PaySuc(string msg)
        {
            paySucArg = msg;
            MonoEvent.AddOneShot(OnPaySuc);
        }

        protected virtual void OnPaySuc()
        {
            Log("PaySuc:{0}", paySucArg);
            EventMgr.Trigger("SdkPaySuc");
        }

        protected virtual void PayFail(string msg)
        {
            payFailArg = msg;
            MonoEvent.AddOneShot(OnPayFail);
        }

        protected virtual void OnPayFail()
        {
            Log("PayFail:{0}", payFailArg);
            EventMgr.Trigger("SdkPayFail");
        }

        protected virtual void PayCancel(string msg)
        {
            MonoEvent.AddOneShot(OnPayCancel);
        }

        protected virtual void OnPayCancel()
        {
            EventMgr.Trigger("SdkPayCancel");
        }
        #endregion

        #region 退出
        protected virtual void ExitSuc(string msg)
        {
            MonoEvent.AddOneShot(OnExitSuc);
        }

        protected virtual void OnExitSuc()
        {
            Log("ExitSuc");
            EventMgr.Trigger("SdkExitSuc");
        }

        protected virtual void ExitFail(string msg)
        {
            MonoEvent.AddOneShot(OnExitFail);
        }

        protected virtual void OnExitFail()
        {
            EventMgr.Trigger("SdkExitFail");
        }

        protected virtual void ExitCancel(string msg)
        {
            MonoEvent.AddOneShot(OnExitCancel);
        }

        protected virtual void OnExitCancel()
        {
            EventMgr.Trigger("SdkExitCancel");
        }
        #endregion


        #region 实名

        /// <summary>
        /// 实名成功回调
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void RealNameSuc(string arg)
        {
            realNameArg = arg;
            MonoEvent.AddOneShot(OnRealNameSuc);
        }

        protected virtual void OnRealNameSuc()
        {
            EventMgr.Trigger("SdkRealNameSuc");
        }

        /// <summary>
        /// 实名失败回调
        /// </summary>
        /// <param name="arg"></param>
        protected virtual void RealNameFail(string arg)
        {
            MonoEvent.AddOneShot(OnRealNameFail);
        }

        protected virtual void OnRealNameFail()
        {
            EventMgr.Trigger("SdkRealNameFail");
        }

        /// <summary>
        /// 判断是否支持实名制
        /// </summary>
        /// <returns></returns>
        public virtual bool SupportRealName()
        {
            return false;
        }


        /// <summary>
        /// 用于拉起实名制接口
        /// </summary>
        public virtual void VerifyRealName(string data)
        {

        }



        #endregion

        #endregion

        #region 公开方法

        #endregion
    }
}