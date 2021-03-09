//=============================================================================
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2018/3/16 17:10:15
// 君海AndroidSDK
//=============================================================================

#if UNITY_ANDROID && SDK_ANDROID_JUNHAI
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Phantom.Protocal;

namespace Loong.Game
{

    public class Sdk : SdkBase
    {

        #region 字段
        private bool hasUC = false;
        private string ucArg = "";

        private string channelInfo = null;
        private string realNameInfo = "";


        private AndroidJavaObject jo = null;

        private static Sdk instance = null;
        #endregion

        #region 属性

        public override int ID
        {
            get { return 3; }
        }

        /// <summary>
        /// true:有用户中心
        /// </summary>
        public bool HasUC
        {
            get { return hasUC; }
        }

        /// <summary>
        /// 渠道信息
        /// channel_id & game_channel_id
        /// </summary>
        public string ChannelInfo
        {
            get { return channelInfo; }
        }


        /// <summary>
        /// 实名制信息
        /// </summary>
        public string RealNameInfo
        {
            get { return realNameInfo; }
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
            if (Application.isEditor) return;

            using (var jc = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
            {
                jo = jc.GetStatic<AndroidJavaObject>("currentActivity");
            }
            if (jo == null)
            {
                iTrace.Error("Loong", "currentActivity为空");
            }
            SetBSUrl();


        }

        /// <summary>
        /// 获取初始化结果
        /// 0:未初始化
        /// 1:初始化成功
        /// 2:初始化失败
        /// </summary>
        /// <returns></returns>
        private void SetInitResult()
        {
            if (Application.isEditor) return;
            using (var sdk = new AndroidJavaObject("phantom.lib.Sdk"))
            {
                sdk.CallStatic("setCanSendInit");
            }
        }

        private void SetChannelInfo(string arg)
        {
            if (!string.IsNullOrEmpty(arg))
            {
                var arr = arg.Split('|');
                if (arr.Length < 2) return;
                User.instance.ChannelID = arr[0];
                User.instance.GameChannelId = arr[1];
            }
            channelInfo = (arg == null) ? " " : arg;
        }

        /// <summary>
        /// 获取实名制信息
        /// </summary>
        /// <param name="arg">1:OK,2:UNKNOWN,3:NEVER</param>
        private void GetPlayerInfo(string arg)
        {
            realNameInfo = arg;
            MonoEvent.AddOneShot(OnGetPlayerInfo);
        }

        private void OnGetPlayerInfo()
        {
            iTrace.Log("Loong", "Unity 接受junhai sdk实名制信息:" + realNameInfo);
            EventMgr.Trigger("GetRealNameInfo");
        }

        /// <summary>
        /// 判断是否有用户中心回调
        /// </summary>
        /// <param name="arg"></param>
        private void HasUserCenterCb(string arg)
        {
            iTrace.Log("XGY", "Unity 接受junhai sdk用户中心回调:" + arg);
            if (arg == null) return;
            hasUC = ((arg == "1") ? true : false);
        }

        /// <summary>
        /// 打开用户中心回调 
        /// </summary>
        /// <param name="arg">"1":打开成功,"2":打开失败,"0/其他":无</param>
        private void OpenUserCenterCb(string arg)
        {
            ucArg = arg;
            MonoEvent.AddOneShot(OnOpenUserCenter);
        }

        private void OnOpenUserCenter()
        {
            EventMgr.Trigger("OnOpenUserCenter", ucArg);
        }

        private void readyExit(string arg)
        {
            MonoEvent.AddOneShot(ReadyExitHandler);
        }

        private void ReadyExitHandler()
        {
            EventMgr.Trigger("readyExit");
        }
        #endregion

        #region 保护方法

        protected override void Awake()
        {
            instance = this;
            base.Awake();
            SetInitResult();
        }

        protected override void InitSuc(string arg)
        {
            SetChannelInfo(arg);
            base.InitSuc(arg);

        }

        protected override void OnInitSuc()
        {
            HasUserCenter();
            App.SdkInit = true;
            base.OnInitSuc();
        }

        #endregion

        #region 公开方法
        public bool Check()
        {
            return !Application.isEditor;
        }

        /// <summary>
        /// 登陆
        /// </summary>
        public void Login()
        {
            if (!Check()) return;
            jo.Call("login");
        }


        /// <summary>
        /// 登出
        /// </summary>
        public void Logout()
        {
            if (!Check()) return;
            jo.Call("logout");
        }

        public void SetBSUrl()
        {
            if (!Check()) return;
            jo.Call("setBSUrl", App.BSUrl);
        }

        /// <summary>
        /// 判断是否有用户中心/论坛
        /// </summary>
        public void HasUserCenter()
        {
            if (!Check()) return;
            jo.Call("hasUserCenter");
        }

        /// <summary>
        /// 打开用户中心/论坛
        /// </summary>
        public void OpenUserCenter()
        {
            if (!Check()) return;
            jo.Call("openUserCenter");
        }

        /// <summary>
        /// 购买
        /// </summary>
        /// <param name="oId">订单号</param>
        /// <param name="roleID">玩家角色id</param>
        /// <param name="roleName">玩家角色名</param>
        /// <param name="svrId">区服id</param>
        /// <param name="proName">商品名,名称前请不要添加任何量词.如钻石,月卡即可</param>
        /// <param name="proID">商品ID</param>
        /// <param name="des">商品描述信息</param>
        /// <param name="cnt">购买的商品数量</param>
        /// <param name="money">支付金额,单位为分</param>
        /// <param name="url">支付结果回调地址</param>
        public void Buy(string oId, string roleID, string roleName,
                    string svrId, string proName, string proID,
                    string des, int cnt, int money, string url)
        {
            if (!Check()) return;
            try
            {
                jo.Call("buy", oId, roleID, roleName, svrId, proName, proID, des, cnt, money, url);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK支付接口失败,err:" + e.Message);
            }
        }


        /// <summary>
        /// 上传数据当进入服务器时
        /// </summary>
        /// <param name="svrID">区服id</param>
        /// <param name="svrName">区服名字</param>
        /// <param name="roleID">角色id</param>
        /// <param name="roleName">角色名</param>
        /// <param name="roleLv">角色等级</param>
        /// <param name="vipLv">VIP 等级</param>
        /// <param name="totalCoin">玩家游戏币总额,如 100 金币</param>
        /// <param name="familyName">帮派,公会名称. 若无,填unknown</param>
        /// <param name="roleCreateTm">角色创建的服务器时间,无填-1</param>
        /// <param name="roleUpgLvTm">角色升级的服务器时间,无填-1</param>
        public void uploadOnEnterSvr(string svrID, string svrName, string roleID,
                                 string roleName, int roleLv, int vipLv, long totalCoin,
                                 string familyName, int careerLv, long roleCreateTm, long roleUpgLvTm)
        {
            if (!Check()) return;
            try
            {
                jo.Call("uploadOnEnterSvr", svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, careerLv, roleCreateTm, roleUpgLvTm);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK:uploadOnEnterSvr,err:" + e.Message);
            }
        }

        /// <summary>
        /// 上传数据当创建角色时,参数同上
        /// </summary>
        /// <param name="svrID"></param>
        /// <param name="svrName"></param>
        /// <param name="roleID"></param>
        /// <param name="roleName"></param>
        /// <param name="roleLv"></param>
        /// <param name="vipLv"></param>
        /// <param name="totalCoin"></param>
        /// <param name="familyName"></param>
        /// <param name="roleCreateTm"></param>
        /// <param name="roleUpgLvTm"></param>
        public void uploadOnCreateRole(string svrID, string svrName, string roleID,
                                 string roleName, int roleLv, int vipLv, long totalCoin,
                                 string familyName, int careerLv, long roleCreateTm, long roleUpgLvTm)
        {
            if (!Check()) return;
            try
            {
                jo.Call("uploadOnCreateRole", svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, careerLv, roleCreateTm, roleUpgLvTm);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK:uploadOnCreateRole,err:" + e.Message);
            }
        }

        /// <summary>
        /// 上传数据当角色升级时,参数同上
        /// </summary>
        /// <param name="svrID"></param>
        /// <param name="svrName"></param>
        /// <param name="roleID"></param>
        /// <param name="roleName"></param>
        /// <param name="roleLv"></param>
        /// <param name="vipLv"></param>
        /// <param name="totalCoin"></param>
        /// <param name="familyName"></param>
        /// <param name="roleCreateTm"></param>
        /// <param name="roleUpgLvTm"></param>
        public void uploadOnRoleUpgLv(string svrID, string svrName, string roleID,
                                 string roleName, int roleLv, int vipLv, long totalCoin,
                                 string familyName, int careerLv, long roleCreateTm, long roleUpgLvTm)
        {
            if (!Check()) return;
            try
            {
                jo.Call("uploadOnRoleUpgLv", svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, careerLv, roleCreateTm, roleUpgLvTm);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK:uploadOnRoleUpgLv,err:" + e.Message);
            }
        }

        public void uploadExit(string svrID, string svrName, string roleID,
                                 string roleName, int roleLv, int vipLv, long totalCoin,
                                 string familyName, int careerLv, long roleCreateTm, long roleUpgLvTm)
        {
            if (!Check()) return;
            try
            {
                jo.Call("uploadExit", svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, careerLv, roleCreateTm, roleUpgLvTm);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK:uploadExit,err:" + e.Message);
            }
        }


        /// <summary>
        /// 上传购买道具统计数据
        /// </summary>
        /// <param name="con">购买道具所花费的游戏币</param>
        /// <param name="conBind">购买道具所花费的绑定游戏币</param>
        /// <param name="remain">剩余多少游戏币</param>
        /// <param name="remainBind">剩余多少绑定游戏币</param>
        /// <param name="cnt">购买道具的数量</param>
        /// <param name="name">道具名称</param>
        /// <param name="des">道具描述,可以传空串</param>
        public void uploadBuyData(int con, int conBind, long remain,
                              long remainBind, int cnt, string name, string des)
        {
            if (!Check()) return;
            try
            {
                jo.Call("uploadBuyData", con, conBind, remain, remainBind, cnt, name, des);
            }
            catch (Exception e)
            {
                iTrace.Error("Loong", "调用SDK:uploadBuyData,err:" + e.Message);
            }
        }
        #endregion

        #region 事件

        #endregion
    }


}
#endif