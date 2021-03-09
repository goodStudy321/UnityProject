//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/4 12:24:08
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Phantom
{
    /// <summary>
    /// AirTest
    /// </summary>
    public static class AirTest
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

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
#if GAME_DEBUG && ENABLE_AIRTEST
            var go = new GameObject(typeof(PocoManager).Name);
            GameObject.DontDestroyOnLoad(go);
            var mgr = go.AddComponent<PocoManager>();
            mgr.port = 5001;
            Debug.LogFormat("Loong, airtest init with port:{0}", mgr.port);
#endif
        }
        #endregion
    }
}