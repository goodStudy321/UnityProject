//=============================================================================
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2014/05/10 16:10:37
// e开头方法,仅在编辑器下有效,建议使用App.IsEditor或UNITY_EDITOR包裹
// d开头方法,仅在Debug模式下有效,建议使用App.IsDebug包裹
//=============================================================================

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Diagnostics;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;

namespace Hello.Game
{

    public static class iTrace
    {
        #region 字段
        private static bool enable = false;
#if GAME_DEBUG || CS_HOTFIX_ENABLE

        /// <summary>
        /// 冷却计时
        /// </summary>
        private static float coolDown = 0;

#endif

        /// <summary>
        /// 日志目录
        /// </summary>
        private static string logDir = null;

        /// <summary>
        /// 线程锁
        /// </summary>
        private static readonly object alock = new object();

#if UNITY_EDITOR
        /// <summary>
        /// 可变字符序列
        /// </summary>
        private static StringBuilder temp = new StringBuilder();
#endif
#if GAME_DEBUG || CS_HOTFIX_ENABLE
        /// <summary>
        /// 当前日志类型
        /// </summary>
        private static LogType logType = LogType.Error;
        /// <summary>
        /// 按钮自动不觉选项
        /// </summary>
        private static GUILayoutOption[] btnOpt = new GUILayoutOption[2];

        /// <summary>
        /// 自动布局选项
        /// </summary>
        private static GUILayoutOption[] layoutOptions = new GUILayoutOption[1] { GUILayout.Width(Screen.width) };

#endif
        /// <summary>
        /// 日志类型字典
        /// </summary>
        private static Dictionary<LogType, LogBase> logDic = new Dictionary<LogType, LogBase>();


        #endregion

        #region 属性

        /// <summary>
        /// true:激活
        /// </summary>
        public static bool Enable
        {
            get { return enable; }
            set { enable = value; }
        }

        #endregion

        #region 构造方法
        static iTrace()
        {

        }
        #endregion

        #region 私有方法

