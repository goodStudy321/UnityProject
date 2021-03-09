//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/25 19:28:57
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Random = UnityEngine.Random;

    //k:类型枚举,v:类型字符串
    using TypeDic = Dictionary<string, CSTypeInfo>;
    /// <summary>
    /// CSType
    /// </summary>
    public static class CSTypeMgr
    {
        #region 字段
        private static TypeDic dic = new TypeDic();

        private static List<string> types = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        static CSTypeMgr()
        {
            SetDic();
            SetTypes();
        }
        #endregion

        #region 私有方法
        private static void SetDic()
        {
            dic.Add("bool", new CSTypeInfo(CSType.Bool, "bool", "false"));
            dic.Add("string", new CSTypeInfo(CSType.String, "string", ""));
            dic.Add("byte", new CSTypeInfo(CSType.Byte, "byte", "0"));
            dic.Add("sbyte", new CSTypeInfo(CSType.SByte, "sbyte", "0"));
            dic.Add("char", new CSTypeInfo(CSType.Char, "char", "0"));
            dic.Add("double", new CSTypeInfo(CSType.Double, "double", "0"));
            dic.Add("float", new CSTypeInfo(CSType.Float, "float", "0"));
            dic.Add("int16", new CSTypeInfo(CSType.Int16, "Int16", "0"));
            dic.Add("uint16", new CSTypeInfo(CSType.UInt16, "UInt16", "0"));
            dic.Add("int32", new CSTypeInfo(CSType.Int32, "Int32", "0"));
            dic.Add("uint32", new CSTypeInfo(CSType.UInt32, "UInt32", "0"));
            dic.Add("int64", new CSTypeInfo(CSType.Int64, "Int64", "0"));
            dic.Add("uint64", new CSTypeInfo(CSType.UInt64, "UInt64", "0"));
            dic.Add("color", new CSTypeInfo(CSType.Color, "Color", "Color.black"));
            dic.Add("vector2", new CSTypeInfo(CSType.Vector2, "Vector2", "Vector2.Zero"));
            dic.Add("vector3", new CSTypeInfo(CSType.Vector3, "Vector3", "Vector3.Zero"));
            dic.Add("vector4", new CSTypeInfo(CSType.Vector4, "Vector4", "Vector4.Zero"));
        }

        private static void SetTypes()
        {
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var cur = em.Current;
                types.Add(cur.Value.Name);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取随机类型
        /// </summary>
        /// <returns></returns>
        public static string GetRandomType()
        {
            int length = types.Count;
            var i = Random.Range(0, length);
            i = Random.Range(0, length);
            var type = types[i];
            return type;
        }

        public static CSTypeInfo Get(string type)
        {
            type = type.ToLower();
            if (dic.ContainsKey(type)) return dic[type];
            return null;
        }

        public static string GetDefault(string type)
        {
            var info = Get(type);
            return (info == null ? "" : info.Default);
        }
        #endregion
    }
}