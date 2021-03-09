//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/19 23:15:58
// 所有方法int类型的返回值,具有如下定义
// 0: Suc               调用API成功
// 1: ErrUnknown        未知错误
// 2: ReLogin           重复登录
// 3: UnLogin           未登录
// 4: PurchaseUnFinish  上一次订单未完成
// 5: ErrParams         参数错误
// 6: ErrQQAuthNotSup   QQ授权登录不支持
// 7: ErrWXAuthNotSup   微信授权登录不支持
// 8: ErrQYAuthNotSup   爱奇艺授权登录不支持
// 9: ErrReBindPhone    已绑定手机
//=============================================================================
#if UNITY_IOS && SDK_IOS_IQIYI
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace Loong.Game
{
    /// <summary>
    /// IQIYI_IOS_Sdk
    /// </summary>
    public class Sdk : SdkBase
    {
#region 字段
        private string bindArg;
        private string bindPhoneSucArg;
        private static Sdk instance = null;
#endregion

#region 属性
        public override int ID
        {
            get { return 2; }
        }

        /// <summary>
        /// 游客绑定成功参数
        /// </summary>
        public string BindArg
        {
            get { return bindArg; }
            set { bindArg = value; }
        }

        public string BindPhoneSucArg
        {
            get { return bindPhoneSucArg; }
            set { bindPhoneSucArg = value; }
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


        private void Start()
        {
            var op = GetInitOP();
            if (op == 1)
            {
                OnInitSuc();
            }
            else if (op == 2)
            {
                OnInitFail();
            }
        }


        private void BindPhoneSuc(string arg)
        {
            bindPhoneSucArg = arg;
            MonoEvent.AddOneShot(OnBindPhoneSuc);
        }

        private void OnBindPhoneSuc()
        {
            EventMgr.Trigger("SDK_BindPhoneSuc", bindPhoneSucArg);
        }

        private void BindPhoneFail(string arg)
        {
            MonoEvent.AddOneShot(OnBindPhoneFail);
        }

        private void OnBindPhoneFail()
        {
            EventMgr.Trigger("SDK_BindPhoneFail");
        }

        /// <summary>
        /// 游客绑定回调
        /// </summary>
        private void DidBindMessage(string arg)
        {
            bindArg = arg;
            MonoEvent.AddOneShot(OnDidBindMessage);
        }


        private void OnDidBindMessage()
        {
            EventMgr.Trigger("SDK_DidBindMsg", bindArg);
        }
#endregion

#region 保护方法
        protected override void Awake()
        {
            instance = this;
            base.Awake();
            SetBSUrl(App.BSUrl);

        }

        protected override void OnInitSuc()
        {
            if (App.SdkInit) return;

            App.SdkInit = true;
            base.OnInitSuc();
        }

#endregion

#region 公开方法

        [DllImport("__Internal")]
        public static extern int Login();

        [DllImport("__Internal")]
        public static extern int Logout();

        /// <summary>
        /// svrID   服务器ID,必须是大于0的整数
        /// roleID  用户角色ID
        /// money   商品金额
        /// proID   商品ID
        /// ordID   订单ID
        /// devInfo 游戏透传信息
        /// </summary>
        /// <param name="json"></param>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int Pay(string json);

        /// <summary>
        /// 显示悬浮窗
        /// </summary>
        /// <param name="x">0:左1:右</param>
        /// <param name="y">0-100</param>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int ShowFloat(int x, int y);

        /// <summary>
        /// 隐藏悬浮窗
        /// </summary>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int HideFloat();

        /// <summary>
        /// 创建角色上传
        /// </summary>
        /// <param name="svrID">服务器ID</param>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int UpdataOnRoleCreate(string svrID);

        /// <summary>
        /// 进入地图上传
        /// </summary>
        /// <param name="svrID">服务器ID</param>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int UpdataOnSceneEnter(string svrID);

        /// <summary>
        /// 通知SDK绑定结果
        /// Code
        /// 100 绑定成功
        /// 101 绑定失败,同一区服不能存在相同角色
        /// 102 绑定失败,同一区服不能存在多个角色
        /// 103 该手机号绑定数量超过限制
        /// 104 不允许绑定
        /// 105 网络异常
        /// </summary>
        /// <param name="json"></param>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int NotifyBind(string json);

        [DllImport("__Internal")]
        public static extern int BindPhone();

        /// <summary>
        /// 获取初始化结果
        /// </summary>
        /// <returns></returns>
        [DllImport("__Internal")]
        public static extern int GetInitOP();

        [DllImport("__Internal")]
        public static extern void SetBSUrl(string url);
#endregion
    }
}
#endif