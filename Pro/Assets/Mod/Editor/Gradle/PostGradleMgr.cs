//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/1 14:35:58
//*****************************************************************************

using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// Gradle后处理管理器
    /// </summary>
    public class PostGradleMgr
    {
        #region 字段
        private PostGradle cur = null;

        public static readonly PostGradleMgr Instance = new PostGradleMgr();
        #endregion

        #region 属性
        /// <summary>
        /// 当前后处理
        /// </summary>
        public PostGradle Cur
        {
            get
            {
                if (cur == null) cur = Create();
                return cur;
            }
            set { cur = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private PostGradleMgr()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static PostGradle Create()
        {

#if SDK_ANDROID_GAT
            return new PostGradleJingQi();
#elif SDK_ANDROID_HG || SDK_ONESTORE_HG || SDK_SAMSUNG_HG
            return new PostGradleHG();
#else
            return null;
#endif
        }

        public void OnPostGradle(string path)
        {
            if (Cur != null) Cur.OnPostGradle(path);
        }
        #endregion
    }
}