//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/3/12 17:55:28
//*****************************************************************************
#if SDK_IOS_GAT
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Loong.Game
{
    /// <summary>
    /// SdkGatiOS
    /// </summary>
    public class Sdk : SdkGat
    {
#region 字段
        private static Sdk instance = null;


#endregion

#region 属性
        public override int ID
        {
            get { return 19; }
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
            SetBSUrl(App.BSUrl, "index/Hmt/auth");
        }

        protected void NeedRelogin(string msg)
        {
            Log("NeedRelogin");
            MonoEvent.AddOneShot(OnNeedRelogin);
        }

        protected void OnNeedRelogin()
        {
            EventMgr.Trigger("SdkNeedRelogin");
        }

        protected override int GetInitResult()
        {
            return GetInitOP();
        }


#endregion

#region 公开方法
        /// <summary>
        /// 请求登陆
        /// </summary>
        [DllImport("__Internal")]
        public static extern void Login();


        /// <summary>
        /// 请求登出
        /// </summary>
        [DllImport("__Internal")]
        public static extern void Logout();

        /// <summary>
        /// 伺服器校验
        /// </summary>
        [DllImport("__Internal")]
        public static extern void CheckSvr(string svrID);

        [DllImport("__Internal")]
        public static extern void SetBSUrl(string url, string login);


        /// <summary>
        /// 创建角色
        /// roleName
        /// roleID
        /// </summary>
        [DllImport("__Internal")]
        public static extern void UploadRoleCreate(string roleName, string roleID);


        /// <summary>
        /// 选择角色
        /// roleName
        /// roleID
        /// lv
        /// </summary>
        [DllImport("__Internal")]
        public static extern void UploadRoleSelect(string roleName, string roleID, string lv);

        /// <summary>
        /// 开始游戏
        /// </summary>
        [DllImport("__Internal")]
        public static extern void UploadBegGame();

        /// <summary>
        /// 会员中心
        /// </summary>
        [DllImport("__Internal")]
        public static extern void UserCenter();

        /// <summary>
        /// 请求支付
        /// </summary>
        /// <param name="json">appleProID</param>
        [DllImport("__Internal")]
        public static extern void Pay(string json);


        [DllImport("__Internal")]
        public static extern int GetInitOP();

        /// <summary>
        /// 分享链接
        /// </summary>
        /// <param name="link">链接</param>
        [DllImport("__Internal")]
        public static extern void ShareFbLink(string link);

        /// <summary>
        /// 分享图片
        /// </summary>
        /// <param name="persist">沙盒/持久化目录</param>
        /// <param name="streaming">流目录</param>
        /// <param name="name">图片名</param>
        [DllImport("__Internal")]
        public static extern void ShareFbTex(string persist, string streaming, string name);

        [DllImport("__Internal")]
        public static extern void Kefu();


        /// <summary>
        /// 日志埋点/无参数
        /// </summary>
        /// <param name="name">事件名称</param>
        [DllImport("__Internal")]
        public static extern void LogEvent(string name);

        /// <summary>
        /// 日志埋点
        /// </summary>
        /// <param name="name">事件名称</param>
        /// <param name="k">参数名</param>
        /// <param name="v">参数值</param>
        [DllImport("__Internal")]
        public static extern void LogEvent1(string name, string k, string v);
#endregion
    }
}
#endif