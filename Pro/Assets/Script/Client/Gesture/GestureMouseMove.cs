using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:鼠标滑动手势
    /// </summary>
    public class GestureMouseMove : GestureOne
    {
        #region 字段
        private float mouseX = 0;

        private float mouseY = 0;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public GestureMouseMove()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void GestureNone()
        {
            if (Input.GetMouseButtonDown(0))
            {
                Process = ProcessState.Enter;
            }
        }


        protected override void GestureEnter()
        {
            if (Input.GetMouseButton(0))
            {
                mouseX = mouseY = 0;
                deltaPos.Set(0, 0);
            }
            else
            {
                Process = ProcessState.Exit;
            }
        }

        protected override void GestureExecute()
        {
            if (Input.GetMouseButton(0))
            {
                mouseX = Input.GetAxis("Mouse X");
                mouseY = Input.GetAxis("Mouse Y");

                deltaPos.Set(mouseX, mouseY);

                if (SwipeState != OneSwipeState.None) return;

                if (mouseX != 0 || mouseY != 0)
                {
                    EvaluateSwipe();
                }
            }
            else if (Input.GetMouseButtonUp(0))
            {
                Process = ProcessState.Exit;
            }
        }

        protected override void GestureExit()
        {
            deltaPos.Set(0, 0);
            SwipeState = OneSwipeState.None;
        }
        #endregion

        #region 公开方法

        #endregion
    }
}