using System;
using ProtoBuf;
using UnityEngine;
using System.Reflection;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2015-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        c68b149a-11df-415a-b2d7-0edb3e661426
    */

    /// <summary>
    /// AU:Loong
    /// TM:2015/3/11 12:19:52
    /// BG:反射工具
    /// </summary>
    public static class ReflectionTool
    {
        #region 字段

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

        public static void Call(Assembly asm, string tn, string func, BindingFlags flags, params object[] args)
        {
            var type = asm.GetType(tn);
            if (type == null) return;
            var method = type.GetMethod(func, flags);
            if (method == null) return;
            method.Invoke(null, args);
        }

        /// <summary>
        /// 获取同一程序集中指定类型的所有子类型
        /// </summary>
        /// <param name="baseType">及</param>
        public static List<Type> GetSubType(Type baseType)
        {
            if (baseType == null) return null;
            List<Type> results = null;
            Assembly asm = Assembly.GetAssembly(baseType);
            Type[] types = asm.GetTypes();
            int length = types.Length;
            for (int i = 0; i < length; i++)
            {
                Type type = types[i];
                if (!type.IsSubclassOf(baseType)) continue;
                if (results == null) results = new List<Type>();
                results.Add(type);
            }
            return results;
        }

        /// <summary>
        /// 获取同一程序集中指定泛型类型定义的所有子类型
        /// </summary>
        /// <param name="genericDefinions">泛型</param>
        /// <returns></returns>
        public static List<Type> GetGenericSubType(Type genericDefinion)
        {
            if (!genericDefinion.IsGenericTypeDefinition) return null;
            List<Type> results = null;
            Assembly asm = Assembly.GetAssembly(genericDefinion);
            Type[] types = asm.GetTypes();
            int length = types.Length;
            for (int i = 0; i < length; i++)
            {
                Type type = types[i];
                Type baseType = type.BaseType;
                while (true)
                {
                    if (baseType == null) break;
                    if (!baseType.IsGenericType) break;
                    Type genericType = baseType.GetGenericTypeDefinition();
                    if (genericType == null) break;
                    if (genericType.Equals(genericDefinion))
                    {
                        if (results == null) results = new List<Type>();
                        results.Add(type);
                        break;
                    }
                    baseType = genericType.BaseType;
                }
            }
            return results;
        }

        /// <summary>
        /// 获取指定类型的特性数组
        /// </summary>
        /// <typeparam name="T">特性类型</typeparam>
        /// <param name="type">指定类型</param>
        /// <returns></returns>
        public static T[] GetAttributes<T>(Type type) where T : Attribute
        {
            object[] objs = type.GetCustomAttributes(typeof(T), false);
            if (objs == null || objs.Length == 0) return null;
            int length = objs.Length;
            T[] attrs = new T[length];
            for (int i = 0; i < length; i++)
            {
                T t = objs[i] as T;
                attrs[i] = t;
            }
            return attrs;
        }

        /// <summary>
        /// 获取指定类型的特性
        /// </summary>
        /// <typeparam name="T">特性类型</typeparam>
        /// <param name="type">指定类型</param>
        public static T GetAttribute<T>(Type type) where T : Attribute
        {
            object[] attrs = type.GetCustomAttributes(typeof(T), false);
            if (attrs == null || attrs.Length == 0) return null;
            return attrs[0] as T;
        }

        /// <summary>
        /// 获取所有子类型某特性的列表
        /// </summary>
        /// <typeparam name="T">特性</typeparam>
        /// <param name="baseType">基类型</param>
        /// <returns></returns>
        public static List<T> GetSubAttributes<T>(Type baseType) where T : Attribute
        {
            if (baseType == null) return null;
            List<Type> types = GetSubType(baseType);
            if (types == null) return null;
            List<T> attrs = null;
            int length = types.Count;
            for (int i = 0; i < length; i++)
            {
                Type type = types[i];
                T attr = GetAttribute<T>(type);
                if (attr == null) continue;
                if (attrs == null) attrs = new List<T>();
                attrs.Add(attr);
            }
            return attrs;
        }


        /// <summary>
        /// 调用对象中所有List属性的Clear方法
        /// </summary>
        /// <param name="obj"></param>
        public static void ListPropClear(object obj)
        {
            if (obj == null) return;
            Type target = obj.GetType();
            if (target == typeof(string)) return;
            if (!target.IsClass) return;
            BindingFlags flags = BindingFlags.Instance | BindingFlags.Public;
            PropertyInfo[] props = target.GetProperties(flags);
            if (props == null) return;
            Type listType = typeof(IList);
            int length = props.Length;
            for (int i = 0; i < length; i++)
            {
                PropertyInfo prop = props[i];
                object propObj = prop.GetValue(obj, null);
                if (propObj == null) continue;
                Type propType = prop.PropertyType;
                if (listType.IsAssignableFrom(propType))
                {
                    IList lst = propObj as IList;
                    lst.Clear();
                }
                else if (propType.IsClass && propType != typeof(string))
                {
                    object[] ps = prop.GetCustomAttributes(typeof(ProtoMemberAttribute), false);
                    if (ps == null || ps.Length < 1)
                    {
                        ListPropClear(propObj);
                    }
                    else
                    {
                        ProtoMemberAttribute pa = ps[0] as ProtoMemberAttribute;
                        if (pa.IsRequired)
                        {
                            ListPropClear(propObj);
                        }
                        else
                        {
                            prop.SetValue(obj, null, null);
                        }
                    }
                }
            }
        }
        #endregion
    }
}