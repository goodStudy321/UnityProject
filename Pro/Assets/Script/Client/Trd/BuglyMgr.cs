/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/24 12:27:58
 ============================================================================*/

using System;
using UnityEngine;
using Phantom.Protocal;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// BuglyMgr
    /// </summary>
    public static class BuglyMgr
    {
        #region 字段
        private static bool isInit = false;

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static bool IsOpen()
        {
            var res = true;
            string num = string.Empty;
            var cfg = GlobalDataManager.instance.Find(199);
            if (cfg != null)
            {
                num = cfg.num1;
                if (!string.IsNullOrEmpty(num))
                {
                    res = num == "1";
                }
            }
            else
            {
                res = false;
            }

            iTrace.Log("bugly", "{0}, cfg:{1}", res ? "开启" : "关闭", num ?? string.Empty);
            return res;
        }

        private static void RespLogin(object obj)
        {

            User user = User.instance;
            ActorData data = user.MapData;
            string id = data.UID.ToString();
            BuglyAgent.SetUserId(id);

            iTrace.Log("bugly", "m_role_login_toc    id: " + id);
        }

        private static void Enable()
        {
            if (isInit) return;
            if (!IsOpen()) return;
            isInit = true;
#if !UNITY_EDITOR
#if UNITY_IOS || UNITY_IPHONE
            string appID = null;
#if SDK_IOS_GAT
            appID = "cc963ad390";
#else
            appID = "0b99c1d604";
#endif
            BuglyAgent.InitWithAppId(appID);
#endif
            BuglyAgent.EnableExceptionHandler();
            NetworkListener.Add<m_role_login_toc>(RespLogin);
#endif
        }

        private static void LoadGloabData()
        {
            try
            {
                if (AssetPath.ExistInPersistent)
                {
                    GlobalDataManager.instance.Load(FileLoader.Home);
                }
            }
            catch (Exception)
            {


            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
            LoadGloabData();
            Enable();
            GlobalDataManager.instance.Clear();
        }


        public static void Restart()
        {
            Enable();
        }
        #endregion
    }
}