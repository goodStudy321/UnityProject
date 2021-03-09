using LuaInterface;
using System.Diagnostics;
using System.Collections.Generic;

namespace Loong.Game
{
    using Lang = Phantom.Localization;
    /// <summary>
    /// AU:Loong
    /// TM:2014.07.5
    /// BG:运行时在屏幕中类似弹幕的提示
    /// </summary>
    public static class UITip
    {
        #region 字段
        private static LuaTable table;

        private static LuaFunction launchFunc = null;

#if UNITY_EDITOR
        private static string EditFlag = "Editor:";
#endif
        #endregion

        #region 属性

        #endregion


        #region 构造方法

        #endregion

        #region 私有方法
        private static void Launch(string msg, string color = null)
        {
            if (table == null)
            {
                table = LuaTool.GetTable(LuaMgr.Lua, "UITip");
            }
            if (table == null)
            {
                return;
            }
            if (launchFunc == null)
            {
                launchFunc = table.GetLuaFunction("Launch");
            }
            if (launchFunc != null)
            {
                launchFunc.BeginPCall();
                launchFunc.Push(msg);
                if (!string.IsNullOrEmpty(color))
                {
                    launchFunc.Push(color);
                }
                launchFunc.PCall();
                launchFunc.EndPCall();
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 普通输出
        /// </summary>
        public static void Log(string fmt, params object[] args)
        {
            var msg = string.Format(fmt, args);
            Launch(msg);
        }

        /// <summary>
        /// 警告输出
        /// </summary>
        public static void Warning(string fmt, params object[] args)
        {
            var msg = string.Format(fmt, args);
            Launch(msg, "[EE9572]");
        }

        /// <summary>
        /// 错误输出
        /// </summary>
        public static void Error(string fmt, params object[] args)
        {
            var msg = string.Format(fmt, args);
            Launch(msg, "[EE0000]");
        }


        #region 本地化

        public static void LocalLog(uint id, params object[] args)
        {
            var fmt = Lang.Instance.GetDes(id);
            Log(fmt, args);
        }

        /// <summary>
        /// 警告输出
        /// </summary>
        public static void LocalWarning(uint id, params object[] args)
        {
            var fmt = Lang.Instance.GetDes(id);
            Warning(fmt, args);
        }

        /// <summary>
        /// 错误输出
        /// </summary>
        public static void LocalError(uint id, params object[] args)
        {
            var fmt = Lang.Instance.GetDes(id);
            Error(fmt, args);
        }
        #endregion

        /// <summary>
        /// 编辑器内普通输出
        /// </summary>
        [Conditional("UNITY_EDITOR")]
        public static void eLog(string fmt, params object[] args)
        {
#if !LOONG_UITIP_DISABLE && UNITY_EDITOR
            fmt = EditFlag + fmt;
            var msg = string.Format(fmt, args);
            Launch(msg);
#endif
        }

        /// <summary>
        /// 编辑器内警告输出
        /// </summary>
        [Conditional("UNITY_EDITOR")]
        public static void eWarning(string fmt, params object[] args)
        {
#if !LOONG_UITIP_DISABLE && UNITY_EDITOR
            fmt = EditFlag + fmt;
            var msg = string.Format(fmt, args);
            Launch(msg, "[EE9572]");
#endif
        }

        /// <summary>
        /// 编辑器内错误输出
        /// </summary>
        [Conditional("UNITY_EDITOR")]
        public static void eError(string fmt, params object[] args)
        {
#if !LOONG_UITIP_DISABLE && UNITY_EDITOR
            fmt = EditFlag + fmt;
            var msg = string.Format(fmt, args);
            Launch(msg, "[EE0000]");
#endif
        }

        #endregion
    }
}