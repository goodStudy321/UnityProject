using System;
using System.IO;
using Hello.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

namespace Hello.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        7d1a7aca-5e49-4fc2-9bb8-30023281643d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/11/13 17:30:37
    /// BG:应用程序
    /// </summary>
    public static class App
    {
        #region 字段
        private static string ver = null;
        private static string bsUrl = null;
        private static string bundleID = null;
        private static int assetVer = 0;
        private static bool sdkInit = false;
        private static bool cancelUpg = false;
        private static bool firstInstall = false;
        private static bool isDebug = false;
        private static bool isEditor = false;
        private static bool isAndroid = false;
        private static bool isIOS = false;
        //private static AppInfo info = null;
        #endregion

        #region 属性

        /// <summary>
        /// 服务器选项
        /// 0:默认
        /// 1:评测
        /// </summary>
        public static int SvrOp
        {
            get
            {
#if SVR_OP_EVALUATION
                return 1;
#else
                return 0;
#endif
            }
        }

        //public static AppInfo Info
        //{
        //    get { return info; }
        //}


        public static bool IsDebug
        {
            get { return isDebug; }
        }

        /// <summary>
        /// true:正式环境下调试
        /// </summary>
        public static bool IsReleaseDebug
        {
            get { return false; }
        }

        public static bool IsEditor
        {
            get { return isEditor; }
        }

        public static bool IsAndroid
        {
            get { return isAndroid; }
        }

        public static bool IsIOS
        {
            get { return isIOS; }
        }

        public static bool LuaDebug
        {
            get
            {
#if LUA_DEBUG
                return true;
#else
                return false;
#endif
            }
        }

        /// <summary>
        /// 平台属性
        /// </summary>
        public static int platform
        {
            get
            {
#if UNITY_EDITOR
                return 0;
#elif UNITY_ANDROID
				return 1;
#elif UNITY_IOS || UNITY_IPHONE
				return 2;
#else
				return 3;
#endif
            }
        }

        /// <summary>
        /// 版本号/VersionName
        /// </summary>
        public static string Ver
        {
            get { return ver; }
        }

        /// <summary>
        /// 内部版本号
        /// </summary>
        public static int VerCode
        {
            get { return 0; }
        }

        /// <summary>
        /// 资源版本号
        /// </summary>
        public static int AssetVer
        {
            get { return assetVer; }
            set { assetVer = value; }
        }

        /// <summary>
        /// true:SDK是否初始化
        /// </summary>
        public static bool SdkInit
        {
            get { return sdkInit; }
            set { sdkInit = value; }
        }


        /// <summary>
        /// 有安装包更新时,若玩家取消更新,则为true
        /// </summary>
        public static bool CancelUpg
        {
            get { return cancelUpg; }
            set { cancelUpg = value; }
        }

        /// <summary>
        /// true:首次安装
        /// </summary>
        public static bool FirstInstall
        {
            get { return firstInstall; }
            set { firstInstall = value; }
        }

        public static string WwwStreaming
        {
            get
            {
                return AssetPath.WwwStreaming;
            }
        }


        /// <summary>
        /// true:资源分包
        /// </summary>
        public static bool IsSubAssets
        {
            get
            {
#if LOONG_SUB_ASSET
                return true;
#else
                return false;
#endif
            }
        }

        /// <summary>
        /// 渠道ID
        /// </summary>
        [NoToLua]
        public static string ChannelID
        {
            get
            {
                //return User.instance.ChannelID;
                return "";
            }
            //set
            //{
            //    User.instance.ChannelID = value;
            //}
        }

        /// <summary>
        /// 渠道ID
        /// </summary>
        [NoToLua]
        public static string GameChannelID
        {
            get
            {
                //return User.instance.GameChannelId;
                return "";
            }
            //set
            //{
            //    User.instance.GameChannelId = value;
            //}
        }

        [NoToLua]
        public static string BSUrl
        {
            get { return bsUrl; }
        }


        public static string BundleID
        {
            get { return bundleID; }
        }


        public static int Pkg
        {
            get { return (int)(0); }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static void SetInfo()
        {
//            var path = AssetPath.WwwStreaming + "AppInfo.xml";
//            info = XmlTool.DeserializerByWWWLoad<AppInfo>(path);
//            ChannelID = info.CID;
//            GameChannelID = info.GCID;
//#if UNITY_EDITOR
//            Fps.Create();
//#else
//            if (info.EnableFps) Fps.Create();
//#endif
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        [NoToLua]
        public static void Init()
        {
            SetInfo();
            ver = Application.version;
            isDebug = Debug.isDebugBuild;
            isEditor = Application.isEditor;
            bundleID = Application.identifier;
            var plat = Application.platform;
            isAndroid = (plat == RuntimePlatform.Android);
            isIOS = (plat == RuntimePlatform.IPhonePlayer);
            //MemUtil.Snap();
            //AppEvent.Init();
            //ScreenUtil.Init();
            //ThreadUtil.Init();
            SetBSUrl();
        }

        [NoToLua]
        public static void SetBSUrl()
        {
            //var domainCfg = DomainCfgManager.instance;
            //var path = Application.persistentDataPath + "/table/" + domainCfg.source;
            //bool hasCfg = false;
            //if (File.Exists(path))
            //{
            //    try
            //    {
            //        domainCfg.Load("table");
            //        ushort k = 1;
            //        var cfg = domainCfg.Find(k);
            //        if (cfg != null)
            //        {
            //            hasCfg = true;
            //            if (IsEditor)
            //            {
            //                bsUrl = cfg.inter;
            //            }
            //            else if (IsReleaseDebug)
            //            {
            //                bsUrl = cfg.exter.Trim();
            //            }
            //            else if (IsDebug)
            //            {
            //                bsUrl = cfg.exterTest.Trim();
            //            }
            //            else
            //            {
            //                bsUrl = cfg.exter.Trim();
            //            }
            //        }
            //    }
            //    catch (Exception e)
            //    {
            //        Debug.LogErrorFormat("Loong,Load DomainCfg err:{0}", e.Message);
            //    }
            //}
            //if (!hasCfg)
            //{
            //    if (IsEditor)
            //    {
            //        bsUrl = "http://192.168.2.250:82/";
            //    }
            //    else if (IsReleaseDebug)
            //    {
            //        bsUrl = "http://api-tdwq.originmood.com/";
            //    }
            //    else if (IsDebug)
            //    {
            //        bsUrl = "http://api-tdwq-test.originmood.com/";
            //    }
            //    else
            //    {
            //        bsUrl = "http://api-tdwq.originmood.com/";
            //    }
            //}
            if (IsDebug)
            {
                Debug.LogFormat("Loong, cs bsUrl:{0}", BSUrl);
            }
        }

        [NoToLua]
        public static void Refresh()
        {
            SetBSUrl();
        }




        [NoToLua]
        public static void Quit()
        {
            Debug.Log("Loong, Quit Game!");
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }


        /// <summary>
        /// 重新启动
        /// </summary>
        public static void Restart()
        {
#if UNITY_EDITOR

            Debug.LogWarning("Loong, Restart not support");
#elif UNITY_ANDROID
            try
            {
                using (var jo = new AndroidJavaObject("loong.lib.AppUtil"))
                {
                    jo.CallStatic("restartBySvs", 100);
                }
            }
            catch (Exception e)
            {

                Debug.LogErrorFormat("Loong, restart err:{0}", e.Message);
            }

#else
             Quit();
#endif
        }

        #endregion
    }
}