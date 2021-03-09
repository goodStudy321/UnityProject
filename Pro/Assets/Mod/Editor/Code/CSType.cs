//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 19:33:37
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// CSType
    /// </summary>
    public enum CSType
    {
        /// <summary>
        /// 无
        /// </summary>
        None = 0,

        /// <summary>
        /// 布尔
        /// </summary>
        Bool,

        /// <summary>
        /// 无符号8位整数 (0,255)
        /// </summary>
        Byte,

        /// <summary>
        /// 有符号8位整数 (-128,127)
        /// </summary>
        SByte,

        /// <summary>
        /// 16位数字  (U+0000,U+FFFF)
        /// </summary>
        Char,


        /// <summary>
        /// 带符号16位整数 (-32768,32767)
        /// </summary>
        Int16,

        /// <summary>
        /// 无符号16位整数 (0,65535)
        /// </summary>
        UInt16,


        /// <summary>
        /// 带符号32位整数 (-2147483648,2147483647)
        /// </summary>
        Int32,

        /// <summary>
        /// 无符号32位整数 (0,4294967295)
        /// </summary>
        UInt32,

        /// <summary>
        /// 带符号64位整数 (-9223372036854775808,9223372036854775807)
        /// </summary>
        Int64,

        /// <summary>
        /// 无符号64位整数 (0,18446744073709551615)
        /// </summary>
        UInt64,


        /// <summary>
        /// 32位浮点型 精度7位
        /// </summary>
        Float,


        /// <summary>
        /// 64位浮点型 精度15-16位
        /// </summary>
        Double,


        /// <summary>
        /// 字符
        /// </summary>
        String,

        /// <summary>
        /// Unity二维向量
        /// </summary>
        Vector2,

        /// <summary>
        /// Unity三维向量
        /// </summary>
        Vector3,

        /// <summary>
        /// Unity四维向量
        /// </summary>
        Vector4,

        /// <summary>
        /// Unity颜色
        /// </summary>
        Color,
    }
}