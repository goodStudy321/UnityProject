/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/2 21:03:32
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 对话框工具
    /// </summary>
    public static class DialogUtil
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
        /// 显示确认对话框
        /// </summary>
        /// <param name="title"></param>
        /// <param name="msg"></param>
        /// <param name="y"></param>
        /// <returns></returns>
        public static bool Show(string title, string msg)
        {
            if (msg == null) msg = "";
            if (title == null) title = "";
            return EditorUtility.DisplayDialog(title, msg, "确定");
        }

        /// <summary>
        /// 显示确认/取消对话框
        /// </summary>
        /// <param name="title">标题</param>
        /// <param name="msg">信息</param>
        /// <param name="ycb">确认回调</param>
        public static void Show(string title, string msg, Action ycb = null, string y = "确定", string n = "取消")
        {
            if (y == null) y = "确定";
            if (n == null) n = "取消";
            if (msg == null) msg = "";
            if (title == null) title = "";
            var yes = EditorUtility.DisplayDialog(title, msg, y, n);
            if (yes)
            {
                ycb();
            }
            else
            {
                UIEditTip.Log("已取消");
            }
        }

        #endregion
    }
}