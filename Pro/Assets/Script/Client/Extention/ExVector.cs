//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/6 14:14:11
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// ExVector
    /// </summary>
    public static class ExVector
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
        public static void Read(ref Vector2 value, BinaryReader br)
        {
            value.x = br.ReadSingle();
            value.y = br.ReadSingle();
        }

        public static void Write(this Vector2 value, BinaryWriter bw)
        {
            bw.Write(value.x);
            bw.Write(value.y);
        }

        public static void Read(ref Vector3 value, BinaryReader br)
        {
            value.x = br.ReadSingle();
            value.y = br.ReadSingle();
            value.z = br.ReadSingle();
        }

        public static void Write(this Vector3 value, BinaryWriter bw)
        {
            bw.Write(value.x);
            bw.Write(value.y);
            bw.Write(value.z);
        }

        public static void Read(ref Vector4 value, BinaryReader br)
        {
            value.x = br.ReadSingle();
            value.y = br.ReadSingle();
            value.z = br.ReadSingle();
            value.w = br.ReadSingle();
        }

        public static void Write(this Vector4 value, BinaryWriter bw)
        {
            bw.Write(value.x);
            bw.Write(value.y);
            bw.Write(value.z);
            bw.Write(value.w);
        }
        #endregion
    }
}