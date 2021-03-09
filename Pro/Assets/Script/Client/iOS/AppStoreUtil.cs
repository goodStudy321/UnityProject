/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/20 22:17:26
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 苹果应用商店工具
    /// </summary>
    public static class AppStoreUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取应用主界面链接
        /// </summary>
        /// <param name="appid"></param>
        /// <returns></returns>
        public static string GetURL(string appid)
        {
            var url = string.Format("itms-apps://itunes.apple.com/cn/app/id{0}?mt=8", appid);
            return url;
        }

        /// <summary>
        /// 打开应用主界面
        /// </summary>
        /// <param name="appid"></param>
        /// <returns></returns>
        public static void Open(string appid)
        {
            var url = GetURL(appid);
            Application.OpenURL(url);
        }

        /// <summary>
        /// 打开评价界面
        /// </summary>
        /// <param name="appid"></param>
        /// <returns></returns>
        public static void Evaluate(string appid)
        {
            var url = GetURL(appid);
            var fullUrl = string.Format("{0}?&action=write-review", url);
            Application.OpenURL(fullUrl);
        }
        #endregion
    }
}