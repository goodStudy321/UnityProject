using System;
using Phantom;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        caa73b85-d25c-4228-adcb-e71832d3eda6
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/16 17:10:23
    /// BG:
    /// </summary>
    public static class SdkFty
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void Gen()
        {
            var go = new GameObject();
            go.AddComponent<Sdk>();
            go.name = "Sdk";
            GameObject.DontDestroyOnLoad(go);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Create()
        {
#if UNITY_EDITOR && LOONG_SIMULATE_SDK
            Gen();

#elif !SDK_ANDROID_NONE && !SDK_IOS_NONE
            Gen();
            iTrace.Warning("Loong", "创建SDK单例");
#elif !UNITY_EDITOR

            iTrace.Warning("Loong", "无SDK创建");
#endif
        }


        public static void Init()
        {
            BuglyMgr.Init();
            AirTest.Init();


#if UNITY_ANDROID
            Activity.Init();
            BetterStreamingAssets.Initialize();
#endif
            SdkFty.Create();
        }
        #endregion
    }
}