//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/10 20:06:54
// 下载OBB文件
//*****************************************************************************

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// DownObb
    /// </summary>
    public class DownObb
    {
        #region 字段


        private bool running;

        #endregion

        #region 属性

        public bool Running
        {
            get { return running; }
            set { running = value; }
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
        public void Start(object o)
        {
            Running = true;
        }


        public void Init()
        {

        }

        public void Update()
        {

        }
        #endregion
    }
}