//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/6 19:51:45
//=============================================================================

using System;
using System.IO;
using System.Text;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// ExString
    /// </summary>
    public static class ExString
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
        public static void Read(ref string str, BinaryReader br)
        {
            var count = br.ReadInt32();
            if (count > 0)
            {
                byte[] bytes = new byte[count];
                var len = br.Read(bytes, 0, count);
                if (len == count)
                {
                    str = Encoding.UTF8.GetString(bytes, 0, count);
                }
                else
                {
                    str = "";
                }
            }
            else
            {
                str = "";
            }
        }


        public static void Write(string str, BinaryWriter bw)
        {
            if (string.IsNullOrEmpty(str))
            {
                bw.Write(0);
            }
            else
            {
                var bytes = Encoding.UTF8.GetBytes(str);
                var len = bytes.Length;
                bw.Write(len);
                bw.Write(bytes, 0, len);
            }
        }

        public static bool IsAlphaNum(this string str)
        {
            if (str == null) return false;
            int length = str.Length;
            for (int i = 0; i < length; i++)
            {
                var a = str[i];
                if (a > 96 && a < 123) continue;
                if (a > 64 && a < 91) continue;
                if (a > 47 && a < 58) continue;
                return false;
            }
            return true;
        }

        public static bool IsAlpha(this string str)
        {
            if (str == null) return false;
            int length = str.Length;
            for (int i = 0; i < length; i++)
            {
                var a = str[i];
                if (a > 96 && a < 123) continue;
                if (a > 64 && a < 91) continue;
                return false;
            }
            return true;
        }

        public static bool IsNum(this string str)
        {
            if (str == null) return false;
            int length = str.Length;
            for (int i = 0; i < length; i++)
            {
                var a = str[i];
                if (a > 47 && a < 58) continue;
                return false;
            }
            return true;
        }
        #endregion
    }
}