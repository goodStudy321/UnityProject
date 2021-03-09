using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:两个手势基类
    /// </summary>
    public abstract class GestureTwo : GestureBase
    {
        #region 字段

        private float ratio = 0;

        #endregion

        #region 属性

        /// <summary>
        /// 速率 正值:扩展 负值:收缩
        /// </summary>
        public float Ratio
        {
            get { return ratio; }
            protected set { ratio = value; }
        }

        /// <summary>
        /// 手势状态
        /// </summary>
        public GestureTwoState State
        {
            get
            {
                if (Ratio == 0) return GestureTwoState.None;
                if (Ratio > 0) return GestureTwoState.Enlarge;
                return GestureTwoState.Shrink;
            }
        }

        #endregion

        #region 构造方法
        public GestureTwo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void SetLock(bool value)
        {
            base.SetLock(value);
            if (value) Ratio = 0;
        }
        #endregion

        #region 公开方法

        #endregion
    }

    /// <summary>
    /// 两个手势状态
    /// </summary>
    public enum GestureTwoState
    {
        /// <summary>
        /// 无
        /// </summary>
        None,
        /// <summary>
        /// 扩展
        /// </summary>
        Enlarge,
        /// <summary>
        /// 收缩
        /// </summary>
        Shrink,
    }
}