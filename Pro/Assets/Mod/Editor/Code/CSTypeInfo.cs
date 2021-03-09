//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/27 0:09:38
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// CSTypeInfo
    /// </summary>
    public class CSTypeInfo
    {
        #region 字段
        private CSType type;

        private string name;

        private string defaultVal;
        #endregion

        #region 属性

        public CSType Type
        {
            get { return type; }
            set { type = value; }
        }


        public string Name
        {
            get { return name; }
            set { name = value; }
        }



        public string Default
        {
            get { return defaultVal; }
            set { defaultVal = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public CSTypeInfo(CSType type, string name, string defaultVal)
        {
            this.type = type;
            this.name = name;
            this.defaultVal = defaultVal;
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