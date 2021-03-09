using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.26
    /// BG:可变字符串工具
    /// </summary>
    public static class SbTool
    {
        #region 字段
        private static StringBuilder temp = new StringBuilder();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 根据字符串数组获取字符串
        /// </summary>
        /// <param name="args">字符串数组</param>
        /// <returns></returns>
        public static string Get(params string[] args)
        {
            return Get(temp, args);
        }

        /// <summary>
        /// 根据字符串数组获取字符串
        /// </summary>
        /// <param name="sb">可变字符串</param>
        /// <param name="args">字符串数组</param>
        /// <returns></returns>
        public static string Get(StringBuilder sb, params string[] args)
        {
            if (sb == null) return null;
            if (args == null || args.Length == 0) return null;
            sb.Remove(0, sb.Length);
            int length = args.Length;
            for (int i = 0; i < length; i++)
            {
                string arg = args[i];
                if (string.IsNullOrEmpty(arg)) continue;
                sb.Append(arg);
            }
            string str = sb.ToString();
            return str;
        }

        /// <summary>
        /// 将字符串数组的所有项使用'/'分割
        /// </summary>
        /// <param name="args">字符串数组</param>
        /// <returns></returns>
        public static string Combine(params string[] args)
        {
            return Combine(temp, args);
        }


        /// <summary>
        /// 将字符串数组的所有项使用'/'分割
        /// </summary>
        /// <param name="sb">可变字符串</param>
        /// <param name="args">字符串数组</param>
        /// <returns></returns>
        public static string Combine(StringBuilder sb, params string[] args)
        {
            if (sb == null) return null;
            if (args == null || args.Length == 0) return null;
            sb.Remove(0, sb.Length);
            int length = args.Length;
            int last = length - 1;
            for (int i = 0; i < length; i++)
            {
                string arg = args[i];
                if (string.IsNullOrEmpty(arg)) continue;
                sb.Append(arg);
                if (i < last) sb.Append("/");
            }
            string str = sb.ToString();
            return str;
        }
        #endregion
    }
}