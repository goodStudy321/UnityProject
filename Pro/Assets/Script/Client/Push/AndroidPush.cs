//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/4/7 21:47:04
//=============================================================================

#if UNITY_ANDROID
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AndroidNotify
    /// </summary>
    public class AndroidPush : IPush
    {
        #region 字段
        private AndroidJavaObject jo = null;

        public static readonly AndroidPush Instance = new AndroidPush();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private AndroidPush()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Init()
        {
            jo = JavaUtil.Create("loong.notify.NoticeMgr");
        }

        public void Add(int id, string name, string title, string content, long mills, long repeat)
        {
            JavaUtil.CallStatic(jo, "add", id, name, title, content, mills, repeat);
        }

        public void AddFromNow(int id, string name, string title, string content, long mills, long repeat)
        {
            JavaUtil.CallStatic(jo, "addFromNow", id, name, title, content, mills, repeat);
        }


        public void Remove(int id)
        {
            JavaUtil.CallStatic(jo, "remove", id);
        }

        public void Save()
        {
            JavaUtil.CallStatic(jo, "save");
        }

        public void Clear()
        {
            JavaUtil.CallStatic(jo, "clear");
        }
        #endregion
    }
}
#endif