        private static void OnDestroy()
        {
            Application.logMessageReceivedThreaded -= Write;
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public static void Init()
        {
#if UNITY_EDITOR
            if (!UnityEditor.EditorApplication.isPlaying) return;
#endif
            if (!App.IsDebug) return;
            //Debug.Log("Loong, iTrace Init");
            CheckOldLog();
            var day = DateTime.Now.ToString("yyyy-MM-dd");
            logDir = Application.persistentDataPath + "/Log/" + day + "/";
            if (!Directory.Exists(logDir)) Directory.CreateDirectory(logDir);
            var errPath = string.Format("{0}Error.txt", logDir);
            var err = new CommonLog(errPath);
            //err.CanWrite = true;
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            err.TextColor = Color.red;
            MonoEvent.onGUI += OnGUI;
            MonoEvent.update += Update;
            MonoEvent.onDestroy += OnDestroy;

            string normPath = string.Format("{0}Normal.txt", logDir);
            var norm = new CommonLog(normPath);
            norm.TextColor = Color.white;

            string warnPath = string.Format("{0}Warning.txt", logDir);
            var warn = new CommonLog(warnPath);
            warn.TextColor = Color.yellow;


            logDic.Add(LogType.Log, norm);
            logDic.Add(LogType.Warning, warn);


            float btnHt = Screen.height * 0.08f;
            btnOpt[0] = GUILayout.Height(btnHt);
            btnOpt[1] = GUILayout.Width(Screen.width / 3);

            //不清理 积累多后I/O很慢
            warn.ClearFile();
            norm.ClearFile();

            logDic.Add(LogType.Assert, err);
            logDic.Add(LogType.Error, err);
            logDic.Add(LogType.Exception, err);
            Application.logMessageReceivedThreaded += Write;
#endif
#if UNITY_EDITOR
            err.ClearFile();
#endif
        }

        public static void ResetBtn()
        {
#if GAME_DEBUG || CS_HOTFIX_ENABLE
            btnOpt[1] = GUILayout.Width(Screen.width / 3);
#endif
        }


        /// <summary>
        /// 检查并清除14天之前/1年内的日志
        /// </summary>
        private static void CheckOldLog()
        {
            for (int i = 14; i < 374; i++)
            {
                TimeSpan span = new TimeSpan(i, 0, 0, 0);
                DateTime time = DateTime.Now - span;
                string day = time.ToString("yyyy-MM-dd");
                string dir = Application.persistentDataPath + "/Log/" + day;
                if (!Directory.Exists(dir)) continue;
                Directory.Delete(dir, true);
                Log("Loong", string.Format("删除日期为{0}的日志", day));
            }
        }

        /// <summary>
        /// 对日志进行分类操作
        /// </summary>
        /// <param name="msg"></param>
        /// <param name="stack"></param>
        /// <param name="type"></param>
        private static void Write(string msg, string stack, LogType type)
        {
            lock (alock)
            {
                if (logDic.ContainsKey(type))
                {
                    logDic[type].Write(msg, stack, type);
                }
            }
        }

#if GAME_DEBUG || CS_HOTFIX_ENABLE
        [Conditional("UNITY_EDITOR")]
        private static void EnableError(LogType logType)
        {
            switch (logType)
            {
                case LogType.Assert:
                case LogType.Error:
                case LogType.Exception:
                    Enable = true;
                    break;
                case LogType.Log:
                case LogType.Warning:
                default:
                    break;
            }
        }

        public static void Update()
        {
            OnMobile();
            OnStandalone();
            if (enable) logDic[logType].Update();
        }



        [Conditional("UNITY_ANDROID"), Conditional("UNITY_IOS"), Conditional("UNITY_IPHONE")]
        private static void OnMobile()
        {
            if (Input.touchCount > 2)
            {
                coolDown += Time.unscaledDeltaTime;
                if (coolDown < 2) return;
                Enable = !enable; if (enable) logDic[logType].Open();
                coolDown = 0;
            }
            else
            {
                coolDown = 0;
            }
        }

        [Conditional("UNITY_STANDALONE"), Conditional("UNITY_EDITOR")]
        private static void OnStandalone()
        {
            if (Input.GetKey(KeyCode.LeftShift))
            {
                if (Input.GetKeyDown(KeyCode.C))
                {
                    Enable = !enable; if (enable) logDic[logType].Open();
                }
            }
        }

        private static void OnGUI()
        {
            if (!enable) return;
            GUILayout.BeginHorizontal(layoutOptions);
            if (GUILayout.Button("一般输出", btnOpt))
            {
                logType = LogType.Log;
            }
            else if (GUILayout.Button("警告输出", btnOpt))
            {
                logType = LogType.Warning;
            }
            else if (GUILayout.Button("错误输出", btnOpt))
            {
                logType = LogType.Error;
            }

            GUILayout.EndHorizontal();
            logDic[logType].OnGUI();
        }
#endif

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 错误输出/并可写入日志
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="id"></param>
        public static void Error(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.LogError(Format(id, fmt, args));
        }

        /// <summary>
        /// 警告输出/并可写入日志
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        public static void Warning(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.LogWarning(Format(id, fmt, args));
        }

        /// <summary>
        /// 一般输出/只编辑器下有效/发布后不可写入日志
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        [Conditional("UNITY_EDITOR")]
        public static void eLog(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.Log(Format(id + "[Editor]", fmt, args));
        }

        /// <summary>
        /// 警告输出/只编辑器下有效/发布后不可写入日志
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="id"></param>
        [Conditional("UNITY_EDITOR")]
        public static void eWarning(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.LogWarning(Format(id + "[Editor]", fmt, args));
        }

        /// <summary>
        /// 错误输出/只编辑器下有效/发布后不可写入日志
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        [Conditional("UNITY_EDITOR")]
        public static void eError(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.LogError(Format(id + "[Editor]", fmt, args));
        }

        /// <summary>
        /// 一般输出,仅Debug模式下有效
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        public static void dLog(string id, string fmt, params object[] args)
        {
#if LOONG_LOG_DISABLE
            return;
#endif
            if (!App.IsDebug) return;
            Debug.Log(Format(id + "[Debug]", fmt, args));
        }

        /// <summary>
        /// 警告输出,仅Debug模式下有效
        /// </summary>
        /// <param name="fmt"></param>
        /// <param name="id"></param>
        public static void dWarning(string id, string fmt, params object[] args)
        {
#if  LOONG_LOG_DISABLE
            return;
#endif
            if (!App.IsDebug) return;
            Debug.LogWarning(Format(id + "[Debug]", fmt, args));
        }

        /// <summary>
        /// 错误输出,仅Debug模式下有效
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        public static void dError(string id, string fmt, params object[] args)
        {
#if LOONG_LOG_DISABLE
            return;
#endif
            if (!App.IsDebug) return;
            Debug.LogError(Format(id + "[Debug]", fmt, args));
        }


        /// <summary>
        ///  一般输出/可写入日志
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        public static void Log(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR && LOONG_LOG_DISABLE
            return;
#endif
            Debug.Log(Format(id, fmt, args));
        }

        /// <summary>
        /// 格式化输出/用于在控制台精确定位代码位置
        /// </summary>
        /// <param name="id"></param>
        /// <param name="fmt"></param>
        /// <returns></returns>
        public static string Format(string id, string fmt, params object[] args)
        {
#if UNITY_EDITOR
            temp.Remove(0, temp.Length);
            temp.Append("<b><i>");
            temp.Append(id).Append(": ");
            temp.Append("</i></b>");
            temp.Append(DateTime.Now.ToString("[HH:mm:ss fff] "));
            if (args == null || args.Length < 1)
            {
                temp.Append(fmt);
            }
            else
            {
                temp.Append(string.Format(fmt, args));
            }
            return temp.ToString();
#else
            if (args == null || args.Length < 1)
            {
                return string.Format("{0}: {1}", id, fmt);
            }
            var str = string.Format(fmt, args);
            return string.Format("{0}: {1}", id, str);
#endif
        }


        /// <summary>
        /// 清理屏幕信息
        /// </summary>
        /// <param name="logtype"></param>
        public static void Clear(LogType logtype)
        {
            if (logDic.ContainsKey(logtype))
            {
                logDic[logtype].Clear();
            }
        }

        /// <summary>
        /// 清理所有信息
        /// </summary>
        public static void ClearAll()
        {
            var em = logDic.GetEnumerator();
            while (em.MoveNext())
            {
                em.Current.Value.Clear();
            }
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            var em = logDic.GetEnumerator();
            while (em.MoveNext())
            {
                em.Current.Value.Dispose();
            }
        }
        #endregion
    }
}