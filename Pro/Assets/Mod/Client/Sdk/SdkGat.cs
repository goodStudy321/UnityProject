//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/3/27 20:55:05
//*****************************************************************************

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// SdkGat
    /// </summary>
    public abstract class SdkGat : SdkBase
    {
        #region 字段
        public string checkSvrSucArg = null;

        public string checkSvrFailArg = null;

        public string shareFbTexArg = null;

        public string shareFbLinkArg = null;

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
        protected override void OnInitFail()
        {
            if (App.SdkInit) return;
            base.OnInitFail();
            var msg = Phantom.Localization.Instance.GetDes(617047);
            var yes = Phantom.Localization.Instance.GetDes(690000);
            MsgBoxProxy.Instance.Show(msg, yes, App.Quit);
            MsgBoxProxy.Instance.Update();
        }


        protected void CheckSvrFail(string msg)
        {
            Log("CheckSvrFail:{0}", msg);
            checkSvrFailArg = msg;
            MonoEvent.AddOneShot(OnCheckSvrFail);
        }

        protected void OnCheckSvrFail()
        {
            EventMgr.Trigger("SdkCheckSvrFail");
        }

        protected void CheckSvrSuc(string msg)
        {
            checkSvrSucArg = msg;
            Log("CheckSvrSuc");
            MonoEvent.AddOneShot(OnCheckSvrSuc);
        }

        protected void OnCheckSvrSuc()
        {
            EventMgr.Trigger("SdkCheckSvrSuc");
        }


        protected void FBShareLink(string msg)
        {
            shareFbLinkArg = msg;
            Log("FBShareLink:{0}", msg);
            MonoEvent.AddOneShot(OnFBShareLink);
        }

        protected void OnFBShareLink()
        {
            EventMgr.Trigger("SDKFBShareLink");

        }

        protected void FBShareTex(string msg)
        {
            shareFbTexArg = msg;
            Log("FBShareTex:{0}", msg);
            MonoEvent.AddOneShot(OnFBShareTex);
        }

        protected void OnFBShareTex()
        {
            EventMgr.Trigger("SDKFBShareTex");
        }
        #endregion

        #region 公开方法

        #endregion
    }
}