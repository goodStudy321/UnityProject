/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/11/3 16:16:04
 ============================================================================*/

#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using MT = MessageType;
    /// <summary>
    /// 编辑器提示工具
    /// </summary>
    public static class UIEditTip
    {
        #region 字段
        private static GUIContent cont = new GUIContent();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static GUIStyle GetStyle(string name)
        {
            GUIStyle style = null;
            try
            {
                style = name;
            }
            catch (Exception)
            {
            }
            return style;
        }

        private static void Tip(MT type, string msg)
        {
            var win = EditorWindow.mouseOverWindow;
            if (win == null)
            {
                if (type == MT.Warning)
                {
                    Debug.LogWarning(msg);
                }
                else if (type == MT.Error)
                {
                    Debug.LogError(msg);
                }
            }
            else
            {
                cont.text = msg;
                Texture tex = null;
                GUIStyle style = null;
                if (type == MT.Warning)
                {
                    style = GetStyle(StyleTool.Warning);

                    Debug.LogWarning(msg);
                }
                else if (type == MT.Error)
                {
                    style = GetStyle(StyleTool.Error);
                    Debug.LogError(msg);
                }
                else
                {
                    //Debug.Log(msg);
                }
                tex = (style == null ? null : style.normal.background);
                cont.image = tex;
                win.ShowNotification(cont);
            }
        }


        private static void Show(MT type, string fmt, params object[] args)
        {
            var msg = string.Format(fmt, args);
            Tip(type, msg);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        /// <summary>
        /// 一般提示
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void Log(string fmt, params object[] args)
        {
            Show(MT.Info, fmt, args);
        }

        /// <summary>
        /// 错误提示
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void Error(string fmt, params object[] args)
        {
            Show(MT.Error, fmt, args);
        }

        /// <summary>
        /// 警告提示
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void Warning(string fmt, params object[] args)
        {
            Show(MT.Warning, fmt, args);
        }


        /// <summary>
        /// suc:显示Log,反之Error
        /// </summary>
        /// <param name="suc"></param>
        /// <param name="fmt"></param>
        /// <param name="args"></param>
        public static void Mutex(bool suc, string fmt, params object[] args)
        {
            MT type = suc ? MT.Info : MT.Error;
            var sfx = suc ? "成功" : "失败";
            fmt += sfx;
            Show(type, fmt, args);
        }
        #endregion
    }
}
#endif