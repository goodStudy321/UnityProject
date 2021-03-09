using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:一个手势工厂
    /// </summary>
    public static class GestureOneFty
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static GestureOne Create()
        {
            switch (Application.platform)
            {
                case RuntimePlatform.IPhonePlayer:
                case RuntimePlatform.Android:
                    return new GestureOneFigure();
                default:
                    return new GestureMouseMove();
            }
        }
        #endregion
    }
}