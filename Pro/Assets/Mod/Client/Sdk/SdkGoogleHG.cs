
#if SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
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
    public class Sdk : SdkBase
    {
#region 字段
        private static Sdk instance = null;

        private static AndroidJavaObject ujo = null;

        // 1:google    2:oneStore  3:Samsung
        private int sdkIndex = 0;

#endregion

#region 属性
        public override int ID
        {
            get { return 25; }
        }

        public static Sdk Instance
        {
            get { return instance; }
        }

        public int SdkIndex
        {
            get { return sdkIndex; }
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
#if SDK_ANDROID_HG
            sdkIndex = 1;
#endif
#if SDK_ONESTORE_HG
            sdkIndex = 2;
#endif
#if SDK_SAMSUNG_HG
            sdkIndex = 3;
#endif
            Debug.Log("登陆SDK 渠道 sdkIndex 1:google    2:oneStore   3:三星  sdkIndex: " + sdkIndex);
        }


        protected override int GetInitResult()
        {
            return JavaUtil.CallGenneric<int>(ujo, "getInitResult", 0);
        }

        protected override void InitSdk()
        {
            base.InitSdk();
        }

#endregion

#region 公开方法


        public void OnInitSdk()
        {
            InitSdk();
        }

        //0:不变     1：登陆界面切换账号
        public void SetSwitchAccIndex(int index)
        {
            JavaUtil.Call(ujo, "setSwitchAccIndex",index);
        }

        public void OpenPermissionDialog()
        {
            JavaUtil.Call(ujo, "openPermissionDialog");
        }

        public void SetPermissionResult(int index)
        {
            string idx = index.ToString();
            JavaUtil.Call(ujo, "setInitResultSuc", idx);
        }

        public string GetUserData()
        {
            return JavaUtil.CallGenneric<string>(ujo, "getUserData","");
        }

        public int GetPermissionResult()
        {
            return JavaUtil.CallGenneric<int>(ujo, "getInitResult", 0);
        }

        public int GetLoginState()
        {
            return JavaUtil.CallGenneric<int>(ujo, "getSignInState", 0);
        }

        public void GoogleLogin()
        {
            JavaUtil.Call(ujo, "googleSignIn");
        }

        public void FacebookLogin()
        {
            JavaUtil.Call(ujo, "facebookSignIn");
        }


        public void Logout()
        {
            JavaUtil.Call(ujo, "logout");
        }

        public void DeleteAccount()
        {
            JavaUtil.Call(ujo, "deleteUser");
        }

        public void OneStoreQueryPurchase()
        {
            JavaUtil.Call(ujo, "oneStoreQueryPurchase");
        }

#if SDK_ANDROID_HG
        public void Pay(string itemID)
        {
            JavaUtil.Call(ujo, "pay", itemID);
        }

        public void GoogleAdBrixPayment(string gameOrderId,string productId,string productName,double price,int quantity)
        {
            JavaUtil.Call(ujo, "adBrixPayment", gameOrderId,productId,productName,price,quantity);
        }

        public void GoogleAdBrixEnterGame()
        {
            JavaUtil.Call(ujo, "enterGame");
        }

        public void GoogleAdBrixCreateRole()
        {
            JavaUtil.Call(ujo, "createRole");
        }

        public void GoogleAdBrixLevelUp(int level)
        {
            JavaUtil.Call(ujo, "levelUpdate", level);
        }
#endif

#if SDK_ONESTORE_HG
        public void Pay(string guid,string productId,string productName)
        {
            JavaUtil.Call(ujo, "payOneStore", guid,productId,productName);
        }
#endif

#if SDK_SAMSUNG_HG

    public void SamGetOwnedList()
        {
            JavaUtil.Call(ujo, "samGetOwnedList");
        }


    public void Pay(string itemID)
        {
            JavaUtil.Call(ujo, "samPurchaseProduct", itemID);
        }
#endif

    }
    #endregion
}

#endif