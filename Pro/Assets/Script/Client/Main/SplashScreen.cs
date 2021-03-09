//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/6/11 10:27:00
// 启动动画
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// SplashScreen
    /// </summary>
    public class SplashScreen
    {
        #region 字段
        private GameObject splashGo = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public event Action CompleteEvent = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Complete()
        {
            if (CompleteEvent != null) CompleteEvent();
            CompleteEvent = null;
        }

        private IEnumerator Begin()
        {
            var info = App.Info;
            var tm = (info == null ? 1 : info.SplashTime);
            yield return new WaitForSeconds(tm);
            GameObject.DestroyImmediate(splashGo);
            Complete();
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 开始
        /// </summary>
        /// <param name="complete">结束回调</param>
        public void Start(Action complete)
        {
            if (complete != null) CompleteEvent += complete;
            if (splashGo == null)
            {
                Complete();
            }
            else
            {
                MonoEvent.Start(Begin());
            }

        }

        public void Init()
        {
            var root = GameObject.Find("UI Root");
            if (root == null) return;
            var target = "Splash";
            splashGo = TransTool.Find(root, target, target);
            if (splashGo == null) return;
            var at = EnableSplash();
            if (!at) GameObject.DestroyImmediate(splashGo);
        }

        public void Dispose()
        {
            if (splashGo != null)
            {
                GameObject.DestroyImmediate(splashGo);
            }
        }

        public void SetActive(bool active)
        {
            if (splashGo == null) return;
            splashGo.SetActive(active);
        }

        public bool EnableSplash()
        {
            var at = (App.Info == null ? true : (App.Info.SplashTime > 0));
            return at;
        }
        #endregion
    }
}