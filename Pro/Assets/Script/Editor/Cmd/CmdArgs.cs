/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2013/5/10 14:39:05
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// 命令行参数
    /// </summary>
    public static class CmdArgs
    {
        #region 字段
        private static StrDic dic = null;

        public const string NO = "n";


        public const string YES = "y";
        /// <summary>
        /// 额外参数的键值
        /// </summary>
        public const string ExtraKey = "-extra";
        #endregion

        #region 属性
        /// <summary>
        /// 参数字典
        /// </summary>
        public static StrDic Dic
        {
            get
            {
                if (dic != null) return dic;
                dic = CmdTool.Parse('|');

                if (dic.ContainsKey(ExtraKey))
                {
                    string extra = dic[ExtraKey];
                    dic = Loong.Game.CmdTool.Parse(extra, ':', dic);
                }
                return dic;
            }
        }

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
        /// 获取布尔值参数
        /// </summary>
        /// <param name="k">键值</param>
        /// <param name="defaultVal">默认值</param>
        /// <returns></returns>
        public static bool GetBool(string k, bool defaultVal = false)
        {
            return GetBool(Dic, k, defaultVal);
        }

        /// <summary>
        /// 获取布尔值参数
        /// </summary>
        /// <param name="k">键值</param>
        /// <param name="defaultVal">默认值</param>
        public static bool GetBool(StrDic dic, string k, bool defaultVal = false)
        {
            if (dic == null) return defaultVal;
            if (string.IsNullOrEmpty(k)) return defaultVal;
            if (!dic.ContainsKey(k)) return defaultVal;
            var val = dic[k];
            val = val.ToLower();
            if (string.IsNullOrEmpty(val))
            {
                return defaultVal;
            }
            if (val == YES)
            {
                return true;
            }
            if (val == NO)
            {
                return false;
            }
            Debug.LogErrorFormat("Loong,k:{0},v:{1},only Y or N", k, val);
            return defaultVal;
        }

        /// <summary>
        /// 获取整型数值
        /// </summary>
        /// <param name="k">键值</param>
        /// <param name="defaultVal">默认值</param>
        /// <returns></returns>
        public static int GetInt(string k, int defaultVal = 0)
        {
            return GetInt(Dic, k, defaultVal);
        }

        public static int GetInt(StrDic dic, string k, int defaultVal = 0)
        {
            if (dic == null) return defaultVal;
            if (string.IsNullOrEmpty(k)) return defaultVal;
            if (dic.ContainsKey(k))
            {
                string str = dic[k];
                if (string.IsNullOrEmpty(str))
                {
                    return defaultVal;
                }
                str = str.Trim();
                int ver = defaultVal;
                if (!int.TryParse(str, out ver))
                {
                    Debug.LogErrorFormat("Loong,k:{0},v:{1},can't parse to int", k, str);
                }
                return ver;
            }
            return defaultVal;
        }

        /// <summary>
        /// 获取字符串参数
        /// </summary>
        /// <param name="dic"></param>
        /// <param name="k"></param>
        /// <param name="defaultVal"></param>
        /// <returns></returns>
        public static string GetStr(StrDic dic, string k, string defaultVal)
        {
            if (dic == null) return defaultVal;
            if (dic.ContainsKey(k))
            {
                return dic[k];
            }
            return defaultVal;
        }

        public static string GetStr(string k, string defaultVal)
        {
            return GetStr(Dic, k, defaultVal);
        }

        /// <summary>
        /// 保存参数
        /// </summary>
        public static void Save()
        {
            var cur = Directory.GetCurrentDirectory();
            var path = cur + "/CmdArgs.txt";
            string str = CmdTool.GetString(Dic);
            FileTool.Save(path, str);
        }
        #endregion
    }
}