using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:一个手势基类
    /// </summary>
    public abstract class GestureOne : GestureBase
    {
        #region 字段
        private OneSwipeState swipeState = OneSwipeState.None;

        protected Vector2 deltaPos = Vector2.zero;

        #endregion

        #region 属性

        /// <summary>
        /// 移动中,只有X和Y任意值发生改变时才会设为true
        /// </summary>
        public bool Moveing
        {
            get
            {
                if (deltaPos.x != 0) return true;
                if (deltaPos.y != 0) return true;
                return false;
            }
        }
        /// <summary>
        /// 在屏幕上的位置增量
        /// </summary>
        public Vector2 DeltaPos
        {
            get { return deltaPos; }
        }

        /// <summary>
        /// 滑动状态
        /// </summary>
        public OneSwipeState SwipeState
        {
            get { return swipeState; }
            protected set { swipeState = value; }
        }


        #endregion

        #region 委托事件
        /// <summary>
        /// 上滑事件
        /// </summary>
        public event Action upSwipe;

        /// <summary>
        /// 下滑事件
        /// </summary>
        public event Action downSwipe;

        /// <summary>
        /// 左滑事件
        /// </summary>
        public event Action leftSwipe;

        /// <summary>
        /// 右滑事件
        /// </summary>
        public event Action rightSwipe;


        #endregion

        #region 构造方法
        public GestureOne()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        /// <summary>
        /// 评估滑动状态
        /// </summary>
        protected void EvaluateSwipe()
        {
            float angle = Vector2.Angle(deltaPos, Vector2.right);
            if (deltaPos.y < 0) angle = 360 - angle;
            if (angle < 45 || angle > 315)
            {
                if (rightSwipe != null) rightSwipe();
                SwipeState = OneSwipeState.Right;
            }
            else if (angle < 135)
            {
                if (upSwipe != null) upSwipe();
                EventMgr.Trigger("upSwipe");
                SwipeState = OneSwipeState.Up;
            }
            else if (angle < 225)
            {
                if (leftSwipe != null) leftSwipe();
                SwipeState = OneSwipeState.Left;
            }
            else if (angle < 315)
            {
                if (downSwipe != null) downSwipe();
                SwipeState = OneSwipeState.Down;
            }

        }

        protected override void SetLock(bool value)
        {
            base.SetLock(value);
            if (value) deltaPos.Set(0, 0);
        }

        #endregion

        #region 公开方法
        public virtual void OnGUI()
        {

        }
        #endregion
    }
}