using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:手势管理
    /// </summary>
    public static class GestureMgr
    {
        #region 字段

        private static GestureOne one = null;

        private static GestureTwo two = null;

        #endregion

        #region 属性
        /// <summary>
        /// 一个手势
        /// </summary>
        public static GestureOne One { get { return one; } }

        /// <summary>
        /// 两个手势
        /// </summary>
        public static GestureTwo Two { get { return two; } }
        #endregion

        #region 构造方法
        static GestureMgr()
        {
            SetProperty();
        }
        #endregion

        #region 私有方法
        private static void SetProperty()
        {
            if (!Application.isPlaying) return;
            one = GestureOneFty.Create();
            two = GestureTwoFty.Create();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            if (one != null) one.Update();
            if (two != null) two.Update();
        }

        public static void Dispose()
        {

        }
        #endregion
    }
}