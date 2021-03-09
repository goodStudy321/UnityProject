using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:一个手指手势
    /// </summary>
    public class GestureOneFigure : GestureOne
    {
        #region 字段
        /// <summary>
        /// 触摸
        /// </summary>
        private Touch touch;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public GestureOneFigure()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void GestureNone()
        {
            if (Input.touchCount != 1) return;
            Process = ProcessState.Enter;
        }


        protected override void GestureEnter()
        {
            if (Input.touchCount == 1)
            {
                touch = Input.GetTouch(0);
            }
            else
            {
                Process = ProcessState.Exit;
            }
        }

        protected override void GestureExecute()
        {
            if (Input.touchCount == 1)
            {
                touch = Input.GetTouch(0);
                if (touch.phase == TouchPhase.Moved)
                {
                    deltaPos.Set(touch.deltaPosition.x, touch.deltaPosition.y);
                    if (SwipeState != OneSwipeState.None) return;

                    if (deltaPos.x != 0 || deltaPos.y != 0)
                    {
                        EvaluateSwipe();
                    }
                }
            }
            else
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