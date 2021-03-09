#if UNITY_EDITOR
using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Game
{
    using MT = MessageType;
    public static class UIEditTip 
    {
        private static GUIContent cont = new GUIContent();

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
    }
}

#endif

