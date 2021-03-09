//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 23:30:09
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// ResInfo
    /// </summary>
    public class ResInfo
    {
        #region 字段
        private Object obj = null;

        private bool persist = false;

        private string assetPath = null;


        #endregion

        #region 属性

        /// <summary>
        /// 资源
        /// </summary>
        public Object Obj
        {
            get { return obj; }
            set { obj = value; }
        }


        public bool Persist
        {
            get { return persist; }
            set { persist = value; }
        }


        /// <summary>
        /// 工程内路径
        /// </summary>
        public string AssetPath
        {
            get { return assetPath; }
            set { assetPath = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ResInfo()
        {

        }

        public ResInfo(Object obj, string assetPath)
        {
            this.obj = obj;
            this.assetPath = assetPath;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}