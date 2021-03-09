//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/4 22:44:48
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Phantom
{
    /// <summary>
    /// OnTrigger
    /// </summary>
    public class OnTrigger : MonoBehaviour
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public event Action<Collider> enter;

        public event Action<Collider> exit;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void OnTriggerEnter(Collider other)
        {
            if (enter != null) enter(other);
        }

        private void OnTriggerExit(Collider other)
        {
            if (exit != null) exit(other);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}