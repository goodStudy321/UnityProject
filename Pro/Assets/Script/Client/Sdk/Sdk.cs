/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/5/24 21:32:33
 ============================================================================*/
#if SDK_ANDROID_NONE || SDK_IOS_NONE

using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Loong.Game
{
    /// <summary>
    /// Sdk
    /// </summary>
    public class Sdk : MonoBehaviour
    {
        #region 字段

#if UNITY_EDITOR
        private int id = 3;
#else
        private int id = 1;
#endif
        #endregion

        #region 属性

        public int ID
        {
            get { return id; }
        }


        public static Sdk Instance
        {
            get { return null; }
        }
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
#if UNITY_EDITOR && LOONG_SIMULATE_SDK

        private void Update()
        {
            if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))
            {
                if (Input.GetKeyDown(KeyCode.L))
                {
                    UITip.Error("模拟SDK通过用户中心退出账号");
                    Logout();
                }
            }
        }

        public void Init()
        {
            EventMgr.Trigger("Sdk_InitSuc_1");
        }

        public void Login()
        {
            int uid = Random.Range(100000, 900000);
            EventMgr.Trigger("SdkSuc", uid.ToString());
        }

        public void Logout()
        {
            EventMgr.Trigger("LogoutSuc");
        }


#endif
        #endregion
    }
}
#endif