//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/3/27 20:50:17
//*****************************************************************************

#if SDK_ANDROID_GAT
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Loong.Game
{
    /// <summary>
    /// SdkGatAnd
    /// </summary>
    public class Sdk : SdkGat
    {
        #region 字段
        private static Sdk instance = null;

        private static AndroidJavaObject ujo = null;

        #endregion

        #region 属性
        public override int ID
        {
            get { return 20; }
        }

        public static Sdk Instance
        {
            get { return instance; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void Awake()
        {
            instance = this;
            base.Awake();
            ujo = JavaUtil.GetUnityPlayer();
            SetBSUrl(App.BSUrl, "index/Hmt/auth");
        }

        protected void SessionExpire(string msg)
        {
            Log("SessionExpire");
            MonoEvent.AddOneShot(OnSessionExpire);
        }

        protected void OnSessionExpire()
        {
            EventMgr.Trigger("SdkSessionExpire");
        }

        protected override int GetInitResult()
        {
            return JavaUtil.CallGenneric<int>(ujo, "getInitResult", 0);
        }

        #endregion

        #region 公开方法

        public static void Login()
        {
            JavaUtil.Call(ujo, "login");
        }


        public static void Logout()
        {
            JavaUtil.Call(ujo, "logout");
        }

        public static void CheckSvr(string svrID)
        {
            JavaUtil.Call(ujo, "checkSvr", svrID);
        }


        public static void UploadRoleCreate(string roleName, string roleID)
        {
            JavaUtil.Call(ujo, "createRole", roleID, roleName);
        }

        public static void UploadRoleSelect(string roleName, string roleID, string lv)
        {
            JavaUtil.Call(ujo, "selectRole", roleID, roleName, lv);
        }

        public static void UploadBegGame()
        {
            JavaUtil.Call(ujo, "startGame");
        }

        public static void UserCenter()
        {
            JavaUtil.Call(ujo, "uc");
        }

        public static void Pay(string itemID)
        {
            JavaUtil.Call(ujo, "pay", itemID);
        }

        public static void PayThird(string lv)
        {
            JavaUtil.Call(ujo, "payThird", lv);
        }

        public static void LogEvent(string name)
        {
            JavaUtil.Call(ujo, "logEvent", name);
        }


        public static void LogEvent1(string name, string k, string v)
        {
            JavaUtil.Call(ujo, "logEvent1", name, k, v);

        }

        public static void ShareFbLink(string link)
        {
            JavaUtil.Call(ujo, "fbShareLink", link);
        }


        public static void ShareFbTex(string persist, string streaming, string name)
        {
            JavaUtil.Call(ujo, "fbShareTex", persist, streaming, name);
        }

        public static void Kefu()
        {
            JavaUtil.Call(ujo, "kefu");
        }


        public static void SetBSUrl(string bs, string login)
        {
            JavaUtil.Call(ujo, "setBSUrl", bs, login);
        }

        public static string GetExterDir()
        {
            return JavaUtil.CallGenneric<string>(ujo,"getExterDir","");
        }

        public static string GetExterDir2()
        {
            return JavaUtil.CallGenneric<string>(ujo, "getExterDir2", "");
        }
        #endregion
    }
}

#endif