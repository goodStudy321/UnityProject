#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.8.2
    /// BG:输入控制
    /// </summary>
    public static class iInputMgr
    {
        #region 字段
        private static float vertical = 0;
        private static float horizontal = 0;
        private static Vector2 dir = Vector2.zero;

        /// <summary>
        /// 纵向轴线名称
        /// </summary>
        public const string VertitalAxisName = "Vertical";

        /// <summary>
        /// 水平轴线名称
        /// </summary>
        public const string HorizontalAxisName = "Horizontal";

        #endregion

        #region 属性
        /// <summary>
        /// true:水平轴线和纵向轴线有输入
        /// </summary>
        public static bool HV
        {
            get
            {
                if (vertical != 0) return true;
                if (horizontal != 0) return true;
                return false;
            }
        }

        /// <summary>
        /// 操作方向,X:代表X轴,y代表Z轴
        /// </summary>
        public static Vector2 Dir
        {
            get { return dir; }
            set { dir = value; }
        }
        #endregion

        #region 构造方法
        static iInputMgr()
        {
            MonoEvent.update += Update;
        }
        #endregion

        #region 私有方法


        private static void Update()
        {
#if UNITY_EDITOR || UNITY_STANDALONE
            OnStandalone();
#else
            OnMobile();
#endif
        }

        /// <summary>
        /// 在移动平台上
        /// </summary>
        private static void OnMobile()
        {

        }

        /// <summary>
        /// 在PC平台上
        /// </summary>
        private static void OnStandalone()
        {
            vertical = Input.GetAxis(VertitalAxisName);
            horizontal = Input.GetAxis(HorizontalAxisName);
            dir.Set(horizontal, vertical);
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}
#endif