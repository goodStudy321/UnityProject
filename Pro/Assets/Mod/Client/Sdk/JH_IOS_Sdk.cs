//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2018/8/20 17:52:15
// 君海iOSSDK
//=============================================================================

#if UNITY_IOS && SDK_IOS_JUNHAI

namespace Loong.Game
{
    using System;
    using UnityEngine;
    using System.Runtime.InteropServices;


    public class Sdk : SdkBase
    {
        private static Sdk instance = null;

        public override int ID
        {
            get { return 3; }
        }

        public static Sdk Instance
        {
            get { return instance; }
        }

        protected override void Awake()
        {
            instance = this;
            base.Awake();
#if !UNITY_EDITOR
            init();
#endif
            setBSUrl(App.BSUrl);
        }

        protected override void OnInitSuc()
        {
            if (App.SdkInit) return;
            App.SdkInit = true;
            base.OnInitSuc();
        }

        /// <summary>
        /// 初始化
        /// </summary>
        [DllImport("__Internal")]
        public static extern void init();

        /// <summary>
        /// 请求登陆
        /// </summary>
        [DllImport("__Internal")]
        public static extern void login();


        /// <summary>
        /// 请求登出
        /// </summary>
        [DllImport("__Internal")]
        public static extern void logout();

        [DllImport("__Internal")]
        public static extern void setBSUrl(string json);

        /// <summary>
        /// 请求支付
        /// json数据应该包含如下字段
        /// ordID:订单号(string)
        /// money:总金额(int),单位为分
        /// count:商品数量(int)
        /// proID:商品ID(string)
        /// proName:商品名称(string)
        /// rate:兑换比率(int),即1元可以买多少商品
        /// desc:订单详细信息(string)
        /// url:充值回调地址(string)
        /// roleID:角色id(string)
        /// svrName:区服名称(string)
        /// svrID:区服ID(int)
        /// roleName:角色名(string)
        /// appleProID:苹果后台申请到的商品编码(string)
        /// </summary>
        /// <param name="json">Json.</param>
        [DllImport("__Internal")]
        public static extern void pay(string json);

        /// <summary>
        /// 当进入服务器时上传数据
        /// json数据应该包含如下字段
        /// roleID:角色ID(string)
        /// svrID:区服ID(int)
        /// svrName:区服名称(string)
        /// roleName:角色名(string)
        /// vipLv:VIP等级(int)
        /// coinCount:游戏币数量(long)
        /// coinName:游戏币名称(string)
        /// roleLv:角色等级
        /// </summary>
        /// <param name="json">Json.</param>
        [DllImport("__Internal")]
        public static extern void updataOnEnterSvr(string json);

        /// <summary>
        /// 当角色升级时上传数据
        /// json数据,字段同上
        /// </summary>
        /// <param name="json">Json.</param>
        [DllImport("__Internal")]
        public static extern void updataOnRoleUpg(string json);
    }
}
#endif