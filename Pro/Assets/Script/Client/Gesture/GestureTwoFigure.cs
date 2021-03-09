using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:两个手指手势
    /// </summary>
    public class GestureTwoFigure : GestureTwo
    {
        #region 字段
        /// <summary>
        /// 手指1
        /// </summary>
        private Touch touch1;

        /// <summary>
        /// 手指2
        /// </summary>
        private Touch touch2;

        /// <summary>
        /// 手指之间当前距离
        /// </summary>
        private float curDistance = 0;

        /// <summary>
        /// 手指之间上一次距离
        /// </summary>
        private float lastDistance = 0;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public GestureTwoFigure()
        {

        }
        #endregion

        #region 私有方法


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        protected override void GestureNone()
        {
            if (Input.touchCount != 2) return;
            Process = ProcessState.Enter;

        }
        protected override void GestureEnter()
        {
            if (Input.touchCount < 2)
            {
                Process = ProcessState.None;
            }
            else
            {
                Ratio = 0;
                touch1 = Input.GetTouch(0);
                touch2 = Input.GetTouch(1);
                curDistance = Vector2.Distance(touch1.position, touch2.position);
                lastDistance = curDistance;
            }
        }

        protected override void GestureExecute()
        {
            if (Input.touchCount < 2)
            {
                Process = ProcessState.Exit;
            }
            else
            {
                touch1 = Input.GetTouch(0);
                touch2 = Input.GetTouch(1);
                curDistance = Vector2.Distance(touch1.position, touch2.position);
                Ratio = curDistance - lastDistance;
                Ratio *= Time.unscaledDeltaTime * 0.5f;
                Ratio = ((Ratio > -0.01f) && (Ratio < 0.01f)) ? 0 : Ratio;
                lastDistance = curDistance;
            }
        }

        protected override void GestureExit()
        {
            Ratio = 0;
        }
        #endregion
    }
}