/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/13 17:21:46
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    public delegate void ScreenOrientHandler(ScreenOrientation orient);

    /// <summary>
    /// ScreenUtil
    /// </summary>
    public static class ScreenUtil
    {
        #region 字段
        private static ScreenOrientation orient = ScreenOrientation.Landscape;
        #endregion

        #region 属性
        public static ScreenOrientation Orient
        {
            get { return orient; }
        }
        #endregion

        #region 委托事件
        /// <summary>
        /// 方向改变事件
        /// </summary>
        public static event ScreenOrientHandler change;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static void Change()
        {

            EventMgr.Trigger("ScreenOrient", (int)orient);
            if (change != null) change(orient);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
#if UNITY_EDITOR
            if (Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift))
            {
                if (Input.GetKeyDown(KeyCode.X))
                {
                    bool isChange = false;
                    if (orient == ScreenOrientation.Portrait)
                    {
                        orient = ScreenOrientation.LandscapeLeft;
                        isChange = true;
                    }
                    if (orient == ScreenOrientation.Landscape)
                    {
                        orient = ScreenOrientation.LandscapeRight;
                        isChange = true;
                    }
                    else if (orient == ScreenOrientation.LandscapeRight)
                    {
                        orient = ScreenOrientation.Landscape;
                        isChange = true;
                    }
                    if (isChange)
                    {
                        Change();
                    }
                }
                else if (Input.GetKeyDown(KeyCode.C))
                {
                    Change();
                }
            }
#else
            if (Screen.orientation == orient) return;
            orient = Screen.orientation;
            Change();
#endif
        }


        public static void Init()
        {
            orient = Screen.orientation;
#if UNITY_EDITOR
            if (orient != ScreenOrientation.LandscapeLeft)
            {
                orient = ScreenOrientation.LandscapeLeft;
            }
#endif
            Change();
        }
        #endregion
    }
}