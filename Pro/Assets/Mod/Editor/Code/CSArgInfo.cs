//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/26 22:29:58
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// CSArgInfo
    /// </summary>
    public class CSArgInfo
    {
        #region 字段
        private string type;
        private string name;

        #endregion

        #region 属性

        public string Type
        {
            get { return type; }
            set { type = value; }
        }


        public string Name
        {
            get { return name; }
            set { name = StrUtil.FirstLower(value); }
        }


        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public CSArgInfo()
        {

        }

        public CSArgInfo(string type, string name)
        {
            this.type = type;
            Name = name;
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