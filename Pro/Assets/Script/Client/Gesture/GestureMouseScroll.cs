using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:鼠标滚动手势
    /// </summary>
    public class GestureMouseScroll : GestureTwo
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public GestureMouseScroll()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void GestureNone()
        {
            Ratio = Input.GetAxisRaw("Mouse ScrollWheel");
            if (Ratio != 0)
            {
                Process = ProcessState.Enter;
            }
        }

        protected override void GestureExecute()
        {
            Ratio = Input.GetAxisRaw("Mouse ScrollWheel");
            Ratio *= 5;
            if (Ratio == 0)
            {
                Process = ProcessState.Exit;
            }
        }

        protected override void GestureExit()
        {
            Ratio = 0;
        }
        #endregion

        #region 公开方法

        #endregion
    }
}