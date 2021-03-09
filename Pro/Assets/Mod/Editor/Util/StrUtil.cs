//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 20:02:52
//=============================================================================

using System;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// StrUtil
    /// </summary>
    public static class StrUtil
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
        /// 返回首字母大写字符串
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string FirstUpper(string str)
        {
            if (string.IsNullOrEmpty(str)) return str;
            var c0 = str[0];
            if ('a' <= c0 && c0 <= 'z')
            {
                c0 = (char)(c0 & ~0x20);
                var arr = str.ToCharArray();
                arr[0] = c0;
                return new string(arr);
            }
            return str;
        }

        /// <summary>
        /// 返回首字母小写字符串
        /// </summary>
        /// <param name="str"></param>
        /// <returns></returns>
        public static string FirstLower(string str)
        {
            if (string.IsNullOrEmpty(str)) return str;
            var c0 = str[0];
            if ('A' <= c0 && c0 <= 'Z')
            {
                c0 = (char)(c0 | 0x20);
                var arr = str.ToCharArray();
                arr[0] = c0;
                return new string(arr);
            }
            return str;
        }
    }
    #endregion
}